/**
 * دليل اللاجئين والمهاجرين — Google Apps Script Web App
 * نسخة 5: AR/FR/EN + نافذة ترحيب (بلد الأصل/بلد التواجد) + روابط ووثائق خاصة بكل دولة + Banners + دفع PayPal/USDT + طلبات.
 */

var PROP = PropertiesService.getScriptProperties();
var DEFAULT_ADMIN_KEY = 'admin';
var SCHEMA = '5';

/* -------------------- Routage -------------------- */
function doGet(e) {
  seedIfEmpty_();
  var page = ((e && e.parameter && e.parameter.page) || 'home').toLowerCase();
  var tpl = (page === 'admin') ? 'Admin' : 'Index';
  var title = (page === 'admin') ? 'لوحة التحكم' : (getSettings_().siteTitle || 'دليل اللاجئين');
  return HtmlService.createTemplateFromFile(tpl).evaluate()
    .setTitle(title)
    .addMetaTag('viewport', 'width=device-width, initial-scale=1')
    .setXFrameOptionsMode(HtmlService.XFrameOptionsMode.ALLOWALL);
}
function include(f) { return HtmlService.createHtmlOutputFromFile(f).getContent(); }

/* -------------------- Stockage -------------------- */
function getSettings_() { var r = PROP.getProperty('SETTINGS'); return r ? JSON.parse(r) : defaultSettings_(); }
function saveSettings_(s) { PROP.setProperty('SETTINGS', JSON.stringify(s)); }
function getTabsMeta_() { var r = PROP.getProperty('TABS'); return r ? JSON.parse(r) : []; }
function saveTabsMeta_(a) { PROP.setProperty('TABS', JSON.stringify(a)); }
function getContentObj_(id) {
  var r = PROP.getProperty('TAB_' + id);
  if (!r) return {};
  try { var o = JSON.parse(r); if (o && typeof o === 'object') return o; } catch (e) {}
  return { ar: r };
}
function setContentObj_(id, obj) { PROP.setProperty('TAB_' + id, JSON.stringify(cleanMl_(obj))); }
function delContent_(id) { PROP.deleteProperty('TAB_' + id); }
function getCodes_() { var r = PROP.getProperty('CODES'); return r ? JSON.parse(r) : []; }
function saveCodes_(a) { PROP.setProperty('CODES', JSON.stringify(a)); }
function getOrders_() { var r = PROP.getProperty('ORDERS'); return r ? JSON.parse(r) : []; }
function saveOrders_(a) { PROP.setProperty('ORDERS', JSON.stringify(a)); }
function getAdminKey_() { return PROP.getProperty('ADMIN_KEY') || DEFAULT_ADMIN_KEY; }
function assertAdmin_(k) { if (String(k) !== getAdminKey_()) throw new Error('UNAUTHORIZED'); }

/* -------------------- Helpers multilingues -------------------- */
function toMl_(v) { if (v == null) return {}; if (typeof v === 'string') return { ar: v }; return v; }
function cleanMl_(o) { var out = {}; o = toMl_(o); for (var k in o) { if (o[k] != null && String(o[k]).length) out[k] = o[k]; } return out; }
function ml_(o, lang) {
  if (o == null) return '';
  if (typeof o === 'string') return o;
  if (o[lang]) return o[lang];
  var order = [lang, 'en', 'fr', 'ar'];
  for (var i = 0; i < order.length; i++) if (o[order[i]]) return o[order[i]];
  for (var k in o) if (o[k]) return o[k];
  return '';
}
function teaser_(html) { var t = String(html || '').replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim(); return t.length > 240 ? t.slice(0, 240) + '…' : t; }
function teaserObj_(c) { var out = {}; if (c && typeof c === 'object') for (var k in c) out[k] = teaser_(c[k]); return out; }

