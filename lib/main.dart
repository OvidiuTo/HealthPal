import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:track_health/blocs/auth/auth_bloc.dart';
import 'package:track_health/blocs/theme/theme_bloc.dart';
import 'package:track_health/firebase_options.dart';
import 'package:track_health/pages/auth_page.dart';
import 'package:track_health/pages/home_page.dart';
import 'package:track_health/pages/main_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:track_health/theme/app_colors.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully'); // Debug print
  } catch (e) {
    print('Error initializing Firebase: $e'); // Debug print
  }

  runApp(MyApp(prefs: prefs));
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;

  const MyApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => AuthBloc()),
        BlocProvider(create: (context) => ThemeBloc(prefs)),
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) {
          return MaterialApp(
            title: 'HealthPal',
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.light(
                primary: AppColors.lightPrimary,
                secondary: AppColors.lightAccent,
                background: AppColors.lightBackground,
                surface: AppColors.lightBackground,
                error: AppColors.error,
                onPrimary: Colors.white,
                onSecondary: Colors.white,
                onBackground: AppColors.textDark,
                onSurface: AppColors.textDark,
              ),
              scaffoldBackgroundColor: AppColors.lightBackground,
              appBarTheme: AppBarTheme(
                backgroundColor: AppColors.lightPrimary,
                foregroundColor: Colors.white,
                elevation: 0,
                systemOverlayStyle: SystemUiOverlayStyle(
                  statusBarColor: AppColors.lightPrimary,
                  statusBarIconBrightness: Brightness.light,
                  statusBarBrightness: Brightness.dark,
                ),
              ),
              cardTheme: CardTheme(
                color: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              floatingActionButtonTheme: FloatingActionButtonThemeData(
                backgroundColor: AppColors.lightPrimary,
                foregroundColor: Colors.white,
              ),
              navigationBarTheme: NavigationBarThemeData(
                backgroundColor: Colors.white,
                indicatorColor: AppColors.lightPrimary.withOpacity(0.2),
                labelTextStyle: MaterialStateProperty.all(
                  const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.dark(
                primary: AppColors.darkPrimary,
                secondary: AppColors.darkAccent,
                background: AppColors.darkBackground,
                surface: AppColors.darkBackground,
                error: AppColors.error,
                onPrimary: Colors.white,
                onSecondary: Colors.white,
                onBackground: AppColors.textLight,
                onSurface: AppColors.textLight,
              ),
              scaffoldBackgroundColor: AppColors.darkBackground,
              appBarTheme: AppBarTheme(
                backgroundColor: AppColors.darkBackground,
                foregroundColor: AppColors.textLight,
                elevation: 0,
              ),
              cardTheme: CardTheme(
                color: AppColors.cardDark,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              floatingActionButtonTheme: FloatingActionButtonThemeData(
                backgroundColor: AppColors.darkPrimary,
                foregroundColor: Colors.white,
              ),
              navigationBarTheme: NavigationBarThemeData(
                backgroundColor: AppColors.darkBackground,
                indicatorColor: AppColors.darkPrimary.withOpacity(0.2),
                labelTextStyle: MaterialStateProperty.all(
                  const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ),
            themeMode: themeState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: BlocConsumer<AuthBloc, AuthState>(
              listener: (context, state) {
                if (state is AuthError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.error),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is AuthLoading) {
                  return const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                if (state is Authenticated) {
                  return const MainPage();
                }
                return const AuthPage();
              },
            ),
          );
        },
      ),
    );
  }
}
