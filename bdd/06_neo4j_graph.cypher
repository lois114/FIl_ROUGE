// =====================================================================
// AquaLab — Base GRAPHE (Neo4j) : tracabilite / chaine de validation
// Axe 4 : 3e paradigme de base (apres relationnel PostgreSQL et document MongoDB).
// Modelise la chaine de custody d'un echantillon et la SEPARATION DES TACHES
// (le technicien qui saisit n'est jamais le validateur qui valide).
//
// Chargement : cypher-shell -u neo4j -p ChangeMeNeo4j_2026 -f 06_neo4j_graph.cypher
//   (ou : docker exec -i aqualab-neo4j cypher-shell -u neo4j -p ChangeMeNeo4j_2026 < 06_neo4j_graph.cypher)
// =====================================================================

// ---------- Nettoyage (rejouable sans doublons) ----------
MATCH (n) DETACH DELETE n;

// ---------- Contraintes d'unicite ----------
CREATE CONSTRAINT util_login  IF NOT EXISTS FOR (u:Utilisateur) REQUIRE u.login IS UNIQUE;
CREATE CONSTRAINT client_id   IF NOT EXISTS FOR (c:Client)      REQUIRE c.id IS UNIQUE;
CREATE CONSTRAINT site_id     IF NOT EXISTS FOR (s:Site)        REQUIRE s.id IS UNIQUE;
CREATE CONSTRAINT ech_id      IF NOT EXISTS FOR (e:Echantillon) REQUIRE e.id IS UNIQUE;
CREATE CONSTRAINT ana_id      IF NOT EXISTS FOR (a:Analyse)     REQUIRE a.id IS UNIQUE;
CREATE CONSTRAINT res_id      IF NOT EXISTS FOR (r:Resultat)    REQUIRE r.id IS UNIQUE;
CREATE CONSTRAINT param_code  IF NOT EXISTS FOR (p:Parametre)   REQUIRE p.code IS UNIQUE;

// ---------- Utilisateurs (profils metier) ----------
UNWIND [
  {login:'marie_tech', nom:'Marie Durand',  role:'Technicien'},
  {login:'jules_tech', nom:'Jules Nguyen',  role:'Technicien'},
  {login:'sofia_tech', nom:'Sofia Bianchi', role:'Technicien'},
  {login:'paul_valid', nom:'Paul Martin',   role:'Validateur'},
  {login:'lea_valid',  nom:'Lea Petit',     role:'Validateur'},
  {login:'hugo_com',   nom:'Hugo Moreau',   role:'Commercial'}
] AS u
CREATE (:Utilisateur {login:u.login, nom:u.nom, role:u.role});

// ---------- Clients ----------
UNWIND [
  {id:1, nom:'Mairie de Toulouse',               type:'collectivite'},
  {id:2, nom:'Syndicat des Eaux de la Garonne',  type:'collectivite'},
  {id:3, nom:'Laiterie du Sud-Ouest',            type:'industriel'},
  {id:4, nom:'Groupe Resto Convivio',            type:'restauration'}
] AS c
CREATE (:Client {id:c.id, raison_sociale:c.nom, type:c.type});

// ---------- Parametres analyses ----------
UNWIND [
  {code:'ECOLI', libelle:'Escherichia coli'},
  {code:'PH',    libelle:'Potentiel hydrogene'},
  {code:'NO3',   libelle:'Nitrates'},
  {code:'PB',    libelle:'Plomb'},
  {code:'TURB',  libelle:'Turbidite'}
] AS p
CREATE (:Parametre {code:p.code, libelle:p.libelle});

// ---------- Sites (2 par client) : (Client)-[:POSSEDE]->(Site) ----------
MATCH (c:Client)
UNWIND [1,2] AS k
CREATE (s:Site {
  id: (c.id-1)*2 + k,
  libelle: 'Site ' + c.raison_sociale + ' #' + toString(k),
  type_matrice: ['eau_potable','eau_usee','surface'][ ((c.id-1)*2 + k) % 3 ]
})
CREATE (c)-[:POSSEDE]->(s);

