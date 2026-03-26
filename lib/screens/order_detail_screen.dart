import 'package:flutter/material.dart';
import '../models/order_history.dart';
import '../models/order_history_item.dart';
import '../services/database_helper.dart';

class OrderDetailScreen extends StatefulWidget {
  final OrderHistory order;

  const OrderDetailScreen({
    super.key,
    required this.order,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  List<OrderHistoryItem> items = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadOrderItems();
  }

  Future<void> loadOrderItems() async {
    final db = DatabaseHelper();
    final data = await db.getOrderItems(widget.order.id!);

    setState(() {
      items = data;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Detail'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order ID: ${order.id}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text('Date: ${order.date}'),
            const SizedBox(height: 8),
            Text('Customer: ${order.fullName}'),
            const SizedBox(height: 8),
            Text('Address: ${order.address}'),
            const SizedBox(height: 8),
            Text('Payment Method: ${order.paymentMethod}'),
            const SizedBox(height: 8),
            if (order.paymentMethod != 'Cash on Delivery' && order.cardNumber.isNotEmpty)
              Text('Card Number: ${order.cardNumber}'),
            const SizedBox(height: 8),
            Text(
              'Total: \$${order.totalPrice.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),

          ],
        ),
      ),
    );
  }
}