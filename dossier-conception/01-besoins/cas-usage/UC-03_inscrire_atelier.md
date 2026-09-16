# UC-03 — S'inscrire à un atelier

| Champ | Valeur |
|-------|--------|
| **Identifiant** | UC-03 |
| **Nom** | S'inscrire à un atelier du jeudi soir |
| **Acteur principal** | Coworker (A1) |
| **Acteurs secondaires** | Service d'e-mailing (A7) |
| **Parties prenantes et intérêts** | Animateur d'atelier : liste des inscrits fiable et jauge respectée à la place près. Hôte d'accueil : salle préparée pour le bon nombre de personnes. Gérant : taux de remplissage des ateliers. DPO : la liste des inscrits est une donnée personnelle. |
| **Déclencheur** | Un atelier publié intéresse le coworker |
| **Préconditions** | Authentifié ; compte actif ; l'atelier est au statut `PUBLIE` et n'a pas commencé |
| **Postconditions (succès)** | Une inscription `CONFIRMEE` existe pour le couple (coworker, atelier) ; le nombre de places restantes a diminué d'une unité ; une confirmation est partie ; l'animateur voit le nouvel inscrit |

## Scénario nominal

1. Le coworker consulte la liste des ateliers à venir.
2. Le système affiche, pour chaque atelier : titre, date et heure, animateur, salle et site, et le nombre de places restantes (places maximales moins inscriptions confirmées, RG-18).
3. Le coworker choisit un atelier et demande son inscription.
4. Le système vérifie qu'il reste au moins une place, que le coworker n'est pas déjà inscrit (RG-18) et que les inscriptions sont encore ouvertes (RG-19).
5. Le système enregistre l'inscription au statut `CONFIRMEE`, horodatée.
6. Le système envoie une confirmation par e-mail (A7) avec le lieu, l'heure et le lien d'annulation.

## Scénarios alternatifs

- **3a. Le coworker souhaite annuler une inscription existante.** Le système passe l'inscription à `ANNULEE`, la place est libérée (RG-19) → confirmation d'annulation par e-mail. Fin.
- **4a. L'atelier est complet.** Le système le dit en texte (« complet ») et propose les prochains ateliers du même animateur ou du même site → reprise en 2 ou abandon. Pas de liste d'attente en V1 (H4).
- **4b. Le coworker est déjà inscrit.** Le système l'indique et propose de consulter ou d'annuler l'inscription existante → 3a ou fin.

## Exceptions

- **E1. Dernière place prise simultanément.** Deux coworkers demandent la dernière place au même instant : le second reçoit un refus explicite et la liste est réaffichée. La jauge est garantie en base (verrou sur l'atelier + trigger), pas seulement à l'écran.
- **E2. Atelier annulé par l'animateur entre l'affichage et la demande.** Le système le signale et propose d'autres ateliers.
- **E3. Inscriptions closes.** L'atelier a commencé (RG-19) : refus, l'atelier n'apparaît plus dans la liste.

## Règles de gestion

| Règle | Énoncé |
|-------|--------|
| RG-17 | Un atelier se tient dans une salle d'un site, est animé par un utilisateur porteur du rôle Animateur et possède un nombre de places maximal strictement positif |
| RG-18 | Le nombre d'inscriptions confirmées à un atelier ne dépasse jamais son nombre de places ; un utilisateur ne détient qu'une inscription par atelier |
| RG-19 | Les inscriptions sont ouvertes de la publication jusqu'au début de l'atelier ; une annulation d'inscription libère la place |
| RG-22 | Un utilisateur désactivé ne peut pas s'inscrire |

## Exigences non fonctionnelles

- **Performance.** Décrément de la jauge atomique : l'insertion de l'inscription et le contrôle du nombre de places se font sous verrou de la ligne `ATELIER` dans la même transaction (trigger `tg_inscription_places_restantes`). Pic attendu à l'ouverture des inscriptions ; la liste des ateliers est la page la plus consultée le jeudi.
- **Accessibilité.** Les places restantes sont écrites en chiffres (« 3 places restantes »), l'état *complet* est un texte et pas seulement un bouton grisé. Toute la liste et le bouton d'inscription sont utilisables au clavier ; le message d'erreur E1 explique la cause et propose une action.
- **Sécurité.** Un coworker ne voit et n'annule que ses propres inscriptions. L'animateur ne voit que la liste de **ses** ateliers (portée « ses ateliers » dans la matrice acteur × UC). L'hôte du site voit le nombre d'inscrits, pas leurs identités, sauf pour l'évacuation (UC-06).
- **Données personnelles.** La liste des inscrits (nom, e-mail) est une donnée personnelle partagée avec l'animateur : conservation 12 mois après l'atelier, puis anonymisation de l'inscription (hypothèse à valider avec le DPO).

## Fréquence et volumétrie

Un atelier par semaine et par site, une quinzaine de places : environ **200 inscriptions par mois**, concentrées dans les heures qui suivent la publication d'un atelier. Volume faible, mais concurrence forte sur la dernière place.

## Questions ouvertes

- Q4 — les ateliers sont-ils gratuits ? ouverts aux personnes sans compte ? (H4 : gratuits, réservés aux titulaires d'un compte)
- Faut-il une liste d'attente avec promotion automatique en cas de désistement ? Non retenue en V1 ; le modèle le permet (statut `LISTE_ATTENTE` à ajouter à `Inscription`).
- Une désinscription tardive (moins de 24 h avant) doit-elle être pénalisée ? Non en V1.
