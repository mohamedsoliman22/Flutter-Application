import 'package:flutter/material.dart';
import '../models/product.dart';
import 'checkout_page.dart';
import '../database/my_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CartPage extends StatefulWidget {
  final Map<Product, int> cart;
  const CartPage({super.key, required this.cart});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  late Map<Product, int> _cart;
  final MyDatabase _database = MyDatabase();
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _cart = widget.cart;
    _refreshCartFromDb();
  }
  
  Future<void> _refreshCartFromDb() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get current user ID
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('current_user_id');
      
      if (userId != null) {
        // Load cart items for the current user
        final cartItems = await _database.getCartItemsWithProductDetails(userId);
        
        setState(() {
          // Clear existing cart and add items from database
          _cart.clear();
          for (var item in cartItems) {
            final product = item['product'] as Product;
            final quantity = item['quantity'] as int;
            _cart[product] = quantity;
          }
        });
      }
    } catch (e) {
      // Show error if cart loading fails
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading cart: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _removeFromCart(Product product, int cartId) async {
    try {
      await _database.removeFromCart(cartId);
      setState(() {
        _cart.remove(product);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing item: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double total = _cart.entries.fold(
      0,
      (sum, entry) => sum + (entry.key.price * entry.value),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshCartFromDb,
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
        children: [
          Expanded(
            child: _cart.isEmpty
                ? const Center(
                    child: Text(
                      'Your cart is empty',
                      style: TextStyle(fontSize: 18),
                    ),
                  )
                : ListView.builder(
                    itemCount: _cart.length,
                    itemBuilder: (context, index) {
                      final entry = _cart.entries.elementAt(index);
                      return ListTile(
                        leading: Image.asset(
                          entry.key.imageUrl,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                        title: Text(entry.key.name),
                        subtitle: Text(
                          '\$${entry.key.price.toStringAsFixed(2)} x ${entry.value}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '\$${(entry.key.price * entry.value).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                // Get cart_id for the product
                                final prefs = await SharedPreferences.getInstance();
                                final userId = prefs.getInt('current_user_id');
                                if (userId != null) {
                                  final cartItems = await _database.getCartItemsWithProductDetails(userId);
                                  for (var item in cartItems) {
                                    final product = item['product'] as Product;
                                    if (product.id == entry.key.id) {
                                      final cartId = item['cart_id'] as int;
                                      _removeFromCart(product, cartId);
                                      break;
                                    }
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  'Total: \$${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _cart.isEmpty ? null : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CheckoutPage(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Proceed to Checkout'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}