/* -------------------- API publique -------------------- */
function getPublicData() {
  seedIfEmpty_();
  var s = getSettings_();
  var tabs = getTabsMeta_().sort(function (a, b) { return a.order - b.order; }).map(function (t) {
    var locked = (Number(t.price) || 0) > 0;
    var o = { id: t.id, title: toMl_(t.title), desc: toMl_(t.desc), icon: t.icon || '', color: t.color || '#0f766e', price: Number(t.price) || 0, locked: locked, links: t.links || [] };
    var c = getContentObj_(t.id);
    if (locked) { o.teaser = teaserObj_(c); }
    else { o.content = c; o.docs = t.docs || []; }
    return o;
  });
  return {
    settings: {
      siteTitle: s.siteTitle, siteSubtitle: s.siteSubtitle, currency: s.currency, lang: s.lang,
      languages: s.languages || defaultLanguages_(), countries: s.countries || defaultCountries_(),
      paypalUrl: s.paypalUrl, usdtAddress: s.usdtAddress, usdtNetwork: s.usdtNetwork, usdtNote: s.usdtNote,
      contactEmail: s.contactEmail, whatsapp: s.whatsapp, supportLabel: s.supportLabel,
      disclaimer: s.disclaimer, verifyNote: s.verifyNote
    },
    tabs: tabs
  };
}

function getLockedContent(id, code) {
  if (!validCodeForTab_(code, id)) return { ok: false };
  var t = getTabsMeta_().filter(function (x) { return x.id === id; })[0];
  return { ok: true, content: getContentObj_(id), links: (t && t.links) || [], docs: (t && t.docs) || [] };
}

function createOrder(data) {
  seedIfEmpty_();
  data = data || {};
  var tab = getTabsMeta_().filter(function (t) { return t.id === data.tabId; })[0];
  if (!tab) throw new Error('NOT_FOUND');
  var s = getSettings_();
  var orders = getOrders_();
  var id = 'o' + Date.now().toString(36) + Math.floor(Math.random() * 1000);
  orders.push({
    id: id, tabId: tab.id, tabTitle: ml_(tab.title, 'ar'), method: data.method || 'paypal',
    amount: Number(tab.price) || 0, currency: s.currency || '€',
    proof: String(data.proof || '').slice(0, 300), contact: String(data.contact || '').slice(0, 200),
    origin: String(data.origin || '').slice(0, 60), current: String(data.current || '').slice(0, 60),
    status: 'pending', code: '', created: new Date().toISOString()
  });
  saveOrders_(orders);
  return { ok: true, orderId: id };
}

function validCodeForTab_(code, tabId) {
  if (!code) return false;
  var c = String(code).trim().toUpperCase();
  return getCodes_().some(function (x) { return x.code === c && x.active !== false && (!x.tabId || x.tabId === tabId); });
}

/* -------------------- API admin -------------------- */
function adminLogin(k) { return String(k) === getAdminKey_(); }

function adminGetData(key) {
  assertAdmin_(key);
  var tabs = getTabsMeta_().sort(function (a, b) { return a.order - b.order; }).map(function (t) {
    return { id: t.id, title: toMl_(t.title), desc: toMl_(t.desc), icon: t.icon || '', color: t.color || '#0f766e', price: Number(t.price) || 0, links: t.links || [], docs: t.docs || [], content: getContentObj_(t.id) };
  });
  var s = getSettings_();
  if (!s.languages) s.languages = defaultLanguages_();
  if (!s.countries) s.countries = defaultCountries_();
  return {
    settings: s, tabs: tabs, codes: getCodes_(),
    orders: getOrders_().sort(function (a, b) { return (a.created < b.created) ? 1 : -1; }),
    adminKeyIsDefault: getAdminKey_() === DEFAULT_ADMIN_KEY
  };
}

function adminAddTab(key, d) {
  assertAdmin_(key);
  var tabs = getTabsMeta_();
  var id = 't' + Date.now().toString(36) + Math.floor(Math.random() * 1000);
  var order = tabs.length ? Math.max.apply(null, tabs.map(function (t) { return t.order; })) + 1 : 0;
  tabs.push({ id: id, title: cleanMl_((d && d.title) || { ar: 'تبويب جديد' }), desc: cleanMl_((d && d.desc) || {}), icon: (d && d.icon) || '📄', color: (d && d.color) || '#0f766e', price: Number(d && d.price) || 0, links: (d && d.links) || [], docs: (d && d.docs) || [], order: order });
  saveTabsMeta_(tabs);
  setContentObj_(id, (d && d.content) || {});
  return adminGetData(key);
}

