import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/voucher.dart';
import '../providers/voucher_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/common_widgets.dart';
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

  Future<void> _goToCreate() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddEditVoucherScreen()),
    );

    if (result == true && mounted) {
      await context.read<VoucherProvider>().loadVouchers();
    }
  }

  Future<void> _goToEdit(Voucher voucher) async {
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

  Future<void> _delete(Voucher voucher) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete Voucher',
      message: 'Do you want to delete "${voucher.code}"?',
      confirmText: 'Delete',
      confirmColor: AppTheme.error,
    );

    if (!confirmed || voucher.id == null) return;

    final success =
    await context.read<VoucherProvider>().deleteVoucher(voucher.id!);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Voucher deleted successfully.' : 'Failed to delete voucher.',
        ),
        backgroundColor: success ? AppTheme.primary : AppTheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Voucher Management')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goToCreate,
        icon: const Icon(Icons.add),
        label: const Text('Add Voucher'),
      ),
      body: Consumer<VoucherProvider>(
        builder: (_, provider, __) {
          if (provider.isLoading && provider.vouchers.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.vouchers.isEmpty) {
            return const EmptyState(
              icon: Icons.local_offer_outlined,
              title: 'No vouchers yet',
              subtitle: 'Tap Add Voucher to create your first voucher',
            );
          }

          return RefreshIndicator(
            onRefresh: provider.loadVouchers,
            child: ListView.builder(
              itemCount: provider.vouchers.length,
              itemBuilder: (context, index) {
                final voucher = provider.vouchers[index];

                return Card(
                  margin:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text(
                      voucher.code,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${voucher.description}\n'
                          'Discount: ${voucher.discountPercent.toStringAsFixed(0)}% • '
                          'Min: \$${voucher.minOrderAmount.toStringAsFixed(2)} • '
                          '${voucher.isActive ? 'Active' : 'Inactive'}',
                    ),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _goToEdit(voucher),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: AppTheme.error,
                          ),
                          onPressed: () => _delete(voucher),
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