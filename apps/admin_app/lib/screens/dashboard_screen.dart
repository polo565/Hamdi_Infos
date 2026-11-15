import 'package:flutter/material.dart';
import '../api.dart';
import '../main.dart';
import 'edit_tab_screen.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _d;
  String? _err;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _err = null; });
    try {
      _d = await AdminApi.getData();
    } catch (e) {
      _err = '$e';
    }
    if (mounted) setState(() => _loading = false);
  }

  void _apply(Map<String, dynamic> d) => setState(() => _d = d);

  void _toast(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kTeal, foregroundColor: Colors.white,
        title: const Text('🛠️ لوحة التحكم', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
          IconButton(onPressed: () {
            AdminApi.key = '';
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const Directionality(textDirection: TextDirection.rtl, child: LoginScreen())),
              (r) => false,
            );
          }, icon: const Icon(Icons.logout)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _err != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('❌ $_err'),
                  TextButton(onPressed: _load, child: const Text('إعادة المحاولة')),
                ]))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(padding: const EdgeInsets.all(14), children: [
                    _ordersCard(),
                    _tabsCard(),
                    _settingsCard(),
                    _codesCard(),
                  ]),
                ),
    );
  }

  Card _section(String title, List<Widget> children) => Card(
        margin: const EdgeInsets.only(bottom: 14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const Divider(),
            ...children,
          ]),
        ),
      );

  // ---------- Orders ----------
  Widget _ordersCard() {
    final orders = List<dynamic>.from(_d!['orders'] ?? []);
    final pending = orders.where((o) => o['status'] == 'pending').length;
    return _section('📨 الطلبات ${pending > 0 ? "($pending قيد المراجعة)" : ""}', [
      if (orders.isEmpty) const Text('لا توجد طلبات.'),
      for (final o in orders)
        Container(
          margin: const EdgeInsets.symmetric(vertical: 5),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(border: Border.all(color: const Color(0x33888888)), borderRadius: BorderRadius.circular(10)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text('${o['tabTitle']}', style: const TextStyle(fontWeight: FontWeight.w700))),
              _statusPill(o['status']),
            ]),
            Text('${o['amount']} ${o['currency']} · ${o['method'] == 'usdt' ? 'USDT' : 'PayPal'}'),
            Text('التواصل: ${o['contact']}'),
            Text('TxID: ${o['proof']}', style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
            Text('من ← إلى: ${o['origin'] ?? '-'} ← ${o['current'] ?? '-'}'),
            if ((o['code'] ?? '').toString().isNotEmpty)
              SelectableText('الرمز: ${o['code']}', style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Wrap(spacing: 6, children: [
              if (o['status'] == 'pending') ...[
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF166534), visualDensity: VisualDensity.compact),
                  onPressed: () async { _apply(await AdminApi.approveOrder(o['id'])); _toast('تم الاعتماد ✓'); },
                  child: const Text('✅ اعتماد'),
                ),
                OutlinedButton(onPressed: () async { _apply(await AdminApi.rejectOrder(o['id'])); }, child: const Text('✖️ رفض')),
              ],
              TextButton(onPressed: () async { _apply(await AdminApi.deleteOrder(o['id'])); }, child: const Text('🗑️')),
            ]),
          ]),
        ),
    ]);
  }

  Widget _statusPill(String? s) {
    const colors = {'pending': Color(0xFFFEF3C7), 'approved': Color(0xFFDCFCE7), 'rejected': Color(0xFFFDE8E8)};
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: colors[s] ?? Colors.grey.shade200, borderRadius: BorderRadius.circular(999)),
      child: Text('$s', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }

  // ---------- Tabs ----------
  Widget _tabsCard() {
    final tabs = List<dynamic>.from(_d!['tabs'] ?? []);
    final cur = (_d!['settings']?['currency'] ?? '€').toString();
    return _section('🎨 التبويبات', [
      for (final t in tabs)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Text('${t['icon'] ?? ''}', style: const TextStyle(fontSize: 20)),
          title: Text(AdminApi.ml(t['title'])),
          subtitle: Text((t['price'] ?? 0) > 0 ? '${t['price']} $cur' : 'مجاني'),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: () => _editTab(t)),
            IconButton(icon: const Icon(Icons.delete, size: 20, color: Colors.red), onPressed: () async {
              if (await _confirm('حذف هذا التبويب؟')) _apply(await AdminApi.deleteTab(t['id']));
            }),
          ]),
        ),
      const SizedBox(height: 6),
      FilledButton.icon(
        style: FilledButton.styleFrom(backgroundColor: kAccent, foregroundColor: Colors.black87),
        onPressed: () => _editTab(null),
        icon: const Icon(Icons.add), label: const Text('إضافة تبويب'),
      ),
    ]);
  }

  Future<void> _editTab(dynamic tab) async {
    final res = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => EditTabScreen(tab: tab, settings: Map<String, dynamic>.from(_d!['settings'] ?? {}))),
    );
    if (res != null) _apply(res);
  }

  // ---------- Settings ----------
  Widget _settingsCard() {
    final s = Map<String, dynamic>.from(_d!['settings'] ?? {});
    final ctl = <String, TextEditingController>{};
    TextEditingController c(String k) => ctl[k] ??= TextEditingController(text: (s[k] ?? '').toString());
    Widget f(String k, String label) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TextField(controller: c(k), decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true)),
        );
    return _section('⚙️ الإعدادات', [
      f('siteTitle', 'عنوان الموقع'),
      f('siteSubtitle', 'العنوان الفرعي'),
      Row(children: [
        Expanded(child: f('price', 'السعر الافتراضي')),
        const SizedBox(width: 8),
        Expanded(child: f('currency', 'العملة')),
      ]),
      f('paypalUrl', 'رابط PayPal'),
      f('usdtAddress', 'عنوان USDT'),
      f('usdtNetwork', 'شبكة USDT (TRC20…)'),
      f('docsRootFolder', '📁 مجلد Drive الرئيسي'),
      f('contactEmail', 'بريد التواصل'),
      f('whatsapp', 'واتساب'),
      FilledButton(
        style: FilledButton.styleFrom(backgroundColor: kTeal, minimumSize: const Size.fromHeight(44)),
        onPressed: () async {
          final out = <String, dynamic>{};
          ctl.forEach((k, v) => out[k] = v.text);
          _apply(await AdminApi.saveSettings(out));
          _toast('تم حفظ الإعدادات ✓');
        },
        child: const Text('💾 حفظ الإعدادات'),
      ),
    ]);
  }

  // ---------- Codes ----------
  Widget _codesCard() {
    final codes = List<dynamic>.from(_d!['codes'] ?? []);
    final nc = TextEditingController();
    return _section('🎟️ رموز الوصول', [
      Row(children: [
        Expanded(child: TextField(controller: nc, decoration: const InputDecoration(labelText: 'رمز (أو فارغ = تلقائي)', border: OutlineInputBorder(), isDense: true))),
        const SizedBox(width: 8),
        FilledButton(onPressed: () async { _apply(await AdminApi.addCode(nc.text)); }, child: const Text('إنشاء')),
      ]),
      const SizedBox(height: 8),
      for (final cd in codes)
        ListTile(
          dense: true, contentPadding: EdgeInsets.zero,
          title: Text('${cd['code']}', style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w700)),
          trailing: IconButton(icon: const Icon(Icons.delete, size: 20, color: Colors.red),
              onPressed: () async { _apply(await AdminApi.deleteCode(cd['code'])); }),
        ),
    ]);
  }

  Future<bool> _confirm(String msg) async =>
      (await showDialog<bool>(context: context, builder: (c) => AlertDialog(
        content: Text(msg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('حذف')),
        ],
      ))) ?? false;
}
