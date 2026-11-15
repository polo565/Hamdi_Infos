import 'package:flutter/material.dart';
import '../api.dart';
import '../main.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _key = TextEditingController();
  bool _busy = false;
  String? _err;

  Future<void> _login() async {
    setState(() { _busy = true; _err = null; });
    try {
      final ok = await AdminApi.login(_key.text);
      if (ok) {
        AdminApi.key = _key.text;
        if (mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
        }
      } else {
        setState(() => _err = 'مفتاح غير صحيح');
      }
    } catch (e) {
      setState(() => _err = '$e');
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF334155), kNavy, Color(0xFF0B1220)],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Text('🛠️ لوحة التحكم', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kTeal)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _key,
                      obscureText: true,
                      onSubmitted: (_) => _login(),
                      decoration: const InputDecoration(labelText: 'مفتاح المدير (Admin key)', border: OutlineInputBorder()),
                    ),
                    if (_err != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text('❌ $_err', style: const TextStyle(color: Colors.red))),
                    const SizedBox(height: 16),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: kTeal, minimumSize: const Size.fromHeight(46)),
                      onPressed: _busy ? null : _login,
                      child: Text(_busy ? '...' : 'دخول'),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
