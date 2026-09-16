# Dictionnaire des données — CoWork'In

> Atelier 3.1. Une ligne par propriété du MCD. Le test du dictionnaire : si une même information apparaît deux fois sous deux noms, ou un même nom pour deux sens, le modèle a un défaut. Les propriétés nommées `statut` ont chacune leur domaine, listé explicitement.

Conventions : type **métier** au MCD, type **SQL** au MPD (PostgreSQL). `E` = élémentaire, `Ca` = calculée (donc absente du modèle, listée pour mémoire), `Si` = signalétique, `Sit` = de situation (change au cours de la vie de l'occurrence), `Mvt` = de mouvement (événement daté).

## 1. Propriétés par entité

### SITE

| Code | Libellé | Type métier | Type SQL | Nature | Règle | Exemple |
|------|---------|-------------|----------|--------|-------|---------|
| idSite | Identifiant du site | Identifiant | `BIGINT IDENTITY` | E, Si | Technique, non significatif | 1 |
| nom | Nom commercial du site | Texte | `VARCHAR(60) NOT NULL` | E, Si | Unique | CoWork'In Lille Centre |
| ville | Ville | Texte | `VARCHAR(60) NOT NULL` | E, Si | — | Lille |
| adresse | Adresse postale | Adresse | `TEXT NOT NULL` | E, Si | Atomicité acceptée : jamais triée ni filtrée par voie | 12 rue Faidherbe, 59000 Lille |
| heureOuverture | Heure d'ouverture | Heure | `TIME NOT NULL` | E, Si | < heureFermeture | 08:00 |
| heureFermeture | Heure de fermeture | Heure | `TIME NOT NULL` | E, Si | > heureOuverture (RG-05) | 20:00 |

### ESPACE (sous-types POSTE et SALLE_REUNION)

| Code | Libellé | Type métier | Type SQL | Nature | Règle | Exemple |
|------|---------|-------------|----------|--------|-------|---------|
| idEspace | Identifiant de l'espace | Identifiant | `BIGINT IDENTITY` | E, Si | Technique | 12 |
| code | Code affiché sur place | Texte | `VARCHAR(20) NOT NULL` | E, Si | Unique **par site** (RG-21) | P-12, S-A |
| typeEspace | Discriminant poste / salle | Énumération | `VARCHAR(10) NOT NULL` | E, Si | `POSTE` \| `SALLE` | SALLE |
| typePoste | Type de poste | Énumération | `VARCHAR(10)` | E, Si | `FLEX` \| `DEDIE` ; renseigné si et seulement si `POSTE` | FLEX |
| capacite | Nombre de places assises | Entier | `SMALLINT` | E, Si | > 0 ; renseigné si et seulement si `SALLE` (RG-11) | 8 |
| statut | État d'exploitation | Énumération | `VARCHAR(15) NOT NULL` | E, Sit | `DISPONIBLE` \| `MAINTENANCE` \| `RETIRE` (RG-14) | DISPONIBLE |

### EQUIPEMENT

| Code | Libellé | Type métier | Type SQL | Nature | Règle | Exemple |
|------|---------|-------------|----------|--------|-------|---------|
| codeEquipement | Code de l'équipement | Code | `VARCHAR(20)` | E, Si | Identifiant naturel | VISIO |
| libelle | Libellé affiché | Texte | `VARCHAR(60) NOT NULL` | E, Si | — | Visioconférence |

### SOCIETE

| Code | Libellé | Type métier | Type SQL | Nature | Règle | Exemple |
|------|---------|-------------|----------|--------|-------|---------|
| idSociete | Identifiant | Identifiant | `BIGINT IDENTITY` | E, Si | Technique | 3 |
| raisonSociale | Raison sociale | Texte | `VARCHAR(120) NOT NULL` | E, Si | — | Nordwave SAS |
| siret | SIRET | Code | `CHAR(14) NOT NULL` | E, Si | Unique, 14 chiffres | 83254789600017 |
| adresseFacturation | Adresse de facturation | Adresse | `TEXT NOT NULL` | E, Si | — | 4 place du Théâtre, 59000 Lille |
| emailFacturation | E-mail de facturation | Email | `VARCHAR(254) NOT NULL` | E, Si | Format e-mail | compta@nordwave.example |

### UTILISATEUR

| Code | Libellé | Type métier | Type SQL | Nature | Règle | Exemple |
|------|---------|-------------|----------|--------|-------|---------|
| idUtilisateur | Identifiant | Identifiant | `BIGINT IDENTITY` | E, Si | Technique ; conservé après anonymisation | 42 |
| nom | Nom | Texte | `VARCHAR(80) NOT NULL` | E, Si | Donnée personnelle | Benali |
| prenom | Prénom | Texte | `VARCHAR(80) NOT NULL` | E, Si | Donnée personnelle | Salma |
| email | Adresse e-mail de connexion | Email | `VARCHAR(254) NOT NULL` | E, Si | Unique, insensible à la casse (RG-01) | salma.benali@example.org |
| telephone | Téléphone | Texte | `VARCHAR(20)` | E, Si | Optionnel ; un seul numéro (1FN) | +33 6 12 34 56 78 |
| actif | Compte actif | Booléen | `BOOLEAN NOT NULL` | E, Sit | `false` = désactivé (RG-22) | true |
| creeLe | Date de création du compte | DateHeure | `TIMESTAMPTZ NOT NULL` | E, Mvt | Par défaut `now()` | 2026-01-15 10:02+01 |

### ROLE

| Code | Libellé | Type métier | Type SQL | Nature | Règle | Exemple |
|------|---------|-------------|----------|--------|-------|---------|
| codeRole | Code du rôle | Code | `VARCHAR(20)` | E, Si | `COWORKER` \| `REFERENT_SOCIETE` \| `HOTE_ACCUEIL` \| `GERANT` \| `ANIMATEUR` | HOTE_ACCUEIL |
| libelle | Libellé | Texte | `VARCHAR(60) NOT NULL` | E, Si | — | Hôte d'accueil |

### FORMULE

| Code | Libellé | Type métier | Type SQL | Nature | Règle | Exemple |
|------|---------|-------------|----------|--------|-------|---------|
| codeFormule | Code de la formule | Code | `VARCHAR(20)` | E, Si | Identifiant naturel | RESIDENT |
| libelle | Libellé commercial | Texte | `VARCHAR(60) NOT NULL` | E, Si | — | Résident |
| quotaSalleH | Heures de salle incluses par mois | Entier | `SMALLINT NOT NULL` | E, Si | ≥ 0 (RG-07) | 4 |
| actif | Formule commercialisée | Booléen | `BOOLEAN NOT NULL` | E, Sit | — | true |

### TARIF

| Code | Libellé | Type métier | Type SQL | Nature | Règle | Exemple |
|------|---------|-------------|----------|--------|-------|---------|
| idTarif | Identifiant | Identifiant | `BIGINT IDENTITY` | E, Si | Technique | 7 |
| prestation | Prestation tarifée | Énumération | `VARCHAR(20) NOT NULL` | E, Si | `ABONNEMENT_MENSUEL` \| `POSTE_HEURE` \| `POSTE_JOUR` \| `SALLE_HEURE` | SALLE_HEURE |
| prixHT | Prix hors taxes | Montant | `NUMERIC(10,2) NOT NULL` | E, Si | ≥ 0 ; jamais `FLOAT` | 15.00 |
| dateDebut | Début de validité | Date | `DATE NOT NULL` | E, Si | — | 2026-01-01 |
| dateFin | Fin de validité | Date | `DATE` | E, Sit | `NULL` = en vigueur ; > dateDebut ; pas de chevauchement pour une même prestation et formule | NULL |

### ABONNEMENT

| Code | Libellé | Type métier | Type SQL | Nature | Règle | Exemple |
|------|---------|-------------|----------|--------|-------|---------|
| idAbonnement | Identifiant | Identifiant | `BIGINT IDENTITY` | E, Si | Technique | 15 |
| dateDebut | Début de la souscription | Date | `DATE NOT NULL` | E, Si | — | 2026-02-01 |
| dateFin | Fin de la souscription | Date | `DATE` | E, Sit | `NULL` = en cours ; un seul abonnement actif par utilisateur à la fois (RG-08) | NULL |
| *quotaConsomme* | *Heures de salle consommées dans le mois* | *Durée* | — | **Ca** | **Non stockée** : somme des réservations de salle confirmées du mois | *2 h 30* |

### RESERVATION

| Code | Libellé | Type métier | Type SQL | Nature | Règle | Exemple |
|------|---------|-------------|----------|--------|-------|---------|
| idReservation | Identifiant | Identifiant | `BIGINT IDENTITY` | E, Si | Technique | 4712 |
| debut | Début du créneau | DateHeure | `TIMESTAMPTZ NOT NULL` | E, Si | — | 2026-03-10 09:00+01 |
| fin | Fin du créneau | DateHeure | `TIMESTAMPTZ NOT NULL` | E, Si | > debut (RG-03) ; ≥ debut + 1 h (RG-05) | 2026-03-10 11:00+01 |
| statut | État de la réservation | Énumération | `VARCHAR(12) NOT NULL` | E, Sit | `EN_ATTENTE` \| `CONFIRMEE` \| `ANNULEE` | CONFIRMEE |
| montantDu | Montant dû figé à la confirmation | Montant | `NUMERIC(10,2) NOT NULL` | E, Si | ≥ 0 ; **historisation** du tarif appliqué, pas une redondance | 15.00 |
| creeLe | Date de création | DateHeure | `TIMESTAMPTZ NOT NULL` | E, Mvt | Par défaut `now()` ; sert à l'expiration RG-09 | 2026-03-02 14:11+01 |
| annuleeLe | Date d'annulation | DateHeure | `TIMESTAMPTZ` | E, Mvt | Renseignée si et seulement si `ANNULEE` | NULL |
| motifAnnulation | Motif d'annulation | Texte | `VARCHAR(200)` | E, Mvt | Obligatoire si annulation par l'exploitant (applicatif) | Salle en maintenance |

### REMBOURSEMENT (objet technique de suivi)

| Code | Libellé | Type métier | Type SQL | Nature | Règle | Exemple |
|------|---------|-------------|----------|--------|-------|---------|
| idRemboursement | Identifiant | Identifiant | `BIGINT IDENTITY` | E, Si | Technique | 9 |
| montant | Montant remboursé | Montant | `NUMERIC(10,2) NOT NULL` | E, Si | > 0 ; ≤ montantDu de la réservation (RG-10) | 7.50 |
| statut | État de la demande | Énumération | `VARCHAR(10) NOT NULL` | E, Sit | `DEMANDE` \| `EFFECTUE` \| `EN_ERREUR` | EFFECTUE |
| referencePsp | Référence renvoyée par le prestataire | Code | `VARCHAR(64)` | E, Si | Renseignée si `EFFECTUE` | rf_8Ks2… |
| demandeLe | Date de la demande | DateHeure | `TIMESTAMPTZ NOT NULL` | E, Mvt | — | 2026-03-05 09:30+01 |
| effectueLe | Date d'exécution | DateHeure | `TIMESTAMPTZ` | E, Mvt | — | 2026-03-05 09:30+01 |

### ATELIER

| Code | Libellé | Type métier | Type SQL | Nature | Règle | Exemple |
|------|---------|-------------|----------|--------|-------|---------|
| idAtelier | Identifiant | Identifiant | `BIGINT IDENTITY` | E, Si | Technique | 21 |
| titre | Titre | Texte | `VARCHAR(120) NOT NULL` | E, Si | — | Introduction à PostgreSQL |
| description | Description | Texte | `TEXT` | E, Si | Optionnelle | … |
| debut | Début | DateHeure | `TIMESTAMPTZ NOT NULL` | E, Si | Un jeudi soir en pratique, non contraint en base | 2026-03-12 18:30+01 |
| fin | Fin | DateHeure | `TIMESTAMPTZ NOT NULL` | E, Si | > debut | 2026-03-12 20:30+01 |
| placesMax | Jauge | Entier | `SMALLINT NOT NULL` | E, Si | > 0 (RG-17) ; ≤ capacité de la salle (applicatif) | 12 |
| statut | État de l'atelier | Énumération | `VARCHAR(10) NOT NULL` | E, Sit | `BROUILLON` \| `PUBLIE` \| `ANNULE` \| `TERMINE` | PUBLIE |
| *placesRestantes* | *Places restantes* | *Entier* | — | **Ca** | **Non stockée** : placesMax − inscriptions confirmées | *3* |

### S'INSCRIRE (relation porteuse → INSCRIPTION)

| Code | Libellé | Type métier | Type SQL | Nature | Règle | Exemple |
|------|---------|-------------|----------|--------|-------|---------|
| dateInscription | Date de l'inscription | DateHeure | `TIMESTAMPTZ NOT NULL` | E, Mvt | — | 2026-03-01 19:04+01 |
| statut | État de l'inscription | Énumération | `VARCHAR(10) NOT NULL` | E, Sit | `CONFIRMEE` \| `ANNULEE` (RG-18, RG-19) | CONFIRMEE |

### FACTURE

| Code | Libellé | Type métier | Type SQL | Nature | Règle | Exemple |
|------|---------|-------------|----------|--------|-------|---------|
| idFacture | Identifiant | Identifiant | `BIGINT IDENTITY` | E, Si | Technique | 118 |
| numero | Numéro de facture | Code | `VARCHAR(20) NOT NULL` | E, Si | Unique, séquentiel par année (exigence expert-comptable) | 2026-000118 |
| periode | Mois facturé | Mois | `DATE NOT NULL` | E, Si | Premier jour du mois ; une facture par destinataire et par période (RG-20) | 2026-02-01 |
| dateEmission | Date d'émission | Date | `DATE` | E, Mvt | Renseignée au passage à `EMISE` | 2026-03-01 |
| statut | État | Énumération | `VARCHAR(10) NOT NULL` | E, Sit | `BROUILLON` \| `EMISE` \| `PAYEE` \| `ANNULEE` ; immuable après `EMISE` (RG-13) | EMISE |
| *montantTotal* | *Total TTC* | *Montant* | — | **Ca** | **Non stockée** : somme des lignes (vue) | *64,00 €* |

### LIGNE_FACTURE (entité faible, identifiée relativement à FACTURE)

| Code | Libellé | Type métier | Type SQL | Nature | Règle | Exemple |
|------|---------|-------------|----------|--------|-------|---------|
| numLigne | Numéro de ligne dans la facture | Entier | `SMALLINT NOT NULL` | E, Si | Identifiant **relatif** : (idFacture, numLigne) | 3 |
| libelle | Libellé de la prestation | Texte | `VARCHAR(200) NOT NULL` | E, Si | **Recopié** à l'émission (RG-13) | Salle S-A — 10/03 09:00–11:00 — dépassement 1 h |
| quantite | Quantité | Décimal | `NUMERIC(8,2) NOT NULL` | E, Si | > 0 | 1.00 |
| unite | Unité | Énumération | `VARCHAR(10) NOT NULL` | E, Si | `HEURE` \| `JOUR` \| `MOIS` | HEURE |
| prixUnitaire | Prix unitaire HT | Montant | `NUMERIC(10,2) NOT NULL` | E, Si | **Recopié** du tarif en vigueur : historisation, pas redondance | 15.00 |

## 2. Contrôle du dictionnaire

| Vérification | Résultat |
|--------------|----------|
| Une même information sous deux noms ? | `prixHT` (TARIF), `montantDu` (RESERVATION) et `prixUnitaire` (LIGNE_FACTURE) désignent **trois informations différentes** : prix courant, prix appliqué à la réservation, prix facturé. Voulu et documenté |
| Un même nom pour deux sens ? | `statut` existe dans six entités avec six domaines distincts, tous listés ci-dessus. En base, chaque colonne a son `CHECK` nommé (`ck_reservation_statut`, `ck_espace_statut`…) |
| Propriétés calculables présentes ? | Aucune : `quotaConsomme`, `placesRestantes`, `montantTotal` sont exclues et signalées `Ca` |
| Propriétés multivaluées ? | Aucune : `roles` → entité ROLE ; `equipements` → entité EQUIPEMENT ; un seul `telephone` |
| Clés étrangères déguisées en propriétés ? | Aucune : `idSite` n'apparaît pas dans ESPACE, le lien est porté par la relation HEBERGER |

## 3. Données personnelles

| Propriété | Catégorie | Conservation | Traitement à la demande d'effacement |
|-----------|-----------|--------------|--------------------------------------|
| UTILISATEUR.nom, prenom, email, telephone | Identité et contact | Durée du compte + 3 ans | **Anonymisation** : remplacés par des valeurs neutres, `idUtilisateur` conservé pour l'intégrité comptable |
| RESERVATION (créneau, espace, utilisateur) | Localisation indirecte | 10 ans (pièce justificative de facturation) | Rattachée à l'utilisateur anonymisé |
| Vue des présents (UC-06) | Localisation en temps réel | Non stockée : calculée ; consultations journalisées | — |
| INSCRIPTION | Participation à un événement | 12 mois après l'atelier, puis anonymisation | — |
| FACTURE, LIGNE_FACTURE | Données comptables | 10 ans, immuables | Conservées, bénéficiaire anonymisé |
| RESERVATION.motifAnnulation | Texte libre | Idem réservation | Consigne à l'écran : aucune donnée de santé |