// ---------- Echantillons : (Site)-[:PRELEVE]->(Echantillon), preleve par un technicien ----------
UNWIND range(1,12) AS eid
MATCH (s:Site {id: ((eid-1) % 8) + 1})
MATCH (t:Utilisateur {login: ['marie_tech','jules_tech','sofia_tech'][eid % 3]})
CREATE (e:Echantillon {
  id: eid,
  reference: 'ECH-' + toString(1000 + eid),
  nature: ['eau','aliment','surface'][eid % 3],
  etat:   ['recu','en_cours','termine','termine'][eid % 4]
})
CREATE (s)-[:PRELEVE]->(e)
CREATE (t)-[:A_PRELEVE]->(e);

// ---------- Analyses : (Echantillon)-[:CONTIENT]->(Analyse)-[:PORTE_SUR]->(Parametre) ----------
MATCH (e:Echantillon)
UNWIND [0,1,2] AS k
MATCH (p:Parametre {code: ['ECOLI','PH','NO3','PB','TURB'][ (e.id + k) % 5 ]})
CREATE (a:Analyse {
  id: e.id*10 + k,
  statut: CASE e.etat WHEN 'recu' THEN 'planifiee' WHEN 'en_cours' THEN 'saisie' ELSE 'validee' END
})
CREATE (e)-[:CONTIENT]->(a)
CREATE (a)-[:PORTE_SUR]->(p);

// ---------- Resultats + SEPARATION DES TACHES ----------
// (Analyse)-[:PRODUIT]->(Resultat) ; (Technicien)-[:A_SAISI]->(Resultat) ;
// (Validateur)-[:A_VALIDE]->(Resultat)  -- toujours une personne differente.
MATCH (e:Echantillon)-[:CONTIENT]->(a:Analyse)
WHERE a.statut IN ['saisie','validee']
MATCH (tech:Utilisateur  {login: ['marie_tech','jules_tech','sofia_tech'][a.id % 3]})
MATCH (valid:Utilisateur {login: ['paul_valid','lea_valid'][a.id % 2]})
WITH a, tech, valid, round(rand()*100)/10.0 AS val
CREATE (r:Resultat {id:a.id, valeur:val, conforme: val < 7.0})
CREATE (a)-[:PRODUIT]->(r)
CREATE (tech)-[:A_SAISI]->(r)
FOREACH (_ IN CASE WHEN a.statut = 'validee' THEN [1] ELSE [] END |
  CREATE (valid)-[:A_VALIDE]->(r));

// ---------- Recapitulatif ----------
MATCH (n) RETURN labels(n)[0] AS type, count(*) AS nombre ORDER BY type;

// =====================================================================
// Exemples de requetes a lancer dans le Neo4j Browser (http://localhost:7474)
// =====================================================================
//
// 1) Voir tout le graphe :
//    MATCH (n) RETURN n LIMIT 300;
//
// 2) Chaine de tracabilite complete d'un echantillon :
//    MATCH path = (c:Client)-[:POSSEDE]->(:Site)-[:PRELEVE]->(e:Echantillon)
//                 -[:CONTIENT]->(:Analyse)-[:PRODUIT]->(:Resultat)
//    WHERE e.reference = 'ECH-1003'
//    RETURN path;
//
// 3) Controle SEPARATION DES TACHES : un saisisseur a-t-il valide son propre resultat ?
//    (doit renvoyer 0 ligne)
//    MATCH (u:Utilisateur)-[:A_SAISI]->(r:Resultat)<-[:A_VALIDE]-(u)
//    RETURN u.login, r.id;
//
// 4) Qui valide le travail de qui (reseau de validation) :
//    MATCH (t:Utilisateur)-[:A_SAISI]->(r)<-[:A_VALIDE]-(v:Utilisateur)
//    RETURN t.login AS technicien, v.login AS validateur, count(r) AS nb
//    ORDER BY nb DESC;
//
// 5) Resultats non conformes et leur echantillon/client :
//    MATCH (c:Client)-[:POSSEDE]->(:Site)-[:PRELEVE]->(e:Echantillon)
//          -[:CONTIENT]->(a:Analyse)-[:PRODUIT]->(r:Resultat {conforme:false})
//    RETURN c.raison_sociale, e.reference, r.valeur;
