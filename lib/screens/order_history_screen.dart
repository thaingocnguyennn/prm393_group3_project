import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../models/order_history.dart';
import 'order_detail_screen.dart';
class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  List<OrderHistory> orders = [];

  @override
  void initState() {
    super.initState();
    loadOrders();
  }

  Future<void> loadOrders() async {
    final db = DatabaseHelper();
    final data = await db.getOrders();

    setState(() {
      orders = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Order History"),
      ),
      body: orders.isEmpty
          ? const Center(child: Text("No orders yet"))
          : ListView.builder(
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              leading: const Icon(Icons.shopping_bag),
              title: Text("Order #${order.id}"),
              subtitle: Text(
                "Date: ${order.date}\nTotal: \$${order.totalPrice.toStringAsFixed(2)}",
              ),
              isThreeLine: true,
              trailing: const Icon(Icons.arrow_forward_ios, size: 18),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OrderDetailScreen(order: order),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}