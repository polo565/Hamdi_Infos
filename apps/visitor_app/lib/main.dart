import 'package:flutter/material.dart';
import 'api.dart';
import 'screens/welcome_screen.dart';

void main() => runApp(const VisitorApp());

const Color kTeal = Color(0xFF0F766E);
const Color kTealLight = Color(0xFF2DD4BF);
const Color kAccent = Color(0xFFF59E0B);

/// نصوص الواجهة (ثلاث لغات).
const Map<String, Map<String, String>> kT = {
  'ar': {
    'appTitle': 'دليل اللاجئين والمهاجرين', 'welcome': 'مرحباً', 'chooseLang': 'اختر لغتك',
    'origin': 'بلدك الأصلي', 'currentC': 'البلد الذي أنت فيه الآن', 'start': 'ابدأ',
    'free': 'مجاني', 'official': 'روابط رسمية', 'docs': 'الوثائق اللازمة', 'download': 'تحميل',
    'youIn': 'أنت في', 'change': 'تغيير', 'locked': 'محتوى مدفوع', 'pay': 'طريقة الدفع',
    'payPaypal': 'ادفع عبر PayPal', 'amount': 'المبلغ', 'network': 'الشبكة', 'copy': 'نسخ',
    'copied': 'تم النسخ', 'haveCode': 'لديّ رمز وصول', 'enterCode': 'أدخل رمز الوصول',
    'unlock': 'فتح', 'badCode': 'رمز غير صحيح', 'unlocked': 'تم الفتح',
    'afterPay': 'بعد الدفع، أكمل النموذج لنرسل لك رمز الوصول:', 'contact': 'بريدك أو واتساب',
    'proof': 'رقم العملية (TxID) / مرجع', 'send': 'إرسال الطلب',
    'sent': 'تم استلام طلبك ✓ سنراجع الدفع ونرسل لك الرمز.', 'fill': 'أكمل التواصل ورقم العملية',
    'retry': 'إعادة المحاولة', 'loadErr': 'تعذّر التحميل',
  },
  'fr': {
    'appTitle': 'Guide réfugiés & migrants', 'welcome': 'Bienvenue', 'chooseLang': 'Choisissez votre langue',
    'origin': 'Pays d\'origine', 'currentC': 'Pays où vous êtes', 'start': 'Commencer',
    'free': 'Gratuit', 'official': 'Liens officiels', 'docs': 'Documents requis', 'download': 'Télécharger',
    'youIn': 'Vous êtes en', 'change': 'Changer', 'locked': 'Contenu payant', 'pay': 'Paiement',
    'payPaypal': 'Payer avec PayPal', 'amount': 'Montant', 'network': 'Réseau', 'copy': 'Copier',
    'copied': 'Copié', 'haveCode': 'J\'ai un code', 'enterCode': 'Code d\'accès',
    'unlock': 'Débloquer', 'badCode': 'Code invalide', 'unlocked': 'Débloqué',
    'afterPay': 'Après paiement, remplissez le formulaire :', 'contact': 'Email ou WhatsApp',
    'proof': 'ID transaction (TxID) / réf', 'send': 'Envoyer',
    'sent': 'Demande reçue ✓ Nous vérifions et envoyons le code.', 'fill': 'Remplissez contact et TxID',
    'retry': 'Réessayer', 'loadErr': 'Échec du chargement',
  },
  'en': {
    'appTitle': 'Refugee & migrant guide', 'welcome': 'Welcome', 'chooseLang': 'Choose your language',
    'origin': 'Country of origin', 'currentC': 'Country you are in', 'start': 'Start',
    'free': 'Free', 'official': 'Official links', 'docs': 'Required documents', 'download': 'Download',
    'youIn': 'You are in', 'change': 'Change', 'locked': 'Paid content', 'pay': 'Payment',
    'payPaypal': 'Pay with PayPal', 'amount': 'Amount', 'network': 'Network', 'copy': 'Copy',
    'copied': 'Copied', 'haveCode': 'I have a code', 'enterCode': 'Access code',
    'unlock': 'Unlock', 'badCode': 'Invalid code', 'unlocked': 'Unlocked',
    'afterPay': 'After paying, fill the form to get your code:', 'contact': 'Email or WhatsApp',
    'proof': 'Transaction ID (TxID) / ref', 'send': 'Send request',
    'sent': 'Request received ✓ We will verify and send the code.', 'fill': 'Fill contact and TxID',
    'retry': 'Retry', 'loadErr': 'Loading failed',
  },
};

String tr(String k) => kT[AppState.lang]?[k] ?? kT['en']?[k] ?? k;
bool get isRtl => AppState.lang == 'ar';

class VisitorApp extends StatelessWidget {
  const VisitorApp({super.key});
  @override
  Widget build(BuildContext context) {
    final base = ColorScheme.fromSeed(seedColor: kTeal);
    return MaterialApp(
      title: 'Guide',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: base,
        scaffoldBackgroundColor: const Color(0xFFE6EBF3),
        fontFamily: 'Roboto',
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: kTeal, brightness: Brightness.dark),
        scaffoldBackgroundColor: const Color(0xFF2B3142),
      ),
      home: const WelcomeScreen(),
    );
  }
}
