import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import '../database/my_database.dart';

class CSVExporter {
  /// Exports data to a CSV file
  /// [data] - List of maps containing the data to export
  /// [filename] - Name of the file (without extension)
  /// [columns] - Map of column names to display and the corresponding key in the data map
  static Future<String> exportToCSV({
    required BuildContext context,
    required List<Map<String, dynamic>> data,
    required String filename,
    required Map<String, String> columns,
  }) async {
    try {
      // Create CSV content
      final StringBuffer csvContent = StringBuffer();
      
      // Add header row
      csvContent.writeln(columns.keys.join(','));
      
      // Add data rows
      for (var item in data) {
        final List<String> rowValues = [];
        for (var key in columns.values) {
          var value = item[key];
          // Format the value for CSV (handle commas, quotes, etc.)
          String formattedValue = _formatCSVValue(value);
          rowValues.add(formattedValue);
        }
        csvContent.writeln(rowValues.join(','));
      }

      // Get directory
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${directory.path}/${filename}_$timestamp.csv';

      // Save file
      final file = File(filePath);
      await file.writeAsString(csvContent.toString());

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('CSV file exported successfully'),
            action: SnackBarAction(
              label: 'SHARE',
              onPressed: () async {
                try {
                  await Share.shareFiles([filePath]);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error sharing file: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
          ),
        );
      }

      return filePath;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      throw Exception('Export failed: $e');
    }
  }

  // Helper function to format values for CSV
  static String _formatCSVValue(dynamic value) {
    if (value == null) return '';
    
    String stringValue = value.toString();
    
    // If the value contains commas, quotes, or newlines, wrap in quotes and escape quotes
    if (stringValue.contains(',') || 
        stringValue.contains('"') || 
        stringValue.contains('\n')) {
      return '"${stringValue.replaceAll('"', '""')}"';
    }
    
    return stringValue;
  }

  /// Exports products data to CSV
  static Future<String> exportProductsToCSV(
    BuildContext context, 
    List<Map<String, dynamic>> products,
  ) async {
    return exportToCSV(
      context: context,
      data: products,
      filename: 'products',
      columns: {
        'ID': 'id',
        'Name': 'name',
        'Description': 'description',
        'Price': 'price',
        'Image URL': 'image_url',
      },
    );
  }

  /// Exports users data to CSV
  static Future<String> exportUsersToCSV(
    BuildContext context, 
    List<Map<String, dynamic>> users,
  ) async {
    return exportToCSV(
      context: context,
      data: users,
      filename: 'users',
      columns: {
        'ID': 'id',
        'Name': 'name',
        'Email': 'email',
        'Is Admin': 'is_admin',
      },
    );
  }

  /// Exports order history to CSV
  static Future<String> exportHistoryToCSV(
    BuildContext context, 
    List<Map<String, dynamic>> history,
  ) async {
    return exportToCSV(
      context: context,
      data: history,
      filename: 'order_history',
      columns: {
        'Order ID': 'id',
        'User ID': 'user_id',
        'Date': 'date',
        'Total': 'total',
      },
    );
  }
  
  /// Exports comprehensive data showing relationships between tables for a specific user
  static Future<String> exportUserRelationshipsToCSV(
    BuildContext context,
    int userId,
  ) async {
    try {
      final database = MyDatabase();
      await database.initializeDatabase();
      
      // Get user details
      final user = await database.getUserById(userId);
      if (user == null) {
        throw Exception('User not found');
      }
      
      // Get cart items with product details
      final cartItems = await database.getCartItemsWithProductDetails(userId);
      
      // Get order history
      final orderHistory = await database.getHistoryForUser(userId);
      
      // Create CSV content
      final StringBuffer csvContent = StringBuffer();
      
      // Add user information section
      csvContent.writeln('USER INFORMATION');
      csvContent.writeln('User ID,Name,Email');
      csvContent.writeln('${user.id},${_formatCSVValue(user.name)},${_formatCSVValue(user.email)}');
      csvContent.writeln();
      
      // Add cart section
      csvContent.writeln('CART ITEMS');
      csvContent.writeln('Product ID,Product Name,Price,Quantity,Total');
      
      for (var item in cartItems) {
        final product = item['product'];
        final quantity = item['quantity'];
        final total = product.price * quantity;
        
        csvContent.writeln('${product.id},${_formatCSVValue(product.name)},${product.price},${quantity},${total}');
      }
      csvContent.writeln();
      
      // Add order history section
      csvContent.writeln('ORDER HISTORY');
      csvContent.writeln('Order ID,Date,Total,Items');
      
      for (var order in orderHistory) {
        final orderId = order['id'];
        final date = order['date'].toString();
        final total = order['total'];
        final items = order['items'] as List<Map<String, dynamic>>;
        
        // Create a summary of items in this order
        final itemsSummary = items.map((item) {
          final product = item['product'];
          final quantity = item['quantity'];
          return '${product.name} (${quantity}x)';
        }).join('; ');
        
        csvContent.writeln('${orderId},${_formatCSVValue(date)},${total},${_formatCSVValue(itemsSummary)}');
      }
      csvContent.writeln();
      
      // Add detailed order items section
      csvContent.writeln('DETAILED ORDER ITEMS');
      csvContent.writeln('Order ID,Product ID,Product Name,Price,Quantity,Subtotal');
      
      for (var order in orderHistory) {
        final orderId = order['id'];
        final items = order['items'] as List<Map<String, dynamic>>;
        
        for (var item in items) {
          final product = item['product'];
          final quantity = item['quantity'];
          final price = item['price'];
          final subtotal = price * quantity;
          
          csvContent.writeln('${orderId},${product.id},${_formatCSVValue(product.name)},${price},${quantity},${subtotal}');
        }
      }
      
      // Get directory and save the file
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${directory.path}/user_${userId}_data_$timestamp.csv';
      
      final file = File(filePath);
      await file.writeAsString(csvContent.toString());
      
      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('User relationship data exported successfully'),
            action: SnackBarAction(
              label: 'SHARE',
              onPressed: () async {
                try {
                  await Share.shareFiles([filePath]);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error sharing file: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
          ),
        );
      }
      
      return filePath;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      throw Exception('Export failed: $e');
    }
  }
  
