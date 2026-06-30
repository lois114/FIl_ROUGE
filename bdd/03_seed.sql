-- =====================================================================
-- AquaLab — Jeu de données fictives (seed) pour démonstration
-- Axe 4 : alimente le LIMS avec des données réalistes mais inventées.
-- Respecte toutes les contraintes (CHECK, clés étrangères, séparation
-- des tâches : un résultat ne peut pas être validé par son saisisseur).
-- Exécution : psql -U postgres -d aqualab -f 03_seed.sql
--             (rejoué automatiquement au démarrage du conteneur Postgres)
-- =====================================================================

SET search_path TO lims;

-- Remise à zéro idempotente (permet de rejouer le seed sans doublons)
TRUNCATE rapport, resultat, analyse_param, echantillon,
         site_prelevement, parametre, client, utilisateur, journal_audit
         RESTART IDENTITY CASCADE;

-- ---------- Utilisateurs internes (profils métier) ----------
INSERT INTO utilisateur (nom, prenom, login, email, role_metier) VALUES
 ('Durand','Marie','marie_tech','marie.durand@aqualab.fr','technicien'),
 ('Nguyen','Jules','jules_tech','jules.nguyen@aqualab.fr','technicien'),
 ('Bianchi','Sofia','sofia_tech','sofia.bianchi@aqualab.fr','technicien'),
 ('Martin','Paul','paul_valid','paul.martin@aqualab.fr','validateur'),
 ('Petit','Léa','lea_valid','lea.petit@aqualab.fr','validateur'),
 ('Moreau','Hugo','hugo_com','hugo.moreau@aqualab.fr','commercial'),
 ('Faure','Nadia','nadia_qual','nadia.faure@aqualab.fr','qualite'),
 ('Roy','Éric','eric_admin','eric.roy@aqualab.fr','admin');

-- ---------- Clients ----------
INSERT INTO client (raison_sociale, type_client, email, telephone, adresse) VALUES
 ('Mairie de Toulouse','collectivite','eau@toulouse.fr','0561000001','Place du Capitole, 31000 Toulouse'),
 ('Syndicat des Eaux de la Garonne','collectivite','contact@sieg.fr','0562000002','Avenue de Blagnac, 31700 Blagnac'),
 ('Laiterie du Sud-Ouest','industriel','qualite@laiterie-so.fr','0563000003','ZI Albasud, 82000 Montauban'),
 ('Soufflet Agro Occitanie','industriel','labo@soufflet-oc.fr','0564000004','Route de Toulouse, 32000 Auch'),
 ('SuperFrais Distribution','distribution','hygiene@superfrais.fr','0565000005','ZAC En Jacca, 31770 Colomiers'),
 ('Groupe Resto Convivio','restauration','hse@convivio.fr','0566000006','Rue de la Cuisine, 31400 Toulouse');

-- ---------- Sites de prélèvement (2 par client) ----------
INSERT INTO site_prelevement (client_id, libelle, type_matrice, localisation)
SELECT c.id,
       'Site ' || c.raison_sociale || ' #' || g,
       (ARRAY['eau_potable','eau_usee','aliment','surface','autre'])[1 + ((c.id + g) % 5)],
       'Zone ' || chr(65 + (g % 4))
FROM client c
CROSS JOIN generate_series(1, 2) AS g;

-- ---------- Catalogue des paramètres analysés ----------
INSERT INTO parametre (code, libelle, methode, unite, seuil_reglementaire) VALUES
 ('ECOLI','Escherichia coli','NF EN ISO 9308-1','UFC/100mL',0),
 ('ENTERO','Entérocoques intestinaux','NF EN ISO 7899-2','UFC/100mL',0),
 ('COLIF','Coliformes totaux','NF EN ISO 9308-1','UFC/100mL',0),
 ('PH','Potentiel hydrogène','NF EN ISO 10523','pH',9.0),
 ('NO3','Nitrates','NF EN ISO 10304-1','mg/L',50.0),
 ('NO2','Nitrites','NF EN ISO 10304-1','mg/L',0.5),
 ('PB','Plomb','NF EN ISO 17294-2','µg/L',10.0),
 ('TURB','Turbidité','NF EN ISO 7027','NFU',2.0),
 ('CL','Chlore libre','NF EN ISO 7393-2','mg/L',0.3),
 ('TEMP','Température','NF EN 25667','°C',25.0);

-- ---------- Échantillons (30, répartis sur ~30 jours) ----------
INSERT INTO echantillon (reference, client_id, site_id, preleveur_id,
                         date_prelevement, date_reception, nature, etat)
SELECT
  'ECH-2026-' || lpad(g::text, 4, '0'),
  cl.id,
  st.id,
  tech.id,
  now() - (g || ' days')::interval,
  now() - (g || ' days')::interval + interval '4 hours',
  (ARRAY['eau','aliment','surface'])[1 + (g % 3)],
  (ARRAY['recu','en_cours','termine','termine','termine'])[1 + (g % 5)]
FROM generate_series(1, 30) AS g
JOIN LATERAL (SELECT id FROM client ORDER BY id OFFSET (g % 6) LIMIT 1) cl ON true
JOIN LATERAL (SELECT id FROM site_prelevement WHERE client_id = cl.id
              ORDER BY id OFFSET (g % 2) LIMIT 1) st ON true
