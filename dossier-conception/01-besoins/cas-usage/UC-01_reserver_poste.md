# UC-01 — Réserver un poste

| Champ | Valeur |
|-------|--------|
| **Identifiant** | UC-01 |
| **Nom** | Réserver un poste de travail |
| **Acteur principal** | Coworker (A1) — et par spécialisation le Référent société (A2) |
| **Acteurs secondaires** | Prestataire de paiement (A6) uniquement si un montant est dû ; Service d'e-mailing (A7) |
| **Parties prenantes et intérêts** | Gérant : aucun poste réservé deux fois, taux d'occupation exact. Hôte d'accueil : liste des présents fiable. Société cliente : consommation d'un collaborateur imputée sur la bonne facture. |
| **Déclencheur** | Le coworker veut travailler sur un site à une date donnée |
| **Préconditions** | Le coworker est authentifié ; son compte est actif ; il possède un abonnement actif **ou** un moyen de paiement est possible (H6) |
| **Postconditions (succès)** | Une réservation `CONFIRMEE` existe sur un poste et un créneau exclusifs ; le montant dû est calculé et figé (0 € pour un abonné) ; si un montant était dû, il a été autorisé par le PSP ; une confirmation est partie |

## Scénario nominal

1. Le coworker indique un site, une date et le mode de réservation : à l'heure (créneau début–fin) ou à la journée.
2. Le système affiche les postes disponibles sur ce créneau (`«include»` UC-05), avec leur type (flex ou dédié) et leur statut en toutes lettres.
3. Le coworker choisit un poste et demande la réservation.
4. Le système vérifie que le poste est toujours libre sur le créneau (RG-04) et qu'il n'est pas en maintenance (RG-14).
5. Le système calcule le montant dû : 0 € si le coworker a un abonnement actif à cette date (RG-06), sinon le tarif poste horaire ou journalier en vigueur (RG-06, `Tarif`).
6. Le système enregistre la réservation au statut `CONFIRMEE`, avec le montant figé (RG-03).
7. Le système envoie une confirmation par e-mail (A7), sans attendre la réponse du service.

## Scénarios alternatifs

- **1a. Réservation à la journée.** Le système fixe le créneau sur les horaires d'ouverture du site (RG-05) → reprise en 2.
- **2a. Aucun poste disponible.** Le système propose les trois créneaux libres les plus proches sur le même site, puis les autres sites à la même date → reprise en 1, ou abandon.
- **4a. Le poste vient d'être pris.** Entre l'affichage et la demande, une autre réservation a été confirmée. Le système explique le conflit et réaffiche les disponibilités → reprise en 2.
- **5a. Un montant est dû (non-abonné, H6).** Le système affiche le montant TTC et le détail du calcul et demande l'accord du coworker → le coworker accepte → le système enregistre la réservation au statut `EN_ATTENTE` → `«extend»` UC-15 *Régler un montant dû* → autorisation obtenue → reprise en 6.
- **5b. Le coworker refuse le montant.** Aucune réservation n'est créée ; le système lui propose de consulter les formules d'abonnement.

## Exceptions

- **5a-E1. Paiement refusé.** La réservation `EN_ATTENTE` passe à `ANNULEE`, le créneau est libéré, le message reprend la cause renvoyée par le PSP et l'action possible (autre moyen de paiement).
- **5a-E2. Prestataire de paiement injoignable.** La réservation reste `EN_ATTENTE` 15 minutes, prolongeables une fois par le coworker (RG-09). Passé ce délai, le planificateur (A8) l'annule et libère le créneau.
- **E3. Compte désactivé entre l'affichage et la confirmation.** Refus explicite, renvoi vers l'accueil du site (RG-22).

## Règles de gestion

| Règle | Énoncé |
|-------|--------|
| RG-03 | Une réservation porte sur un seul espace et un seul utilisateur ; sa fin est strictement postérieure à son début |
| RG-04 | Deux réservations confirmées ne se chevauchent jamais sur un même espace |
| RG-05 | Une réservation dure au moins 1 h, par pas de 30 min, et ne dépasse pas la journée d'ouverture du site |
| RG-06 | Un abonné actif ne paie pas les postes ; un non-abonné paie le tarif poste horaire ou journalier en vigueur au moment de la réservation |
| RG-09 | Une réservation en attente de paiement expire au bout de 15 min, prolongeables une fois |
| RG-14 | Un espace en maintenance ne peut recevoir aucune nouvelle réservation |
| RG-22 | Un utilisateur désactivé ne peut ni réserver ni s'inscrire |

## Exigences non fonctionnelles

- **Performance.** Affichage des disponibilités d'un site de 200 espaces en moins d'une seconde. La vérification de disponibilité et l'insertion se font dans la **même transaction** ; la RG-04 est garantie en base par une contrainte d'exclusion, le code applicatif ne sert qu'à produire un message compréhensible.
- **Accessibilité (RGAA 4.1).** La grille des créneaux se parcourt et se sélectionne au clavier seul. L'état *libre / occupé / maintenance* est porté par un libellé texte, jamais par la couleur seule. Chaque message d'erreur énonce la cause et l'action corrective (4a, 5a-E1). Le délai de 15 min est prolongeable (5a-E2), conformément au critère sur les limites de temps.
- **Sécurité.** Un coworker ne réserve que pour lui-même : l'autorisation est vérifiée dans la couche métier sur l'objet réservé, pas seulement sur le rôle. Aucune donnée de carte ne transite ni n'est stockée : le PSP renvoie un jeton. Création, confirmation et annulation sont journalisées (qui, quand).
- **Données personnelles.** La réservation est une pièce justificative de facturation : conservée 10 ans, mais rattachée à un utilisateur anonymisable (RG-22). Le motif éventuel est un champ court et non obligatoire.

## Fréquence et volumétrie

Trois sites d'environ 60 postes chacun, occupés à 60 % sur 22 jours ouvrés : de l'ordre de **2 400 réservations de poste par mois**, avec un pic le lundi entre 8 h et 9 h (jusqu'à 80 réservations dans le quart d'heure). C'est le cas d'usage le plus fréquent du système.

## Questions ouvertes

- Q6 — un non-abonné peut-il réellement réserver un poste ? (H6 : oui)
- Q7 — faut-il une réservation récurrente (« tous les mardis ») ? Non retenue en V1.
- Les postes *dédiés* de la formule Résident sont-ils attribués une fois pour toutes (pas de réservation) ou réservés comme les autres ? Hypothèse : réservés comme les autres, le type ne sert qu'au filtrage.
