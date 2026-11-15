import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../api.dart';
import '../main.dart';
import '../html_view.dart';

class TopicScreen extends StatefulWidget {
  final Map<dynamic, dynamic> tab;
  const TopicScreen({super.key, required this.tab});
  @override
  State<TopicScreen> createState() => _TopicScreenState();
}

class _TopicScreenState extends State<TopicScreen> {
  late bool _locked;
  bool _unlocked = false;
  dynamic _content;
  List<dynamic> _docs = [];
  List<dynamic> _links = [];
  String _method = 'paypal';
  final _code = TextEditingController();
  final _contact = TextEditingController();
  final _proof = TextEditingController();
  bool _sending = false;
  String? _msg;

  @override
  void initState() {
    super.initState();
    _locked = widget.tab['locked'] == true;
    _links = List<dynamic>.from(widget.tab['links'] ?? []);
    _docs = List<dynamic>.from(widget.tab['docs'] ?? []);
    if (!_locked) {
      _content = widget.tab['content'];
      _unlocked = true;
    }
  }

  Future<void> _open(String url) async {
    final u = Uri.tryParse(url);
    if (u != null) await launchUrl(u, mode: LaunchMode.externalApplication);
  }

  Future<void> _unlock() async {
    final code = _code.text.trim().toUpperCase();
    if (code.isEmpty) return;
    try {
      final r = await Api.getLockedContent(widget.tab['id'], code);
      if (r['ok'] == true) {
        setState(() {
          _content = r['content'];
          _links = List<dynamic>.from(r['links'] ?? []);
          _docs = List<dynamic>.from(r['docs'] ?? []);
          _unlocked = true;
        });
      } else {
        _toast(tr('badCode'));
      }
    } catch (e) {
      _toast('$e');
    }
  }

  Future<void> _submit() async {
    if (_contact.text.trim().isEmpty || _proof.text.trim().isEmpty) {
      _toast(tr('fill'));
      return;
    }
    setState(() => _sending = true);
    try {
      await Api.createOrder({
        'tabId': widget.tab['id'], 'method': _method,
        'proof': _proof.text.trim(), 'contact': _contact.text.trim(),
        'origin': AppState.origin, 'current': AppState.current,
      });
      setState(() => _msg = tr('sent'));
    } catch (e) {
      _toast('$e');
    }
    if (mounted) setState(() => _sending = false);
  }

