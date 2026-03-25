import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/voucher.dart';
import '../providers/voucher_provider.dart';
import 'add_edit_voucher_screen.dart';

class VoucherListScreen extends StatefulWidget {
  const VoucherListScreen({super.key});

  @override
  State<VoucherListScreen> createState() => _VoucherListScreenState();
}

class _VoucherListScreenState extends State<VoucherListScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VoucherProvider>().loadVouchers();
    });
  }

  Future<void> _goToAddVoucher() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AddEditVoucherScreen(),
      ),
    );

    if (result == true && mounted) {
      await context.read<VoucherProvider>().loadVouchers();
    }
  }

  Future<void> _goToEditVoucher(Voucher voucher) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditVoucherScreen(voucher: voucher),
      ),
    );

    if (result == true && mounted) {
      await context.read<VoucherProvider>().loadVouchers();
    }
  }

  Future<void> _deleteVoucher(Voucher voucher) async {
    if (voucher.id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Voucher'),
        content: Text('Bạn có chắc muốn xóa voucher "${voucher.code}" không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final provider = context.read<VoucherProvider>();
    final success = await provider.deleteVoucher(voucher.id!);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Xóa voucher thành công' : 'Xóa voucher thất bại',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voucher List'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _goToAddVoucher,
        child: const Icon(Icons.add),
      ),
      body: Consumer<VoucherProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.vouchers.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.vouchers.isEmpty) {
            return const Center(
              child: Text(
                'Chưa có voucher nào',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: provider.loadVouchers,
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: provider.vouchers.length,
              itemBuilder: (context, index) {
                final voucher = provider.vouchers[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          voucher.code,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(voucher.description),
                        const SizedBox(height: 8),
                        Text(
                          'Discount: ${voucher.discountPercent.toStringAsFixed(0)}%',
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Min Order: \$${voucher.minOrderAmount.toStringAsFixed(2)}',
                        ),
                        const SizedBox(height: 4),
                        Text(
                          voucher.isActive ? 'Status: Active' : 'Status: Inactive',
                          style: TextStyle(
                            color: voucher.isActive ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _goToEditVoucher(voucher),
                                child: const Text('Edit'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _deleteVoucher(voucher),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: const Text('Delete'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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