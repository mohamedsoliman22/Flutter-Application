import 'package:flutter/material.dart';
import '../database/my_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final MyDatabase _database = MyDatabase();
  bool _isProcessing = false;
  bool _isLoadingCardInfo = true;
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  
  String name = '';
  String cardNumber = '';
  String expiry = '';
  String cvv = '';
  int? _currentUserId;
  bool _saveCardInfo = true;

  @override
  void initState() {
    super.initState();
    _database.initializeDatabase();
    _loadCardInfo();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }
  
  Future<void> _loadCardInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentUserId = prefs.getInt('current_user_id');
      
      if (_currentUserId != null) {
        final cardInfo = await _database.getUserCardInfo(_currentUserId!);
        
        if (mounted) {
          setState(() {
            if (cardInfo['cardName'] != null) {
              _nameController.text = cardInfo['cardName']!;
              name = cardInfo['cardName']!;
            }
            
            if (cardInfo['cardNumber'] != null) {
              _cardNumberController.text = cardInfo['cardNumber']!;
              cardNumber = cardInfo['cardNumber']!;
            }
            
            if (cardInfo['cardExpiry'] != null) {
              _expiryController.text = cardInfo['cardExpiry']!;
              expiry = cardInfo['cardExpiry']!;
            }
            
            if (cardInfo['cardCVV'] != null) {
              _cvvController.text = cardInfo['cardCVV']!;
              cvv = cardInfo['cardCVV']!;
            }
            
            _isLoadingCardInfo = false;
          });
        }
      } else {
        setState(() {
          _isLoadingCardInfo = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingCardInfo = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading saved card info: $e')),
        );
      }
    }
  }

  Future<void> _processPayment() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      setState(() {
        _isProcessing = true;
      });

      try {
        // Get current user ID
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getInt('current_user_id');
        
        if (userId != null) {
          // Save card info if checkbox is checked
          if (_saveCardInfo) {
            await _database.updateUserCardInfo(userId, cardNumber, name, expiry, cvv);
          }
          
          // Get cart items for the current user
          final cartItems = await _database.getCartItemsWithProductDetails(userId);
          
          // Calculate total
          double total = 0.0;
          for (var item in cartItems) {
            final product = item['product'];
            final quantity = item['quantity'] as int;
            total += product.price * quantity;
          }
          
          if (cartItems.isNotEmpty) {
            // Save cart to history and clear cart
            await _database.saveCartToHistory(userId, total, cartItems);
            
            if (mounted) {
              setState(() {
                _isProcessing = false;
              });
              
              // Show success dialog
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Payment Successful'),
                  content: const Text('Your order has been placed.'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context); // Close dialog
                        Navigator.pop(context); // Go back to cart page (will be empty now)
                      },
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            }
          } else {
            // Cart is empty
            if (mounted) {
              setState(() {
                _isProcessing = false;
              });
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Your cart is empty')),
              );
            }
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error processing payment: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: _isLoadingCardInfo 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                'Enter Your Payment Details',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Enter your name' : null,
                onSaved: (value) => name = value!,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cardNumberController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Card Number',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.length < 16 ? 'Enter a valid card number' : null,
                onSaved: (value) => cardNumber = value!,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _expiryController,
                      decoration: const InputDecoration(
                        labelText: 'Expiry (MM/YY)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Enter expiry date' : null,
                      onSaved: (value) => expiry = value!,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _cvvController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'CVV',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value!.length < 3 ? 'Enter CVV' : null,
                      onSaved: (value) => cvv = value!,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Save card for future purchases'),
                value: _saveCardInfo,
                onChanged: (value) {
                  setState(() {
                    _saveCardInfo = value ?? true;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isProcessing ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isProcessing 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Pay Now',
                      style: TextStyle(fontSize: 18),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
