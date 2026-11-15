/**
 * دليل اللاجئين والمهاجرين — تطبيق ويب على Google Apps Script
 * Backend : stockage via PropertiesService, API publique + API admin (protégée par clé).
 */

var PROP = PropertiesService.getScriptProperties();
var DEFAULT_ADMIN_KEY = 'admin';

/* ------------------------------------------------------------------ */
/*  Routage / rendu                                                    */
/* ------------------------------------------------------------------ */

function doGet(e) {
  seedIfEmpty_();
  var page = ((e && e.parameter && e.parameter.page) || 'home').toLowerCase();
  var tplName = 'Index';
  var title = getSettings_().siteTitle || 'دليل اللاجئين';
  if (page === 'admin') {
    tplName = 'Admin';
    title = 'لوحة التحكم';
  }
  return HtmlService.createTemplateFromFile(tplName)
    .evaluate()
    .setTitle(title)
    .addMetaTag('viewport', 'width=device-width, initial-scale=1')
    .setXFrameOptionsMode(HtmlService.XFrameOptionsMode.ALLOWALL);
}

function include(filename) {
  return HtmlService.createHtmlOutputFromFile(filename).getContent();
}

/* ------------------------------------------------------------------ */
/*  Accès au stockage                                                  */
/* ------------------------------------------------------------------ */

function getSettings_() {
  var raw = PROP.getProperty('SETTINGS');
  return raw ? JSON.parse(raw) : defaultSettings_();
}
function saveSettings_(s) { PROP.setProperty('SETTINGS', JSON.stringify(s)); }

function getTabsMeta_() {
  var raw = PROP.getProperty('TABS');
  return raw ? JSON.parse(raw) : [];
}
function saveTabsMeta_(arr) { PROP.setProperty('TABS', JSON.stringify(arr)); }

function getTabContent_(id) { return PROP.getProperty('TAB_' + id) || ''; }
function setTabContent_(id, html) { PROP.setProperty('TAB_' + id, html || ''); }
function delTabContent_(id) { PROP.deleteProperty('TAB_' + id); }

function getCodes_() { var raw = PROP.getProperty('CODES'); return raw ? JSON.parse(raw) : []; }
function saveCodes_(arr) { PROP.setProperty('CODES', JSON.stringify(arr)); }

function getAdminKey_() { return PROP.getProperty('ADMIN_KEY') || DEFAULT_ADMIN_KEY; }

function assertAdmin_(key) {
  if (String(key) !== getAdminKey_()) throw new Error('UNAUTHORIZED');
}

/* ------------------------------------------------------------------ */
/*  API publique                                                       */
/* ------------------------------------------------------------------ */

function getPublicData() {
  seedIfEmpty_();
  var settings = getSettings_();
  var tabs = getTabsMeta_().sort(function (a, b) { return a.order - b.order; }).map(function (t) {
    var o = { id: t.id, title: t.title, icon: t.icon || '', locked: !!t.locked };
    if (t.locked) {
      o.teaser = makeTeaser_(getTabContent_(t.id));
    } else {
      o.content = getTabContent_(t.id);
    }
    return o;
  });
  return { settings: settings, tabs: tabs };
}

function getLockedContent(id, code) {
  if (!validCode_(code)) return { ok: false };
  return { ok: true, content: getTabContent_(id) };
}

function validCode_(code) {
  if (!code) return false;
  var codes = getCodes_();
  var c = String(code).trim().toUpperCase();
  return codes.some(function (x) { return x.code === c && x.active !== false; });
}

function makeTeaser_(html) {
  var text = String(html || '').replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim();
  return text.length > 260 ? text.slice(0, 260) + '…' : text;
}

/* ------------------------------------------------------------------ */
/*  API admin (protégée par clé)                                       */
/* ------------------------------------------------------------------ */

function adminLogin(key) { return String(key) === getAdminKey_(); }

function adminGetData(key) {
  assertAdmin_(key);
  var tabs = getTabsMeta_().sort(function (a, b) { return a.order - b.order; }).map(function (t) {
    return { id: t.id, title: t.title, icon: t.icon || '', locked: !!t.locked, content: getTabContent_(t.id) };
  });
  return {
    settings: getSettings_(),
    tabs: tabs,
    codes: getCodes_(),
    adminKeyIsDefault: getAdminKey_() === DEFAULT_ADMIN_KEY
  };
}

function adminAddTab(key, data) {
  assertAdmin_(key);
  var tabs = getTabsMeta_();
  var id = 't' + Date.now().toString(36) + Math.floor(Math.random() * 1000);
  var order = tabs.length ? Math.max.apply(null, tabs.map(function (t) { return t.order; })) + 1 : 0;
  tabs.push({ id: id, title: (data && data.title) || 'تبويب جديد', icon: (data && data.icon) || '📄', locked: !!(data && data.locked), order: order });
  saveTabsMeta_(tabs);
  setTabContent_(id, (data && data.content) || '');
  return adminGetData(key);
}