  /// Exports comprehensive database relationships for all users
  static Future<String> exportAllRelationshipsToCSV(BuildContext context) async {
    try {
      final database = MyDatabase();
      await database.initializeDatabase();
      
      // Get all users
      final users = await database.getAllUsers();
      
      // Create CSV content
      final StringBuffer csvContent = StringBuffer();
      
      // Add header information
      csvContent.writeln('COMPREHENSIVE DATABASE EXPORT');
      csvContent.writeln('Generated on,${DateTime.now().toString()}');
      csvContent.writeln();
      
      // Add users section
      csvContent.writeln('USERS');
      csvContent.writeln('User ID,Name,Email,Is Admin');
      for (var user in users) {
        csvContent.writeln('${user.id},${_formatCSVValue(user.name)},${_formatCSVValue(user.email)},${user.isAdmin ? "Yes" : "No"}');
      }
      csvContent.writeln();
      
      // Add products section
      final products = await database.getAllProducts();
      csvContent.writeln('PRODUCTS');
      csvContent.writeln('Product ID,Name,Description,Price,Image URL');
      for (var product in products) {
        csvContent.writeln('${product.id},${_formatCSVValue(product.name)},${_formatCSVValue(product.description)},${product.price},${_formatCSVValue(product.imageUrl)}');
      }
      csvContent.writeln();
      
      // Add user-cart-product relationships
      csvContent.writeln('USER CART ITEMS');
      csvContent.writeln('User ID,User Name,Product ID,Product Name,Price,Quantity,Total');
      
      for (var user in users) {
        if (user.id == null) continue;
        
        final cartItems = await database.getCartItemsWithProductDetails(user.id!);
        for (var item in cartItems) {
          final product = item['product'];
          final quantity = item['quantity'];
          final total = product.price * quantity;
          
          csvContent.writeln('${user.id},${_formatCSVValue(user.name)},${product.id},${_formatCSVValue(product.name)},${product.price},${quantity},${total}');
        }
      }
      csvContent.writeln();
      
      // Add order history relationships
      csvContent.writeln('ORDER HISTORY');
      csvContent.writeln('Order ID,User ID,User Name,Date,Total');
      
      for (var user in users) {
        if (user.id == null) continue;
        
        final orderHistory = await database.getHistoryForUser(user.id!);
        for (var order in orderHistory) {
          final orderId = order['id'];
          final date = order['date'].toString();
          final total = order['total'];
          
          csvContent.writeln('${orderId},${user.id},${_formatCSVValue(user.name)},${_formatCSVValue(date)},${total}');
        }
      }
      csvContent.writeln();
      
      // Add detailed order items relationships
      csvContent.writeln('DETAILED ORDER ITEMS');
      csvContent.writeln('Order ID,User ID,User Name,Product ID,Product Name,Price,Quantity,Subtotal');
      
      for (var user in users) {
        if (user.id == null) continue;
        
        final orderHistory = await database.getHistoryForUser(user.id!);
        for (var order in orderHistory) {
          final orderId = order['id'];
          final items = order['items'] as List<Map<String, dynamic>>;
          
          for (var item in items) {
            final product = item['product'];
            final quantity = item['quantity'];
            final price = item['price'];
            final subtotal = price * quantity;
            
            csvContent.writeln('${orderId},${user.id},${_formatCSVValue(user.name)},${product.id},${_formatCSVValue(product.name)},${price},${quantity},${subtotal}');
          }
        }
      }
      
      // Get directory and save the file
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${directory.path}/full_database_export_$timestamp.csv';
      
      final file = File(filePath);
      await file.writeAsString(csvContent.toString());
      
      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Full database relationships exported successfully'),
            action: SnackBarAction(
              label: 'SHARE',
              onPressed: () async {
                try {
                  await Share.shareFiles([filePath]);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error sharing file: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
          ),
        );
      }
      
      return filePath;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      throw Exception('Export failed: $e');
    }
  }
} 