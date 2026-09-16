# Acteurs et parties prenantes — CoWork'In

> Atelier 1.1. Un acteur est un **rôle** qui échange de l'information avec le système. Une personne peut cumuler plusieurs rôles (une hôtesse qui est aussi coworker le samedi) : le diagramme parle rôles, la base parle identités.

## 1. Tableau des acteurs

| Code | Acteur (rôle) | Type | Objectif vis-à-vis du système | Portée des droits | Criticité |
|------|---------------|------|-------------------------------|-------------------|-----------|
| A1 | **Coworker** | Principal · humain | Trouver un poste ou une salle, réserver, annuler, s'inscrire à un atelier, suivre sa consommation et ses factures | **Soi** : ses réservations, ses inscriptions, ses factures | Haute — c'est l'utilisateur quotidien |
| A2 | **Référent société** | Principal · humain — *spécialise A1* | Rattacher et détacher les collaborateurs de sa société, consulter la facture globale et le détail par collaborateur | **Sa société** : collaborateurs et factures de sa société uniquement | Moyenne |
| A3 | **Hôte d'accueil** | Principal · humain | Exploiter un site au quotidien : mettre un espace en maintenance, consulter les présents, annuler pour le compte d'un coworker | **Son site** : espaces, réservations et présents du ou des sites où il est affecté | Haute — accès à une donnée sensible (les présents) |
| A4 | **Gérant** | Principal · humain | Piloter l'occupation et la facturation des trois sites, relancer une clôture | **Tous sites** : lecture de toutes les données financières et d'occupation | Haute |
| A5 | **Animateur d'atelier** | Principal · humain | Proposer un atelier, suivre les inscriptions, consulter la liste des inscrits | **Ses ateliers** uniquement | Basse |
| A6 | **Prestataire de paiement** (PSP) | Secondaire · système | Autoriser, capturer ou rembourser une transaction à la demande du système | Aucune donnée de carte n'est stockée chez CoWork'In ; le PSP renvoie un jeton et un statut | Haute — point de non-retour financier |
| A7 | **Service d'e-mailing** | Secondaire · système | Acheminer confirmations, annulations, rappels et factures | Reçoit nom, e-mail et contenu du message : sous-traitant au sens RGPD, à contractualiser | Moyenne |
| A8 | **Planificateur** (le temps) | Secondaire · temps | Déclencher la clôture de facturation le 1er de chaque mois pour le mois écoulé ; expirer les réservations en attente | — | Haute — si la clôture ne part pas, personne n'est facturé |

### Tests appliqués pour classer

- **Acteur ou pas ?** « Envoie-t-il ou reçoit-il de l'information du système ? » Le DPO ne clique jamais : partie prenante. Le PSP répond à des appels : acteur.
- **Principal ou secondaire ?** « À qui le cas d'usage rend-il service ? » Le service d'e-mailing ne demande rien, il est sollicité : secondaire.
- **Un ou deux rôles ?** « Les droits diffèrent-ils ? » L'hôte voit les présents de son site, le gérant voit tout : deux rôles, même si le client dit « l'équipe ».
- **Spécialisation ?** Le référent société fait tout ce que fait un coworker, plus la gestion de ses collaborateurs : généralisation A2 → A1 sur le diagramme.

## 2. Parties prenantes non actrices

Elles n'apparaissent pas sur le diagramme de cas d'utilisation, mais leurs exigences sont reportées dans les fiches de cas d'usage (section *Parties prenantes et intérêts*).

| Partie prenante | Intérêt dans le système | Exigence à reporter | Fiches concernées |
|-----------------|-------------------------|---------------------|-------------------|
| **Société cliente** (personne morale) | Payer une facture unique et lisible, contrôler la consommation de ses collaborateurs | Facture globale avec une ligne par collaborateur ; aucun collaborateur facturé individuellement à tort | UC-08, UC-10 |
| **DPO** | Conformité RGPD : la liste des présents est une donnée de localisation indirecte | Accès restreint au rôle hôte du site, journalisation des consultations, durée de conservation courte | UC-06, UC-03 |
| **Expert-comptable** | Factures numérotées sans trou, immuables, exportables | Numérotation séquentielle par année, lignes figées (prix recopié), export CSV | UC-08 |
| **Bailleur / propriétaire des murs** | Taux d'occupation contractuel | Indicateur d'occupation calculable par site et par mois | UC-09 |
| **Coworkers non inscrits** (prospects) | Voir s'il reste de la place avant de créer un compte | Question ouverte Q4 : consultation anonyme des disponibilités ? | UC-05, UC-13 |

