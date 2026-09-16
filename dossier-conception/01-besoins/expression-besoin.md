# Expression de besoin — CoWork'In

> Séquence J1·1 — matière première du dossier. Tout ce qui suit dans le dossier doit pouvoir être ramené à une phrase de ce document.

## 1. Contexte et objectifs

### 1.1 Situation actuelle

CoWork'In exploite trois espaces de coworking (Lille, Roubaix, Tourcoing). La gestion repose aujourd'hui sur un tableur partagé et des échanges de mails. Conséquence mesurée par le client : au moins une double réservation de salle par semaine. La facturation de fin de mois est manuelle, et personne ne sait en temps réel qui est présent dans un bâtiment.

### 1.2 Objectifs mesurables

| # | Objectif | Indicateur de succès |
|---|----------|----------------------|
| O1 | Supprimer les doubles réservations | 0 chevauchement sur un même espace, garanti par la base (pas seulement par l'écran) |
| O2 | Donner une visibilité en temps réel des postes et salles | Disponibilité affichée en moins d'une seconde, cohérente avec la base |
| O3 | Automatiser la facturation mensuelle | Une facture par client émise le 1er du mois, sans intervention manuelle |
| O4 | Sécuriser l'exploitation des sites | Liste des présents consultable par l'accueil en moins de 10 secondes |
| O5 | Piloter l'activité | Taux d'occupation par site et par période, sans export tableur |
| O6 | Gérer les ateliers du jeudi | Inscription en ligne avec jauge respectée à la place près |

### 1.3 Périmètre

**Dans le périmètre (V1)** : comptes coworkers, catalogue des espaces (postes et salles) par site, recherche de disponibilités, réservation à l'heure ou à la journée, annulation, abonnements et quota de salle, paiement des montants dus via un prestataire, facturation mensuelle (individuelle et société), mise en maintenance d'un espace, liste des présents, tableau de bord d'occupation, ateliers et inscriptions.

**Hors périmètre explicite** :

- la comptabilité générale (export vers l'expert-comptable uniquement) ;
- le contrôle d'accès physique (badgeuse) — intégration future possible, non modélisée ;
- la gestion RH du personnel d'accueil (planning, contrats) ;
- la CRM / prospection commerciale ;
- la conservation de données bancaires : elles restent chez le prestataire de paiement.

## 2. Verbatim client

Compte rendu d'entretien, reproduit tel quel (c'est la donnée d'entrée du module, il ne doit pas être reformulé) :

> « Nous gérons trois espaces de coworking, à Lille, Roubaix et Tourcoing. Aujourd'hui tout passe par un tableur partagé et des mails : on double-réserve une salle au moins une fois par semaine.
>
> On voudrait un site où les coworkers créent leur compte, voient les postes libres et les salles de réunion en temps réel, et réservent à l'heure ou à la journée. Les abonnés — formules Nomade, Résident, Team — ne paient pas les postes, mais paient les salles au-delà de 4 h par mois.
>
> À la fin du mois, il faut sortir une facture par client ; pour les sociétés, une facture globale avec le détail par collaborateur. L'équipe d'accueil doit pouvoir fermer une salle pour maintenance et voir qui est présent en cas d'évacuation. Le gérant veut un tableau de bord du taux d'occupation par site.
>
> Ah, et on organise des ateliers le jeudi soir, avec inscription en ligne et places limitées. »

## 3. Les trois lectures

### 3.1 Lecture « Qui ? » — rôles, services externes, déclencheurs

| Extrait du verbatim | Candidat | Décision |
|---------------------|----------|----------|
| « les coworkers créent leur compte » | Coworker | Acteur principal (A1) |
| « pour les sociétés, une facture globale » | Société | Partie prenante payeuse ; le rôle humain qui interagit est le **Référent société** (A2) |
| « L'équipe d'accueil doit pouvoir fermer une salle » | Hôte d'accueil | Acteur principal (A3) |
| « Le gérant veut un tableau de bord » | Gérant | Acteur principal (A4) |
| « on organise des ateliers » | Animateur d'atelier | Acteur principal (A5) — implicite : quelqu'un propose l'atelier et a besoin de la liste des inscrits |
| « paient les salles au-delà de 4 h » | Prestataire de paiement | Acteur secondaire système (A6) — implicite : encaisser en ligne |
| « tout passe par […] des mails » | Service d'e-mailing | Acteur secondaire système (A7) — confirmations, factures |
| « À la fin du mois, il faut sortir une facture » | Le temps (planificateur) | Acteur secondaire (A8) — déclenchement périodique |
| « un tableur partagé » | — | **Écarté** : outil actuel, pas un rôle du futur système |

Le détail est dans [`acteurs.md`](acteurs.md).

### 3.2 Lecture « Quoi ? » — verbes d'action métier

| Extrait | Cas d'usage candidat | Code |
|---------|----------------------|------|
| « créent leur compte » | Créer son compte | UC-13 |
| « voient les postes libres et les salles […] en temps réel » | Consulter les disponibilités | UC-05 (inclus dans UC-01 et UC-02) |
| « réservent à l'heure ou à la journée » (postes) | Réserver un poste | UC-01 |
| « réservent […] salles de réunion » | Réserver une salle de réunion | UC-02 |
| implicite — toute réservation doit pouvoir être défaite | Annuler une réservation | UC-04 |
| « paient les salles au-delà de 4 h par mois » | Régler un montant dû | UC-15 (extension de UC-01 / UC-02) |
| « sortir une facture par client […] facture globale » | Éditer les factures mensuelles | UC-08 |
| implicite — suivre sa consommation et ses factures | Suivre sa consommation | UC-14 |
| « facture globale avec le détail par collaborateur » | Gérer les collaborateurs de sa société | UC-10 |
| « fermer une salle pour maintenance » | Mettre un espace en maintenance | UC-07 |
| « voir qui est présent en cas d'évacuation » | Consulter les présents d'un site | UC-06 |
| « tableau de bord du taux d'occupation par site » | Suivre le taux d'occupation | UC-09 |
| « on organise des ateliers » | Proposer un atelier | UC-11 |
| « inscription en ligne et places limitées » | S'inscrire à un atelier | UC-03 |
| implicite — l'animateur doit savoir qui vient | Consulter les inscrits de son atelier | UC-12 |

Aucun verbe CRUD : « modifier une réservation » est traité comme *annuler puis réserver* (question ouverte Q7 sur le report).

### 3.3 Lecture « Sur quoi ? » — noms désignant des choses persistantes

| Extrait | Candidat | Filtre des quatre questions | Décision |
|---------|----------|-----------------------------|----------|
| « trois espaces de coworking, à Lille, Roubaix et Tourcoing » | Site | durable, identifiable, dans la bouche du client, porte des horaires | **Classe** `Site` ; « ville » est un attribut |
| « postes libres », « salles de réunion » | Poste, Salle de réunion | deux natures d'unité réservable, une capacité pour la salle seulement | **Classe abstraite** `Espace` spécialisée en `Poste` et `SalleReunion` |
| « les coworkers créent leur compte » | Coworker, Compte | même objet vu sous deux angles | **Classe** `Utilisateur` ; « compte » écarté |
| « les sociétés » | Société | identifiable (SIRET), reçoit la facture | **Classe** `Societe` |
| « formules Nomade, Résident, Team » | Formule | catalogue, prix, quota | **Classe** `Formule` |
| « les abonnés » | Abonnement | un utilisateur souscrit une formule sur une période | **Classe** `Abonnement` (distincte de `Formule`) |
| « paient les salles au-delà de 4 h » | Tarif | un prix qui change dans le temps | **Classe** `Tarif` (historisation) |
| « réservent » | Réservation | identité propre, cycle de vie, se répète pour un même couple | **Classe** `Reservation` |
| « une facture par client » | Facture, Ligne de facture | immuable une fois émise, composée de lignes | **Classes** `Facture` et `LigneFacture` (composition) |
| « ateliers le jeudi soir » | Atelier | titre, date, jauge, animateur | **Classe** `Atelier` |
| « inscription en ligne » | Inscription | date, statut, appartient au couple utilisateur × atelier | **Classe d'association** `Inscription` |
| « en temps réel », « tableau de bord », « tableur », « mails », « jeudi soir » | — | non durables ou non identifiables | **Écartés** |

## 4. Hypothèses de travail et questions ouvertes

Les questions à poser au client et les hypothèses retenues en attendant sont consolidées dans [`acteurs.md`, section 4](acteurs.md#4-questions-à-poser-au-client). Les hypothèses sont référencées **H1 à H7** dans tout le dossier ; chacune est réversible tant que le MPD n'est pas figé.