function adminUpdateTab(key, id, data) {
  assertAdmin_(key);
  var tabs = getTabsMeta_();
  var t = tabs.filter(function (x) { return x.id === id; })[0];
  if (!t) throw new Error('NOT_FOUND');
  if (data.title != null) t.title = data.title;
  if (data.icon != null) t.icon = data.icon;
  if (data.locked != null) t.locked = !!data.locked;
  saveTabsMeta_(tabs);
  if (data.content != null) setTabContent_(id, data.content);
  return adminGetData(key);
}

function adminDeleteTab(key, id) {
  assertAdmin_(key);
  var tabs = getTabsMeta_().filter(function (x) { return x.id !== id; });
  saveTabsMeta_(tabs);
  delTabContent_(id);
  return adminGetData(key);
}

function adminReorder(key, ids) {
  assertAdmin_(key);
  var tabs = getTabsMeta_();
  ids.forEach(function (id, i) {
    var t = tabs.filter(function (x) { return x.id === id; })[0];
    if (t) t.order = i;
  });
  saveTabsMeta_(tabs);
  return adminGetData(key);
}

function adminSaveSettings(key, settings) {
  assertAdmin_(key);
  var merged = Object.assign({}, getSettings_(), settings);
  saveSettings_(merged);
  return adminGetData(key);
}

function adminChangeKey(key, newKey) {
  assertAdmin_(key);
  newKey = String(newKey || '').trim();
  if (newKey.length < 4) throw new Error('KEY_TOO_SHORT');
  PROP.setProperty('ADMIN_KEY', newKey);
  return true;
}

function adminAddCode(key, code) {
  assertAdmin_(key);
  var codes = getCodes_();
  code = (code && String(code).trim().toUpperCase()) || genCode_();
  if (codes.some(function (c) { return c.code === code; })) throw new Error('EXISTS');
  codes.push({ code: code, active: true, created: new Date().toISOString() });
  saveCodes_(codes);
  return adminGetData(key);
}

function adminDeleteCode(key, code) {
  assertAdmin_(key);
  var codes = getCodes_().filter(function (c) { return c.code !== code; });
  saveCodes_(codes);
  return adminGetData(key);
}

function genCode_() {
  var s = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789', o = '';
  for (var i = 0; i < 8; i++) o += s.charAt(Math.floor(Math.random() * s.length));
  return o;
}

/* ------------------------------------------------------------------ */
/*  Valeurs par défaut + amorçage                                      */
/* ------------------------------------------------------------------ */

function defaultSettings_() {
  return {
    siteTitle: 'دليل اللاجئين والمهاجرين',
    siteSubtitle: 'معلومات قانونية موثوقة لطالبي اللجوء والمقيمين · Guide juridique pour demandeurs d\'asile',
    price: '5',
    currency: '€',
    payUrl: '',
    payLabel: 'ادفع / Payer',
    supportLabel: 'ادعم المشروع · Soutenir',
    contactEmail: '',
    whatsapp: '',
    lang: 'ar',
    disclaimer: '⚠️ هذه معلومات عامة للتوعية وليست استشارة قانونية رسمية. يُرجى دائماً التحقق من الجهات الرسمية والمنظمات المعتمدة. · Informations générales, non juridiquement contraignantes.'
  };
}

function seedIfEmpty_() {
  if (PROP.getProperty('TABS')) return;
  if (!PROP.getProperty('SETTINGS')) saveSettings_(defaultSettings_());
  var seed = seedTabs_();
  var meta = [];
  seed.forEach(function (s, i) {
    meta.push({ id: s.id, title: s.title, icon: s.icon, locked: !!s.locked, order: i });
    setTabContent_(s.id, s.content);
  });
  saveTabsMeta_(meta);
}

