import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../database/my_database.dart';
import '../models/product.dart';
import 'main_navigation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  final MyDatabase _database = MyDatabase();

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    await _database.initializeDatabase();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final result = await _database.validateUser(
          _emailController.text,
          _passwordController.text,
        );

        if (result['isValid']) {
          final user = result['user'];
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('current_user_email', user.email);
          await prefs.setInt('current_user_id', user.id!);
          
          if (result['isAdmin']) {
            // Navigate to admin home page
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/admin-home');
            }
          } else {
            // Load cart items for the current user
            final cartItems = await _database.getCartItemsWithProductDetails(user.id!);
            Map<Product, int> cartMap = {};
            
            // Convert cart items to Map<Product, int>
            for (var item in cartItems) {
              final product = item['product'] as Product;
              final quantity = item['quantity'] as int;
              cartMap[product] = quantity;
            }
            
            // Navigate to main app with NavBar and loaded cart
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => MainNavigation(
                    cart: cartMap,
                    onAddToCart: (product) async {
                      // Get current user ID from SharedPreferences
                      final prefs = await SharedPreferences.getInstance();
                      final userId = prefs.getInt('current_user_id');
                      if (userId != null) {
                        // Add to database
                        await _database.addToCart(userId, product.id!, 1);
                        // Update local cart
                        final currentCount = cartMap[product] ?? 0;
                        cartMap[product] = currentCount + 1;
                      }
                    },
                  ),
                ),
              );
            }
          }
        } else {
          Fluttertoast.showToast(msg: "Invalid email or password");
        }
      } catch (e) {
        print('Login error: $e');
        Fluttertoast.showToast(msg: "Login failed. Try again.");
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _login(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Login'),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/signup'),
                child: const Text('Don\'t have an account? Sign Up'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}