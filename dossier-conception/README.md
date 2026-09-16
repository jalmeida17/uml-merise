# Dossier de conception — CoWork'In

Module « Du besoin à la base » (BC.4 · C4.1) — analyse et conception UML & MERISE. Fil rouge : CoWork'In, réseau de trois espaces de coworking.

## Le problème, en trois phrases

CoWork'In gère trois sites avec un tableur partagé et des mails, et double-réserve une salle par semaine. Le client veut un site où les coworkers créent leur compte, voient les disponibilités en temps réel, réservent postes et salles à l'heure ou à la journée, et où la facturation mensuelle (individuelle ou globale par société) sort toute seule. L'accueil doit pouvoir fermer une salle et savoir qui est présent ; le gérant veut un taux d'occupation ; les ateliers du jeudi soir doivent avoir des inscriptions à jauge.

## Où commencer la lecture

1. [`01-besoins/expression-besoin.md`](01-besoins/expression-besoin.md) — le verbatim client, les trois lectures, le périmètre et le hors-périmètre.
2. [`01-besoins/acteurs.md`](01-besoins/acteurs.md) — acteurs, parties prenantes, et les **sept hypothèses H1–H7** qui remplacent les réponses du client en attendant.
3. Puis suivre l'ordre des dossiers : chaque étape consomme la précédente.

## Arborescence

```
dossier-conception/
├── README.md                          ← vous êtes ici
├── 01-besoins/
│   ├── expression-besoin.md           verbatim, objectifs, périmètre, trois lectures
│   ├── acteurs.md                     8 acteurs, parties prenantes, questions Q1–Q7 / hypothèses H1–H7
│   └── cas-usage/
│       ├── UC-01_reserver_poste.md
│       ├── UC-02_reserver_salle.md
│       ├── UC-03_inscrire_atelier.md
│       └── UC-04_annuler_reservation.md
├── 02-uml/
│   ├── cas-utilisation.puml / .md     DCU (15 UC, 4 relations, 2 généralisations) + matrice acteur × UC avec portées
│   ├── classes-metier.puml / .md      14 classes, glossaire, justification des choix, opérations issues des séquences
│   ├── sequence-systeme.puml / .md    UC-04, boîte noire → opérations système (contrat d'API)
│   ├── sequence-detaillee.puml / .md  UC-04, boîte blanche → responsabilités, transaction, compensation
│   ├── composants.puml / .md          3 couches, 7 composants métier + fiche de synthèse applicative (8 sections)
│   └── export/*.svg                   rendus PlantUML commités avec leurs sources (régénérables, voir ci-dessous)
├── 03-merise/
│   ├── dictionnaire-donnees.md        toutes les propriétés, types métier et SQL, données personnelles
│   ├── mcd.md / mcd.mcd               14 entités, 19 relations, source Mocodo, 4 cas délicats, 9 vérifications
│   ├── mld.md                         18 tables dérivées règle par règle, erDiagram, normalisation tableur → 3FN
│   └── mpd.md                         types, contraintes nommées, ON DELETE justifiés, index, vues
├── 04-sql/
│   ├── 000_reset_dev.sql              DÉVELOPPEMENT UNIQUEMENT : remise à zéro
│   ├── 001_schema.sql                 extensions, tables, CHECK, index
│   ├── 002_contraintes.sql            exclusions, fonctions, triggers, vues
│   └── 010_jeu_de_test.sql            5 familles de données, 23 tests dont 21 opérations interdites, 10 vérifications
└── 05-tracabilite/
    └── matrice.md                     besoin → RG → UC → classe → table → contrainte → test, et retour
```

## Régénérer les diagrammes

Les sources sont du texte (PlantUML, Mocodo, Mermaid) : diffables, relisibles en pull request. Les fichiers `.md` contiennent une version Mermaid rendue nativement par GitHub.

```bash
# PlantUML — avec Java installé
plantuml -tsvg 02-uml/*.puml

# PlantUML — sans Java, via Docker
docker run --rm -v "$PWD/02-uml:/data" plantuml/plantuml -tsvg /data/*.puml

# Mocodo — MCD : coller le contenu de 03-merise/mcd.mcd sur https://www.mocodo.net
# ou, avec Python :  pip install mocodo && mocodo --input 03-merise/mcd.mcd --output_dir 03-merise
```

Sans installation : coller le contenu d'un `.puml` sur <https://www.plantuml.com/plantuml>.

## Créer la base à partir de zéro

Cible PostgreSQL 16. La chaîne s'exécute **dans l'ordre**, sur une base vide, et doit passer sans erreur du premier coup : c'est le test qui fait foi.

```bash
# 1. Un PostgreSQL jetable
docker run -d --name coworkin-pg -e POSTGRES_PASSWORD=coworkin -e POSTGRES_DB=coworkin -p 5432:5432 postgres:16

# 2. Copier les scripts dans le conteneur (évite les problèmes d'encodage du terminal)
docker cp 04-sql coworkin-pg:/sql

# 3. La chaîne — ON_ERROR_STOP arrête tout à la première erreur
docker exec coworkin-pg psql -U postgres -d coworkin -v ON_ERROR_STOP=1 -f /sql/001_schema.sql
docker exec coworkin-pg psql -U postgres -d coworkin -v ON_ERROR_STOP=1 -f /sql/002_contraintes.sql
docker exec coworkin-pg psql -U postgres -d coworkin -v ON_ERROR_STOP=1 -f /sql/010_jeu_de_test.sql
```

