# Hamdi Infos — GitHub → Google Apps Script

Développe ton code ici (sur GitHub) et pousse-le vers Google Apps Script avec [`clasp`](https://github.com/google/clasp).

## Structure

```
.
├── .github/workflows/deploy.yml   # Auto-déploiement vers Apps Script à chaque push sur main
├── src/
│   ├── appsscript.json            # Manifeste du projet Apps Script
│   └── Code.js                    # Ton code (doGet / doPost pour le Web App)
├── .clasp.json                    # Config clasp (Script ID + dossier source)
├── .claspignore                   # Fichiers exclus du push
├── package.json                   # Scripts npm pratiques
└── .gitignore
```

---

## ⚙️ Configuration initiale (une seule fois)

### 1. Renseigner ton Script ID

Ouvre `.clasp.json` et remplace `REMPLACER_PAR_TON_SCRIPT_ID` par ton vrai **Script ID**.

> ⚠️ **Le Script ID n'est PAS l'URL `/exec`.**
> L'URL `.../macros/s/AKfyc.../exec` est l'ID de *déploiement* du Web App.
>
> **Où trouver le Script ID :**
> 1. Ouvre ton projet sur [script.google.com](https://script.google.com)
> 2. Menu **⚙️ Paramètres du projet** (Project Settings)
> 3. Copie l'**ID du script** (une longue chaîne de ~57 caractères)
>
> Ou bien : il est dans l'URL de l'éditeur :
> `https://script.google.com/.../projects/`**`<SCRIPT_ID>`**`/edit`

### 2. Développement local (manuel)

```bash
npm install          # installe clasp en local
npm run login        # connexion à ton compte Google (ouvre le navigateur)
npm run push         # pousse src/ vers Apps Script
npm run pull         # récupère la version en ligne vers src/
npm run open         # ouvre le projet dans le navigateur
```

### 3. Auto-déploiement via GitHub Actions

Le workflow `.github/workflows/deploy.yml` pousse automatiquement vers Apps Script
à chaque `push` sur la branche `main`. Il faut lui donner tes identifiants clasp **une fois** :

1. **En local**, connecte-toi : `npm run login` (ça crée `~/.clasprc.json`).
2. Affiche le contenu du fichier :
   - macOS / Linux : `cat ~/.clasprc.json`
   - Windows : `type %USERPROFILE%\.clasprc.json`
3. Copie **tout** le contenu JSON.
4. Sur GitHub : **Settings → Secrets and variables → Actions → New repository secret**
   - **Name :** `CLASPRC_JSON`
   - **Secret :** colle le contenu copié
5. C'est prêt. À chaque push sur `main`, le code part vers Apps Script. 🚀

> 🔒 `~/.clasprc.json` contient tes tokens Google — il est déjà dans `.gitignore`,
> ne le committe jamais. Utilise uniquement le secret GitHub.

---

## Flux de travail quotidien

```bash
# 1. Modifie ton code dans src/
# 2. Commit + push
git add .
git commit -m "Ma modif"
git push

# → GitHub Actions déploie automatiquement vers Apps Script
```

Pour re-déployer le **Web App** (nouvelle version de l'URL `/exec`), utilise
`clasp deploy` ou gère les déploiements depuis l'éditeur Apps Script.
