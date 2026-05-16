import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/invoice.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';

class PaymentScreen extends StatefulWidget {
  final Invoice invoice;
  const PaymentScreen({super.key, required this.invoice});
  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() { _amountCtrl.dispose(); _noteCtrl.dispose(); super.dispose(); }

  Future<void> _record() async {
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount'), backgroundColor: AppColors.accent),
      );
      return;
    }
    final rem = widget.invoice.remaining;
    if (amount > rem + 0.01) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Amount exceeds remaining balance of \$${rem.toStringAsFixed(2)}'), backgroundColor: AppColors.accent),
      );
      return;
    }
    setState(() => _saving = true);
    await context.read<AppState>().recordPayment(widget.invoice.id, amount);
    if (mounted) {
      Navigator.pop(context);
      final newRemaining = (rem - amount).clamp(0, double.infinity);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(newRemaining <= 0.01
            ? '${widget.invoice.client} — fully paid! 🎉'
            : '\$${amount.toStringAsFixed(2)} recorded — \$${newRemaining.toStringAsFixed(2)} remaining'),
        backgroundColor: newRemaining <= 0.01 ? AppColors.green : AppColors.yellow,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final inv = widget.invoice;
    final pct = inv.amount > 0 ? inv.paidAmount / inv.amount : 0.0;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Record Payment'), backgroundColor: AppColors.surface),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Summary card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(inv.client, style: const TextStyle(fontFamily: 'Syne', fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
              const SizedBox(height: 12),
              Row(children: [
                _summaryItem('Invoice Total', '\$${inv.amount.toStringAsFixed(2)}', AppColors.ink),
                _summaryItem('Received', '\$${inv.paidAmount.toStringAsFixed(2)}', AppColors.green),
                _summaryItem('Remaining', '\$${inv.remaining.toStringAsFixed(2)}', AppColors.accent),
              ]),
              const SizedBox(height: 14),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Payment progress', style: TextStyle(fontFamily: 'Syne', fontSize: 11, color: AppColors.muted)),
                Text('${(pct * 100).round()}% collected',
                    style: const TextStyle(fontFamily: 'Syne', fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.yellow)),
              ]),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: pct.toDouble(),
                  backgroundColor: AppColors.border2,
                  color: AppColors.yellow,
                  minHeight: 6,
                ),
              ),
            ]),
          ),
          const SizedBox(height: 20),

          // Amount input
          const Text('PAYMENT AMOUNT (\$)', style: TextStyle(fontFamily: 'Syne', fontSize: 9, color: AppColors.muted, letterSpacing: 1.0)),
          const SizedBox(height: 6),
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontFamily: 'Syne', fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink),
            decoration: InputDecoration(
              hintText: 'Enter amount received',
              hintStyle: const TextStyle(fontFamily: 'Syne', fontSize: 16, color: AppColors.muted2),
            ),
          ),
          const SizedBox(height: 10),
          Row(children: [
            _quickBtn('Full amount', () => _amountCtrl.text = inv.remaining.toStringAsFixed(2)),
            const SizedBox(width: 8),
            _quickBtn('50%', () => _amountCtrl.text = (inv.remaining / 2).toStringAsFixed(2)),
          ]),
          const SizedBox(height: 16),

          // Note
          const Text('PAYMENT NOTE (OPTIONAL)', style: TextStyle(fontFamily: 'Syne', fontSize: 9, color: AppColors.muted, letterSpacing: 1.0)),
          const SizedBox(height: 6),
          TextField(
            controller: _noteCtrl,
            decoration: const InputDecoration(hintText: 'e.g. Bank transfer, Stripe, Cash...'),
            style: const TextStyle(fontFamily: 'Syne', fontSize: 13),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.greenBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.green.withOpacity(0.2))),
            child: const Text('💡 If this clears the full balance, the invoice will automatically be marked as Fully Paid.',
                style: TextStyle(fontFamily: 'Syne', fontSize: 12, color: AppColors.green)),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _record,
              child: _saving
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Record Payment'),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _summaryItem(String label, String value, Color color) {
    return Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontFamily: 'Syne', fontSize: 9, color: AppColors.muted, letterSpacing: 0.8)),
      const SizedBox(height: 3),
      Text(value, style: TextStyle(fontFamily: 'Syne', fontSize: 16, fontWeight: FontWeight.w700, color: color)),
    ]));
  }

  Widget _quickBtn(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(border: Border.all(color: AppColors.border2), borderRadius: BorderRadius.circular(6)),
        child: Text(label, style: const TextStyle(fontFamily: 'Syne', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted)),
      ),
    );
  }
}