Avec un PostgreSQL local : `createdb coworkin` puis les trois `psql -d coworkin -v ON_ERROR_STOP=1 -f 04-sql/…` dans le même ordre.

Ce que vous devez voir à la fin du troisième script : une série de lignes `NOTICE: T-xx OK — rejeté par …` (chaque insertion interdite a bien été refusée par la contrainte attendue), puis les résultats des vérifications V-01 à V-09. Si une insertion interdite passe, le script **s'arrête en erreur** : un test qui réussit alors qu'il devrait échouer ne prouve rien.

Pour rejouer : `docker exec coworkin-pg psql -U postgres -d coworkin -f /sql/000_reset_dev.sql` puis la chaîne. Pour tout supprimer : `docker rm -f coworkin-pg`.

## État du dossier

| Partie | État | Remarque |
|--------|------|----------|
| Besoins, acteurs, fiches UC | Validé en binôme | En attente des réponses client Q1–Q7 |
| DCU, classes, séquences, composants | Validé en binôme | La séquence détaillée est volontairement périssable |
| Dictionnaire, MCD, MLD, MPD | Validé en binôme | 18 tables, écart avec le corrigé du cours justifié table par table |
| Scripts SQL | Exécutés sur PostgreSQL 16 (image `postgres:16`), chaîne complète sans erreur | Voir la section « Créer la base » |
| Traçabilité | Complète dans les deux sens | — |
| Revue croisée | **Auto-revue seulement** | Les remarques du binôme relecteur sont à ajouter dans `05-tracabilite/matrice.md` §4 |

## Décisions structurantes

| Décision | Justification |
|----------|---------------|
| `Reservation` est une classe (puis une entité), pas une classe d'association | Le même coworker réserve la même salle chaque semaine : le couple se répète — [`classes-metier.md` §3.1](02-uml/classes-metier.md) |
| `Espace` abstraite, tranchée en **table unique + discriminant** | Un poste ne devient jamais une salle ; la requête chaude est « tous les espaces du site » — [`mld.md` §3](03-merise/mld.md) |
| `Abonnement` distinct de `Formule`, prix dans `Tarif` historisé | Un coworker change de formule, un prix change en janvier, une facture émise ne bouge plus — [`mcd.md` §4.4](03-merise/mcd.md) |
| La RG-04 (pas de double réservation) est une **contrainte d'exclusion** en base | Deux requêtes simultanées contournent toute vérification applicative ; c'est la plainte n° 1 du client — [`mpd.md` §3](03-merise/mpd.md) |
| `RESTRICT` partout, une seule cascade (`facture → ligne_facture`) | Supprimer un compte n'efface pas l'historique de facturation ; RGPD = anonymisation — [`mpd.md` §4](03-merise/mpd.md) |
| Rien de calculable n'est stocké (`quota_consomme`, `nb_inscrits`, `montant_total`) | Aucune mesure de performance ne le justifie ; fonctions et vues à la place — [`mld.md` §6](03-merise/mld.md) |
| La facturation lit les réservations par une **interface**, jamais par leurs tables | Point de couplage P1 corrigé — [`composants.md` §5](02-uml/composants.md) |
| Rôles, équipements, affectations en tables de jonction | 1FN, et la portée « site » de la matrice des droits doit être implémentable — [`cas-utilisation.md` §3](02-uml/cas-utilisation.md) |

## Questions ouvertes

Consolidées dans [`acteurs.md` §4](01-besoins/acteurs.md). À poser au client, par priorité : **Q2** (politique d'annulation), **Q3** (comment on constate la présence), **Q5** (formule Team : qui paie quoi). Puis Q1 (administration), Q4 (ateliers gratuits ? liste d'attente ?), Q6 (non-abonnés), Q7 (report). Chaque hypothèse H1–H7 est isolée dans le modèle pour être levée sans refonte.

## Où trouver chaque critère de la grille d'évaluation

| Critère | Fichier(s) |
|---------|------------|
| Acteurs et parties prenantes distingués | `01-besoins/acteurs.md` |
| Fiches UC complètes (alternatifs, exceptions, exigences NF) | `01-besoins/cas-usage/` |
| DCU lisible, frontière explicite, relations justifiées | `02-uml/cas-utilisation.puml`, `.md` §2 |
| Diagramme de classes cohérent avec les UC | `02-uml/classes-metier.puml`, `.md` §4 |
| Séquences système et détaillée, fragments corrects | `02-uml/sequence-*.puml` |
| Découpage en couches, couplage analysé | `02-uml/composants.md` §4–5 |
| MCD valide, cas délicats traités | `03-merise/mcd.md` §4–5 |
| MLD règle par règle, 3FN vérifiée | `03-merise/mld.md` §1, §4–5 |
| DDL exécutable, contraintes nommées et actives | `04-sql/`, preuve par les T-xx |
| Traçabilité dans les deux sens | `05-tracabilite/matrice.md` §1–2 |
| Accessibilité et sécurité rattachées aux UC | fiches UC § exigences NF, `matrice.md` §3 |
| Dossier versionné, README, retours de revue | ce fichier, `matrice.md` §4 |
