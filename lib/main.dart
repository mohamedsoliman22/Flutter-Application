import 'package:flutter/material.dart';
import 'pages/checkout_page.dart';
import 'pages/about_page.dart';
import 'pages/signup_page.dart';
import 'pages/login_page.dart';
import 'pages/cart_page.dart';
import 'pages/profile_page.dart';
import 'pages/history_page.dart';
import 'models/product.dart';
import 'database/admin_home.dart';
import 'pages/main_navigation.dart';
import 'pages/intro_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SportsWearApp());
}

class SportsWearApp extends StatelessWidget {
  const SportsWearApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Empty cart map for initial setup - will be populated on login
    final Map<Product, int> cartMap = {};
    
    return MaterialApp(
      title: 'SportsWear Shop',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF9F6F2),
      ),
      home: const IntroPage(),
      routes: {
        '/home': (context) => MainNavigation(
          cart: cartMap,
          onAddToCart: (Product product) {},
        ),
        '/cart': (context) => CartPage(cart: cartMap),
        '/about': (context) => const AboutPage(),
        '/profile': (context) => const ProfilePage(),
        '/history': (context) => const HistoryPage(),
        '/checkout': (context) => const CheckoutPage(),
        '/signup': (context) => const SignUpPage(),
        '/login': (context) => const LoginPage(),
        '/admin-home': (context) => const AdminHomePage(),
        '/intro': (context) => const IntroPage(),
      },
    );
  }
}