  void _toast(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: kTeal, foregroundColor: Colors.white,
          title: Text(AppState.pick(widget.tab['title']),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: _unlocked ? _contentView() : _lockedView(),
        ),
      ),
    );
  }

  // ---------- Content ----------
  List<Widget> _contentView() {
    return [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: HtmlView(AppState.pick(_content)),
        ),
      ),
      _docsSection(),
      _linksSection(),
    ];
  }

  Widget _docsSection() {
    final dd = _docs.where((x) => AppState.matchCountry(x['country'])).toList();
    if (dd.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('📎 ${tr('docs')}', style: const TextStyle(fontWeight: FontWeight.w800, color: kTeal)),
          const Divider(),
          for (final x in dd)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                const Text('📄  '),
                Expanded(child: Text(AppState.pick(x['label']))),
                if ((x['country'] ?? '').toString().isNotEmpty)
                  _tag(AppState.countryLabel(x['country'])),
                if ((x['fileUrl'] ?? '').toString().isNotEmpty)
                  TextButton.icon(
                    onPressed: () => _open(x['fileUrl']),
                    icon: const Icon(Icons.download, size: 18),
                    label: Text(tr('download')),
                  ),
              ]),
            ),
        ]),
      ),
    );
  }

  Widget _linksSection() {
    final ll = _links.where((x) => AppState.matchCountry(x['country'])).toList();
    if (ll.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('🔗 ${tr('official')}', style: const TextStyle(fontWeight: FontWeight.w800, color: kTeal)),
          const Divider(),
          for (final l in ll)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Text('🌐', style: TextStyle(fontSize: 18)),
              title: Text('${l['label']}'),
              trailing: const Icon(Icons.open_in_new, size: 18),
              onTap: () => _open(l['url']),
            ),
        ]),
      ),
    );
  }

  Widget _tag(String t) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: const Color(0xFFFFF1D6), borderRadius: BorderRadius.circular(999)),
        child: Text(t, style: const TextStyle(fontSize: 11, color: Color(0xFF9A6A0A), fontWeight: FontWeight.w800)),
      );

  // ---------- Locked / checkout ----------
  List<Widget> _lockedView() {
    if (_msg != null) {
      return [
        const SizedBox(height: 40),
        const Center(child: Text('✅', style: TextStyle(fontSize: 48))),
        const SizedBox(height: 12),
        Center(child: Text(_msg!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
      ];
    }
    final s = AppState.settings;
    final cur = (s['currency'] ?? '€').toString();
    return [
      const SizedBox(height: 6),
      const Center(child: Text('🔒', style: TextStyle(fontSize: 40))),
      Center(child: Text('${AppState.pick(widget.tab['title'])} · ${tr('locked')}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
      const SizedBox(height: 6),
      Center(child: Text('${widget.tab['price']} $cur',
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFFC9810A)))),
      _docsSection(),
      const SizedBox(height: 10),
      _methodToggle(),
      const SizedBox(height: 8),
      _methodPane(),
      const SizedBox(height: 16),
      Text(tr('afterPay'), style: const TextStyle(fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      TextField(controller: _contact, decoration: InputDecoration(labelText: tr('contact'), border: const OutlineInputBorder())),
      const SizedBox(height: 10),
      TextField(controller: _proof, decoration: InputDecoration(labelText: tr('proof'), border: const OutlineInputBorder())),
      const SizedBox(height: 12),
      FilledButton(
        style: FilledButton.styleFrom(backgroundColor: kTeal, minimumSize: const Size.fromHeight(48)),
        onPressed: _sending ? null : _submit,
        child: Text(_sending ? '...' : '📨 ${tr('send')}'),
      ),
      const Divider(height: 30),
      Text(tr('haveCode'), style: const TextStyle(fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: TextField(controller: _code, textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(labelText: tr('enterCode'), border: const OutlineInputBorder()))),
        const SizedBox(width: 8),
        FilledButton(onPressed: _unlock, child: Text('🔓 ${tr('unlock')}')),
      ]),
    ];
  }

  Widget _methodToggle() => Row(children: [
        Expanded(child: _mBtn('paypal', '🅿️ PayPal')),
        const SizedBox(width: 8),
        Expanded(child: _mBtn('usdt', '₮ USDT (Bybit)')),
      ]);

  Widget _mBtn(String m, String label) {
    final active = _method == m;
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: active ? const Color(0xFFEEFAF7) : null,
        side: BorderSide(color: active ? kTeal : const Color(0xFFDBE2EE), width: 2),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      onPressed: () => setState(() => _method = m),
      child: Text(label, style: TextStyle(fontWeight: FontWeight.w800, color: active ? kTeal : null)),
    );
  }

  Widget _methodPane() {
    final s = AppState.settings;
    final cur = (s['currency'] ?? '€').toString();
    if (_method == 'paypal') {
      final url = (s['paypalUrl'] ?? '').toString();
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(children: [
            Text('${tr('amount')}: ${widget.tab['price']} $cur', style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            if (url.isNotEmpty)
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: kAccent, foregroundColor: const Color(0xFF3A2A05), minimumSize: const Size.fromHeight(46)),
                onPressed: () => _open(url),
                child: Text('🅿️ ${tr('payPaypal')}'),
              )
            else
              const Text('PayPal غير مُفعّل بعد.'),
          ]),
        ),
      );
    }
    final addr = (s['usdtAddress'] ?? '').toString();
    final net = (s['usdtNetwork'] ?? 'TRC20').toString();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(children: [
          Text('${tr('amount')}: ${widget.tab['price']} USDT · ${tr('network')}: $net',
              style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          if (addr.isNotEmpty) ...[
            SelectableText(addr, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'monospace', fontSize: 12.5)),
            const SizedBox(height: 6),
            OutlinedButton.icon(
              onPressed: () { Clipboard.setData(ClipboardData(text: addr)); _toast(tr('copied')); },
              icon: const Icon(Icons.copy, size: 16), label: Text(tr('copy')),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              color: Colors.white,
              child: QrImageView(data: addr, size: 170),
            ),
            if ((s['usdtNote'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(s['usdtNote'], style: const TextStyle(fontSize: 12.5, color: Colors.black54)),
            ],
          ] else
            const Text('عنوان USDT غير مضبوط بعد.'),
        ]),
      ),
    );
  }
}
