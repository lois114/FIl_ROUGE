# AquaLab — Checklist de durcissement (Axe 5)

Référentiels : Guide d'hygiène ANSSI, CIS Benchmarks, OWASP. Cocher au fur et à mesure.

## Systèmes Linux (serveurs LIMS, app, BDD)
- [ ] Mises à jour de sécurité automatiques activées (`unattended-upgrades`)
- [ ] SSH : authentification par clé uniquement (`PasswordAuthentication no`), pas de root direct (`PermitRootLogin no`)
- [ ] `fail2ban` installé (anti brute-force SSH)
- [ ] Pare-feu local actif (`ufw`/`nftables`), tout fermé sauf nécessaire
- [ ] Services et paquets inutiles désinstallés
- [ ] Comptes nominatifs, `sudo` journalisé, pas de comptes partagés
- [ ] Journalisation `auditd` + envoi des logs vers le SIEM (Wazuh)
- [ ] Chiffrement des disques / partitions sensibles

## Windows / Active Directory
- [ ] GPO de durcissement (CIS) appliquées
- [ ] SMBv1 désactivé
- [ ] LAPS (mots de passe admin locaux uniques)
- [ ] Politique de mot de passe robuste + MFA sur les comptes à privilèges
- [ ] Modèle d'administration en tiers (tiering), comptes admin séparés
- [ ] EDR déployé sur tous les postes/serveurs

## Réseau
- [ ] Segmentation en VLAN (DMZ / production / OT / gestion / admin)
- [ ] Pare-feu inter-zones avec règles explicites (deny par défaut)
- [ ] **Zone OT (instruments) isolée** du LAN bureautique (pare-feu / diode)
- [ ] Protocoles non chiffrés (Telnet, FTP, HTTP) désactivés
- [ ] Administration via bastion + MFA uniquement

## Application web (portail client)
- [ ] HTTPS forcé, TLS 1.2+ uniquement, redirection HTTP→HTTPS
- [ ] En-têtes de sécurité : HSTS, Content-Security-Policy, X-Frame-Options, X-Content-Type-Options
- [ ] Verrouillage de compte après N échecs + MFA
- [ ] Validation/échappement des entrées (anti-injection SQL, XSS)
- [ ] WAF en frontal
- [ ] Pas de messages d'erreur détaillés en production

## Base de données
- [ ] Moindre privilège (rôles GRANT/REVOKE — cf. axe 4)
- [ ] Aucun compte par défaut / mot de passe par défaut
- [ ] Chiffrement des données sensibles et des sauvegardes
- [ ] Accès BDD restreint au réseau applicatif

## Instruments / OT
- [ ] Inventaire complet des instruments connectés
- [ ] Isolation réseau, accès de télémaintenance via bastion tracé
- [ ] Mises à jour encadrées avec le mainteneur
- [ ] Surveillance des flux (IDS Suricata)
