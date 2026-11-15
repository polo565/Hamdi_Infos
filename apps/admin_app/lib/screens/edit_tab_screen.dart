import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../api.dart';
import '../main.dart';

class EditTabScreen extends StatefulWidget {
  final dynamic tab; // null = جديد
  final Map<String, dynamic> settings;
  const EditTabScreen({super.key, required this.tab, required this.settings});
  @override
  State<EditTabScreen> createState() => _EditTabScreenState();
}

class _EditTabScreenState extends State<EditTabScreen> {
  final Map<String, String> _title = {}, _desc = {}, _content = {};
  String _icon = '📄', _color = '#0f766e', _price = '0', _docsFolder = '', _docsSubfolder = '';
  List<Map<String, dynamic>> _links = [];
  List<Map<String, dynamic>> _docs = [];
  late String _lang;
  bool _busy = false;
  String _subInfo = '';

  List<String> get _langCodes {
    final l = List<dynamic>.from(widget.settings['languages'] ?? []);
    return l.isEmpty ? ['ar', 'fr', 'en'] : l.map((x) => x['code'].toString()).toList();
  }

  List<Map<String, dynamic>> get _countries =>
      List<Map<String, dynamic>>.from((widget.settings['countries'] ?? []).map((e) => Map<String, dynamic>.from(e)));

  @override
  void initState() {
    super.initState();
    _lang = _langCodes.first;
    final t = widget.tab;
    if (t != null) {
      _icon = (t['icon'] ?? '📄').toString();
      _color = (t['color'] ?? '#0f766e').toString();
      _price = (t['price'] ?? 0).toString();
      _docsFolder = (t['docsFolder'] ?? '').toString();
      _docsSubfolder = (t['docsSubfolder'] ?? '').toString();
      _fill(_title, t['title']);
      _fill(_desc, t['desc']);
      _fill(_content, t['content']);
      _links = List<Map<String, dynamic>>.from((t['links'] ?? []).map((e) => Map<String, dynamic>.from(e)));
      _docs = List<Map<String, dynamic>>.from((t['docs'] ?? []).map((e) => Map<String, dynamic>.from(e)));
    }
  }

  void _fill(Map<String, String> m, dynamic o) {
    if (o is Map) o.forEach((k, v) => m['$k'] = '$v');
    else if (o is String) m['ar'] = o;
  }

  Map<String, String> _clean(Map<String, String> m) {
    final out = <String, String>{};
    m.forEach((k, v) { if (v.trim().isNotEmpty) out[k] = v; });
    return out;
  }

  Future<void> _open(String url) async {
    final u = Uri.tryParse(url);
    if (u != null) await launchUrl(u, mode: LaunchMode.externalApplication);
  }

