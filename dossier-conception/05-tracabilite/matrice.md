# Matrice de traçabilité — CoWork'In

> Atelier 4.3. Deux parcours, deux questions. **Descendant** : chaque phrase du client a-t-elle produit quelque chose ? **Remontant** : chaque table est-elle justifiée par une phrase du client ? Une ligne vide au milieu est un défaut d'analyse ; une table sans phrase à gauche est soit technique et légitime, soit une fonctionnalité que personne n'a demandée.

Références : RG = règle de gestion (énoncées dans les fiches et le MPD), UC = cas d'usage, T-xx = insertion volontairement invalide du jeu de test, V-xx = requête de vérification.

## 1. Parcours descendant — du verbatim à la base

| # | Besoin exprimé (verbatim) | RG | UC | Classe / entité | Table et colonnes | Contrainte ou objet | Test |
|---|---------------------------|----|----|-----------------|-------------------|---------------------|------|
| 1 | « trois espaces de coworking, à Lille, Roubaix et Tourcoing » | RG-05, RG-21 | UC-05, UC-09 | `Site` | `site(nom, ville, heure_ouverture, heure_fermeture)` | `uq_site_nom`, `ck_site_horaires` | jeu §1 |
| 2 | « tout passe par un tableur partagé et des mails » | — (situation actuelle) | — | — | — | Normalisation du tableur en 3FN : `mld.md` §4 | — |
| 3 | « on double-réserve une salle au moins une fois par semaine » | RG-04 | UC-01, UC-02 | `Reservation`, `Espace` | `reservation(id_espace, debut, fin, statut)` | **`ex_reservation_pas_de_chevauchement`** (contrainte d'exclusion), défendue aussi en métier (`DisponibiliteChecker`) | T-04, T-04b, V-01 |
| 4 | « les coworkers créent leur compte » | RG-01, RG-22 | UC-13 | `Utilisateur`, `Role` | `utilisateur(email, actif)`, `utilisateur_role` | `uq_utilisateur_email_lower`, `pk_utilisateur_role` | T-01, V-07 |
| 5 | « voient les postes libres et les salles de réunion en temps réel » | RG-11, RG-14 | UC-05 | `Espace` {abstract}, `Poste`, `SalleReunion`, `Equipement` | `espace(type_espace, type_poste, capacite, statut)`, `salle_equipement` | `ck_espace_capacite_si_salle`, `ck_espace_type_poste_si_poste`, index GiST de `ex_reservation_pas_de_chevauchement` pour la recherche par créneau | T-11, V-10 |
| 6 | « réservent à l'heure ou à la journée » | RG-03, RG-05 | UC-01, UC-02 | `Reservation` | `reservation(debut, fin)` | `ck_reservation_fin_apres_debut`, `ck_reservation_duree_minimale`, `ck_reservation_pas_30min` | T-03, T-05, jeu R4 |
| 7 | « Les abonnés — formules Nomade, Résident, Team » | RG-08 | UC-14 | `Formule`, `Abonnement`, `Tarif` | `formule`, `abonnement(date_debut, date_fin)`, `tarif(prestation, prix_ht, date_debut, date_fin)` | `ex_abonnement_un_seul_actif`, `ex_tarif_pas_de_chevauchement`, `ck_tarif_formule_si_abonnement` | T-08 |
| 8 | « ne paient pas les postes » | RG-06 | UC-01, UC-15 | `Abonnement.estActif()`, `Tarif`, `Reservation.montantDu` | `reservation(montant_du)`, `tarif(POSTE_HEURE, POSTE_JOUR)` | `ck_reservation_montant_positif` ; le calcul est applicatif (`TarificationService`) | jeu R4, R10, R11 ; V-05 |
| 9 | « mais paient les salles au-delà de 4 h par mois » | RG-07 | UC-02, UC-15 | `Formule.quotaSalleH`, `Abonnement.quotaRestant()` | `formule(quota_salle_h)`, fonction `quota_consomme_h()` | `ck_formule_quota_positif` ; quota **calculé**, jamais stocké | V-02 |
| 10 | « À la fin du mois, il faut sortir une facture par client » | RG-13, RG-20 | UC-08 | `Facture`, `LigneFacture` | `facture(numero, periode, statut)`, `ligne_facture(libelle, prix_unitaire)` | `uq_facture_utilisateur_periode`, `uq_facture_societe_periode`, `tg_facture_immuable`, `tg_ligne_facture_immuable` | T-20, T-13, T-13b, T-13c, V-05 |
| 11 | « pour les sociétés, une facture globale avec le détail par collaborateur » | RG-12 | UC-08, UC-10 | `Societe`, `Facture` {xor}, `LigneFacture — bénéficie de → Utilisateur` | `facture(id_societe)`, `ligne_facture(id_utilisateur)`, `utilisateur(id_societe)` | `ck_facture_destinataire_unique`, `fk_utilisateur_societe ON DELETE SET NULL` | T-12, V-08 |
| 12 | « L'équipe d'accueil doit pouvoir fermer une salle pour maintenance » | RG-14 | UC-07 | `Espace.statut`, `Utilisateur — est affecté à → Site` | `espace(statut)`, `affectation` | `ck_espace_statut`, `tg_reservation_espace_disponible` | T-14 |
| 13 | « voir qui est présent en cas d'évacuation » | RG-15 (H3) | UC-06 | `Reservation`, `Utilisateur`, `Site` | vue **`v_presents_par_site`** | accès restreint au rôle `coworkin_accueil` ; consultations journalisées | V-04 |
| 14 | « Le gérant veut un tableau de bord du taux d'occupation par site » | RG-16 | UC-09 | `Reservation`, `Espace`, `Site` | vue **`v_taux_occupation_jour`** | — (lecture seule) | V-09 |
| 15 | « on organise des ateliers le jeudi soir » | RG-17 | UC-11, UC-12 | `Atelier`, `Utilisateur` (anime), `SalleReunion` (accueille) | `atelier(id_espace, id_animateur, debut, fin, places_max, statut)` | `tg_atelier_salle_et_animateur`, `ck_atelier_places_positif` | T-17, T-17b |
| 16 | « avec inscription en ligne et places limitées » | RG-18, RG-19 | UC-03 | `Inscription` (classe d'association) | `inscription(id_utilisateur, id_atelier, statut)`, `atelier(places_max)` | **`pk_inscription`**, **`tg_inscription_places_restantes`** (verrou `FOR UPDATE`) | T-18, T-18b, T-19, V-03 |
| 17 | *implicite* — une réservation doit pouvoir être défaite (analyse) | RG-10 | UC-04 | `Reservation.annuler()`, `PolitiqueAnnulation`, `Remboursement` | `reservation(annulee_le, motif_annulation)`, `remboursement` | `ck_reservation_annulation_coherente`, `tg_remboursement_plafond` | T-10, T-10b, T-04b, jeu R6, R7 |
| 18 | *implicite* — encaisser en ligne (« paient les salles ») | RG-09 | UC-15 | `Reservation` (statut `EN_ATTENTE`), acteur PSP | `reservation(statut, cree_le)` | `ix_reservation_en_attente` ; expiration par le planificateur | jeu R8 |
| 19 | *partie prenante DPO* — données de présence et comptes | RG-22 | UC-06, UC-13 | `Utilisateur.actif` | `utilisateur(actif)`, toutes les FK vers `utilisateur` en `RESTRICT` | `fk_reservation_utilisateur ON DELETE RESTRICT` ; anonymisation, pas suppression | T-RI |

### Lignes vides et ce qu'elles signifient

| Constat | Interprétation | Décision |
|---------|----------------|----------|
| Ligne 2 : un besoin sans UC ni table | C'est la description de l'existant, pas un besoin | Sert d'entrée à l'exercice de normalisation ; rien à construire |
| Lignes 13 et 14 : un UC sans table propre | Cas d'usage de **lecture** : les données existent déjà | Vues SQL, choix assumé et écrit |
| `PolitiqueAnnulation` : une classe sans table | Classe de **service**, sans état persistant | Normal ; les seuils (H2) sont de la configuration, pas des données |
| `Espace` abstraite : une classe sans table dédiée | Héritage tranché en table unique | Documenté dans `mld.md` §3 |

## 2. Parcours remontant — de chaque table à sa justification

| Table | Justifiée par | Type |
|-------|---------------|------|
| `site` | ligne 1 — « trois espaces de coworking » | Métier |
| `espace` | lignes 5, 12 — « postes libres et salles », « fermer une salle » | Métier |
| `equipement`, `salle_equipement` | ligne 5 + fiche UC-02 étape 2 (« avec leurs équipements ») ; 1FN | Métier, déduit |
| `societe` | ligne 11 — « pour les sociétés, une facture globale » | Métier |
| `utilisateur` | ligne 4 — « les coworkers créent leur compte » | Métier |
| `role`, `utilisateur_role` | lignes 4, 12, 15 — coworker, équipe d'accueil, gérant, animateur : quatre rôles nommés par le client ; 1FN | Métier, déduit de la liste des acteurs |
| `affectation` | ligne 12 — « l'équipe d'accueil » d'**un** site : portée « site » de la matrice acteur × UC | Métier, déduit de la sécurité |
| `formule` | ligne 7 — « formules Nomade, Résident, Team » | Métier |
| `tarif` | lignes 8, 9 — il y a des prix, et ils changent (historisation) | Métier |
| `abonnement` | ligne 7 — « les abonnés » : une personne est abonnée sur une période | Métier |
| `reservation` | lignes 3, 6 — « réservent », « double-réserve » | Métier |
| `remboursement` | ligne 17 — séquence détaillée UC-04 : suivi des demandes au PSP, idempotence | **Technique légitime** |
| `atelier` | ligne 15 — « on organise des ateliers » | Métier |
| `inscription` | ligne 16 — « inscription en ligne et places limitées » | Métier |
| `facture` | ligne 10 — « une facture par client » | Métier |
| `ligne_facture` | ligne 11 — « le détail par collaborateur » | Métier |

Aucune table sans phrase à gauche. Trois tables sont **déduites** plutôt que citées (équipements, rôles, affectations) ; une est **technique** (remboursements). Les quatre sont nommées ici pour qu'un relecteur puisse contester le choix plutôt que le découvrir.

## 3. Couverture des exigences non fonctionnelles

| Exigence | Où elle est rattachée | Où elle est implémentée |
|----------|-----------------------|-------------------------|
| Aucune information par la couleur seule | fiches UC-01, UC-02, UC-03 § accessibilité | statuts textuels en base (`DISPONIBLE`, `MAINTENANCE`, `complet` calculé) → libellables |
| Parcours au clavier | fiches UC-01, UC-02, UC-03 | présentation (hors dossier) ; l'architecture garde le rendu serveur possible |
| Messages d'erreur avec cause et action | fiches UC-01 (4a, 5a-E1), UC-04 (E1, E3) | contraintes **nommées** (`ex_…`, `ck_…`, `tg_…`) traduites par la couche présentation |
| Délai de 15 min prolongeable | fiche UC-01 (5a-E2), RG-09 | règle métier + `ix_reservation_en_attente`, pas un timeout de session |
| Autorisation sur l'objet (soi / périmètre / tous) | matrice acteur × UC | `affectation`, `utilisateur.id_societe`, `atelier.id_animateur` ; vérification en couche métier |
| Aucune donnée bancaire stockée | fiches UC-01, UC-02 ; acteur A6 | `remboursement.reference_psp` est un jeton, pas une carte |
| Droit à l'effacement sans perte comptable | dictionnaire §3, MPD §4 | `ON DELETE RESTRICT` vers `utilisateur` + anonymisation |
| Liste des présents = donnée sensible | fiche UC-03, acteurs (DPO) | vue dédiée, rôle base séparé, journalisation applicative |

## 4. Revue croisée — remarque / décision / justification

La revue croisée avec un autre binôme n'a pas encore eu lieu : le tableau ci-dessous est une **auto-revue** menée avec la grille en dix points du cours, en attendant les remarques du relecteur. Les lignes du relecteur s'ajouteront à la suite, avec la même discipline : « rejetée » est une décision valable si elle est écrite.

| # | Remarque (question de la grille) | Décision | Justification |
|---|----------------------------------|----------|---------------|
| 1 | *Q1 — Montre-moi la phrase du client qui justifie cette table.* Dix-huit tables quand le cours en compte onze : `role`, `utilisateur_role`, `affectation`, `equipement`, `salle_equipement`, `tarif`, `remboursement` sont-elles demandées ? | **Maintenu** | Chacune a une ligne au parcours remontant : quatre viennent de la 1FN ou de la matrice des droits, une de l'historisation, une de la séquence UC-04. Supprimer `affectation` rendrait la portée « site » inimplémentable |
| 2 | *Q6 — Cette information est-elle stockée deux fois ?* `montant_du`, `prix_unitaire` et `prix_ht` | **Maintenu** | Trois informations : prix courant, prix appliqué, prix facturé. Une facture doit rester reproductible dix ans plus tard |
| 3 | *Q5 — Où est garantie la RG-07 (quota 4 h) ?* Nulle part en base | **Assumé** | Règle dépendant du mois calendaire et de l'abonnement actif : calculée par `quota_consomme_h()`, appliquée par `TarificationService`. Un trigger la recalculerait à chaque insertion pour un gain nul |
| 4 | *Q4 — Que se passe-t-il si je supprime cette société ?* `utilisateur.id_societe` passe à `NULL` : la facture globale perd-elle ses collaborateurs ? | **Maintenu** | Non : `ligne_facture.id_utilisateur` porte le bénéficiaire et la facture est immuable ; `facture.id_societe` est en `RESTRICT`, on ne peut pas supprimer une société facturée |
| 5 | *Q9 — Deux utilisateurs font la même action en même temps.* Dernière place d'un atelier | **Maintenu** | `SELECT … FOR UPDATE` sur la ligne `atelier` dans le trigger : la seconde transaction attend, recompte, échoue proprement (T-18) |
| 6 | *Q3 — Lis-moi cette cardinalité.* HEBERGER (1,n) côté SITE n'est pas garantie | **Assumé** | Non garantissable par SQL simple (le site existe avant son premier espace). Applicatif + V-06 |
| 7 | *Q7 — Comment retrouve-t-on l'état du système à une date passée ?* Le statut d'un espace n'est pas historisé | **Assumé, dette notée** | Aucune exigence client sur l'historique des maintenances ; si le gérant veut un taux d'indisponibilité, une table `periode_maintenance` sera ajoutée |
| 8 | *Q8 — Quelles colonnes contiennent des données personnelles ?* | **Fait** | Dictionnaire §3 : nom, prénom, e-mail, téléphone, réservations (localisation indirecte), inscriptions, motif d'annulation |
| 9 | *Q2 — Qui crée la première ligne de `tarif` et de `formule` ?* | **Question ouverte Q1** | Hypothèse H1 : le gérant, par script ou back-office ; UC d'administration hors V1 |
| 10 | *Q10 — Quel choix regretterais-tu le plus dans un an ?* | — | `inscription` en relation porteuse : si les ateliers deviennent récurrents, il faudra la promouvoir en entité. Le choix est documenté dans `mcd.md` §4.1 pour que la migration soit un choix, pas une surprise |
