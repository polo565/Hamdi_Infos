import 'package:flutter/material.dart';
import '../api.dart';
import '../main.dart';
import 'home_screen.dart';

const List<String> kAfrica = [
  'Algeria','Angola','Benin','Botswana','Burkina Faso','Burundi','Cabo Verde','Cameroon',
  'Central African Republic','Chad','Comoros','Congo (Republic)','Congo (DRC)','Côte d\'Ivoire',
  'Djibouti','Egypt','Equatorial Guinea','Eritrea','Eswatini','Ethiopia','Gabon','Gambia','Ghana',
  'Guinea','Guinea-Bissau','Kenya','Lesotho','Liberia','Libya','Madagascar','Malawi','Mali',
  'Mauritania','Mauritius','Morocco','Mozambique','Namibia','Niger','Nigeria','Rwanda',
  'São Tomé and Príncipe','Senegal','Seychelles','Sierra Leone','Somalia','South Africa',
  'South Sudan','Sudan','Tanzania','Togo','Tunisia','Uganda','Zambia','Zimbabwe','Other',
];

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _loading = true;
  String? _error;
  String _lang = 'ar';
  String? _origin;
  String? _current;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      AppState.data = await Api.getPublicData();
      _lang = (AppState.settings['lang'] ?? 'ar').toString();
    } catch (e) {
      _error = '$e';
    }
    if (mounted) setState(() => _loading = false);
  }

  void _start() {
    AppState.lang = _lang;
    AppState.origin = _origin ?? '';
    AppState.current = _current ?? '';
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final countries = List<dynamic>.from(AppState.settings['countries'] ?? []);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [kTealLight, kTeal, Color(0xFF134E4A)],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: SafeArea(
          child: Center(
            child: _loading
                ? const CircularProgressIndicator(color: Colors.white)
                : _error != null
                    ? _errorView()
                    : _form(countries),
          ),
        ),
      ),
    );
  }

  Widget _errorView() => Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.wifi_off, color: Colors.white, size: 48),
        const SizedBox(height: 12),
        Text('$_error', style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 12),
        FilledButton(onPressed: _load, child: const Text('إعادة المحاولة · Retry')),
      ]);

  Widget _form(List<dynamic> countries) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('🌍 مرحباً · Bienvenue · Welcome',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kTeal)),
            const SizedBox(height: 4),
            const Text('اختر لغتك وبلدك · Choose your language and country',
                textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 16),
            Row(children: [
              for (final l in const [['ar','العربية'],['fr','Français'],['en','English']])
                Expanded(child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: _langBtn(l[0], l[1]),
                )),
            ]),
            const SizedBox(height: 16),
            const Text('بلدك الأصلي · Pays d\'origine · Country of origin',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _origin,
              isExpanded: true,
              decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
              items: [for (final c in kAfrica) DropdownMenuItem(value: c, child: Text(c))],
              onChanged: (v) => setState(() => _origin = v),
            ),
            const SizedBox(height: 14),
            const Text('البلد الذي أنت فيه الآن · Pays où vous êtes · Country you are in now',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _current,
              isExpanded: true,
              decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
              items: [
                for (final c in countries)
                  DropdownMenuItem(
                    value: c['code'] as String,
                    child: Text((c['label']?[_lang] ?? c['label']?['en'] ?? c['code']).toString()),
                  ),
              ],
              onChanged: (v) => setState(() => _current = v),
            ),
            const SizedBox(height: 18),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: kTeal, padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: _start,
              child: const Text('ابدأ · Commencer · Start  →', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _langBtn(String code, String label) {
    final active = _lang == code;
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: active ? const Color(0xFFEEFAF7) : Colors.white,
        side: BorderSide(color: active ? kTeal : const Color(0xFFDBE2EE), width: 2),
        padding: const EdgeInsets.symmetric(vertical: 10),
      ),
      onPressed: () => setState(() => _lang = code),
      child: Text(label, style: TextStyle(color: active ? kTeal : Colors.black87, fontWeight: FontWeight.w700)),
    );
  }
}
