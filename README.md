# 🐳 docker-port-list

**Un utilitaire bash stylé pour visualiser les ports exposés par vos conteneurs Docker, regroupés par projet.**

Ce script vous permet d’obtenir une vision claire et rapide de vos conteneurs Docker actifs, leurs IP internes, les ports exposés, et ce projet par projet (via `docker-compose`), avec un affichage coloré façon "terminal de film de hacker" 💚.

## ✨ Fonctionnalités

- Affichage **groupé par stack (projet docker-compose)**.
- Affichage des **conteneurs "hors stack"** séparément.
- Détection des **ports exposés**, **IP internes**, et mode réseau.
- **Mode résumé** pour lister rapidement les ports ouverts par projet.
- Compatible avec tous les systèmes où Bash + Docker sont installés.

---

## 📦 Installation

Clone ce repo, rends le script exécutable et ajoute-le à ton `$PATH` si tu veux l’utiliser partout :

```bash
git clone https://github.com/ton-utilisateur/docker-port-list.git
cd docker-port-list
chmod +x docker-port-list
```

## Utilisation
```shell
./docker-port-list          # Affiche la liste complète des conteneurs actifs, groupés par projet
./docker-port-list --short  # Affiche un résumé compact des ports exposés par projet
```

## Exemple
### Sortie complète
```shell

╔═══════════════════════════════════════════════════╗
║             SCAN DES CONTENEURS DOCKER           ║
╚═══════════════════════════════════════════════════╝
✔ Conteneurs détectés.

╔═ Project: nextcloud ═════════════════════════════════════════════════╗
║ CONTAINER                  │ IP INTERNE     │ PORTS EXPOSES                 ║
╟──────────────────────────────────────────────────────────────────────╢
║ nextcloud-app              │ 172.20.0.3     │ 80/tcp -> 8080                ║
╚══════════════════════════════════════════════════════════════════════╝

╔═ Autres conteneurs (non compose) ═════════════════════════════════════╗
║ CONTAINER                  │ IP INTERNE     │ PORTS EXPOSES                 ║
╟──────────────────────────────────────────────────────────────────────╢
║ random-container           │ 172.17.0.2     │ Aucun                        ║
╚══════════════════════════════════════════════════════════════════════╝

```

### Sortie résumé

```shell
📦 Projet : nextcloud
  → 8080

📦 Projet : odoo
  → 8069
```