function adminUpdateTab(key, id, d) {
  assertAdmin_(key);
  var tabs = getTabsMeta_();
  var t = tabs.filter(function (x) { return x.id === id; })[0];
  if (!t) throw new Error('NOT_FOUND');
  if (d.title != null) t.title = cleanMl_(d.title);
  if (d.desc != null) t.desc = cleanMl_(d.desc);
  if (d.icon != null) t.icon = d.icon;
  if (d.color != null) t.color = d.color;
  if (d.price != null) t.price = Number(d.price) || 0;
  if (d.links != null) t.links = d.links;
  if (d.docs != null) t.docs = d.docs;
  saveTabsMeta_(tabs);
  if (d.content != null) setContentObj_(id, d.content);
  return adminGetData(key);
}

function adminDeleteTab(key, id) { assertAdmin_(key); saveTabsMeta_(getTabsMeta_().filter(function (x) { return x.id !== id; })); delContent_(id); return adminGetData(key); }
function adminReorder(key, ids) { assertAdmin_(key); var tabs = getTabsMeta_(); ids.forEach(function (id, i) { var t = tabs.filter(function (x) { return x.id === id; })[0]; if (t) t.order = i; }); saveTabsMeta_(tabs); return adminGetData(key); }
function adminSaveSettings(key, settings) { assertAdmin_(key); saveSettings_(Object.assign({}, getSettings_(), settings)); return adminGetData(key); }
function adminChangeKey(key, newKey) { assertAdmin_(key); newKey = String(newKey || '').trim(); if (newKey.length < 4) throw new Error('KEY_TOO_SHORT'); PROP.setProperty('ADMIN_KEY', newKey); return true; }

function adminAddCode(key, code, tabId) {
  assertAdmin_(key);
  var codes = getCodes_();
  code = (code && String(code).trim().toUpperCase()) || genCode_();
  if (codes.some(function (c) { return c.code === code; })) throw new Error('EXISTS');
  codes.push({ code: code, active: true, tabId: tabId || '', created: new Date().toISOString() });
  saveCodes_(codes);
  return adminGetData(key);
}
function adminDeleteCode(key, code) { assertAdmin_(key); saveCodes_(getCodes_().filter(function (c) { return c.code !== code; })); return adminGetData(key); }

function adminApproveOrder(key, orderId) {
  assertAdmin_(key);
  var orders = getOrders_();
  var o = orders.filter(function (x) { return x.id === orderId; })[0];
  if (!o) throw new Error('NOT_FOUND');
  var code = genCode_();
  var codes = getCodes_();
  codes.push({ code: code, active: true, tabId: o.tabId, created: new Date().toISOString() });
  saveCodes_(codes);
  o.status = 'approved'; o.code = code; saveOrders_(orders);
  return adminGetData(key);
}
function adminRejectOrder(key, orderId) { assertAdmin_(key); var o = getOrders_(); var x = o.filter(function (v) { return v.id === orderId; })[0]; if (x) { x.status = 'rejected'; saveOrders_(o); } return adminGetData(key); }
function adminDeleteOrder(key, orderId) { assertAdmin_(key); saveOrders_(getOrders_().filter(function (x) { return x.id !== orderId; })); return adminGetData(key); }

