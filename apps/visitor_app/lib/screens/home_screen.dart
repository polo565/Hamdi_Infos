import 'package:flutter/material.dart';
import '../api.dart';
import '../main.dart';
import 'welcome_screen.dart';
import 'topic_screen.dart';

Color hexColor(String? h, [Color fallback = kTeal]) {
  if (h == null || !h.startsWith('#')) return fallback;
  try {
    return Color(int.parse('FF${h.substring(1)}', radix: 16));
  } catch (_) {
    return fallback;
  }
}

Color shade(Color c, double f) {
  final r = (c.red + 255 * f).clamp(0, 255).toInt();
  final g = (c.green + 255 * f).clamp(0, 255).toInt();
  final b = (c.blue + 255 * f).clamp(0, 255).toInt();
  return Color.fromARGB(255, r, g, b);
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppState.settings;
    final tabs = AppState.tabs;
    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: kTeal,
          foregroundColor: Colors.white,
          title: Text(AppState.pick(s['siteTitle']).isEmpty ? tr('appTitle') : s['siteTitle'],
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
          children: [
            if (AppState.current.isNotEmpty) _locBar(context),
            const SizedBox(height: 8),
            for (final t in tabs) _banner(context, t),
            const SizedBox(height: 16),
            if ((s['disclaimer'] ?? '').toString().isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: const Color(0xFFFFF8EC),
                    border: Border.all(color: const Color(0xFFF6E3BD)),
                    borderRadius: BorderRadius.circular(10)),
                child: Text(s['disclaimer'], style: const TextStyle(fontSize: 12.5, color: Color(0xFF7A5A12))),
              ),
          ],
        ),
      ),
    );
  }

  Widget _locBar(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
            color: const Color(0xFFEEFAF7),
            border: Border.all(color: const Color(0xFFBFE6DF)),
            borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Expanded(child: Text('📍 ${tr('youIn')}: ${AppState.countryLabel(AppState.current)}',
              style: const TextStyle(fontWeight: FontWeight.w600))),
          TextButton(
            onPressed: () => Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => const WelcomeScreen())),
            child: Text('🔄 ${tr('change')}'),
          ),
        ]),
      );

  Widget _banner(BuildContext context, dynamic t) {
    final c = hexColor(t['color']);
    final locked = t['locked'] == true;
    final cur = (AppState.settings['currency'] ?? '€').toString();
    final badge = locked ? '${t['price']} $cur' : tr('free');
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TopicScreen(tab: t))),
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [shade(c, .04), shade(c, -.09)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: c.withOpacity(.45), blurRadius: 18, offset: const Offset(0, 8))],
            ),
            child: Stack(children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [Colors.white.withOpacity(.30), Colors.white.withOpacity(0)],
                      stops: const [0, .55],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                child: Row(children: [
                  Text('${t['icon'] ?? ''}', style: const TextStyle(fontSize: 30)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(AppState.pick(t['title']),
                          style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(AppState.pick(t['desc']),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white.withOpacity(.92), fontSize: 12.5)),
                    ]),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.28), borderRadius: BorderRadius.circular(999)),
                    child: Text(badge, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12.5)),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
