# UC-04 — Annuler une réservation

| Champ | Valeur |
|-------|--------|
| **Identifiant** | UC-04 |
| **Nom** | Annuler une réservation (poste ou salle) |
| **Acteur principal** | Coworker (A1) pour ses propres réservations ; Hôte d'accueil (A3) ou Gérant (A4) pour le compte d'un coworker |
| **Acteurs secondaires** | Prestataire de paiement (A6) si un remboursement est dû ; Service d'e-mailing (A7) |
| **Parties prenantes et intérêts** | Gérant : aucun remboursement indu, créneau libéré immédiatement pour les autres. Expert-comptable : tout remboursement est tracé et rattaché à la réservation d'origine. Autres coworkers : le créneau redevient réservable. |
| **Déclencheur** | Le coworker n'a plus besoin du créneau, ou l'accueil doit libérer un espace (maintenance) |
| **Préconditions** | Authentifié ; la réservation est `CONFIRMEE` ou `EN_ATTENTE` ; elle appartient au coworker (ou l'acteur est hôte du site / gérant) ; son début n'est pas passé |
| **Postconditions (succès)** | La réservation est `ANNULEE` et horodatée ; le créneau est libéré ; les heures de salle sont recréditées sur le quota si elles y étaient imputées ; le remboursement dû selon RG-10 est demandé au PSP et référencé ; une notification est partie |

## Scénario nominal — annulation à plus de 24 h du début

1. Le coworker consulte ses réservations à venir et demande l'annulation de l'une d'elles.
2. Le système vérifie que la réservation lui appartient et qu'elle n'a pas commencé.
3. Le système applique la politique d'annulation (RG-10) : ici, remboursement total et quota recrédité. Il affiche ces conséquences et demande confirmation.
4. Le coworker confirme.
5. Le système passe la réservation au statut `ANNULEE` avec l'horodatage et libère le créneau.
6. Si un montant avait été encaissé, le système demande le remboursement au PSP (A6) et enregistre la référence de l'opération.
7. Le système envoie la confirmation d'annulation par e-mail (A7).

## Scénarios alternatifs

- **1a. Annulation par l'hôte d'accueil ou le gérant pour le compte du coworker** (par exemple une salle passée en maintenance, RG-14). Le motif est obligatoire ; le remboursement est total quel que soit le délai → reprise en 5 ; la notification indique le motif au coworker.
- **3a. Annulation entre 24 h et 2 h avant le début** — remboursement partiel. Le système calcule 50 % du montant encaissé (H2), affiche le montant remboursé et le montant conservé → reprise en 4.
- **3b. Annulation à moins de 2 h du début** — hors délai. Aucun remboursement : le montant dû reste acquis et sera facturé (H2). Le système le dit clairement → reprise en 4 ; le coworker peut renoncer à l'annulation.
- **3c. Réservation `EN_ATTENTE`** (paiement non finalisé). Aucun remboursement à traiter → reprise en 5.

## Exceptions

- **E1. Réservation déjà commencée ou terminée.** Refus explicite ; l'annulation n'est plus possible, le message renvoie vers l'accueil du site.
- **E2. Prestataire de paiement injoignable pour le remboursement.** L'annulation est enregistrée (étape 5), la demande de remboursement est mise en file et rejouée par le planificateur ; le coworker est informé du délai. Le créneau est libéré sans attendre.
- **E3. Réservation déjà annulée** (double clic, deux onglets). L'opération est idempotente : le système répond « déjà annulée » et **n'émet aucun second remboursement**.

## Règles de gestion

| Règle | Énoncé |
|-------|--------|
| RG-04 | L'annulation libère le créneau : seules les réservations `CONFIRMEE` participent à la contrainte de non-chevauchement |
| RG-07 | Les heures de salle d'une réservation annulée sont recréditées sur le quota du mois où elle avait lieu |
| RG-10 | Politique d'annulation (H2) : plus de 24 h avant le début → remboursement total ; entre 24 h et 2 h → 50 % ; moins de 2 h ou après le début → aucun remboursement, montant dû conservé. Annulation par l'exploitant → remboursement total |
| RG-14 | Une mise en maintenance signale à l'hôte les réservations confirmées sur la période, qu'il annule une à une avec motif |

## Exigences non fonctionnelles

- **Performance et fiabilité.** L'annulation (étape 5) et la demande de remboursement (étape 6) ne sont pas dans la même transaction : l'appel au PSP est externe. La réservation est annulée d'abord, puis le remboursement est journalisé avec son statut (`DEMANDE`, `EFFECTUE`, `EN_ERREUR`) et rejoué si besoin. Idempotence garantie par la clé de la réservation.
- **Accessibilité.** La conséquence financière est annoncée **avant** la confirmation, en texte (« 12,00 € vous seront remboursés, 12,00 € restent dus »). Le bouton de confirmation ne s'appuie pas sur la couleur pour distinguer « annuler la réservation » de « renoncer ».
- **Sécurité.** Autorisation sur l'objet : ce coworker peut-il annuler *cette* réservation ? Vérification en couche métier. Une annulation par l'exploitant exige un motif et est journalisée (qui, quand, pour qui, pourquoi). Aucun montant remboursé ne dépasse le montant encaissé.
- **Données personnelles.** Le motif d'annulation est un texte libre court, conservé avec la réservation ; il ne doit pas contenir de données de santé (consigne à l'écran pour l'hôte).

## Fréquence et volumétrie

Environ 10 % des réservations sont annulées : de l'ordre de **400 annulations par mois**, dont une minorité avec remboursement (les abonnés dans leur quota n'ont rien payé).

## Questions ouvertes

- Q2 — la politique d'annulation (délais, pourcentages) est une hypothèse (H2) à valider avec le client ; elle est isolée dans une classe `PolitiqueAnnulation` pour être modifiable sans toucher au reste.
- Le référent société peut-il annuler la réservation d'un collaborateur ? Hypothèse : non en V1 (portée « société » en lecture seulement).
- Un remboursement doit-il produire un avoir comptable plutôt qu'un remboursement PSP ? Question pour l'expert-comptable.