function genCode_() { var s = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789', o = ''; for (var i = 0; i < 8; i++) o += s.charAt(Math.floor(Math.random() * s.length)); return o; }

/* -------------------- Langues + Pays -------------------- */
function defaultLanguages_() {
  return [
    { code: 'ar', label: 'العربية', dir: 'rtl' },
    { code: 'fr', label: 'Français', dir: 'ltr' },
    { code: 'en', label: 'English', dir: 'ltr' }
  ];
}
function defaultCountries_() {
  return [
    { code: 'FR', label: { ar: 'فرنسا', fr: 'France', en: 'France' } },
    { code: 'IT', label: { ar: 'إيطاليا', fr: 'Italie', en: 'Italy' } },
    { code: 'ES', label: { ar: 'إسبانيا', fr: 'Espagne', en: 'Spain' } },
    { code: 'DE', label: { ar: 'ألمانيا', fr: 'Allemagne', en: 'Germany' } },
    { code: 'BE', label: { ar: 'بلجيكا', fr: 'Belgique', en: 'Belgium' } },
    { code: 'NL', label: { ar: 'هولندا', fr: 'Pays-Bas', en: 'Netherlands' } },
    { code: 'OTHER', label: { ar: 'دولة أوروبية أخرى', fr: 'Autre pays européen', en: 'Other European country' } }
  ];
}

/* -------------------- Défauts + amorçage -------------------- */
function defaultSettings_() {
  return {
    siteTitle: 'دليل اللاجئين والمهاجرين',
    siteSubtitle: 'معلومات موثوقة وروابط رسمية لطالبي اللجوء والمقيمين في أوروبا',
    currency: '€', lang: 'ar', languages: defaultLanguages_(), countries: defaultCountries_(),
    paypalUrl: '', usdtAddress: '', usdtNetwork: 'TRC20',
    usdtNote: 'افتح تطبيق Bybit ← Assets ← Withdraw، الصق العنوان، اختر الشبكة الصحيحة، ثم أرسل المبلغ.',
    contactEmail: '', whatsapp: '', supportLabel: 'دعم المشروع',
    disclaimer: '⚠️ معلومات عامة للتوعية وليست استشارة قانونية رسمية. المواعيد والمعلومات لدى الجهات الرسمية مجانية؛ هذه الخدمة لتبسيط وتجميع المعلومات فقط. تحقّق دائماً من الجهات الرسمية.',
    verifyNote: '🔗 الروابط تؤدي إلى جهات رسمية ومنظمات معروفة. قد تتغيّر العناوين؛ يُرجى التحقق قبل الاعتماد عليها. لا تدفع أبداً مقابل موعد رسمي — فهو مجاني.'
  };
}

function seedIfEmpty_() {
  if (PROP.getProperty('SCHEMA_VERSION') === SCHEMA && PROP.getProperty('TABS')) return;
  var existing = PROP.getProperty('SETTINGS');
  var merged = existing ? Object.assign(defaultSettings_(), JSON.parse(existing)) : defaultSettings_();
  merged.languages = defaultLanguages_();              // نُثبّت AR/FR/EN
  if (!merged.countries) merged.countries = defaultCountries_();
  saveSettings_(merged);
  var seed = seedTabs_();
  var meta = [];
  seed.forEach(function (s, i) {
    meta.push({ id: s.id, title: s.title, desc: s.desc, icon: s.icon, color: s.color, price: s.price || 0, links: s.links || [], docs: s.docs || [], order: i });
    setContentObj_(s.id, s.content);
  });
  saveTabsMeta_(meta);
  PROP.setProperty('SCHEMA_VERSION', SCHEMA);
}

function seedTabs_() {
  var L = {
    unhcr: { label: 'UNHCR Help (الأمم المتحدة)', url: 'https://help.unhcr.org', country: '' },
    unhcrIt: { label: 'UNHCR إيطاليا', url: 'https://help.unhcr.org/italy/', country: 'IT' },
    unhcrFr: { label: 'UNHCR فرنسا', url: 'https://help.unhcr.org/france/', country: 'FR' },
    unhcrEs: { label: 'UNHCR إسبانيا', url: 'https://help.unhcr.org/spain/', country: 'ES' },
    unhcrBe: { label: 'UNHCR بلجيكا', url: 'https://help.unhcr.org/belgium/', country: 'BE' },
    ofpra: { label: 'فرنسا — OFPRA', url: 'https://www.ofpra.gouv.fr', country: 'FR' },
    frAsile: { label: 'فرنسا — طلب اللجوء (الداخلية)', url: 'https://www.immigration.interieur.gouv.fr/politique-de-lasile/demander-l-asile-en-france', country: 'FR' },
    spFr: { label: 'فرنسا — Service-Public', url: 'https://www.service-public.gouv.fr/particuliers/vosdroits/F2649', country: 'FR' },
    bamf: { label: 'ألمانيا — BAMF', url: 'https://www.bamf.de', country: 'DE' },
    ind: { label: 'هولندا — IND', url: 'https://ind.nl/en', country: 'NL' },
    cgrs: { label: 'بلجيكا — CGRS', url: 'https://www.cgrs.be/en', country: 'BE' },
    fedasil: { label: 'بلجيكا — Fedasil', url: 'https://www.fedasil.be/en', country: 'BE' },
    cear: { label: 'إسبانيا — CEAR', url: 'https://www.cear.es', country: 'ES' },
    interiorEs: { label: 'إسبانيا — وزارة الداخلية', url: 'https://www.interior.gob.es', country: 'ES' },
    policiaEs: { label: 'إسبانيا — الشرطة (مواعيد)', url: 'https://sede.policia.gob.es', country: 'ES' },
    polIt: { label: 'إيطاليا — Polizia di Stato', url: 'https://questure.poliziadistato.it/stranieri', country: 'IT' },
    portaleIt: { label: 'إيطاليا — Portale Immigrazione', url: 'https://www.portaleimmigrazione.it', country: 'IT' },
    caritas: { label: 'Caritas (مساعدات)', url: 'https://www.caritas.org', country: '' }
  };
  var allAuth = [L.unhcr, L.unhcrFr, L.unhcrIt, L.unhcrEs, L.unhcrBe, L.ofpra, L.frAsile, L.spFr, L.polIt, L.portaleIt, L.interiorEs, L.policiaEs, L.bamf, L.ind, L.cgrs, L.fedasil];
  var D = function (ar, fr, en, country) { return { label: { ar: ar, fr: fr, en: en }, country: country || '' }; };
  return [
    {
      id: 'asylum', icon: '🛡️', color: '#0f766e', price: 0,
      title: { ar: 'طالب لجوء', fr: 'Demandeur d\'asile', en: 'Asylum seeker' },
      desc: { ar: 'كيف تطلب الحماية الدولية خطوة بخطوة', fr: 'Demander la protection internationale', en: 'How to seek international protection' },
      links: allAuth,
      docs: [
        D('جواز سفر أو أي إثبات هوية', 'Passeport ou pièce d\'identité', 'Passport or any ID'),
        D('صور شخصية حديثة', 'Photos d\'identité récentes', 'Recent ID photos'),
        D('إثبات الدخول/السفر (تذاكر، أختام)', 'Preuve d\'entrée/voyage', 'Proof of entry/travel'),
        D('أي وثائق تدعم طلبك (أدلة الخطر)', 'Documents appuyant votre demande', 'Evidence supporting your claim'),
        D('نموذج C3', 'Formulaire C3', 'C3 form', 'IT'),
        D('شهادة إيواء/عنوان عبر SPADA', 'Attestation de domiciliation (SPADA)', 'Address certificate (SPADA)', 'FR')
      ],
      content: {
        ar: '<h3>من هو طالب اللجوء؟</h3><p>شخص غادر بلده بسبب خطر على حياته أو حريته (حرب، اضطهاد، عنف) ويطلب الحماية الدولية في بلد أوروبي.</p><h4>الخطوات الأساسية</h4><ol><li>التوجّه فور الوصول إلى الجهة المختصة وطلب الحماية الدولية.</li><li>التسجيل وأخذ البصمات.</li><li>الحصول على إقامة مؤقتة لطالب اللجوء.</li><li>المقابلة أمام الجهة المختصة.</li><li>انتظار القرار: لجوء، حماية فرعية، أو حماية خاصة.</li></ol><h4>نصائح</h4><ul><li>احتفظ بكل الوثائق والإيصالات.</li><li>اطلب مترجماً — هذا حقك.</li><li>تواصل مع منظمات المساعدة القانونية المجانية.</li></ul>',
        fr: '<h3>Qui est demandeur d\'asile ?</h3><p>Une personne ayant fui son pays pour un danger (guerre, persécution, violence) et demandant une protection internationale en Europe.</p><h4>Étapes</h4><ol><li>Se présenter dès l\'arrivée et demander la protection internationale.</li><li>Enregistrement et prise d\'empreintes.</li><li>Attestation / séjour provisoire.</li><li>Entretien avec l\'autorité compétente.</li><li>Décision : asile, protection subsidiaire ou spéciale.</li></ol><h4>Conseils</h4><ul><li>Gardez tous vos documents.</li><li>Demandez un interprète — c\'est votre droit.</li><li>Contactez l\'aide juridique gratuite.</li></ul>',
        en: '<h3>Who is an asylum seeker?</h3><p>Someone who fled their country due to danger (war, persecution, violence) and asks for international protection in Europe.</p><h4>Main steps</h4><ol><li>Report on arrival and request international protection.</li><li>Registration and fingerprinting.</li><li>Temporary asylum-seeker permit.</li><li>Interview with the competent authority.</li><li>Decision: asylum, subsidiary or special protection.</li></ol><h4>Tips</h4><ul><li>Keep all documents and receipts.</li><li>Ask for an interpreter — it is your right.</li><li>Contact free legal aid organizations.</li></ul>'
      }
    },
    {
      id: 'rights', icon: '⚖️', color: '#1d4ed8', price: 0,
      title: { ar: 'حقوقك وواجباتك', fr: 'Droits et devoirs', en: 'Rights & duties' },
      desc: { ar: 'ما لك وما عليك أثناء الإجراءات', fr: 'Vos droits et obligations', en: 'What you may and must do' },
      links: [L.unhcr, L.fedasil, L.cgrs],
      docs: [],
      content: {
        ar: '<h3>حقوقك وواجباتك</h3><h4>حقوقك</h4><ul><li>الحق في مترجم ومحامٍ.</li><li>الحق في الرعاية الصحية الطارئة.</li><li>الحق في معاملة إنسانية.</li></ul><h4>واجباتك</h4><ul><li>احترام القوانين المحلية.</li><li>الحضور في المواعيد الرسمية.</li><li>تحديث عنوانك لدى السلطات.</li></ul>',
        fr: '<h3>Vos droits et devoirs</h3><h4>Droits</h4><ul><li>Droit à un interprète et à un avocat.</li><li>Droit aux soins d\'urgence.</li><li>Droit à un traitement digne.</li></ul><h4>Devoirs</h4><ul><li>Respecter les lois locales.</li><li>Se présenter aux rendez-vous.</li><li>Mettre à jour votre adresse.</li></ul>',
        en: '<h3>Your rights and duties</h3><h4>Rights</h4><ul><li>Right to an interpreter and a lawyer.</li><li>Right to emergency healthcare.</li><li>Right to humane treatment.</li></ul><h4>Duties</h4><ul><li>Respect local laws.</li><li>Attend official appointments.</li><li>Keep your address updated.</li></ul>'
      }
    },
    {
      id: 'aid', icon: '🤝', color: '#059669', price: 0,
      title: { ar: 'المعونات والمساعدات', fr: 'Aides', en: 'Aid & assistance' },
      desc: { ar: 'سكن، طعام، صحة، ودعم قانوني مجاني', fr: 'Logement, nourriture, santé, aide', en: 'Housing, food, health, legal aid' },
      links: [L.unhcr, L.caritas, L.fedasil, L.cear],
      docs: [],
      content: {
        ar: '<h3>المعونات والمساعدات</h3><p>توجد جهات حكومية وجمعيات تقدّم السكن والطعام والرعاية الصحية والدعم القانوني مجاناً.</p><ul><li>مراكز الاستقبال الرسمية.</li><li>الرعاية الصحية الطارئة متاحة للجميع.</li><li>جمعيات: Caritas، الصليب الأحمر، وغيرها.</li><li>المساعدة القانونية المجانية.</li></ul>',
        fr: '<h3>Aides et assistance</h3><p>Des services publics et des associations offrent gratuitement hébergement, nourriture, soins et aide juridique.</p><ul><li>Centres d\'accueil officiels.</li><li>Soins d\'urgence pour tous.</li><li>Associations : Caritas, Croix-Rouge, etc.</li><li>Aide juridique gratuite.</li></ul>',
        en: '<h3>Aid and assistance</h3><p>Public services and NGOs offer free housing, food, healthcare and legal support.</p><ul><li>Official reception centers.</li><li>Emergency care for everyone.</li><li>NGOs: Caritas, Red Cross, etc.</li><li>Free legal aid.</li></ul>'
      }
    },
    {
      id: 'faq', icon: '❓', color: '#7c3aed', price: 0,
      title: { ar: 'أسئلة شائعة', fr: 'FAQ', en: 'FAQ' },
      desc: { ar: 'إجابات سريعة لأكثر الأسئلة تكراراً', fr: 'Réponses aux questions fréquentes', en: 'Quick answers to common questions' },
      links: [L.unhcr],
      docs: [],
      content: {
        ar: '<h3>أسئلة شائعة</h3><p><b>هل أحتاج محامياً؟</b> ليس إلزامياً لكنه مفيد، وهناك مساعدة قانونية مجانية.</p><p><b>كم يستغرق قرار اللجوء؟</b> من بضعة أشهر إلى أكثر من سنة.</p><p><b>ماذا لو رُفض طلبي؟</b> يمكنك الطعن أمام المحكمة خلال المهلة القانونية.</p>',
        fr: '<h3>FAQ</h3><p><b>Ai-je besoin d\'un avocat ?</b> Non obligatoire mais utile ; l\'aide juridique gratuite existe.</p><p><b>Durée de la décision ?</b> De quelques mois à plus d\'un an.</p><p><b>En cas de refus ?</b> Vous pouvez faire appel dans les délais.</p>',
        en: '<h3>FAQ</h3><p><b>Do I need a lawyer?</b> Not mandatory but helpful; free legal aid exists.</p><p><b>How long for a decision?</b> From a few months to over a year.</p><p><b>If refused?</b> You can appeal before the court within the deadline.</p>'
      }
    },
    {
      id: 'regularize', icon: '📋', color: '#b45309', price: 5,
      title: { ar: 'تسوية الإقامة', fr: 'Régularisation', en: 'Regularize stay' },
      desc: { ar: 'مسارات تسوية وضعية الإقامة حسب حالتك', fr: 'Voies de régularisation du séjour', en: 'Paths to regularize your stay' },
      links: allAuth,
      docs: [
        D('إثبات الهوية / جواز السفر', 'Identité / passeport', 'ID / passport'),
        D('إثبات التواجد في البلد (وثائق، إيصالات)', 'Preuve de présence dans le pays', 'Proof of presence in the country'),
        D('عقد عمل أو عرض عمل (حسب المسار)', 'Contrat ou offre d\'emploi', 'Work contract or job offer'),
        D('إثبات العنوان/السكن', 'Justificatif de domicile', 'Proof of address')
      ],
      content: {
        ar: '<h3>تسوية وضعية الإقامة</h3><p>مسارات قانونية ممكنة لتسوية وضعك حسب البلد وظروفك.</p><h4>مسارات ممكنة</h4><ul><li>التسوية عن طريق العمل (عقد عمل، أو تسويات استثنائية عند توفرها).</li><li>الإقامة لأسباب إنسانية أو حماية خاصة.</li><li>الإقامة بسبب الروابط العائلية.</li><li>الإقامة الطبية في حالات المرض الخطير.</li></ul>',
        fr: '<h3>Régularisation du séjour</h3><p>Des voies légales existent selon le pays et votre situation.</p><h4>Voies possibles</h4><ul><li>Par le travail (contrat, régularisations exceptionnelles).</li><li>Motifs humanitaires ou protection spéciale.</li><li>Liens familiaux.</li><li>Raisons médicales graves.</li></ul>',
        en: '<h3>Regularizing your stay</h3><p>Legal pathways exist depending on country and situation.</p><h4>Possible paths</h4><ul><li>Through work (contract, exceptional schemes).</li><li>Humanitarian grounds or special protection.</li><li>Family ties.</li><li>Serious medical reasons.</li></ul>'
      }
    },
    {
      id: 'family', icon: '👨‍👩‍👧', color: '#be185d', price: 5,
      title: { ar: 'لم الشمل العائلي', fr: 'Regroupement familial', en: 'Family reunification' },
      desc: { ar: 'شروط وخطوات جلب أفراد الأسرة', fr: 'Conditions du regroupement familial', en: 'Conditions to bring your family' },
      links: [L.unhcr, L.ind, L.bamf, L.ofpra, L.cgrs, L.interiorEs],
      docs: [
        D('إقامة سارية المفعول', 'Titre de séjour valide', 'Valid residence permit'),
        D('إثبات صلة القرابة (وثائق مصدّقة)', 'Preuve du lien familial (légalisée)', 'Proof of family ties (legalized)'),
        D('إثبات دخل كافٍ', 'Preuve de ressources suffisantes', 'Proof of sufficient income'),
        D('إثبات سكن مناسب', 'Preuve de logement adéquat', 'Proof of adequate housing')
      ],
      content: {
        ar: '<h3>لم الشمل العائلي</h3><p>يحق لبعض المقيمين بشكل قانوني جلب أفراد أسرهم (الزوج/الزوجة، الأبناء القُصّر) وفق شروط.</p><h4>الشروط العامة</h4><ul><li>إقامة سارية المفعول.</li><li>دخل كافٍ وسكن مناسب.</li><li>إثبات صلة القرابة (وثائق مصدّقة).</li></ul>',
        fr: '<h3>Regroupement familial</h3><p>Certains résidents légaux peuvent faire venir leur famille (conjoint, enfants mineurs) sous conditions.</p><h4>Conditions générales</h4><ul><li>Titre de séjour valide.</li><li>Ressources suffisantes et logement adapté.</li><li>Preuve du lien familial (documents légalisés).</li></ul>',
        en: '<h3>Family reunification</h3><p>Some legal residents can bring family members (spouse, minor children) under conditions.</p><h4>General conditions</h4><ul><li>Valid residence permit.</li><li>Sufficient income and adequate housing.</li><li>Proof of family ties (legalized documents).</li></ul>'
      }
    },
    {
      id: 'guide', icon: '⭐', color: '#c2410c', price: 10,
      title: { ar: 'الدليل الكامل خطوة بخطوة', fr: 'Guide complet', en: 'Complete guide' },
      desc: { ar: 'ملف شامل: الوثائق، النماذج، العناوين، ونصائح المقابلة', fr: 'Documents, modèles, adresses, entretien', en: 'Documents, forms, addresses, interview' },
      links: allAuth,
      docs: [
        D('قائمة الوثائق الكاملة لكل حالة', 'Liste complète des documents', 'Full document checklist'),
        D('نماذج وطلبات جاهزة', 'Modèles et demandes prêts', 'Ready-made forms')
      ],
      content: {
        ar: '<h3>الدليل الكامل خطوة بخطوة</h3><p>محتوى مفصّل يشرح كل خطوة مع قائمة الوثائق الكاملة لكل حالة، نماذج جاهزة، عناوين المكاتب الرسمية، وكيفية الاستعداد للمقابلة وماذا تفعل عند الرفض (الطعن).</p><h4>يشمل</h4><ul><li>قائمة الوثائق الكاملة لكل حالة.</li><li>نماذج وطلبات جاهزة.</li><li>عناوين الجهات الرسمية.</li><li>الاستعداد للمقابلة.</li><li>إجراءات الطعن عند الرفض.</li></ul>',
        fr: '<h3>Guide complet étape par étape</h3><p>Contenu détaillé : liste complète des documents par cas, modèles prêts, adresses officielles, préparation à l\'entretien et recours en cas de refus.</p><h4>Inclut</h4><ul><li>Liste complète des documents par cas.</li><li>Modèles et demandes prêts.</li><li>Adresses des autorités.</li><li>Préparation à l\'entretien.</li><li>Procédure de recours.</li></ul>',
        en: '<h3>Complete step-by-step guide</h3><p>Detailed content: full document checklist per case, ready templates, official office addresses, interview preparation, and appeal if refused.</p><h4>Includes</h4><ul><li>Full document checklist per case.</li><li>Ready-made forms.</li><li>Official authority addresses.</li><li>Interview preparation.</li><li>Appeal procedure.</li></ul>'
      }
    }
  ];
}
