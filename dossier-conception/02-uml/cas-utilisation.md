# Diagramme de cas d'utilisation — CoWork'In

> Atelier 1.3. Source versionnable : [`cas-utilisation.puml`](cas-utilisation.puml). Rendu : `plantuml -tsvg cas-utilisation.puml` ou collage sur <https://www.plantuml.com/plantuml>. Le diagramme est une table des matières ; le contenu est dans les [fiches](../01-besoins/cas-usage/).

## 1. La frontière

Le rectangle s'appelle **« CoWork'In — plateforme de réservation »**. Ce que nous nous engageons à construire est à l'intérieur : quinze cas d'usage regroupés en cinq paquets (Compte, Réservation, Ateliers, Exploitation du site, Facturation).

Ce qui reste dehors, volontairement : l'encaissement lui-même (chez le prestataire de paiement), l'acheminement des e-mails, la comptabilité, le contrôle d'accès physique. Ces éléments apparaissent comme acteurs secondaires ou ne figurent pas du tout.

## 2. Justification des relations

Le diagramme contient **quatre relations entre cas d'usage et deux généralisations**, pour dix-sept associations acteur–cas. On reste sous le seuil au-delà duquel un DCU devient de la décomposition fonctionnelle.

| Relation | Sens de la flèche | Pourquoi |
|----------|-------------------|----------|
| UC-01 `«include»` UC-05 | de la base (UC-01) vers l'inclus (UC-05) | On ne peut pas réserver un poste sans avoir consulté les disponibilités : factorisation **obligatoire**, présente dans deux cas de base |
| UC-02 `«include»` UC-05 | idem | Même comportement, même raison |
| UC-15 `«extend»` UC-01 `[montant dû > 0]` | de l'extension (UC-15) vers la base (UC-01) | Un abonné réserve un poste sans jamais payer : UC-01 est **complet seul**. Le règlement ne se déclenche qu'au point d'extension « montant dû > 0 » (non-abonné, H6). La base ignore son extension, donc c'est l'extension qui la désigne |
| UC-15 `«extend»` UC-02 `[montant dû > 0]` | idem | Dépassement du quota de 4 h (RG-07) ou absence d'abonnement |
| Référent société ▷ Coworker | du spécialisé vers le général | Le référent fait **strictement tout** ce que fait un coworker, plus la gestion des collaborateurs (UC-10) et la lecture des factures de sa société |
| Gérant ▷ Hôte d'accueil | idem | Le gérant fait tout ce que fait un hôte, sur **tous** les sites, plus le pilotage (UC-09) et la facturation (UC-08). C'est la traduction de la portée « tous » de la matrice |

### Ce qu'on a choisi de ne pas tracer

- **Pas de cas « Notifier par e-mail » inclus partout.** Il aurait fallu cinq flèches `«include»` supplémentaires pour une information déjà présente dans chaque fiche (étape finale « le système envoie une confirmation »). Le service d'e-mailing est relié directement, comme acteur secondaire, aux cinq cas qui se terminent par un envoi.
- **Pas de cas « S'authentifier ».** Ce n'est pas un objectif d'une session de travail ; c'est une précondition de toutes les fiches. Le tracer aurait mêlé deux niveaux de granularité.
- **Pas de cas « Consulter les inscrits » pour l'hôte.** L'hôte connaît l'effectif attendu d'un atelier via les présents (UC-06), pas via la liste nominative : c'est une restriction RGPD assumée.
- **Pas d'administration du référentiel** (créer un site, une formule, un tarif). Question Q1 ouverte ; hypothèse H1 : le gérant le fait, par une interface d'administration hors V1 fonctionnelle (données chargées par script).

## 3. Matrice acteur × cas d'usage, avec portées

Elle se lit comme la future **table des permissions**. Trois portées pour les humains : **soi** (ses propres objets), **son périmètre** (site pour l'exploitant, société pour le référent, ses ateliers pour l'animateur), **tous**. `S` marque un acteur secondaire sollicité par le système, `D` un déclencheur.

| Cas d'usage | Coworker (A1) | Référent société (A2) | Hôte d'accueil (A3) | Gérant (A4) | Animateur (A5) | PSP (A6) | E-mailing (A7) | Planificateur (A8) |
|-------------|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| UC-01 Réserver un poste | soi | soi | site ¹ | tous ¹ | — | S | S | — |
| UC-02 Réserver une salle | soi | soi | site ¹ | tous ¹ | — | S | S | — |
| UC-03 S'inscrire à un atelier | soi | soi | — | — | — | — | S | — |
| UC-04 Annuler une réservation | soi | soi | site | tous | — | S | S | — |
| UC-05 Consulter les disponibilités | soi ² | soi ² | site ² | tous ² | — | — | — | — |
| UC-06 Consulter les présents | — | — | site | tous | — | — | — | — |
| UC-07 Mettre un espace en maintenance | — | — | site | tous | — | — | — | — |
| UC-08 Éditer les factures mensuelles | — | — | — | tous (relance) | — | — | S | D |
| UC-09 Suivre le taux d'occupation | — | — | — | tous | — | — | — | — |
| UC-10 Gérer les collaborateurs | — | société | — | tous ³ | — | — | — | — |
| UC-11 Proposer un atelier | — | — | — | tous ³ | ses ateliers | — | — | — |
| UC-12 Consulter les inscrits | — | — | — | tous ³ | ses ateliers | — | — | — |
| UC-13 Créer son compte | soi | soi | — | — | — | — | S | — |
| UC-14 Suivre sa consommation et ses factures | soi | société | — | tous | — | — | — | — |
| UC-15 Régler un montant dû | soi | soi | — | — | — | S | — | — |

¹ Réservation au comptoir pour un coworker du site (l'hôte saisit pour le compte de quelqu'un ; la réservation reste rattachée au coworker).
² Inclus dans UC-01 et UC-02 : la portée est celle du cas de base.
³ Portée « tous » du gérant sur l'administration : découle de l'hypothèse H1 (le gérant administre le référentiel).

### Ce que la matrice impose à la conception

- Trois niveaux de test d'autorisation à écrire : *soi*, *périmètre*, *tous*. Ils se vérifient dans la **couche métier**, sur l'objet manipulé, jamais dans le seul contrôleur.
- La portée « site » suppose de savoir à quel site un hôte est affecté : c'est l'association `Utilisateur — Site : est affecté à` du diagramme de classes, et la table `AFFECTATION` du MLD.
- La portée « société » suppose un rattachement `Utilisateur → Societe` (0..1) et le rôle `REFERENT_SOCIETE`.
- La portée « ses ateliers » se déduit de l'association `Utilisateur — Atelier : anime`.
