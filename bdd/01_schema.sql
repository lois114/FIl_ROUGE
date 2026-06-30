-- =====================================================================
-- AquaLab — Modèle de données du LIMS (PostgreSQL)
-- Axe 4 : Administration BDD - schéma relationnel des entités métier
-- =====================================================================
-- Exécution : psql -U postgres -d aqualab -f 01_schema.sql

CREATE SCHEMA IF NOT EXISTS lims;
SET search_path TO lims;

-- ---------- Utilisateurs internes (techniciens, validateurs, etc.) ----------
CREATE TABLE utilisateur (
    id              SERIAL PRIMARY KEY,
    nom             VARCHAR(80)  NOT NULL,
    prenom          VARCHAR(80)  NOT NULL,
    login           VARCHAR(60)  NOT NULL UNIQUE,
    email           VARCHAR(150) NOT NULL UNIQUE,
    role_metier     VARCHAR(30)  NOT NULL
                    CHECK (role_metier IN ('technicien','validateur','commercial','qualite','admin')),
    actif           BOOLEAN      NOT NULL DEFAULT TRUE,
    cree_le         TIMESTAMPTZ  NOT NULL DEFAULT now()
);

-- ---------- Clients ----------
CREATE TABLE client (
    id              SERIAL PRIMARY KEY,
    raison_sociale  VARCHAR(150) NOT NULL,
    type_client     VARCHAR(30)  NOT NULL
                    CHECK (type_client IN ('collectivite','industriel','distribution','restauration','particulier')),
    email           VARCHAR(150),
    telephone       VARCHAR(30),
    adresse         VARCHAR(255),
    cree_le         TIMESTAMPTZ  NOT NULL DEFAULT now()
);

-- ---------- Sites / points de prélèvement ----------
CREATE TABLE site_prelevement (
    id              SERIAL PRIMARY KEY,
    client_id       INTEGER NOT NULL REFERENCES client(id) ON DELETE CASCADE,
    libelle         VARCHAR(150) NOT NULL,
    type_matrice    VARCHAR(30)  NOT NULL
                    CHECK (type_matrice IN ('eau_potable','eau_usee','aliment','surface','autre')),
    localisation    VARCHAR(255)
);

-- ---------- Échantillons ----------
CREATE TABLE echantillon (
    id                  SERIAL PRIMARY KEY,
    reference           VARCHAR(40) NOT NULL UNIQUE,            -- code-barres / référence labo
    client_id           INTEGER NOT NULL REFERENCES client(id),
    site_id             INTEGER REFERENCES site_prelevement(id),
    preleveur_id        INTEGER REFERENCES utilisateur(id),
    date_prelevement    TIMESTAMPTZ NOT NULL,
    date_reception      TIMESTAMPTZ NOT NULL DEFAULT now(),
    nature              VARCHAR(30) NOT NULL
                        CHECK (nature IN ('eau','aliment','surface')),
    etat                VARCHAR(20) NOT NULL DEFAULT 'recu'
                        CHECK (etat IN ('recu','en_cours','termine','rejete'))
);

-- ---------- Catalogue des paramètres analysés ----------
CREATE TABLE parametre (
    id                  SERIAL PRIMARY KEY,
    code                VARCHAR(20) NOT NULL UNIQUE,            -- ex: ECOLI, PH, NO3
    libelle             VARCHAR(120) NOT NULL,
    methode             VARCHAR(120),                           -- méthode normalisée (ISO ...)
    unite               VARCHAR(20),
    seuil_reglementaire NUMERIC(12,4)                           -- limite de conformité
);

-- ---------- Analyses (un paramètre mesuré sur un échantillon) ----------
-- NB : la table s'appelle "analyse_param" car ANALYSE/ANALYZE est un mot-clé
--      réservé de PostgreSQL (impossible comme nom de table sans guillemets).
CREATE TABLE analyse_param (
    id              SERIAL PRIMARY KEY,
    echantillon_id  INTEGER NOT NULL REFERENCES echantillon(id) ON DELETE CASCADE,
    parametre_id    INTEGER NOT NULL REFERENCES parametre(id),
    technicien_id   INTEGER REFERENCES utilisateur(id),
    date_analyse    TIMESTAMPTZ,
    statut          VARCHAR(20) NOT NULL DEFAULT 'planifiee'
                    CHECK (statut IN ('planifiee','en_cours','saisie','validee')),
    UNIQUE (echantillon_id, parametre_id)
);

-- ---------- Résultats (avec double validation = séparation des tâches) ----------
CREATE TABLE resultat (
    id              SERIAL PRIMARY KEY,
    analyse_id      INTEGER NOT NULL UNIQUE REFERENCES analyse_param(id) ON DELETE CASCADE,
    valeur          NUMERIC(12,4),
    conforme        BOOLEAN,                                    -- valeur <= seuil réglementaire
    saisi_par       INTEGER REFERENCES utilisateur(id),         -- technicien
    saisi_le        TIMESTAMPTZ,
    valide_par      INTEGER REFERENCES utilisateur(id),         -- validateur (DOIT être différent du technicien)
    valide_le       TIMESTAMPTZ,
    CONSTRAINT chk_validation_separee
        CHECK (valide_par IS NULL OR valide_par <> saisi_par)   -- séparation des tâches au niveau BDD
);

-- ---------- Rapports d'analyse remis au client ----------
CREATE TABLE rapport (
    id              SERIAL PRIMARY KEY,
    echantillon_id  INTEGER NOT NULL REFERENCES echantillon(id),
    date_emission   TIMESTAMPTZ NOT NULL DEFAULT now(),
    chemin_pdf      VARCHAR(255),
    emis_par        INTEGER REFERENCES utilisateur(id)
);

-- ---------- Journal d'audit applicatif (traçabilité - exigence COFRAC) ----------
CREATE TABLE journal_audit (
    id          BIGSERIAL PRIMARY KEY,
    horodatage  TIMESTAMPTZ NOT NULL DEFAULT now(),
    utilisateur VARCHAR(60),
    action      VARCHAR(40)  NOT NULL,        -- INSERT / UPDATE / VALIDATION ...
    table_cible VARCHAR(60),
    cle_cible   VARCHAR(60),
    details     TEXT
);

-- ---------- Index utiles ----------
CREATE INDEX idx_echantillon_client     ON echantillon(client_id);
CREATE INDEX idx_analyse_echantillon    ON analyse_param(echantillon_id);
CREATE INDEX idx_resultat_analyse       ON resultat(analyse_id);
CREATE INDEX idx_audit_horodatage       ON journal_audit(horodatage);
