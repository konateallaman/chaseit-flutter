import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/invoice.dart';
import '../services/app_state.dart';
import '../services/ai_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class ChaseScreen extends StatefulWidget {
  final Invoice invoice;
  const ChaseScreen({super.key, required this.invoice});

  @override
  State<ChaseScreen> createState() => _ChaseScreenState();
}

class _ChaseScreenState extends State<ChaseScreen> {
  String _channel = 'email';
  final _msgController = TextEditingController();
  bool _generating = false;
  bool _sending = false;

  final _channels = [
    {'id': 'email', 'label': 'Email', 'icon': Icons.email_outlined},
    {'id': 'sms', 'label': 'SMS', 'icon': Icons.sms_outlined},
    {'id': 'whatsapp', 'label': 'WhatsApp', 'icon': Icons.chat_outlined},
  ];

  @override
  void dispose() { _msgController.dispose(); super.dispose(); }

  Future<void> _generate() async {
    setState(() { _generating = true; _msgController.clear(); });
    try {
      final msg = await AiService.generateChaseMessage(invoice: widget.invoice, channel: _channel);
      _msgController.text = msg ?? '';
    } catch (e) {
      _msgController.text = 'Error generating message. Check your API connection and try again.';
    }
    setState(() => _generating = false);
  }

  Future<void> _send() async {
    if (_msgController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generate or write a message first'), backgroundColor: AppColors.accent),
      );
      return;
    }
    setState(() => _sending = true);
    await context.read<AppState>().incrementChase(widget.invoice.id);
    setState(() => _sending = false);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chase sent to ${widget.invoice.client} via $_channel'), backgroundColor: AppColors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final inv = widget.invoice;
    final chaseNum = inv.chases + 1;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text('Chase — ${inv.client}'), backgroundColor: AppColors.surface),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Invoice info
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.blueBg, borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.blue.withOpacity(0.2))),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(fontFamily: 'Syne', fontSize: 13, color: AppColors.blue),
                  children: [
                    TextSpan(text: inv.client, style: const TextStyle(fontWeight: FontWeight.w700)),
                    TextSpan(text: ' (${inv.email}) owes '),
                    TextSpan(text: '\$${inv.remaining.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w700)),
                    TextSpan(text: ' — due ${inv.due}. '),
                    if (inv.daysOverdue > 0)
                      TextSpan(text: '${inv.daysOverdue} days overdue. ',
                          style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600)),
                    TextSpan(text: 'Chase #$chaseNum'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Channel selector
            const Text('SEND VIA', style: TextStyle(fontFamily: 'Syne', fontSize: 9, color: AppColors.muted, letterSpacing: 1.0)),
            const SizedBox(height: 8),
            Row(
              children: _channels.map((ch) {
                final active = _channel == ch['id'];
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() { _channel = ch['id'] as String; _msgController.clear(); }),
                    child: Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: active ? AppColors.accentBg : Colors.transparent,
                        border: Border.all(color: active ? AppColors.accent : AppColors.border2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(children: [
                        Icon(ch['icon'] as IconData, size: 16, color: active ? AppColors.accent : AppColors.muted),
                        const SizedBox(height: 3),
                        Text(ch['label'] as String,
                            style: TextStyle(fontFamily: 'Syne', fontSize: 11, fontWeight: FontWeight.w600,
                                color: active ? AppColors.accent : AppColors.muted)),
                      ]),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Message box
            Container(
              decoration: BoxDecoration(color: AppColors.bg, border: Border.all(color: AppColors.border2), borderRadius: BorderRadius.circular(10)),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_channel.toUpperCase() + ' MESSAGE',
                            style: const TextStyle(fontFamily: 'Syne', fontSize: 9, color: AppColors.muted, letterSpacing: 1.0)),
                        GestureDetector(
                          onTap: _generating ? null : _generate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(6)),
                            child: _generating
                                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Row(mainAxisSize: MainAxisSize.min, children: [
                                    Icon(Icons.auto_awesome, size: 12, color: Colors.white),
                                    SizedBox(width: 4),
                                    Text('AI Write', style: TextStyle(fontFamily: 'Syne', fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                                  ]),
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextField(
                    controller: _msgController,
                    maxLines: 8,
                    decoration: const InputDecoration(
                      hintText: "Click 'AI Write' to generate a message, or type your own...",
                      hintStyle: TextStyle(fontFamily: 'Syne', fontSize: 13, color: AppColors.muted2, fontStyle: FontStyle.italic),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(12),
                    ),
                    style: const TextStyle(fontFamily: 'Syne', fontSize: 13, color: AppColors.ink, height: 1.7),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            NoteBox.yellow('⚡ Preview mode — messages are generated but not sent. Connect SendGrid / Twilio in Settings to send live.'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _sending ? null : _send,
                child: _sending
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Send Chase →'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── BULK CHASE SCREEN ──
class BulkChaseScreen extends StatefulWidget {
  final List<Invoice> invoices;
  const BulkChaseScreen({super.key, required this.invoices});

  @override
  State<BulkChaseScreen> createState() => _BulkChaseScreenState();
}

class _BulkChaseScreenState extends State<BulkChaseScreen> {
  String _channel = 'email';
  late Set<String> _selected;
  Map<String, String> _statuses = {};
  bool _running = false;
  int _done = 0;

  @override
  void initState() {
    super.initState();
    _selected = widget.invoices.map((i) => i.id).toSet();
  }

  Future<void> _runAll() async {
    setState(() { _running = true; _done = 0; _statuses = {}; });
    final state = context.read<AppState>();
    final selected = widget.invoices.where((i) => _selected.contains(i.id)).toList();

    for (final inv in selected) {
      setState(() => _statuses[inv.id] = 'generating');
      try {
        await AiService.generateChaseMessage(invoice: inv, channel: _channel);
        await state.incrementChase(inv.id);
        setState(() { _statuses[inv.id] = 'done'; _done++; });
      } catch (_) {
        setState(() => _statuses[inv.id] = 'error');
      }
    }

    setState(() => _running = false);
    if (mounted) {
      await Future.delayed(const Duration(milliseconds: 1200));
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$_done chase messages generated!'), backgroundColor: AppColors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('⚡ Run Chasers'), backgroundColor: AppColors.surface),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary
                  Row(children: [
                    _summaryCard('${widget.invoices.length}', 'overdue', AppColors.accent),
                    const SizedBox(width: 10),
                    _summaryCard('\$${widget.invoices.fold(0.0, (s, i) => s + i.remaining).toStringAsFixed(0)}', 'outstanding', AppColors.ink),
                    const SizedBox(width: 10),
                    _summaryCard(_channel, 'channel', AppColors.yellow),
                  ]),
                  const SizedBox(height: 16),

                  // Channel tabs
                  Row(children: [
                    for (final ch in ['email', 'sms', 'whatsapp'])
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _channel = ch),
                          child: Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _channel == ch ? AppColors.accentBg : Colors.transparent,
                              border: Border.all(color: _channel == ch ? AppColors.accent : AppColors.border2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(ch.toUpperCase(),
                                style: TextStyle(fontFamily: 'Syne', fontSize: 11, fontWeight: FontWeight.w600,
                                    color: _channel == ch ? AppColors.accent : AppColors.muted)),
                          ),
                        ),
                      ),
                  ]),
                  const SizedBox(height: 16),

                  // Invoice list
                  ...widget.invoices.map((inv) {
                    final status = _statuses[inv.id];
                    final selected = _selected.contains(inv.id);
                    return GestureDetector(
                      onTap: _running ? null : () => setState(() {
                        if (selected) _selected.remove(inv.id); else _selected.add(inv.id);
                      }),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: status == 'done' ? AppColors.greenBg
                              : status == 'generating' ? AppColors.yellowBg
                              : status == 'error' ? AppColors.accentBg
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: selected ? AppColors.accent : AppColors.border, width: selected ? 1.5 : 1),
                                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 18, height: 18,
                              decoration: BoxDecoration(
                                color: selected ? AppColors.accent : Colors.transparent,
                                border: Border.all(color: selected ? AppColors.accent : AppColors.border2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: selected ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(inv.client, style: const TextStyle(fontFamily: 'Syne', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink)),
                                Text('\$${inv.remaining.toStringAsFixed(2)} · ${inv.daysOverdue}d overdue · Chase #${inv.chases + 1}',
                                    style: const TextStyle(fontFamily: 'Syne', fontSize: 11, color: AppColors.muted)),
                              ]),
                            ),
                            Text(
                              status == 'done' ? '✓ Done' : status == 'generating' ? 'Writing...' : status == 'error' ? '✗ Error' : 'Queued',
                              style: TextStyle(fontFamily: 'Syne', fontSize: 11, fontWeight: FontWeight.w600,
                                  color: status == 'done' ? AppColors.green : status == 'error' ? AppColors.accent : AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  if (_running) ...[
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: widget.invoices.isEmpty ? 0 : _done / widget.invoices.length,
                      backgroundColor: AppColors.border2,
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    const SizedBox(height: 6),
                    Text('$_done of ${widget.invoices.length} processed...',
                        style: const TextStyle(fontFamily: 'Syne', fontSize: 12, color: AppColors.muted)),
                  ],

                  const SizedBox(height: 12),
                  NoteBox.yellow('⚡ Preview mode — AI generates personalized messages. Connect SendGrid / Twilio to send live.'),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _running || _selected.isEmpty ? null : _runAll,
                child: _running
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('Generate All Messages (${_selected.length})'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(String val, String lbl, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: AppColors.surface, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(8)),
        alignment: Alignment.center,
        child: Column(children: [
          Text(val, style: TextStyle(fontFamily: 'Syne', fontSize: 18, fontWeight: FontWeight.w800, color: color)),
          Text(lbl, style: const TextStyle(fontFamily: 'Syne', fontSize: 10, color: AppColors.muted)),
        ]),
      ),
    );
  }
}
