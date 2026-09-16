# UC-02 — Réserver une salle de réunion

| Champ | Valeur |
|-------|--------|
| **Identifiant** | UC-02 |
| **Nom** | Réserver une salle de réunion |
| **Acteur principal** | Coworker (A1) |
| **Acteurs secondaires** | Prestataire de paiement (A6) si le quota est dépassé ou en l'absence d'abonnement ; Service d'e-mailing (A7) |
| **Parties prenantes et intérêts** | Gérant : plus aucune double réservation de salle (c'est la plainte n° 1 du client), facturation exacte des dépassements. Société cliente : dépassements d'un collaborateur imputés à la société (H5). Hôte d'accueil : salle en maintenance jamais proposée. |
| **Déclencheur** | Le coworker a besoin d'une salle pour un créneau et un nombre de participants donnés |
| **Préconditions** | Authentifié ; compte actif |
| **Postconditions (succès)** | Une réservation `CONFIRMEE` existe sur une salle et un créneau exclusifs ; les heures consommées sur le quota du mois sont décomptées ; le montant du dépassement, s'il existe, est figé et autorisé ; une confirmation est partie |

## Scénario nominal

1. Le coworker indique un site, une date, un créneau et le nombre de participants.
2. Le système affiche les salles disponibles dont la capacité couvre le nombre demandé (`«include»` UC-05), avec leurs équipements.
3. Le coworker choisit une salle et demande la réservation.
4. Le système vérifie que le créneau est toujours libre (RG-04) et que la salle n'est pas en maintenance (RG-14).
5. Le système calcule les heures de quota restantes sur le mois calendaire pour l'abonnement actif (RG-07) et en déduit le montant dû pour les heures au-delà, au tarif salle en vigueur.
6. Le système enregistre la réservation au statut `CONFIRMEE` avec le montant figé.
7. Le système envoie une confirmation par e-mail (A7) mentionnant le quota restant.

## Scénarios alternatifs

- **2a. Aucune salle disponible.** Le système propose les trois créneaux libres les plus proches pour cette capacité, et les salles de capacité supérieure disponibles sur le créneau demandé → reprise en 3 ou abandon.
- **4a. Le créneau vient d'être pris.** Le système signale le conflit et réaffiche les disponibilités → reprise en 2.
- **5a. Le quota mensuel est dépassé.** Le système affiche la répartition (heures incluses / heures facturées) et le montant TTC → le coworker accepte → réservation `EN_ATTENTE` → `«extend»` UC-15 *Régler un montant dû* → autorisation obtenue → reprise en 6.
- **5b. Pas d'abonnement actif (H6).** L'intégralité du créneau est facturée au tarif salle → même parcours que 5a.
- **5c. Le coworker est rattaché à une société (H5).** Le montant dû n'est pas encaissé immédiatement : il est porté sur la facture mensuelle de la société → reprise en 6 sans passer par UC-15.

## Exceptions

- **5a-E1. Paiement refusé.** Aucune réservation confirmée ; la réservation `EN_ATTENTE` passe à `ANNULEE`, le créneau est libéré, message explicite.
- **5a-E2. Prestataire de paiement injoignable.** Réservation `EN_ATTENTE` pendant 15 min prolongeables (RG-09), puis expiration par le planificateur.
- **E3. Capacité demandée supérieure à la plus grande salle du site.** Le système le dit dès l'étape 1 et propose les autres sites.

## Règles de gestion

| Règle | Énoncé |
|-------|--------|
| RG-03 | Une réservation porte sur un seul espace et un seul utilisateur ; fin > début |
| RG-04 | Deux réservations confirmées ne se chevauchent jamais sur un même espace |
| RG-07 | Le quota de salle est de 4 h par mois calendaire et par abonnement ; au-delà, les heures sont facturées au tarif salle en vigueur ; pas de report (H7) |
| RG-09 | Réservation en attente : expiration à 15 min, prolongeable une fois |
| RG-11 | Seule une salle possède une capacité ; un poste n'en a pas |
| RG-14 | Un espace en maintenance ne peut recevoir aucune nouvelle réservation |

## Exigences non fonctionnelles

- **Performance.** Même exigence que UC-01 : vérification et insertion sous une seule transaction, RG-04 tenue par la base. Le calcul du quota lit les réservations confirmées du mois : un index partiel sur `(id_utilisateur, debut) WHERE statut = 'CONFIRMEE'` est prévu au MPD.
- **Accessibilité.** Le quota restant est annoncé en chiffres et en texte (« il vous reste 1 h 30 sur 4 h »), pas seulement par une jauge. Sélection du créneau au clavier. Les équipements d'une salle sont listés en texte, pas en pictogrammes seuls.
- **Sécurité.** Réservation pour soi uniquement. Le montant est calculé côté serveur à partir des tarifs en base, jamais repris du client. Aucune donnée bancaire stockée.
- **Données personnelles.** Identiques à UC-01.

## Fréquence et volumétrie

Trois sites, quatre salles chacun, cinq réservations par salle et par jour : environ **1 300 réservations de salle par mois**. Le calcul de quota est appelé à chaque réservation et à chaque annulation.

## Questions ouvertes

- Q5 — le quota de 4 h est-il par abonnement ou mutualisé au niveau de la société pour la formule Team ? (H5 : par abonnement)
- Q7 — report du quota non consommé ? (H7 : non)
- Le tarif salle est-il le même pour toutes les salles et tous les sites ? Hypothèse : oui, un seul tarif `SALLE_HEURE` ; la table `Tarif` permet d'en ajouter sans changer le modèle.
