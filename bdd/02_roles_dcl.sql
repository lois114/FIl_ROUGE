-- =====================================================================
-- AquaLab — Contrôle d'accès (DCL) : rôles et privilèges PostgreSQL
-- Axe 4 : stratégie de contrôle d'accès — moindre privilège + séparation des tâches
-- =====================================================================
-- Principe : chaque profil métier reçoit le strict nécessaire (GRANT),
-- rien de plus. Les comptes nominatifs héritent d'un rôle de groupe.

SET search_path TO lims;

-- ---------- 1) Rôles de GROUPE (NOLOGIN) = profils de droits ----------
CREATE ROLE r_lecture        NOLOGIN;   -- consultation seule
CREATE ROLE r_technicien     NOLOGIN;   -- saisie des analyses et résultats
CREATE ROLE r_validateur     NOLOGIN;   -- validation des résultats
CREATE ROLE r_commercial     NOLOGIN;   -- clients et rapports
CREATE ROLE r_appli          NOLOGIN;   -- compte de service de l'application (least privilege)
CREATE ROLE r_admin_bdd      NOLOGIN;   -- administration

-- ---------- 2) Privilèges par rôle ----------
-- Lecture : SELECT sur les tables de référence et de production
GRANT USAGE ON SCHEMA lims TO r_lecture;
GRANT SELECT ON ALL TABLES IN SCHEMA lims TO r_lecture;

-- Technicien : lecture + saisie des analyses/résultats (pas de validation)
GRANT r_lecture TO r_technicien;
GRANT INSERT, UPDATE ON analyse, resultat TO r_technicien;
GRANT INSERT, UPDATE ON echantillon       TO r_technicien;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA lims TO r_technicien;
-- Le technicien NE PEUT PAS écrire la validation (colonnes valide_par/valide_le)
-- => géré par la contrainte chk_validation_separee + la logique applicative.

-- Validateur : lecture + mise à jour de la validation des résultats
GRANT r_lecture TO r_validateur;
GRANT UPDATE ON resultat TO r_validateur;

-- Commercial : lecture clients/rapports + création de rapports
GRANT r_lecture TO r_commercial;
GRANT INSERT ON rapport TO r_commercial;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA lims TO r_commercial;

-- Application (compte de service) : juste ce qu'il faut pour fonctionner
GRANT r_lecture TO r_appli;
GRANT INSERT, UPDATE ON echantillon, analyse, resultat, rapport TO r_appli;
GRANT INSERT ON journal_audit TO r_appli;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA lims TO r_appli;

-- Admin BDD : tous les droits sur le schéma
GRANT ALL PRIVILEGES ON ALL TABLES    IN SCHEMA lims TO r_admin_bdd;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA lims TO r_admin_bdd;

-- ---------- 3) Révocations explicites (principe de moindre privilège) ----------
REVOKE INSERT, UPDATE, DELETE ON parametre FROM r_technicien, r_commercial; -- catalogue figé
REVOKE DELETE ON ALL TABLES IN SCHEMA lims FROM r_lecture, r_technicien, r_commercial;

-- Empêcher l'accès par défaut du rôle PUBLIC
REVOKE ALL ON SCHEMA lims FROM PUBLIC;
REVOKE ALL ON ALL TABLES IN SCHEMA lims FROM PUBLIC;

-- ---------- 4) Comptes nominatifs (LOGIN) rattachés aux rôles ----------
-- (mots de passe à remplacer ; en prod : authentification forte / SSO)
CREATE ROLE marie_tech   LOGIN PASSWORD 'ChangeMe_2026' IN ROLE r_technicien;
CREATE ROLE paul_valid   LOGIN PASSWORD 'ChangeMe_2026' IN ROLE r_validateur;
CREATE ROLE lea_commerce LOGIN PASSWORD 'ChangeMe_2026' IN ROLE r_commercial;
CREATE ROLE svc_app      LOGIN PASSWORD 'ChangeMe_2026' IN ROLE r_appli;       -- compte applicatif
CREATE ROLE dba_admin    LOGIN PASSWORD 'ChangeMe_2026' IN ROLE r_admin_bdd;

-- ---------- 5) Droits par défaut pour les futurs objets ----------
ALTER DEFAULT PRIVILEGES IN SCHEMA lims
    GRANT SELECT ON TABLES TO r_lecture;

-- Vérification : \du  puis  \dp lims.*
