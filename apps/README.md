# تطبيقات Flutter — دليل اللاجئين والمهاجرين

تطبيقان يتصلان بخادم Google Apps Script عبر **API (JSON)**:

| التطبيق | المجلد | الوصف | الأيقونة |
|---|---|---|---|
| 👤 الزائر | `visitor_app` | ترحيب بالبلد، تبويبات، محتوى، وثائق Drive، دفع PayPal/USDT | درع + دبوس موقع (تركواز) |
| 🛠️ الأدمن | `admin_app` | دخول، طلبات، تبويبات، إعدادات، مجلدات Drive | لوحة تحكم (كحلي) |

## 1) اضبط رابط الـ API
في كلا التطبيقين، افتح `lib/api.dart` وضع رابط النشر `/exec` الخاص بك في `kApiUrl`.
> ⚠️ لتفعيل الـ API يجب أن يكون خادمك محدّثاً: شغّل `npm run push` من جذر المشروع (الكود الجديد يحتوي `doPost`/`doGet` JSON).

## 2) البناء تلقائياً على GitHub (بدون تثبيت Flutter)
- ادفع التغييرات إلى `main` (أو شغّل workflow يدوياً من تبويب **Actions**).
- الـ workflow `.github/workflows/flutter.yml` يبني **APK** لكل تطبيق.
- حمّل الملفات من **Actions → آخر تشغيل → Artifacts** (`visitor_app-apk`, `admin_app-apk`).

## 3) البناء محلياً (إن توفّر Flutter SDK)
```bash
cd apps/visitor_app      # أو admin_app
flutter create --platforms=android .   # يولّد مجلدات المنصّات
flutter pub get
dart run flutter_launcher_icons        # يطبّق الأيقونة
flutter run                            # أو: flutter build apk --release
```

## ملاحظات
- الخادم يعرّض `doPost` (JSON) و`doGet?action=...` — نفس عمليات لوحة الويب.
- إنشاء/حذف مجلدات Drive من تطبيق الأدمن يتطلب منح إذن Drive مرة واحدة (شغّل `authorizeDrive` من محرّر Apps Script).
- هذه الشيفرة كاملة لكنها لم تُبنَ هنا؛ استعمل GitHub Actions أو Flutter محلياً.