  void _toast(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  String get _subName => _docsSubfolder.trim().isNotEmpty ? _docsSubfolder.trim() : AdminApi.ml(_title);

  Future<void> _createSub() async {
    if (_subName.isEmpty) { _toast('أدخل اسماً أو عنوان الباب'); return; }
    setState(() => _subInfo = '⏳ ...');
    try {
      final r = await AdminApi.createSubfolder(_subName);
      setState(() { _docsSubfolder = r['name'].toString(); _subInfo = '✅ تم — افتح المجلد وارفع الوثائق'; });
      _open(r['url'].toString());
    } catch (e) {
      setState(() => _subInfo = '❌ ${e.toString().contains("NO_ROOT") ? "عيّن المجلد الرئيسي أولاً" : e}');
    }
  }

  Future<void> _deleteSub() async {
    if (_subName.isEmpty) return;
    try { await AdminApi.deleteSubfolder(_subName); setState(() => _subInfo = '🗑️ تم حذف المجلد'); }
    catch (e) { _toast('$e'); }
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    var title = _clean(_title);
    if (title.isEmpty) title = {'ar': 'تبويب'};
    final data = {
      'icon': _icon.isEmpty ? '📄' : _icon, 'color': _color, 'price': int.tryParse(_price) ?? 0,
      'title': title, 'desc': _clean(_desc), 'content': _clean(_content),
      'links': _links.where((l) => '${l['label']}'.trim().isNotEmpty && '${l['url']}'.trim().isNotEmpty).toList(),
      'docs': _docs.where((d) {
        final hasLabel = ['ar', 'fr', 'en'].any((k) => '${d[k] ?? ''}'.trim().isNotEmpty);
        return hasLabel || '${d['fileUrl'] ?? ''}'.trim().isNotEmpty;
      }).map((d) {
        final lab = <String, String>{};
        for (final k in ['ar', 'fr', 'en']) { if ('${d[k] ?? ''}'.trim().isNotEmpty) lab[k] = '${d[k]}'; }
        return {'label': lab, 'country': d['country'] ?? '', if ('${d['fileUrl'] ?? ''}'.isNotEmpty) 'fileUrl': d['fileUrl']};
      }).toList(),
      'docsFolder': _docsFolder.trim(), 'docsSubfolder': _docsSubfolder.trim(),
    };
    try {
      final res = widget.tab == null
          ? await AdminApi.addTab(data)
          : await AdminApi.updateTab(widget.tab['id'], data);
      if (mounted) Navigator.pop(context, res);
    } catch (e) {
      _toast('$e');
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kTeal, foregroundColor: Colors.white,
        title: Text(widget.tab == null ? 'تبويب جديد' : 'تعديل التبويب'),
        actions: [IconButton(onPressed: _busy ? null : _save, icon: const Icon(Icons.save))],
      ),
      body: ListView(padding: const EdgeInsets.all(14), children: [
        Row(children: [
          SizedBox(width: 70, child: TextFormField(initialValue: _icon, decoration: const InputDecoration(labelText: 'أيقونة'), onChanged: (v) => _icon = v)),
          const SizedBox(width: 8),
          SizedBox(width: 120, child: TextFormField(initialValue: _color, decoration: const InputDecoration(labelText: 'اللون hex'), onChanged: (v) => _color = v)),
          const SizedBox(width: 8),
          Expanded(child: TextFormField(initialValue: _price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'السعر (0=مجاني)'), onChanged: (v) => _price = v)),
        ]),
        const SizedBox(height: 12),
        _langRow(),
        const SizedBox(height: 8),
        TextFormField(key: ValueKey('t_$_lang'), initialValue: _title[_lang] ?? '', decoration: const InputDecoration(labelText: 'اسم التبويب', border: OutlineInputBorder()), onChanged: (v) => _title[_lang] = v),
        const SizedBox(height: 10),
        TextFormField(key: ValueKey('d_$_lang'), initialValue: _desc[_lang] ?? '', decoration: const InputDecoration(labelText: 'وصف قصير', border: OutlineInputBorder()), onChanged: (v) => _desc[_lang] = v),
        const SizedBox(height: 10),
        TextFormField(key: ValueKey('c_$_lang'), initialValue: _content[_lang] ?? '', maxLines: 8, decoration: const InputDecoration(labelText: 'المحتوى (نص أو HTML بسيط)', border: OutlineInputBorder(), alignLabelWithHint: true), onChanged: (v) => _content[_lang] = v),
        const Divider(height: 28),
        _linksEditor(),
        const Divider(height: 28),
        _docsEditor(),
        const Divider(height: 28),
        _folderEditor(),
        const SizedBox(height: 24),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: kTeal, minimumSize: const Size.fromHeight(48)),
          onPressed: _busy ? null : _save,
          child: Text(_busy ? '...' : '💾 حفظ'),
        ),
      ]),
    );
  }

  Widget _langRow() => Wrap(spacing: 6, children: [
        for (final c in _langCodes)
          ChoiceChip(label: Text(c.toUpperCase()), selected: _lang == c, onSelected: (_) => setState(() => _lang = c)),
      ]);

  Widget _countryDropdown(String? value, void Function(String) onChanged) => DropdownButton<String>(
        value: (value ?? '').isEmpty ? '' : value,
        items: [
          const DropdownMenuItem(value: '', child: Text('🌍 الكل')),
          for (final c in _countries) DropdownMenuItem(value: c['code'].toString(), child: Text(c['code'].toString())),
        ],
        onChanged: (v) => onChanged(v ?? ''),
      );

  Widget _linksEditor() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('🔗 الروابط الرسمية', style: TextStyle(fontWeight: FontWeight.w800)),
        for (int i = 0; i < _links.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              Expanded(child: TextFormField(initialValue: '${_links[i]['label'] ?? ''}', decoration: const InputDecoration(hintText: 'الاسم', isDense: true), onChanged: (v) => _links[i]['label'] = v)),
              const SizedBox(width: 6),
              Expanded(flex: 2, child: TextFormField(initialValue: '${_links[i]['url'] ?? ''}', decoration: const InputDecoration(hintText: 'https://', isDense: true), onChanged: (v) => _links[i]['url'] = v)),
              _countryDropdown('${_links[i]['country'] ?? ''}', (v) => setState(() => _links[i]['country'] = v)),
              IconButton(icon: const Icon(Icons.close, color: Colors.red, size: 18), onPressed: () => setState(() => _links.removeAt(i))),
            ]),
          ),
        TextButton.icon(onPressed: () => setState(() => _links.add({'label': '', 'url': '', 'country': ''})), icon: const Icon(Icons.add), label: const Text('إضافة رابط')),
      ]);

  Widget _docsEditor() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('📎 الوثائق (ع/FR/EN + رابط Drive اختياري)', style: TextStyle(fontWeight: FontWeight.w800)),
        for (int i = 0; i < _docs.length; i++)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(border: Border.all(color: const Color(0x22888888)), borderRadius: BorderRadius.circular(8)),
            child: Column(children: [
              Row(children: [
                Expanded(child: TextFormField(initialValue: '${_docs[i]['ar'] ?? ''}', decoration: const InputDecoration(hintText: 'عربي', isDense: true), onChanged: (v) => _docs[i]['ar'] = v)),
                const SizedBox(width: 4),
                Expanded(child: TextFormField(initialValue: '${_docs[i]['fr'] ?? ''}', decoration: const InputDecoration(hintText: 'FR', isDense: true), onChanged: (v) => _docs[i]['fr'] = v)),
                const SizedBox(width: 4),
                Expanded(child: TextFormField(initialValue: '${_docs[i]['en'] ?? ''}', decoration: const InputDecoration(hintText: 'EN', isDense: true), onChanged: (v) => _docs[i]['en'] = v)),
              ]),
              Row(children: [
                Expanded(child: TextFormField(initialValue: '${_docs[i]['fileUrl'] ?? ''}', decoration: const InputDecoration(hintText: '🔗 رابط Drive', isDense: true), onChanged: (v) => _docs[i]['fileUrl'] = v)),
                _countryDropdown('${_docs[i]['country'] ?? ''}', (v) => setState(() => _docs[i]['country'] = v)),
                IconButton(icon: const Icon(Icons.close, color: Colors.red, size: 18), onPressed: () => setState(() => _docs.removeAt(i))),
              ]),
            ]),
          ),
        TextButton.icon(onPressed: () => setState(() => _docs.add({'ar': '', 'fr': '', 'en': '', 'fileUrl': '', 'country': ''})), icon: const Icon(Icons.add), label: const Text('إضافة وثيقة')),
      ]);

  Widget _folderEditor() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('📁 مجلد Drive لهذا الباب', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        TextFormField(initialValue: _docsSubfolder, decoration: const InputDecoration(labelText: 'اسم المجلد الفرعي (يطابق اسم الباب)', border: OutlineInputBorder(), isDense: true), onChanged: (v) => _docsSubfolder = v),
        const SizedBox(height: 6),
        Row(children: [
          FilledButton.icon(style: FilledButton.styleFrom(backgroundColor: const Color(0xFF166534)), onPressed: _createSub, icon: const Icon(Icons.create_new_folder, size: 18), label: const Text('إنشاء/فتح')),
          const SizedBox(width: 8),
          OutlinedButton.icon(onPressed: _deleteSub, icon: const Icon(Icons.delete, size: 18, color: Colors.red), label: const Text('حذف')),
        ]),
        if (_subInfo.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(_subInfo, style: const TextStyle(fontSize: 12))),
        const SizedBox(height: 8),
        TextFormField(initialValue: _docsFolder, decoration: const InputDecoration(labelText: 'أو رابط مجلد مباشر (اختياري)', border: OutlineInputBorder(), isDense: true), onChanged: (v) => _docsFolder = v),
      ]);
}
