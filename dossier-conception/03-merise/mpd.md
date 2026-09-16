# Modèle physique de données (MPD) — CoWork'In

> Atelier 4.1. Cible : **PostgreSQL 16**. Chaque colonne est une décision ; chaque contrainte est nommée, parce que c'est ce nom qui apparaîtra dans les journaux et à l'écran. Scripts exécutables : [`../04-sql/`](../04-sql/).

## 1. Cible et conventions

| Sujet | Décision |
|-------|----------|
| SGBD | PostgreSQL 16 (image `postgres:16` pour le test), extension `btree_gist` pour les contraintes d'exclusion |
| Nommage | `snake_case`, singulier ; contraintes préfixées `pk_`, `fk_`, `uq_`, `ck_`, `ex_` ; index `ix_` ; triggers `tg_` ; vues `v_` |
| Identifiants | `BIGINT GENERATED ALWAYS AS IDENTITY` ; `SERIAL` est déprécié ; les identifiants exposés publiquement (URL de facture) seront des UUID côté applicatif, hors modèle |
| Horodatages | `TIMESTAMPTZ` partout : le passage à l'heure d'hiver ne doit pas créer de réservation fantôme |
| Montants | `NUMERIC(10,2)`, jamais `FLOAT` |
| Énumérations | `VARCHAR` + `CHECK` nommé (modifiable par migration simple) plutôt que type `ENUM` |
| Booléens | `BOOLEAN NOT NULL` avec défaut : un booléen `NULL` a trois états |
| E-mail | `VARCHAR(254)` + index unique sur `lower(email)` : `Salma@` et `salma@` sont le même compte (RG-01) |
| Ordre des scripts | `001_schema.sql` (extensions, tables, index) → `002_contraintes.sql` (exclusions, triggers, fonctions, vues) → `010_jeu_de_test.sql`. `000_reset_dev.sql` sert uniquement en développement |

## 2. Types physiques — les arbitrages

| Donnée | Type retenu | Pourquoi pas l'autre |
|--------|-------------|----------------------|
| `espace.code` | `VARCHAR(20)` | La longueur est une règle métier (code affiché sur une plaque) |
| `societe.siret` | `CHAR(14)` + `CHECK (siret ~ '^[0-9]{14}$')` | Longueur fixe et format connus |
| `site.heure_ouverture` | `TIME` | Une heure sans date ; le fuseau est celui du site, tous en France |
| `facture.periode` | `DATE` contraint au 1er du mois | Plus simple qu'un couple (année, mois) ; `CHECK (periode = date_trunc('month', periode))` |
| `reservation.debut` / `fin` | `TIMESTAMPTZ` | Voir ci-dessus |
| `tarif.prix_ht`, `reservation.montant_du`, `ligne_facture.prix_unitaire` | `NUMERIC(10,2)` | Une facture fausse d'un centime est fausse |
| `ligne_facture.quantite` | `NUMERIC(8,2)` | 1,5 h de dépassement |
| `utilisateur.telephone` | `VARCHAR(20)` | Pas d'entier : indicatifs, zéros initiaux |
| `atelier.places_max`, `espace.capacite` | `SMALLINT` | Bornes réalistes, `CHECK > 0` |

## 3. Contraintes — quelle règle, quel mécanisme

La question posée pour chaque règle de gestion : *est-elle vérifiable sur une seule ligne ?* Si oui, `CHECK`. Plusieurs lignes : contrainte d'exclusion ou trigger. Appel externe : applicatif seul.

