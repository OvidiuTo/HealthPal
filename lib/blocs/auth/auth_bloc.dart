import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:track_health/models/user_model.dart';

// Events
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class SignInRequested extends AuthEvent {
  final String email;
  final String password;

  const SignInRequested(this.email, this.password);

  @override
  List<Object?> get props => [email, password];
}

class SignUpRequested extends AuthEvent {
  final String email;
  final String password;

  const SignUpRequested(this.email, this.password);

  @override
  List<Object?> get props => [email, password];
}

class SignOutRequested extends AuthEvent {}

class AuthStateChanged extends AuthEvent {
  final User? user;

  const AuthStateChanged(this.user);

  @override
  List<Object?> get props => [user];
}

// States
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final User user;

  const Authenticated(this.user);

  @override
  List<Object?> get props => [user];
}

class UnAuthenticated extends AuthState {}

class AuthError extends AuthState {
  final String error;

  const AuthError(this.error);

  @override
  List<Object?> get props => [error];
}

// Bloc
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final StreamSubscription<User?> _authStateSubscription;

  AuthBloc() : super(AuthInitial()) {
    // Listen to auth state changes
    _authStateSubscription = _auth.authStateChanges().listen((user) {
      add(AuthStateChanged(user));
    });

    // Handle auth state changes
    on<AuthStateChanged>((event, emit) {
      if (event.user != null) {
        emit(Authenticated(event.user!));
      } else {
        emit(UnAuthenticated());
      }
    });

    // When User Signs In
    on<SignInRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final userCredential = await _auth.signInWithEmailAndPassword(
          email: event.email,
          password: event.password,
        );
        emit(Authenticated(userCredential.user!));
      } on FirebaseAuthException catch (e) {
        emit(AuthError(e.message ?? 'An error occurred'));
        emit(UnAuthenticated());
      }
    });

    // When User Signs Up
    on<SignUpRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        print('Starting sign up process...'); // Debug print

        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: event.email,
          password: event.password,
        );

        print(
            'User created with ID: ${userCredential.user!.uid}'); // Debug print

        // Create user document in Firestore
        final user = UserModel(
          uid: userCredential.user!.uid,
          email: userCredential.user!.email!,
          dailyCalorieGoal: 2000,
        );

        print('Attempting to create Firestore document...'); // Debug print
        print('User data to save: ${user.toMap()}'); // Debug print

        try {
          await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .set(user.toMap())
              .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              throw TimeoutException('Firestore operation timed out');
            },
          );
          print('Firestore document created successfully'); // Debug print
        } catch (e, stackTrace) {
          print('Error creating Firestore document: $e'); // Debug print
          print('Stack trace: $stackTrace'); // Debug print
          emit(AuthError('Account created but failed to save preferences: $e'));
        }

        emit(Authenticated(userCredential.user!));
      } on FirebaseAuthException catch (e) {
        print('Firebase Auth Error: ${e.message}'); // Debug print
        emit(AuthError(e.message ?? 'An error occurred'));
        emit(UnAuthenticated());
      } catch (e, stackTrace) {
        print('Unexpected error during sign up: $e'); // Debug print
        print('Stack trace: $stackTrace'); // Debug print
        emit(AuthError('An unexpected error occurred: $e'));
        emit(UnAuthenticated());
      }
    });

    // When User Signs Out
    on<SignOutRequested>((event, emit) async {
      emit(AuthLoading());
      await _auth.signOut();
      emit(UnAuthenticated());
    });
  }

  @override
  Future<void> close() {
    _authStateSubscription.cancel();
    return super.close();
  }
}
