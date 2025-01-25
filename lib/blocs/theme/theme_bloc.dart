import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Events
abstract class ThemeEvent extends Equatable {
  const ThemeEvent();

  @override
  List<Object?> get props => [];
}

class ToggleTheme extends ThemeEvent {}

class LoadTheme extends ThemeEvent {}

// State
class ThemeState extends Equatable {
  final bool isDarkMode;

  const ThemeState({required this.isDarkMode});

  @override
  List<Object?> get props => [isDarkMode];
}

// Bloc
class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  static const _prefsKey = 'isDarkMode';
  final SharedPreferences _prefs;

  ThemeBloc(this._prefs) : super(ThemeState(isDarkMode: false)) {
    on<LoadTheme>((event, emit) {
      final isDarkMode = _prefs.getBool(_prefsKey) ?? false;
      emit(ThemeState(isDarkMode: isDarkMode));
    });

    on<ToggleTheme>((event, emit) {
      final isDarkMode = !state.isDarkMode;
      _prefs.setBool(_prefsKey, isDarkMode);
      emit(ThemeState(isDarkMode: isDarkMode));
    });

    add(LoadTheme());
  }
}
