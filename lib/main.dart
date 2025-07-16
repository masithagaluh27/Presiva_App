import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:presiva/endpoint/app_routes.dart';
import 'package:presiva/screens/attendance/request_screen.dart';
import 'package:presiva/screens/authentication/forgot_password_screen.dart';
import 'package:presiva/screens/authentication/login_screen.dart';
import 'package:presiva/screens/authentication/register_screen.dart';
import 'package:presiva/screens/authentication/reset_password_with_otp.dart';
import 'package:presiva/screens/main_botom_navigation_bar.dart';
import 'package:presiva/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('id', null);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PRESIVA',
      initialRoute: AppRoutes.SplashScreen,
      routes: {
        AppRoutes.SplashScreen: (context) => const SplashScreen(),
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.register: (context) => const RegisterScreen(),
        AppRoutes.main: (context) => MainBottomNavigationBar(),
        AppRoutes.request: (context) => RequestScreen(),
        AppRoutes.forgotPassword: (context) => const ForgotPasswordScreen(),
        AppRoutes.resetPassword: (context) {
          final email = ModalRoute.of(context)?.settings.arguments as String?;
          if (email == null) {
            return const Text('Error: Email not provided for password reset.');
          }
          return ResetPasswordScreen(email: email);
        },
      },
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
    );
  }
}