JOIN LATERAL (SELECT id FROM utilisateur WHERE role_metier = 'technicien'
              ORDER BY id OFFSET (g % 3) LIMIT 1) tech ON true;

-- ---------- Analyses : 3 paramètres distincts par échantillon ----------
INSERT INTO analyse_param (echantillon_id, parametre_id, technicien_id, date_analyse, statut)
SELECT
  e.id,
  ((e.id + k) % 10) + 1,
  t.id,
  CASE WHEN e.etat = 'recu' THEN NULL ELSE e.date_reception + interval '1 day' END,
  CASE e.etat
    WHEN 'recu'     THEN 'planifiee'
    WHEN 'en_cours' THEN 'saisie'
    ELSE 'validee'
  END
FROM echantillon e
CROSS JOIN generate_series(0, 2) AS k
JOIN LATERAL (SELECT id FROM utilisateur WHERE role_metier = 'technicien'
              ORDER BY id OFFSET ((e.id + k) % 3) LIMIT 1) t ON true;

-- ---------- Résultats : seulement pour analyses saisies ou validées ----------
-- Valeurs générées dans des plages plausibles par paramètre.
-- Séparation des tâches garantie : saisi_par = technicien, valide_par = validateur
-- (deux personnes par construction => respecte chk_validation_separee).
INSERT INTO resultat (analyse_id, valeur, conforme, saisi_par, saisi_le, valide_par, valide_le)
SELECT
  a.id,
  v.valeur,
  (v.valeur <= p.seuil_reglementaire),
  a.technicien_id,
  a.date_analyse,
  CASE WHEN a.statut = 'validee' THEN val.id END,
  CASE WHEN a.statut = 'validee' THEN a.date_analyse + interval '1 day' END
FROM analyse_param a
JOIN parametre p ON p.id = a.parametre_id
JOIN LATERAL (
  SELECT round((
    CASE p.code
      WHEN 'PH'   THEN 6.5 + random() * 3.0          -- 6.5 .. 9.5
      WHEN 'TEMP' THEN 8.0 + random() * 20.0         -- 8 .. 28
      WHEN 'NO3'  THEN random() * 70.0               -- 0 .. 70
      WHEN 'NO2'  THEN random() * 0.9                -- 0 .. 0.9
      WHEN 'PB'   THEN random() * 18.0               -- 0 .. 18
      WHEN 'TURB' THEN random() * 3.5                -- 0 .. 3.5
      WHEN 'CL'   THEN 0.05 + random() * 0.5         -- 0.05 .. 0.55
      ELSE -- microbiologie (seuil = 0) : majorité conforme (0), sinon contamination
        CASE WHEN random() < 0.85 THEN 0 ELSE round(random() * 40) END
    END)::numeric, 2) AS valeur
) v ON true
JOIN LATERAL (SELECT id FROM utilisateur WHERE role_metier = 'validateur'
              ORDER BY id OFFSET (a.id % 2) LIMIT 1) val ON true
WHERE a.statut IN ('saisie', 'validee');

-- ---------- Rapports émis pour les échantillons terminés ----------
INSERT INTO rapport (echantillon_id, date_emission, chemin_pdf, emis_par)
SELECT e.id,
       e.date_reception + interval '5 days',
       '/rapports/' || e.reference || '.pdf',
       (SELECT id FROM utilisateur WHERE role_metier = 'commercial' LIMIT 1)
FROM echantillon e
WHERE e.etat = 'termine';

-- ---------- Journal d'audit applicatif (traçabilité) ----------
INSERT INTO journal_audit (horodatage, utilisateur, action, table_cible, cle_cible, details)
SELECT now() - (g || ' hours')::interval,
       (ARRAY['marie_tech','jules_tech','paul_valid','hugo_com','svc_app'])[1 + (g % 5)],
       (ARRAY['INSERT','UPDATE','VALIDATION','LOGIN','EXPORT'])[1 + (g % 5)],
       (ARRAY['resultat','analyse_param','echantillon','rapport','utilisateur'])[1 + (g % 5)],
       g::text,
       'Événement de démonstration #' || g
FROM generate_series(1, 50) AS g;

-- ---------- Récapitulatif ----------
DO $$
DECLARE r RECORD;
BEGIN
  RAISE NOTICE 'Seed AquaLab terminé :';
  FOR r IN
    SELECT 'utilisateur' t, count(*) n FROM utilisateur
    UNION ALL SELECT 'client', count(*) FROM client
    UNION ALL SELECT 'site_prelevement', count(*) FROM site_prelevement
    UNION ALL SELECT 'parametre', count(*) FROM parametre
    UNION ALL SELECT 'echantillon', count(*) FROM echantillon
    UNION ALL SELECT 'analyse_param', count(*) FROM analyse_param
    UNION ALL SELECT 'resultat', count(*) FROM resultat
    UNION ALL SELECT 'rapport', count(*) FROM rapport
    UNION ALL SELECT 'journal_audit', count(*) FROM journal_audit
    ORDER BY t
  LOOP
    RAISE NOTICE '  % : % lignes', rpad(r.t, 18), r.n;
  END LOOP;
END $$;
