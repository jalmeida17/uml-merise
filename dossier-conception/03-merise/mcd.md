# Modèle conceptuel de données (MCD) — CoWork'In

> Atelier 3.1 et 3.2. Traduit du diagramme de classes d'hier ([`../02-uml/classes-metier.puml`](../02-uml/classes-metier.puml)), facturation comprise. Niveau conceptuel : identifiants métier ou techniques marqués `#`, **aucune clé étrangère**, aucun type SQL. Les cardinalités se lisent en partant de l'entité **elle-même** : « un SITE participe de 1 à n fois à HÉBERGER ».

## 1. Le MCD en texte

### 1.1 Entités

| Entité | Identifiant | Propriétés | Issue de la classe |
|--------|-------------|------------|--------------------|
| **SITE** | #idSite | nom, ville, adresse, heureOuverture, heureFermeture | `Site` |
| **ESPACE** | #idEspace | code, typeEspace, statut — sous-types **POSTE** (typePoste) et **SALLE_REUNION** (capacite) | `Espace` {abstract}, `Poste`, `SalleReunion` |
| **EQUIPEMENT** | #codeEquipement | libelle | attribut multivalué `equipements [*]` de `SalleReunion` (1FN) |
| **SOCIETE** | #idSociete | raisonSociale, siret, adresseFacturation, emailFacturation | `Societe` |
| **UTILISATEUR** | #idUtilisateur | nom, prenom, email, telephone, actif, creeLe | `Utilisateur` |
| **ROLE** | #codeRole | libelle | attribut multivalué `roles [1..*]` de `Utilisateur` (1FN) |
| **FORMULE** | #codeFormule | libelle, quotaSalleH, actif | `Formule` |
| **TARIF** | #idTarif | prestation, prixHT, dateDebut, dateFin | `Tarif` |
| **ABONNEMENT** | #idAbonnement | dateDebut, dateFin | `Abonnement` |
| **RESERVATION** | #idReservation | debut, fin, statut, montantDu, creeLe, annuleeLe, motifAnnulation | `Reservation` |
| **REMBOURSEMENT** | #idRemboursement | montant, statut, referencePsp, demandeLe, effectueLe | objet de suivi apparu à la séquence détaillée UC-04 |
| **ATELIER** | #idAtelier | titre, description, debut, fin, placesMax, statut | `Atelier` |
| **FACTURE** | #idFacture | numero, periode, dateEmission, statut | `Facture` |
| **LIGNE_FACTURE** | numLigne *(relatif à FACTURE)* | libelle, quantite, unite, prixUnitaire | `LigneFacture` (composition) |

Quatorze entités. `Inscription` n'est pas une entité : c'est une **relation porteuse** (voir 1.2).

### 1.2 Relations

Lecture : « une occurrence de *Entité A* participe *(min,max)* fois à *RELATION* ». La colonne « traduction » anticipe la règle de passage appliquée au MLD.

