import 'package:flutter/material.dart';
import '../models/product.dart';
import 'home_page.dart';
import 'cart_page.dart';
import 'profile_page.dart';
import 'about_page.dart';
import 'history_page.dart';
import 'navbar.dart';
import '../database/my_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainNavigation extends StatefulWidget {
  final Map<Product, int> cart;
  final Function(Product) onAddToCart;
  const MainNavigation({super.key, required this.cart, required this.onAddToCart});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  late Map<Product, int> _cart;
  final MyDatabase _database = MyDatabase();
  
  @override
  void initState() {
    super.initState();
    _cart = widget.cart;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _updateCart(Product product) async {
    // Add to cart in memory
    setState(() {
      final currentCount = _cart[product] ?? 0;
      _cart[product] = currentCount + 1;
    });
    
    // Add to database
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('current_user_id');
    if (userId != null) {
      await _database.addToCart(userId, product.id!, 1);
    }
    
    // Show snackbar
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${product.name} added to cart!')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(cart: _cart, onAddToCart: _updateCart),
      CartPage(cart: _cart),
      const HistoryPage(),
      const ProfilePage(),
      const AboutPage(),
    ];
    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: NavBar(
        cart: _cart,
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
} 