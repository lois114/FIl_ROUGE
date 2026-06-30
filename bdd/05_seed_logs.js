// =====================================================================
// AquaLab — Seed de logs fictifs (MongoDB)
// Axe 4 : alimente la base NoSQL de journaux avec ~200 événements variés
// pour démontrer les agrégations de sécurité (détection brute-force, etc.).
// Exécution : mongosh < 05_seed_logs.js
//             (rejoué automatiquement au démarrage du conteneur Mongo)
// =====================================================================

const logsDb = db.getSiblingDB("aqualab_logs");

// On repart propre pour pouvoir rejouer le seed sans accumuler de doublons
logsDb.logs.deleteMany({});

const sources = ["lims", "portail", "siem", "systeme"];
const levels  = ["INFO", "INFO", "INFO", "WARN", "ERROR", "SECURITY"];
const users   = ["marie_tech", "jules_tech", "sofia_tech", "paul_valid",
                 "lea_valid", "hugo_com", "svc_app", "client_42", "client_7"];
const actions = ["SAISIE_RESULTAT", "VALIDATION_RESULTAT", "LOGIN",
                 "EXPORT_RAPPORT", "CONSULT_ECHANTILLON", "MODIF_PARAMETRE"];
const params  = ["ECOLI", "PH", "NO3", "PB", "TURB"];
// IP 203.0.113.7 sur-représentée => fera ressortir une tentative de brute-force
const ips = ["10.20.0.15", "10.20.0.22", "10.20.0.31", "192.168.1.50",
             "203.0.113.7", "203.0.113.7", "203.0.113.7", "198.51.100.23"];

const pick = (arr) => arr[Math.floor(Math.random() * arr.length)];
const docs = [];

for (let i = 0; i < 200; i++) {
  const level = pick(levels);
  const action = level === "SECURITY" ? "LOGIN_FAILED" : pick(actions);
  const doc = {
    timestamp: new Date(Date.now() - Math.floor(Math.random() * 30 * 24 * 3600 * 1000)),
    source: pick(sources),
    level: level,
    utilisateur: pick(users),
    action: action,
    ip: pick(ips),
    details: action === "LOGIN_FAILED"
      ? { motif: "mauvais_mot_de_passe" }
      : { parametre: pick(params), ref: "AUTO-" + i }
  };
  docs.push(doc);
}

logsDb.logs.insertMany(docs);

// Index (idempotents) + rétention 1 an (cohérent PSSI)
logsDb.logs.createIndex({ timestamp: -1 });
logsDb.logs.createIndex({ source: 1, level: 1 });
logsDb.logs.createIndex({ utilisateur: 1 });
logsDb.logs.createIndex({ timestamp: 1 }, { expireAfterSeconds: 60 * 60 * 24 * 365 });

print(">> Seed MongoDB : " + logsDb.logs.countDocuments() + " logs dans 'aqualab_logs'");
