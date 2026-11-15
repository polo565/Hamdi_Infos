/**
 * Point d'entrée du Web App (requêtes GET).
 * URL de déploiement : .../macros/s/<DEPLOYMENT_ID>/exec
 */
function doGet(e) {
  return ContentService
    .createTextOutput(JSON.stringify({ status: 'ok', message: 'Hamdi Infos — Web App en ligne', time: new Date().toISOString() }))
    .setMimeType(ContentService.MimeType.JSON);
}

/**
 * Point d'entrée du Web App (requêtes POST).
 */
function doPost(e) {
  var payload = {};
  try {
    if (e && e.postData && e.postData.contents) {
      payload = JSON.parse(e.postData.contents);
    }
  } catch (err) {
    return ContentService
      .createTextOutput(JSON.stringify({ status: 'error', message: 'JSON invalide' }))
      .setMimeType(ContentService.MimeType.JSON);
  }

  return ContentService
    .createTextOutput(JSON.stringify({ status: 'ok', received: payload }))
    .setMimeType(ContentService.MimeType.JSON);
}