## 3. Candidats écartés

| Candidat | Pourquoi ce n'est pas un acteur |
|----------|---------------------------------|
| Le tableur partagé, les mails | Outils de la situation actuelle. Ils disparaissent avec le système ; le mail devient un canal porté par A7 |
| « Le client » | Terme ambigu dans le verbatim : désigne tantôt le coworker (celui qui réserve), tantôt la société (celle qui paie). Tranché par le glossaire : *Coworker* réserve, *Société* ou *Coworker* paie |
| L'administrateur technique | Personne ne le nomme dans le verbatim. Qui crée une formule, un site, un compte hôte ? **Trou identifié → Q1.** Hypothèse H1 : le Gérant porte ce rôle en V1 |
| La badgeuse / contrôle d'accès | Hors périmètre V1 ; si elle arrive, elle deviendra un acteur secondaire système pour la présence |

## 4. Questions à poser au client

Chaque question bloque une décision de conception. L'hypothèse retenue permet d'avancer ; elle est marquée dans le dossier et se lève dès la réponse.

| # | Question | Ce que ça bloque | Hypothèse retenue (H) |
|---|----------|------------------|-----------------------|
| Q1 | Qui administre le référentiel : création d'un site, d'une formule, d'un tarif, d'un compte hôte ? Y a-t-il un administrateur distinct du gérant ? | Liste des acteurs, matrice des droits, UC de paramétrage | **H1** — Le Gérant assume l'administration en V1 ; pas de rôle *Administrateur* séparé |
| Q2 | Quelle est la politique d'annulation : délai, remboursement total ou partiel, pénalité ? | UC-04, séquence système, règle RG-10, colonne `annulee_le` | **H2** — Remboursement total à plus de 24 h du début, 50 % entre 24 h et 2 h, aucun en dessous de 2 h ou après le début |
| Q3 | Comment constate-t-on la présence d'une personne : réservation en cours, pointage à l'accueil, badge ? | UC-06, vue des présents, éventuelle entité *Pointage* | **H3** — V1 : est présent quiconque a une réservation confirmée en cours sur le site ; le pointage physique est hors périmètre |
| Q4 | Les ateliers sont-ils gratuits, réservés aux titulaires d'un compte, animés par du personnel interne ou externe ? Y a-t-il une liste d'attente ? | UC-03, UC-11, entité *Atelier*, facturation des ateliers | **H4** — Gratuits, réservés aux titulaires d'un compte ; l'animateur est un utilisateur porteur du rôle A5 ; pas de liste d'attente en V1 |
| Q5 | Formule Team : combien de collaborateurs, nominatifs ou non ? Qui paie le dépassement de quota d'un collaborateur, lui ou la société ? | Rattachement Abonnement ↔ Utilisateur ou Société, destinataire des lignes de facture | **H5** — Chaque collaborateur détient son propre abonnement Team ; tout montant dû d'un collaborateur rattaché est porté sur la facture de la société |
| Q6 | Un non-abonné peut-il réserver un poste ou une salle en payant à l'heure ou à la journée ? | UC-01 alternative 5a, entité *Tarif*, extension UC-15 sur UC-01 | **H6** — Oui : le verbatim dit que les abonnés *ne paient pas* les postes, donc les autres paient |
| Q7 | Une réservation peut-elle être déplacée (reportée) plutôt qu'annulée puis recréée ? Le quota non consommé se reporte-t-il ? | Un UC *Reporter* éventuel, règle de quota | **H7** — Pas de report en V1 ; le quota est mensuel calendaire, sans report |

Les trois questions prioritaires à poser dès la prochaine réunion sont **Q2, Q3 et Q5** : ce sont celles dont la réponse change la structure de la base (colonnes d'annulation, notion de présence, destinataire des factures).