| Règle | Énoncé court | Mécanisme | Nom de l'objet |
|-------|--------------|-----------|----------------|
| RG-01 | E-mail unique, insensible à la casse | index unique fonctionnel | `uq_utilisateur_email_lower` |
| RG-03 | fin > debut | `CHECK` | `ck_reservation_fin_apres_debut` |
| RG-04 | Pas de chevauchement de réservations **confirmées** sur un espace | **contrainte d'exclusion** (`btree_gist`) sur `(id_espace, tstzrange(debut, fin)) WHERE statut = 'CONFIRMEE'` | `ex_reservation_pas_de_chevauchement` |
| RG-05 | Durée ≥ 1 h, pas de 30 min | `CHECK` sur `fin - debut` | `ck_reservation_duree_minimale`, `ck_reservation_pas_30min` ; la borne « journée d'ouverture » est applicative (dépend du site) |
| RG-07 | Quota 4 h / mois / abonnement | **applicatif** (calcul du montant) + fonction SQL de contrôle | `quota_consomme_h(id_abonnement, periode)` |
| RG-08 | Un seul abonnement actif par utilisateur à la fois | contrainte d'exclusion sur `(id_utilisateur, daterange(date_debut, date_fin))` | `ex_abonnement_un_seul_actif` |
| RG-09 | Expiration à 15 min | **applicatif / planificateur** (dépend du temps) ; `cree_le` fournit la donnée | — |
| RG-10 | Remboursement ≤ montant dû | trigger (compare à la réservation) | `tg_remboursement_plafond` |
| RG-11 | Capacité ssi salle ; type de poste ssi poste | `CHECK` | `ck_espace_capacite_si_salle`, `ck_espace_type_poste_si_poste` |
| RG-12 | Facture adressée à exactement un destinataire | `CHECK ((id_utilisateur IS NULL) <> (id_societe IS NULL))` | `ck_facture_destinataire_unique` |
| RG-13 | Facture immuable après émission | trigger `BEFORE UPDATE OR DELETE` sur `facture` et `ligne_facture` | `tg_facture_immuable`, `tg_ligne_facture_immuable` |
| RG-14 | Pas de réservation sur un espace en maintenance ou retiré | trigger `BEFORE INSERT OR UPDATE` sur `reservation` | `tg_reservation_espace_disponible` |
| RG-17 | Un atelier se tient dans une salle, animé par un porteur du rôle ANIMATEUR | trigger `BEFORE INSERT OR UPDATE` sur `atelier` | `tg_atelier_salle_et_animateur` |
| RG-18 | Jauge respectée ; une inscription par personne et par atelier | clé primaire `(id_utilisateur, id_atelier)` + trigger avec verrou sur `atelier` | `pk_inscription`, `tg_inscription_places_restantes` |
| RG-20 | Une facture par destinataire et par période | index uniques partiels | `uq_facture_utilisateur_periode`, `uq_facture_societe_periode` |
| RG-21 | Code d'espace unique par site | `UNIQUE (id_site, code)` | `uq_espace_code_par_site` |
| Tarifs | Pas de chevauchement de validité pour une même prestation et formule | contrainte d'exclusion | `ex_tarif_pas_de_chevauchement` |
| Annulation | `annulee_le` renseigné ssi statut `ANNULEE` | `CHECK` | `ck_reservation_annulation_coherente` |