function seedTabs_() {
  return [
    {
      id: 'asylum', icon: '🛡️', title: 'طالب لجوء', locked: false,
      content:
        '<h3>من هو طالب اللجوء؟ <span class="fr">Demandeur d\'asile</span></h3>' +
        '<p>طالب اللجوء شخص غادر بلده بسبب خطر على حياته أو حريته (حرب، اضطهاد، عنف) ويطلب الحماية الدولية في بلد أوروبي.</p>' +
        '<h4>الخطوات الأساسية</h4>' +
        '<ol>' +
        '<li>التوجه فور الوصول إلى الشرطة أو مكتب الهجرة وطلب الحماية الدولية.</li>' +
        '<li>تقديم الطلب وأخذ البصمات (في إيطاليا: Modello C3).</li>' +
        '<li>الحصول على إقامة مؤقتة لطالب اللجوء (permesso di soggiorno per richiesta asilo).</li>' +
        '<li>المقابلة أمام اللجنة المختصة (Commissione Territoriale).</li>' +
        '<li>انتظار القرار: لجوء، حماية فرعية، أو حماية خاصة.</li>' +
        '</ol>' +
        '<h4>نصائح مهمة</h4>' +
        '<ul><li>احتفظ بكل الوثائق والإيصالات.</li><li>اطلب مترجماً — هذا حقك.</li><li>تواصل مع منظمات المساعدة القانونية المجانية.</li></ul>' +
        '<p class="muted">Italie : rendez-vous à la Questura la plus proche pour déposer votre demande.</p>'
    },
    {
      id: 'regularize', icon: '📋', title: 'تسوية الإقامة', locked: false,
      content:
        '<h3>تسوية وضعية الإقامة <span class="fr">Régularisation du séjour</span></h3>' +
        '<p>إذا كنت مقيماً دون أوراق، فهناك مسارات قانونية ممكنة لتسوية وضعك حسب البلد وظروفك.</p>' +
        '<h4>مسارات ممكنة</h4>' +
        '<ul>' +
        '<li>التسوية عن طريق العمل (عقد عمل، أو sanatoria عند توفرها).</li>' +
        '<li>الإقامة لأسباب إنسانية أو حماية خاصة.</li>' +
        '<li>الإقامة بسبب الروابط العائلية.</li>' +
        '<li>الإقامة الطبية في حالات المرض الخطير.</li>' +
        '</ul>' +
        '<h4>ما تحتاجه عادة</h4>' +
        '<ul><li>إثبات الهوية/جواز السفر إن وُجد.</li><li>إثبات التواجد في البلد (وثائق، إيصالات).</li><li>عقد أو عرض عمل في بعض المسارات.</li></ul>'
    },
    {
      id: 'aid', icon: '🤝', title: 'المعونات والمساعدات', locked: false,
      content:
        '<h3>المعونات والمساعدات <span class="fr">Aides publiques et associatives</span></h3>' +
        '<p>توجد جهات حكومية وجمعيات تقدّم السكن والطعام والرعاية الصحية والدعم القانوني مجاناً.</p>' +
        '<ul>' +
        '<li>مراكز الاستقبال (في إيطاليا: CAS / SAI).</li>' +
        '<li>الرعاية الصحية الطارئة متاحة للجميع (رمز STP).</li>' +
        '<li>جمعيات: Caritas، Croce Rossa، Arci وغيرها.</li>' +
        '<li>المساعدة القانونية المجانية (gratuito patrocinio).</li>' +
        '</ul>'
    },
    {
      id: 'family', icon: '👨‍👩‍👧', title: 'لم الشمل العائلي', locked: false,
      content:
        '<h3>لم الشمل العائلي <span class="fr">Regroupement familial</span></h3>' +
        '<p>يحق لبعض المقيمين بشكل قانوني جلب أفراد أسرهم (الزوج/الزوجة، الأبناء القُصّر) وفق شروط.</p>' +
        '<h4>الشروط العامة</h4>' +
        '<ul><li>إقامة سارية المفعول.</li><li>دخل كافٍ وسكن مناسب.</li><li>إثبات صلة القرابة (وثائق مصدّقة).</li></ul>'
    },
    {
      id: 'rights', icon: '⚖️', title: 'حقوقك وواجباتك', locked: false,
      content:
        '<h3>حقوقك وواجباتك <span class="fr">Vos droits et devoirs</span></h3>' +
        '<h4>حقوقك</h4>' +
        '<ul><li>الحق في مترجم ومحامٍ.</li><li>الحق في الرعاية الصحية الطارئة.</li><li>الحق في معاملة إنسانية.</li></ul>' +
        '<h4>واجباتك</h4>' +
        '<ul><li>احترام القوانين المحلية.</li><li>الحضور في المواعيد الرسمية.</li><li>تحديث عنوانك لدى السلطات.</li></ul>'
    },
    {
      id: 'faq', icon: '❓', title: 'أسئلة شائعة', locked: false,
      content:
        '<h3>أسئلة شائعة <span class="fr">FAQ</span></h3>' +
        '<p><b>هل أحتاج محامياً؟</b> ليس إلزامياً لكنه مفيد، وهناك مساعدة قانونية مجانية.</p>' +
        '<p><b>كم يستغرق قرار اللجوء؟</b> يختلف من بضعة أشهر إلى أكثر من سنة.</p>' +
        '<p><b>ماذا لو رُفض طلبي؟</b> يمكنك الطعن أمام المحكمة خلال المهلة القانونية.</p>'
    },
    {
      id: 'premium', icon: '⭐', title: 'الدليل الكامل خطوة بخطوة', locked: true,
      content:
        '<h3>الدليل الكامل خطوة بخطوة <span class="fr">Guide complet · Premium</span></h3>' +
        '<p>محتوى مفصّل يشرح كل خطوة مع قائمة الوثائق الكاملة، النماذج الجاهزة، عناوين المكاتب حسب المدينة، ونصائح المقابلة.</p>' +
        '<h4>يشمل:</h4>' +
        '<ul><li>قائمة الوثائق الكاملة لكل حالة.</li><li>نماذج وطلبات جاهزة.</li><li>عناوين المكاتب الرسمية حسب المدينة.</li><li>كيف تستعد لمقابلة اللجنة.</li><li>ماذا تفعل عند الرفض (الطعن).</li></ul>' +
        '<p class="muted">يظهر هذا المحتوى كاملاً بعد الدفع وإدخال رمز الوصول.</p>'
    }
  ];
}
