import 'dart:io';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class ExcelExporter {
  /// Exports data to an Excel file
  /// [data] - List of maps containing the data to export
  /// [filename] - Name of the file (without extension)
  /// [sheetName] - Name of the sheet in the Excel file
  /// [columns] - Map of column names to display and the corresponding key in the data map
  static Future<String> exportToExcel({
    required BuildContext context,
    required List<Map<String, dynamic>> data,
    required String filename,
    required String sheetName,
    required Map<String, String> columns,
  }) async {
    try {
      // Create Excel workbook
      var excel = Excel.createExcel();
      var sheet = excel[sheetName];

      // Add headers
      List<String> headersList = columns.keys.toList();
      sheet.appendRow(headersList);

      // Add data rows
      for (var item in data) {
        List<dynamic> rowData = [];
        for (var key in columns.values) {
          var value = item[key];
          rowData.add(value?.toString() ?? '');
        }
        sheet.appendRow(rowData);
      }

      // Get directory
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${directory.path}/${filename}_$timestamp.xlsx';

      // Save file
      final file = File(filePath);
      await file.writeAsBytes(excel.encode()!);

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Excel file exported successfully'),
            action: SnackBarAction(
              label: 'OPEN',
              onPressed: () async {
                try {
                  final result = await OpenFile.open(filePath);
                  if (result.type != ResultType.done && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Could not open file: ${result.message}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error opening file: $e'),
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

  /// Exports products data to Excel
  static Future<String> exportProductsToExcel(
    BuildContext context, 
    List<Map<String, dynamic>> products,
  ) async {
    return exportToExcel(
      context: context,
      data: products,
      filename: 'products',
      sheetName: 'Products',
      columns: {
        'ID': 'id',
        'Name': 'name',
        'Description': 'description',
        'Price': 'price',
        'Image URL': 'image_url',
      },
    );
  }

  /// Exports users data to Excel
  static Future<String> exportUsersToExcel(
    BuildContext context, 
    List<Map<String, dynamic>> users,
  ) async {
    return exportToExcel(
      context: context,
      data: users,
      filename: 'users',
      sheetName: 'Users',
      columns: {
        'ID': 'id',
        'Name': 'name',
        'Email': 'email',
        'Is Admin': 'is_admin',
      },
    );
  }

  /// Exports order history to Excel
  static Future<String> exportHistoryToExcel(
    BuildContext context, 
    List<Map<String, dynamic>> history,
  ) async {
    return exportToExcel(
      context: context,
      data: history,
      filename: 'order_history',
      sheetName: 'Orders',
      columns: {
        'Order ID': 'id',
        'User ID': 'user_id',
        'Date': 'date',
        'Total': 'total',
      },
    );
  }
} 