// =====================================================================
// AquaLab — Base NoSQL MongoDB pour la gestion des logs (Axe 4)
// Besoin spécifique : stockage et interrogation des journaux applicatifs
// et de sécurité (volumineux, semi-structurés) — complète le SIEM.
// Exécution : mongosh < 04_mongodb_logs.js
// =====================================================================

// 1) Base et collection dédiées
const db = db.getSiblingDB("aqualab_logs");

// 2) Schéma souple (document JSON) — exemple d'événement
db.logs.insertMany([
  {
    timestamp: new Date(),
    source: "lims",            // lims | portail | siem | systeme
    level: "INFO",             // INFO | WARN | ERROR | SECURITY
    utilisateur: "marie_tech",
    action: "SAISIE_RESULTAT",
    ip: "10.20.0.15",
    details: { analyse_id: 1042, parametre: "ECOLI" }
  },
  {
    timestamp: new Date(),
    source: "portail",
    level: "SECURITY",
    utilisateur: "client_42",
    action: "LOGIN_FAILED",
    ip: "203.0.113.7",
    details: { tentative: 5, motif: "mauvais_mot_de_passe" }
  }
]);

// 3) Index pour des requêtes rapides
db.logs.createIndex({ timestamp: -1 });
db.logs.createIndex({ source: 1, level: 1 });
db.logs.createIndex({ utilisateur: 1 });

// 4) Rétention automatique (TTL) : suppression après 365 jours
//    (cohérent avec la règle PSSI "journalisation conservée 1 an")
db.logs.createIndex({ timestamp: 1 }, { expireAfterSeconds: 60 * 60 * 24 * 365 });

// 5) Exemples de requêtes d'exploitation -------------------------------
// a) Tous les événements de sécurité des dernières 24h
db.logs.find({
  level: "SECURITY",
  timestamp: { $gte: new Date(Date.now() - 24 * 60 * 60 * 1000) }
}).sort({ timestamp: -1 });

// b) Comptage des échecs de connexion par IP (détection brute-force)
db.logs.aggregate([
  { $match: { action: "LOGIN_FAILED" } },
  { $group: { _id: "$ip", tentatives: { $sum: 1 } } },
  { $match: { tentatives: { $gte: 5 } } },
  { $sort: { tentatives: -1 } }
]);

// c) Activité d'un utilisateur donné
db.logs.find({ utilisateur: "marie_tech" }).sort({ timestamp: -1 }).limit(50);

print(">> Base de logs MongoDB initialisée (collection 'logs', index + TTL 1 an).");