| Relation | Patte A (cardinalité) | Patte B (cardinalité) | Propriétés portées | Traduction au MLD |
|----------|-----------------------|-----------------------|--------------------|-------------------|
| **HEBERGER** | SITE (1,n) | ESPACE (1,1) | — | R2 : `id_site` dans ESPACE. Le (1,n) côté SITE n'est pas garantissable par SQL seul : noté |
| **DISPOSER DE** | SALLE_REUNION (0,n) | EQUIPEMENT (0,n) | — | R3 : table SALLE_EQUIPEMENT |
| **EMPLOYER** | SOCIETE (0,n) | UTILISATEUR (0,1) | — | R2 : `id_societe` **nullable** dans UTILISATEUR |
| **EXERCER** | UTILISATEUR (1,n) | ROLE (0,n) | — | R3 : table UTILISATEUR_ROLE. Le (1,n) côté UTILISATEUR (au moins un rôle) est applicatif |
| **AFFECTER** | UTILISATEUR (0,n) | SITE (0,n) | — | R3 : table AFFECTATION (personnel d'accueil affecté à un ou plusieurs sites) |
| **TARIFER** | FORMULE (0,n) | TARIF (0,1) | — | R2 : `code_formule` **nullable** dans TARIF (renseigné si prestation = ABONNEMENT_MENSUEL) |
| **SOUSCRIRE** | UTILISATEUR (0,n) | ABONNEMENT (1,1) | — | R2 : `id_utilisateur` dans ABONNEMENT |
| **RELEVER DE** | ABONNEMENT (1,1) | FORMULE (0,n) | — | R2 : `code_formule` dans ABONNEMENT |
| **EFFECTUER** | UTILISATEUR (0,n) | RESERVATION (1,1) | — | R2 : `id_utilisateur` dans RESERVATION |
| **PORTER SUR** | RESERVATION (1,1) | ESPACE (0,n) | — | R2 : `id_espace` dans RESERVATION |
| **REMBOURSER** | RESERVATION (0,n) | REMBOURSEMENT (1,1) | — | R2 : `id_reservation` dans REMBOURSEMENT |
| **ANIMER** | UTILISATEUR (0,n) | ATELIER (1,1) | — | R2 : `id_animateur` dans ATELIER |
| **ACCUEILLIR** | SALLE_REUNION (0,n) | ATELIER (1,1) | — | R2 : `id_espace` dans ATELIER |
| **S'INSCRIRE** | UTILISATEUR (0,n) | ATELIER (0,n) | **dateInscription, statut** | R3 : table INSCRIPTION, clé (id_utilisateur, id_atelier) |
| **ADRESSER À (utilisateur)** | FACTURE (0,1) | UTILISATEUR (0,n) | — | R2 : `id_utilisateur` nullable dans FACTURE |
| **ADRESSER À (société)** | FACTURE (0,1) | SOCIETE (0,n) | — | R2 : `id_societe` nullable dans FACTURE — **contrainte d'exclusion** : exactement une des deux |
| **COMPOSER** | FACTURE (1,n) | LIGNE_FACTURE (1,1) *identification relative* | — | R6 : clé composite (id_facture, num_ligne), suppression en cascade |
| **FACTURER** | LIGNE_FACTURE (0,1) | RESERVATION (0,1) | — | R5 : `id_reservation` nullable **UNIQUE** dans LIGNE_FACTURE |
| **BENEFICIER** | LIGNE_FACTURE (1,1) | UTILISATEUR (0,n) | — | R2 : `id_utilisateur` dans LIGNE_FACTURE (le collaborateur bénéficiaire) |

Dix-neuf relations, dont une porteuse (S'INSCRIRE), trois (x,n)–(x,n) sans propriété (DISPOSER DE, EXERCER, AFFECTER) et une identification relative (COMPOSER).

## 2. Source Mocodo

Fichier à coller sur <https://www.mocodo.net> ou à rendre avec `mocodo --input mcd.mcd` (le bloc ci-dessous est aussi enregistré tel quel dans [`mcd.mcd`](mcd.mcd)). Les identifiants techniques sont préfixés `_` dans la notation Mocodo (souligné) ; la barre d'identification relative est portée par `_11`.

```
SITE: idSite, nom, ville, adresse, heureOuverture, heureFermeture
HEBERGER, 1N SITE, 11 ESPACE
ESPACE: idEspace, code, typeEspace, statut
/XT\ ESPACE <= POSTE, SALLE_REUNION
POSTE: typePoste
SALLE_REUNION: capacite
DISPOSER DE, 0N SALLE_REUNION, 0N EQUIPEMENT
EQUIPEMENT: codeEquipement, libelle

SOCIETE: idSociete, raisonSociale, siret, adresseFacturation, emailFacturation
EMPLOYER, 0N SOCIETE, 01 UTILISATEUR
UTILISATEUR: idUtilisateur, nom, prenom, email, telephone, actif, creeLe
EXERCER, 1N UTILISATEUR, 0N ROLE
ROLE: codeRole, libelle
AFFECTER, 0N UTILISATEUR, 0N SITE

FORMULE: codeFormule, libelle, quotaSalleH, actif
TARIFER, 0N FORMULE, 01 TARIF
TARIF: idTarif, prestation, prixHT, dateDebut, dateFin
SOUSCRIRE, 0N UTILISATEUR, 11 ABONNEMENT
ABONNEMENT: idAbonnement, dateDebut, dateFin
RELEVER DE, 11 ABONNEMENT, 0N FORMULE

EFFECTUER, 0N UTILISATEUR, 11 RESERVATION
RESERVATION: idReservation, debut, fin, statut, montantDu, creeLe, annuleeLe, motifAnnulation
PORTER SUR, 11 RESERVATION, 0N ESPACE
REMBOURSER, 0N RESERVATION, 11 REMBOURSEMENT
REMBOURSEMENT: idRemboursement, montant, statut, referencePsp, demandeLe, effectueLe

ANIMER, 0N UTILISATEUR, 11 ATELIER
ATELIER: idAtelier, titre, description, debut, fin, placesMax, statut
ACCUEILLIR, 0N SALLE_REUNION, 11 ATELIER
S'INSCRIRE, 0N UTILISATEUR, 0N ATELIER: dateInscription, statut

ADRESSER A U, 01 FACTURE, 0N UTILISATEUR
ADRESSER A S, 01 FACTURE, 0N SOCIETE
FACTURE: idFacture, numero, periode, dateEmission, statut
COMPOSER, 1N FACTURE, _11 LIGNE_FACTURE
LIGNE_FACTURE: numLigne, libelle, quantite, unite, prixUnitaire
FACTURER, 01 LIGNE_FACTURE, 01 RESERVATION
BENEFICIER, 11 LIGNE_FACTURE, 0N UTILISATEUR
```

## 3. Du diagramme de classes au MCD : ce qui a changé

| Dans le diagramme de classes | Dans le MCD | Pourquoi |
|------------------------------|-------------|----------|
| Multiplicité `Site "1" — "0..*" Espace` lue depuis la classe opposée | Cardinalités HEBERGER : SITE **(1,n)**, ESPACE **(1,1)** | Placement inversé : la cardinalité MERISE est collée à l'entité qu'elle compte. Relue à voix haute : « un espace est hébergé par exactement un site », « un site héberge au moins un espace » |
| `roles : Role [1..*]` | Entité ROLE + relation EXERCER | MERISE interdit les propriétés multivaluées |
| `equipements : String [*]` | Entité EQUIPEMENT + relation DISPOSER DE | Idem, et on pourra filtrer « salles avec visio » |
| Classe d'association `Inscription` | Relation porteuse S'INSCRIRE | Équivalents ; la limite « une occurrence par couple » est la RG-18 |
| Composition `Facture *— LigneFacture` | Identification relative COMPOSER | Proches : l'un parle cycle de vie, l'autre identifiant. Ici les deux sont vrais |
| Opérations (`annuler`, `quotaRestant`…) | Absentes | Le MCD ne modélise que les données |
| Contrainte `{xor}` sur les deux « est adressée à » | Deux relations (0,1) + contrainte d'exclusion notée | MERISE n'a pas de notation standard ; elle devient un `CHECK` au MPD |
| Objet-valeur `Adresse` | Propriété `adresse` en une chaîne | Jamais triée ni filtrée par composant dans les cas d'usage ; atomicité acceptée et documentée |

## 4. Les quatre cas délicats (atelier 3.2)

### 4.1 Relation porteuse — S'INSCRIRE

`dateInscription` et `statut` ne sont ni une propriété de l'utilisateur ni une propriété de l'atelier : elles appartiennent au **couple**. La relation les porte. Limite vérifiée : un utilisateur ne s'inscrit qu'une fois à un atelier donné (RG-18) ; s'il annule puis se réinscrit, la même occurrence change de statut. Si un jour un atelier se répète en sessions, S'INSCRIRE devra devenir une entité avec son propre identifiant, exactement comme RESERVATION aujourd'hui.

Contre-exemple assumé dans le même modèle : **RESERVATION est une entité, pas une relation porteuse** entre UTILISATEUR et ESPACE, parce que le même coworker réserve la même salle chaque mardi. Le couple se répète, donc la porteuse est fausse.

### 4.2 Ternaire à arbitrer — ANIMER (animateur × salle × créneau)

Première tentation : une relation ternaire ANIMER entre UTILISATEUR (animateur), SALLE_REUNION et un CRENEAU, comme dans l'exemple du cours. Test décisif : *la relation a-t-elle besoin d'un identifiant propre, d'un statut, d'un cycle de vie ?* Oui : un atelier a un titre, une jauge, un statut (`BROUILLON`, `PUBLIE`, `ANNULE`), et surtout des inscrits. C'est une **entité déguisée**. On la nomme ATELIER et on la relie par deux binaires : ANIMER (UTILISATEUR (0,n) – ATELIER (1,1)) et ACCUEILLIR (SALLE_REUNION (0,n) – ATELIER (1,1)) ; le créneau devient deux propriétés (`debut`, `fin`). La ternaire a disparu, et S'INSCRIRE a maintenant quelque chose à quoi s'accrocher.

### 4.3 Entité faible — LIGNE_FACTURE

« La ligne n° 3 » ne veut rien dire ; « la ligne n° 3 de la facture 2026-000118 » oui. LIGNE_FACTURE n'a pas d'identifiant propre ayant du sens hors de son parent : identification relative à FACTURE, matérialisée par la barre sur la patte (1,1). Conséquences au MPD : clé primaire composite `(id_facture, num_ligne)` et `ON DELETE CASCADE` — la seule cascade du modèle, parce que c'est la seule composition vraie.

### 4.4 Historisation — TARIF, ABONNEMENT, montant figé

Trois questions du cours, trois réponses différentes dans le modèle :

1. *Faut-il retrouver la valeur passée ?* Le prix d'une formule change en janvier → entité **TARIF** avec `dateDebut` / `dateFin`, plutôt qu'un `UPDATE` du prix dans FORMULE.
2. *Faut-il connaître la valeur à une date donnée ?* Quelle formule avait ce coworker en février ? → **ABONNEMENT** borné dans le temps, et non une clé de formule sur l'utilisateur.
3. *Faut-il figer la valeur au moment d'un événement ?* Une facture émise ne bouge plus → `prixUnitaire` et `libelle` **recopiés** dans LIGNE_FACTURE, et `montantDu` figé dans RESERVATION. Ce n'est pas une redondance : prix courant, prix appliqué et prix facturé sont trois informations.

## 5. Validation du MCD — les neuf vérifications

| # | Vérification | Résultat |
|---|--------------|----------|
| 1 | Chaque entité a un identifiant, et un seul | Oui ; LIGNE_FACTURE a un identifiant relatif (idFacture, numLigne) |
| 2 | Aucune propriété dupliquée entre entités | `statut` ×6 sont des propriétés différentes (domaines distincts, voir dictionnaire) ; `debut`/`fin` de RESERVATION et d'ATELIER sont deux créneaux distincts |
| 3 | Propriétés atomiques | `adresse` gardée en une chaîne : décision explicite, jamais filtrée par composant |
| 4 | Aucune propriété calculable | `quotaConsomme`, `placesRestantes`, `montantTotal` exclues |
| 5 | Aucune propriété multivaluée | `roles` → ROLE, `equipements` → EQUIPEMENT |
| 6 | Chaque relation est un verbe avec ses deux cardinalités | Oui, dix-neuf relations |
| 7 | Aucune clé étrangère parmi les propriétés | Aucune : `idSite` absent d'ESPACE, `idFacture` absent de LIGNE_FACTURE (porté par l'identification relative) |
| 8 | Aucune relation redondante | RESERVATION → ESPACE → SITE : pas de relation directe RESERVATION–SITE, le site se déduit. Exception connue (site historique si un espace déménage) : **non retenue**, un espace ne change pas de site chez CoWork'In |
| 9 | Les porteuses n'ont que des propriétés dépendant de toutes leurs pattes | `dateInscription` et `statut` dépendent du couple (utilisateur, atelier) |

Points notés pour l'implémentation : deux cardinalités minimales à 1 côté « n » — HEBERGER (un site a au moins un espace) et EXERCER (un utilisateur a au moins un rôle) — ne sont **pas garantissables par une contrainte SQL simple**. Elles sont assurées par l'applicatif (création du site avec son premier espace dans la même transaction ; rôle `COWORKER` attribué à la création du compte) et vérifiées par une requête du jeu de test.