**Pourquoi la RG-04 est en base et pas seulement dans le code.** Deux requêtes simultanées `SELECT` puis `INSERT` passent toutes les deux : c'est exactement le double-booking dont se plaint le client. La contrainte d'exclusion est la seule des trois implémentations du cours qui tient sans verrou explicite. Le code applicatif garde la vérification pour produire un message clair (« ce créneau vient d'être pris ») — la règle est défendue à deux endroits, volontairement (point de couplage P6 de la fiche de synthèse).

## 4. Intégrité référentielle — chaque `ON DELETE` justifié

Règle de travail : `RESTRICT` partout, puis chaque exception justifiée.

| Clé étrangère | `ON DELETE` | Justification |
|---------------|-------------|---------------|
| `espace.id_site → site` | `RESTRICT` | On ne supprime pas un site qui a des espaces ; on le retire du catalogue |
| `salle_equipement.*` | `CASCADE` | Ligne de jonction sans sens hors des deux parents ; supprimer un équipement du référentiel le retire des salles |
| `utilisateur.id_societe → societe` | `SET NULL` | Un utilisateur survit à sa société : il redevient indépendant. Colonne nullable par construction (0,1) |
| `utilisateur_role.*`, `affectation.*` | `CASCADE` | Lignes de jonction pures ; un utilisateur supprimé n'a plus ni rôles ni affectations. En pratique on **désactive** (`actif = false`) plutôt que supprimer |
| `tarif.code_formule → formule` | `RESTRICT` | Un tarif historique justifie des factures |
| `abonnement.id_utilisateur → utilisateur` | `RESTRICT` | Historique de facturation : on anonymise l'utilisateur, on ne le supprime pas |
| `abonnement.code_formule → formule` | `RESTRICT` | Idem |
| `reservation.id_utilisateur → utilisateur` | `RESTRICT` | **Le piège du cours** : `CASCADE` effacerait l'historique de facturation. La réponse RGPD est l'anonymisation, pas la suppression |
| `reservation.id_espace → espace` | `RESTRICT` | Un espace qui a été réservé passe en `RETIRE`, il ne disparaît pas |
| `remboursement.id_reservation → reservation` | `RESTRICT` | Trace financière |
| `atelier.id_espace → espace`, `atelier.id_animateur → utilisateur` | `RESTRICT` | Un atelier passé reste dans l'historique |
| `inscription.*` | `RESTRICT` | Supprimer un atelier avec des inscrits est une erreur : on l'annule (statut) et on prévient |
| `facture.id_utilisateur`, `facture.id_societe` | `RESTRICT` | Pièce comptable |
| `ligne_facture.id_facture → facture` | **`CASCADE`** | La seule composition vraie : une ligne sans facture est absurde. Protégée en amont par `tg_facture_immuable` (une facture `EMISE` ne se supprime pas) |
| `ligne_facture.id_utilisateur → utilisateur` | `RESTRICT` | Bénéficiaire d'une pièce comptable |
| `ligne_facture.id_reservation → reservation` | `RESTRICT` | Idem |

## 5. Index

PostgreSQL n'indexe **pas** les clés étrangères automatiquement. Sans index, chaque suppression ou mise à jour dans le parent balaie l'enfant.

| Index | Pourquoi |
|-------|----------|
| Un index par clé étrangère (`ix_<table>_<colonne>`) | Jointures et vérification d'intégrité |
| Index GiST porté par `ex_reservation_pas_de_chevauchement` | **La requête chaude** : recherche de disponibilité par recouvrement de créneau (`tstzrange && …`). La contrainte qui garantit la RG-04 sert aussi la lecture — vérifié par le plan V-10 |
| `ix_reservation_espace_debut_confirmee` sur `reservation (id_espace, debut) WHERE statut = 'CONFIRMEE'` | Planning chronologique d'un espace (« les réservations de la salle S-A cette semaine »). Partiel : petit, ciblé |
| `ix_reservation_utilisateur_debut_confirmee` sur `reservation (id_utilisateur, debut) WHERE statut = 'CONFIRMEE'` | Calcul du quota mensuel et « mes réservations » |
| `ix_reservation_en_attente` sur `reservation (cree_le) WHERE statut = 'EN_ATTENTE'` | Balayage du planificateur pour l'expiration à 15 min |
| `ix_inscription_atelier_confirmee` sur `inscription (id_atelier) WHERE statut = 'CONFIRMEE'` | `COUNT` des places restantes — ce qui rend `nb_inscrits` inutile |
| `uq_utilisateur_email_lower` sur `lower(email)` | Unicité RG-01 et connexion |
| Les index implicites des `PRIMARY KEY`, `UNIQUE` et `EXCLUDE` | — |

Non indexé, volontairement : `utilisateur.actif`, `espace.statut` (faible cardinalité), `reservation.statut` seul (couvert par les index partiels).

## 6. Vues et fonctions

| Objet | Rôle | UC |
|-------|------|----|
| `v_presents_par_site` | Réservations confirmées en cours (`debut <= now() < fin`) avec utilisateur et espace, par site (H3) ; accès restreint au rôle base `coworkin_accueil` | UC-06 |
| `v_taux_occupation_jour` | Heures confirmées par site, jour et type d'espace, rapportées aux heures ouvrables × nombre d'espaces disponibles (RG-16) | UC-09 |
| `v_facture_total` | Total HT par facture, calculé | UC-08, UC-14 |
| `v_consommation_mensuelle` | Réservations confirmées du mois par bénéficiaire et société, avec montant dû : c'est la matérialisation SQL de l'interface `IConsommationMensuelle` | UC-08 |
| `quota_consomme_h(id_abonnement, periode)` | Heures de salle confirmées imputées à l'abonnement sur le mois | UC-02, UC-04 |
| `places_restantes(id_atelier)` | `places_max - COUNT(inscriptions confirmées)` | UC-03 |

## 7. Sécurité et données personnelles au niveau physique

- **Deux rôles de base** : `coworkin_app` (lecture/écriture sur les tables, aucun `DROP`, aucune modification de schéma) et `coworkin_accueil` (lecture de `v_presents_par_site` uniquement, pour un éventuel poste d'accueil autonome). Créés dans `002_contraintes.sql` sous forme commentée : l'exécution des `GRANT` dépend de l'environnement.
- **Chiffrement au repos** : responsabilité de l'hébergement (volume chiffré) ; pas de colonne chiffrée applicativement en V1.
- **Journalisation** : les consultations de `v_presents_par_site` sont tracées côté applicatif (qui, quand, quel site). Une table `journal_acces` est prévue mais hors du modèle métier, donc hors de ce dossier.
- **Anonymisation** : fonction applicative qui remplace `nom`, `prenom`, `email`, `telephone` par des valeurs neutres et passe `actif = false` ; les identifiants et l'historique de facturation restent intacts (voir dictionnaire, section 3).

## 8. Ce que le MPD n'a pas résolu, et où c'est écrit

| Point | Où |
|-------|----|
| Cardinalités minimales (1,n) de HEBERGER et EXERCER non garantissables en SQL | requêtes de vérification V-06 et V-07 du jeu de test |
| Borne « la réservation ne dépasse pas la journée d'ouverture » dépend du site | applicatif ; RG-05 partiellement en `CHECK` |
| Expiration à 15 min | planificateur applicatif (A8) |
| Jauge d'un atelier ≤ capacité de la salle | applicatif à la publication ; non contraint en base (la capacité peut changer après) |
