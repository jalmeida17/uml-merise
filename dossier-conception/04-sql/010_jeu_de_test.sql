-- =============================================================================
-- CoWork'In — 010_jeu_de_test.sql — PostgreSQL 16
-- Jeu de données synthétique (aucune donnée réelle) qui cherche à CASSER le modèle.
-- Cinq familles : nominal, limites, nuls, volume, interdits.
-- Les INSERT volontairement invalides sont encapsulés dans des blocs DO qui
-- ÉCHOUENT si la contrainte attendue ne se déclenche pas : un test qui passe
-- alors qu'il devrait échouer ne prouve rien.
-- Exécution : psql -v ON_ERROR_STOP=1 -f 010_jeu_de_test.sql
-- Prérequis : 001_schema.sql puis 002_contraintes.sql.
-- =============================================================================

BEGIN;

-- 1. Référentiels ---------------------------------------------------------------

INSERT INTO site (id_site, nom, ville, adresse, heure_ouverture, heure_fermeture) OVERRIDING SYSTEM VALUE VALUES
  (1, 'CoWork''In Lille Centre', 'Lille',     '12 rue Faidherbe, 59000 Lille',        '08:00', '20:00'),
  (2, 'CoWork''In Roubaix',      'Roubaix',   '3 grande rue, 59100 Roubaix',          '08:00', '19:00'),
  (3, 'CoWork''In Tourcoing',    'Tourcoing', '8 rue de Tournai, 59200 Tourcoing',    '08:30', '19:00');

INSERT INTO equipement (code_equipement, libelle) VALUES
  ('ECRAN',   'Écran mural'),
  ('VISIO',   'Visioconférence'),
  ('TABLEAU', 'Tableau blanc');

INSERT INTO societe (id_societe, raison_sociale, siret, adresse_facturation, email_facturation) OVERRIDING SYSTEM VALUE VALUES
  (1, 'Nordwave SAS',      '83254789600017', '4 place du Théâtre, 59000 Lille',  'compta@nordwave.example'),
  (2, 'Atelier Bleu SARL', '91234567800021', '17 rue Nationale, 59800 Lille',    'facture@atelierbleu.example');

INSERT INTO role (code_role, libelle) VALUES
  ('COWORKER',         'Coworker'),
  ('REFERENT_SOCIETE', 'Référent société'),
  ('HOTE_ACCUEIL',     'Hôte d''accueil'),
  ('GERANT',           'Gérant'),
  ('ANIMATEUR',        'Animateur d''atelier');

INSERT INTO formule (code_formule, libelle, quota_salle_h, actif) VALUES
  ('NOMADE',   'Nomade',   4, true),
  ('RESIDENT', 'Résident', 4, true),
  ('TEAM',     'Team',     4, true);

-- Tarifs : l'historique 2025 de NOMADE montre l'historisation ; date_fin NULL = en vigueur.
INSERT INTO tarif (code_formule, prestation, prix_ht, date_debut, date_fin) VALUES
  ('NOMADE',   'ABONNEMENT_MENSUEL', 139.00, '2025-01-01', '2025-12-31'),
  ('NOMADE',   'ABONNEMENT_MENSUEL', 149.00, '2026-01-01', NULL),
  ('RESIDENT', 'ABONNEMENT_MENSUEL', 249.00, '2026-01-01', NULL),
  ('TEAM',     'ABONNEMENT_MENSUEL', 199.00, '2026-01-01', NULL),
  (NULL,       'POSTE_HEURE',          4.00, '2026-01-01', NULL),
  (NULL,       'POSTE_JOUR',          25.00, '2026-01-01', NULL),
  (NULL,       'SALLE_HEURE',         15.00, '2026-01-01', NULL);

-- 2. Espaces ----------------------------------------------------------------------
-- Lille : 5 postes (dont 1 dédié), 2 salles (S-B en maintenance). Roubaix : 2 postes, 1 salle. Tourcoing : 1 poste.
INSERT INTO espace (id_espace, id_site, code, type_espace, type_poste, capacite, statut) OVERRIDING SYSTEM VALUE VALUES
  (1,  1, 'P-01', 'POSTE', 'FLEX',  NULL, 'DISPONIBLE'),
  (2,  1, 'P-02', 'POSTE', 'FLEX',  NULL, 'DISPONIBLE'),
  (3,  1, 'P-03', 'POSTE', 'FLEX',  NULL, 'DISPONIBLE'),
  (4,  1, 'P-04', 'POSTE', 'FLEX',  NULL, 'DISPONIBLE'),
  (5,  1, 'P-05', 'POSTE', 'DEDIE', NULL, 'DISPONIBLE'),
  (6,  1, 'S-A',  'SALLE', NULL,    8,    'DISPONIBLE'),
  (7,  1, 'S-B',  'SALLE', NULL,    4,    'MAINTENANCE'),
  (8,  2, 'P-01', 'POSTE', 'FLEX',  NULL, 'DISPONIBLE'),   -- même code P-01 qu'à Lille : unique PAR SITE (RG-21)
  (9,  2, 'P-02', 'POSTE', 'FLEX',  NULL, 'DISPONIBLE'),
  (10, 2, 'S-A',  'SALLE', NULL,    6,    'DISPONIBLE'),
  (11, 3, 'P-01', 'POSTE', 'FLEX',  NULL, 'DISPONIBLE');

INSERT INTO salle_equipement (id_espace, code_equipement) VALUES
  (6, 'ECRAN'), (6, 'VISIO'), (6, 'TABLEAU'),
  (7, 'TABLEAU');
  -- cas nul : la salle 10 (Roubaix S-A) n'a aucun équipement

-- 3. Utilisateurs, rôles, affectations, abonnements -----------------------------
INSERT INTO utilisateur (id_utilisateur, id_societe, nom, prenom, email, telephone, actif, cree_le) OVERRIDING SYSTEM VALUE VALUES
  (1, NULL, 'Benali',   'Salma',  'salma.benali@example.org',   '+33 6 12 34 56 78', true,  '2026-01-15 10:02+01'),
  (2, 1,    'Lefebvre', 'Karim',  'karim.lefebvre@nordwave.example', NULL,           true,  '2026-01-20 09:15+01'),
  (3, 1,    'Dubois',   'Inès',   'ines.dubois@nordwave.example',    NULL,           true,  '2026-01-20 09:20+01'),
  (4, NULL, 'Martin',   'Thomas', 'thomas.martin@example.org',  NULL,                true,  '2026-02-03 18:40+01'),
  (5, NULL, 'Roussel',  'Nadia',  'nadia.roussel@coworkin.example', '+33 3 20 00 00 01', true, '2026-01-02 08:00+01'),
  (6, NULL, 'Petit',    'Yann',   'yann.petit@example.org',     NULL,                true,  '2026-01-10 12:00+01'),
  (7, NULL, 'Moreau',   'Léa',    'lea.moreau@example.org',     NULL,                false, '2025-09-01 10:00+02');   -- compte désactivé (RG-22)

INSERT INTO utilisateur_role (id_utilisateur, code_role) VALUES
  (1, 'COWORKER'), (1, 'HOTE_ACCUEIL'),          -- Salma : hôtesse ET coworker — deux rôles, une ligne utilisateur
  (2, 'COWORKER'), (2, 'REFERENT_SOCIETE'),
  (3, 'COWORKER'),
  (4, 'COWORKER'),                                -- Thomas : non-abonné (H6)
  (5, 'COWORKER'), (5, 'GERANT'),
  (6, 'COWORKER'), (6, 'ANIMATEUR'),
  (7, 'COWORKER');

INSERT INTO affectation (id_utilisateur, id_site) VALUES
  (1, 1),                     -- Salma est affectée à Lille : portée "site"
  (5, 1), (5, 2), (5, 3);     -- la gérante voit les trois sites

INSERT INTO abonnement (id_abonnement, id_utilisateur, code_formule, date_debut, date_fin) OVERRIDING SYSTEM VALUE VALUES
  (1, 1, 'NOMADE',   '2025-06-01', '2025-12-31'),   -- historique : Salma était Nomade en 2025…
  (2, 1, 'NOMADE',   '2026-01-01', NULL),           -- …et l'est toujours en 2026 (périodes disjointes : RG-08 respectée)
  (3, 2, 'TEAM',     '2026-02-01', NULL),
  (4, 3, 'TEAM',     '2026-02-01', NULL),
  (5, 6, 'RESIDENT', '2026-01-15', NULL);
  -- cas nul : Thomas (4) et Nadia (5) n'ont pas d'abonnement

-- 4. Réservations -------------------------------------------------------------------
-- Février 2026 (facturé) et mars 2026 (en cours). Offsets +01 : heure d'hiver.
INSERT INTO reservation (id_reservation, id_utilisateur, id_espace, debut, fin, statut, montant_du, cree_le, annulee_le, motif_annulation) OVERRIDING SYSTEM VALUE VALUES
  -- février : entrées de la facturation
  (9,  2, 6, '2026-02-05 09:00+01', '2026-02-05 14:00+01', 'CONFIRMEE', 15.00, '2026-02-01 10:00+01', NULL, NULL),  -- Karim, 5 h de salle : 1 h au-delà du quota (RG-07)
  (10, 3, 1, '2026-02-06 09:00+01', '2026-02-06 12:00+01', 'CONFIRMEE',  0.00, '2026-02-02 10:00+01', NULL, NULL),  -- Inès, poste, abonnée : gratuit (RG-06)
  (11, 4, 1, '2026-02-10 09:00+01', '2026-02-10 13:00+01', 'CONFIRMEE', 16.00, '2026-02-09 18:00+01', NULL, NULL),  -- Thomas, non-abonné : 4 h x 4 €
  -- mars : cas nominal et cas limites
  (1,  1, 6, '2026-03-10 09:00+01', '2026-03-10 11:00+01', 'CONFIRMEE',  0.00, '2026-03-02 14:11+01', NULL, NULL),  -- nominal : Salma, salle, 2 h dans le quota
  (2,  2, 6, '2026-03-10 11:00+01', '2026-03-10 12:00+01', 'CONFIRMEE',  0.00, '2026-03-03 09:00+01', NULL, NULL),  -- LIMITE : bornes jointives avec la 1 → doit passer
  (3,  1, 6, '2026-03-17 14:00+01', '2026-03-17 17:00+01', 'CONFIRMEE', 15.00, '2026-03-05 09:30+01', NULL, NULL),  -- Salma : 3 h de plus → 5 h en mars → 1 h facturée
  (4,  4, 1, '2026-03-10 09:00+01', '2026-03-10 18:00+01', 'CONFIRMEE', 25.00, '2026-03-09 20:00+01', NULL, NULL),  -- Thomas : poste à la journée (RG-05, tarif POSTE_JOUR)
  (5,  3, 2, '2026-03-11 09:00+01', '2026-03-11 12:00+01', 'CONFIRMEE',  0.00, '2026-03-10 08:00+01', NULL, NULL),
  (6,  1, 3, '2026-03-12 09:00+01', '2026-03-12 10:00+01', 'ANNULEE',    0.00, '2026-03-01 09:00+01', '2026-03-11 08:00+01', 'Empêchement'),                -- annulée > 24 h : rien à rembourser
  (7,  4, 8, '2026-03-13 10:00+01', '2026-03-13 12:00+01', 'ANNULEE',    8.00, '2026-03-11 09:00+01', '2026-03-12 20:00+01', 'Déplacement annulé'),        -- annulée 14 h avant : remboursement partiel 50 % (H2)
  (8,  4, 10,'2026-03-20 09:00+01', '2026-03-20 10:00+01', 'EN_ATTENTE', 15.00, '2026-03-16 17:50+01', NULL, NULL);                                         -- en attente de paiement (RG-09)

-- Remboursement partiel de la réservation 7 : 50 % de 8,00 € (RG-10)
INSERT INTO remboursement (id_reservation, montant, statut, reference_psp, demande_le, effectue_le) VALUES
  (7, 4.00, 'EFFECTUE', 'rf_TEST_0001', '2026-03-12 20:00+01', '2026-03-12 20:00+01');

-- 5. Ateliers et inscriptions ---------------------------------------------------------
INSERT INTO atelier (id_atelier, id_espace, id_animateur, titre, description, debut, fin, places_max, statut) OVERRIDING SYSTEM VALUE VALUES
  (1, 6,  6, 'Introduction à PostgreSQL',      'Premiers pas : tables, clés, contraintes.',  '2026-03-12 18:30+01', '2026-03-12 20:30+01', 3,  'PUBLIE'),   -- jauge volontairement petite
  (2, 10, 6, 'Atelier pitch',                  NULL,                                          '2026-03-19 18:30+01', '2026-03-19 20:00+01', 10, 'PUBLIE'),   -- cas nul : aucun inscrit
  (3, 6,  6, 'Accessibilité web : les bases',  NULL,                                          '2026-04-02 18:30+02', '2026-04-02 20:30+02', 12, 'BROUILLON');

INSERT INTO inscription (id_utilisateur, id_atelier, date_inscription, statut) VALUES
  (1, 1, '2026-03-01 19:04+01', 'CONFIRMEE'),
  (2, 1, '2026-03-01 19:10+01', 'CONFIRMEE'),
  (3, 1, '2026-03-02 08:00+01', 'ANNULEE'),      -- Inès s'est désinscrite : sa place est libérée
  (4, 1, '2026-03-02 09:30+01', 'CONFIRMEE');    -- 3 confirmées sur 3 : l'atelier 1 est COMPLET

-- 6. Factures de février (émises le 1er mars) ----------------------------------------
INSERT INTO facture (id_facture, id_utilisateur, id_societe, numero, periode, date_emission, statut) OVERRIDING SYSTEM VALUE VALUES
  (1, NULL, 1,    '2026-000001', '2026-02-01', '2026-03-01', 'EMISE'),    -- facture GLOBALE société Nordwave (RG-12)
  (2, 4,    NULL, '2026-000002', '2026-02-01', '2026-03-01', 'EMISE'),    -- Thomas, non-abonné
  (3, 1,    NULL, '2026-000003', '2026-02-01', '2026-03-01', 'PAYEE'),    -- Salma, abonnement
  (4, NULL, 1,    '2026-000004', '2026-03-01', NULL,         'BROUILLON');-- brouillon de mars : encore modifiable

-- Les lignes sont insérées AVANT que la facture soit émise dans la vraie vie ; ici la facture est déjà EMISE,
-- on passe donc par un brouillon temporaire pour respecter le trigger RG-13.
UPDATE facture SET statut = 'BROUILLON' WHERE id_facture IN (1, 2, 3);

INSERT INTO ligne_facture (id_facture, num_ligne, id_utilisateur, id_reservation, libelle, quantite, unite, prix_unitaire) VALUES
  -- facture société : détail PAR COLLABORATEUR (RG-12), libellés et prix RECOPIÉS (RG-13)
  (1, 1, 2, NULL, 'Abonnement Team — février 2026 — Karim Lefebvre',                     1.00, 'MOIS',  199.00),
  (1, 2, 3, NULL, 'Abonnement Team — février 2026 — Inès Dubois',                        1.00, 'MOIS',  199.00),
  (1, 3, 2, 9,    'Salle S-A Lille — 05/02 09:00–14:00 — dépassement de quota — K. Lefebvre', 1.00, 'HEURE', 15.00),
  -- facture individuelle : poste à l'heure
  (2, 1, 4, 11,   'Poste P-01 Lille — 10/02 09:00–13:00 — non-abonné',                   4.00, 'HEURE',   4.00),
  -- abonnement Nomade
  (3, 1, 1, NULL, 'Abonnement Nomade — février 2026',                                    1.00, 'MOIS',  149.00);

UPDATE facture SET statut = 'EMISE' WHERE id_facture IN (1, 2);
UPDATE facture SET statut = 'PAYEE' WHERE id_facture = 3;

-- 7. Resynchronisation des séquences après les insertions à identifiant explicite ---
-- Indispensable AVANT toute insertion sans identifiant explicite (section 8 et tests T-xx).
SELECT setval(pg_get_serial_sequence('site',        'id_site'),        (SELECT MAX(id_site)        FROM site));
SELECT setval(pg_get_serial_sequence('societe',     'id_societe'),     (SELECT MAX(id_societe)     FROM societe));
SELECT setval(pg_get_serial_sequence('espace',      'id_espace'),      (SELECT MAX(id_espace)      FROM espace));
SELECT setval(pg_get_serial_sequence('utilisateur', 'id_utilisateur'), (SELECT MAX(id_utilisateur) FROM utilisateur));
SELECT setval(pg_get_serial_sequence('abonnement',  'id_abonnement'),  (SELECT MAX(id_abonnement)  FROM abonnement));
SELECT setval(pg_get_serial_sequence('reservation', 'id_reservation'), (SELECT MAX(id_reservation) FROM reservation));
SELECT setval(pg_get_serial_sequence('atelier',     'id_atelier'),     (SELECT MAX(id_atelier)     FROM atelier));
SELECT setval(pg_get_serial_sequence('facture',     'id_facture'),     (SELECT MAX(id_facture)     FROM facture));

-- 8. Cas de volume ----------------------------------------------------------------------
-- 40 postes supplémentaires à Tourcoing et une réservation par poste et par jour ouvré d'avril 2026 (~880 lignes).
-- C'est ici que les index manquants se verraient. Aucun chevauchement par construction.
INSERT INTO espace (id_site, code, type_espace, type_poste, statut)
SELECT 3, 'V-' || lpad(g::TEXT, 3, '0'), 'POSTE', 'FLEX', 'DISPONIBLE'
FROM generate_series(1, 40) AS g;

INSERT INTO reservation (id_utilisateur, id_espace, debut, fin, statut, montant_du, cree_le)
SELECT 1 + (e.id_espace % 3),                                   -- rotation Salma / Karim / Inès
       e.id_espace,
       (d::DATE + TIME '09:00') AT TIME ZONE 'Europe/Paris',
       (d::DATE + TIME '12:00') AT TIME ZONE 'Europe/Paris',
       'CONFIRMEE',
       0.00,
       (d::DATE - 1) AT TIME ZONE 'Europe/Paris'
FROM espace e
CROSS JOIN generate_series('2026-04-01'::DATE, '2026-04-30'::DATE, INTERVAL '1 day') AS d
WHERE e.id_site = 3 AND e.code LIKE 'V-%'
  AND EXTRACT(ISODOW FROM d) BETWEEN 1 AND 5;

COMMIT;

-- =============================================================================
-- 9. CAS INTERDITS — chaque bloc ÉCHOUE si l'INSERT est accepté.
--    Le NOTICE affiche le nom de la contrainte qui a rejeté la ligne.
-- =============================================================================

-- T-04 : chevauchement sur la salle S-A le 10/03 (10:00–11:30 recouvre 09:00–11:00) → ex_reservation_pas_de_chevauchement
DO $$
BEGIN
  INSERT INTO reservation (id_utilisateur, id_espace, debut, fin, statut)
  VALUES (3, 6, '2026-03-10 10:00+01', '2026-03-10 11:30+01', 'CONFIRMEE');
  RAISE EXCEPTION 'T-04 ÉCHEC : le chevauchement a été accepté';
EXCEPTION WHEN exclusion_violation THEN
  RAISE NOTICE 'T-04 OK — rejeté par % : %', 'ex_reservation_pas_de_chevauchement', SQLERRM;
END $$;

-- T-04b : le même créneau sur une réservation ANNULÉE ne bloque pas → doit PASSER (la contrainte est partielle)
DO $$
BEGIN
  INSERT INTO reservation (id_utilisateur, id_espace, debut, fin, statut)
  VALUES (3, 3, '2026-03-12 09:00+01', '2026-03-12 10:00+01', 'CONFIRMEE');   -- la 6 (annulée) occupait ce créneau
  RAISE NOTICE 'T-04b OK — un créneau libéré par une annulation est de nouveau réservable';
END $$;

-- T-03 : fin avant début → ck_reservation_fin_apres_debut (ou ck_reservation_duree_minimale, évaluée avant par ordre alphabétique : les deux sont violées)
DO $$
BEGIN
  INSERT INTO reservation (id_utilisateur, id_espace, debut, fin, statut)
  VALUES (1, 1, '2026-03-25 11:00+01', '2026-03-25 10:00+01', 'CONFIRMEE');
  RAISE EXCEPTION 'T-03 ÉCHEC : fin < début acceptée';
EXCEPTION WHEN check_violation THEN
  RAISE NOTICE 'T-03 OK — rejeté : %', SQLERRM;
END $$;

-- T-05 : durée de 45 min → ck_reservation_duree_minimale
DO $$
BEGIN
  INSERT INTO reservation (id_utilisateur, id_espace, debut, fin, statut)
  VALUES (1, 1, '2026-03-25 10:00+01', '2026-03-25 10:45+01', 'CONFIRMEE');
  RAISE EXCEPTION 'T-05 ÉCHEC : durée < 1 h acceptée';
EXCEPTION WHEN check_violation THEN
  RAISE NOTICE 'T-05 OK — rejeté : %', SQLERRM;
END $$;

-- T-14 : réservation sur S-B, en maintenance → tg_reservation_espace_disponible
DO $$
BEGIN
  INSERT INTO reservation (id_utilisateur, id_espace, debut, fin, statut)
  VALUES (1, 7, '2026-03-25 10:00+01', '2026-03-25 11:00+01', 'CONFIRMEE');
  RAISE EXCEPTION 'T-14 ÉCHEC : réservation acceptée sur un espace en maintenance';
EXCEPTION WHEN check_violation THEN
  RAISE NOTICE 'T-14 OK — rejeté : %', SQLERRM;
END $$;

-- T-11 : un poste avec une capacité → ck_espace_capacite_si_salle
DO $$
BEGIN
  INSERT INTO espace (id_site, code, type_espace, type_poste, capacite) VALUES (1, 'P-99', 'POSTE', 'FLEX', 4);
  RAISE EXCEPTION 'T-11 ÉCHEC : capacité acceptée sur un poste';
EXCEPTION WHEN check_violation THEN
  RAISE NOTICE 'T-11 OK — rejeté : %', SQLERRM;
END $$;

-- T-21 : code P-01 déjà utilisé à Lille → uq_espace_code_par_site
DO $$
BEGIN
  INSERT INTO espace (id_site, code, type_espace, type_poste) VALUES (1, 'P-01', 'POSTE', 'FLEX');
  RAISE EXCEPTION 'T-21 ÉCHEC : code d''espace dupliqué sur le même site accepté';
EXCEPTION WHEN unique_violation THEN
  RAISE NOTICE 'T-21 OK — rejeté : %', SQLERRM;
END $$;

-- T-01 : même e-mail avec une casse différente → uq_utilisateur_email_lower
DO $$
BEGIN
  INSERT INTO utilisateur (nom, prenom, email) VALUES ('Benali', 'Salma', 'SALMA.BENALI@Example.org');
  RAISE EXCEPTION 'T-01 ÉCHEC : doublon d''e-mail accepté';
EXCEPTION WHEN unique_violation THEN
  RAISE NOTICE 'T-01 OK — rejeté : %', SQLERRM;
END $$;

-- T-08 : deuxième abonnement actif pour Salma → ex_abonnement_un_seul_actif
DO $$
BEGIN
  INSERT INTO abonnement (id_utilisateur, code_formule, date_debut, date_fin) VALUES (1, 'RESIDENT', '2026-06-01', NULL);
  RAISE EXCEPTION 'T-08 ÉCHEC : abonnements chevauchants acceptés';
EXCEPTION WHEN exclusion_violation THEN
  RAISE NOTICE 'T-08 OK — rejeté : %', SQLERRM;
END $$;

-- T-18 : quatrième inscription confirmée sur un atelier de 3 places → tg_inscription_places_restantes
DO $$
BEGIN
  INSERT INTO inscription (id_utilisateur, id_atelier) VALUES (5, 1);
  RAISE EXCEPTION 'T-18 ÉCHEC : inscription acceptée sur un atelier complet';
EXCEPTION WHEN check_violation THEN
  RAISE NOTICE 'T-18 OK — rejeté : %', SQLERRM;
END $$;

-- T-18b : la même personne deux fois sur le même atelier → pk_inscription
DO $$
BEGIN
  INSERT INTO inscription (id_utilisateur, id_atelier) VALUES (1, 2);
  INSERT INTO inscription (id_utilisateur, id_atelier) VALUES (1, 2);
  RAISE EXCEPTION 'T-18b ÉCHEC : double inscription acceptée';
EXCEPTION WHEN unique_violation THEN
  RAISE NOTICE 'T-18b OK — rejeté : %', SQLERRM;
END $$;

-- T-19 : inscription sur un atelier BROUILLON → tg_inscription_places_restantes (RG-19)
DO $$
BEGIN
  INSERT INTO inscription (id_utilisateur, id_atelier) VALUES (1, 3);
  RAISE EXCEPTION 'T-19 ÉCHEC : inscription acceptée sur un atelier non publié';
EXCEPTION WHEN check_violation THEN
  RAISE NOTICE 'T-19 OK — rejeté : %', SQLERRM;
END $$;

-- T-17 : un atelier dans un poste → tg_atelier_salle_et_animateur
DO $$
BEGIN
  INSERT INTO atelier (id_espace, id_animateur, titre, debut, fin, places_max, statut)
  VALUES (1, 6, 'Atelier dans un poste', '2026-05-07 18:30+02', '2026-05-07 20:00+02', 5, 'PUBLIE');
  RAISE EXCEPTION 'T-17 ÉCHEC : atelier accepté dans un poste';
EXCEPTION WHEN check_violation THEN
  RAISE NOTICE 'T-17 OK — rejeté : %', SQLERRM;
END $$;

-- T-17b : animateur sans le rôle ANIMATEUR (Thomas) → tg_atelier_salle_et_animateur
DO $$
BEGIN
  INSERT INTO atelier (id_espace, id_animateur, titre, debut, fin, places_max, statut)
  VALUES (6, 4, 'Atelier sans animateur habilité', '2026-05-07 18:30+02', '2026-05-07 20:00+02', 5, 'PUBLIE');
  RAISE EXCEPTION 'T-17b ÉCHEC : animateur non habilité accepté';
EXCEPTION WHEN check_violation THEN
  RAISE NOTICE 'T-17b OK — rejeté : %', SQLERRM;
END $$;

-- T-12 : facture adressée à un utilisateur ET une société → ck_facture_destinataire_unique
DO $$
BEGIN
  INSERT INTO facture (id_utilisateur, id_societe, numero, periode) VALUES (2, 1, '2026-999999', '2026-03-01');
  RAISE EXCEPTION 'T-12 ÉCHEC : deux destinataires acceptés';
EXCEPTION WHEN check_violation THEN
  RAISE NOTICE 'T-12 OK — rejeté : %', SQLERRM;
END $$;

-- T-20 : deuxième facture de février pour Thomas → uq_facture_utilisateur_periode
DO $$
BEGIN
  INSERT INTO facture (id_utilisateur, id_societe, numero, periode) VALUES (4, NULL, '2026-999998', '2026-02-01');
  RAISE EXCEPTION 'T-20 ÉCHEC : deux factures pour la même période acceptées';
EXCEPTION WHEN unique_violation THEN
  RAISE NOTICE 'T-20 OK — rejeté : %', SQLERRM;
END $$;

-- T-13 : modifier une facture émise → tg_facture_immuable
DO $$
BEGIN
  UPDATE facture SET numero = '2026-000099' WHERE id_facture = 1;
  RAISE EXCEPTION 'T-13 ÉCHEC : facture émise modifiée';
EXCEPTION WHEN check_violation THEN
  RAISE NOTICE 'T-13 OK — rejeté : %', SQLERRM;
END $$;

-- T-13b : ajouter une ligne à une facture émise → tg_ligne_facture_immuable
DO $$
BEGIN
  INSERT INTO ligne_facture (id_facture, num_ligne, id_utilisateur, libelle, quantite, unite, prix_unitaire)
  VALUES (1, 9, 2, 'Ligne ajoutée après émission', 1, 'HEURE', 1.00);
  RAISE EXCEPTION 'T-13b ÉCHEC : ligne ajoutée à une facture émise';
EXCEPTION WHEN check_violation THEN
  RAISE NOTICE 'T-13b OK — rejeté : %', SQLERRM;
END $$;

-- T-13c : supprimer une facture émise → tg_facture_immuable
DO $$
BEGIN
  DELETE FROM facture WHERE id_facture = 2;
  RAISE EXCEPTION 'T-13c ÉCHEC : facture émise supprimée';
EXCEPTION WHEN check_violation THEN
  RAISE NOTICE 'T-13c OK — rejeté : %', SQLERRM;
END $$;

-- T-10 : rembourser plus que le montant dû (réservation 7 : 8,00 € dus, 4,00 € déjà remboursés) → tg_remboursement_plafond
DO $$
BEGIN
  INSERT INTO remboursement (id_reservation, montant, statut) VALUES (7, 5.00, 'DEMANDE');
  RAISE EXCEPTION 'T-10 ÉCHEC : remboursement supérieur au montant dû accepté';
EXCEPTION WHEN check_violation THEN
  RAISE NOTICE 'T-10 OK — rejeté : %', SQLERRM;
END $$;

-- T-10b : rembourser une réservation non annulée → tg_remboursement_plafond
DO $$
BEGIN
  INSERT INTO remboursement (id_reservation, montant, statut) VALUES (3, 5.00, 'DEMANDE');
  RAISE EXCEPTION 'T-10b ÉCHEC : remboursement accepté sur une réservation confirmée';
EXCEPTION WHEN check_violation THEN
  RAISE NOTICE 'T-10b OK — rejeté : %', SQLERRM;
END $$;

-- T-RI : supprimer un utilisateur qui a des réservations → fk_reservation_utilisateur (RESTRICT, pas CASCADE)
DO $$
BEGIN
  DELETE FROM utilisateur WHERE id_utilisateur = 4;
  RAISE EXCEPTION 'T-RI ÉCHEC : utilisateur supprimé avec son historique';
EXCEPTION WHEN foreign_key_violation THEN
  RAISE NOTICE 'T-RI OK — rejeté : % (la bonne réponse métier est actif = false)', SQLERRM;
END $$;

-- T-CASCADE : supprimer un BROUILLON supprime ses lignes (la seule cascade voulue) → doit PASSER
DO $$
DECLARE v_lignes INTEGER;
BEGIN
  INSERT INTO ligne_facture (id_facture, num_ligne, id_utilisateur, libelle, quantite, unite, prix_unitaire)
  VALUES (4, 1, 2, 'Ligne de brouillon', 1, 'MOIS', 199.00);
  DELETE FROM facture WHERE id_facture = 4;
  SELECT COUNT(*) INTO v_lignes FROM ligne_facture WHERE id_facture = 4;
  IF v_lignes <> 0 THEN RAISE EXCEPTION 'T-CASCADE ÉCHEC : lignes orphelines'; END IF;
  RAISE NOTICE 'T-CASCADE OK — brouillon supprimé avec ses lignes';
END $$;

-- =============================================================================
-- 10. REQUÊTES DE VÉRIFICATION MÉTIER (V-01 à V-09)
-- =============================================================================

-- V-01 : aucune paire de réservations confirmées ne se chevauche → 0 ligne attendue
SELECT 'V-01 chevauchements confirmés (attendu : 0)' AS verification, COUNT(*) AS resultat
FROM reservation a
JOIN reservation b ON b.id_espace = a.id_espace AND b.id_reservation > a.id_reservation
WHERE a.statut = 'CONFIRMEE' AND b.statut = 'CONFIRMEE'
  AND tstzrange(a.debut, a.fin) && tstzrange(b.debut, b.fin);

-- V-02 : quota de salle consommé en mars par abonnement (RG-07) — Salma (abonnement 2) : 5 h, donc 1 h facturée
SELECT 'V-02 quota mars' AS verification, a.id_abonnement, u.prenom, f.quota_salle_h,
       quota_consomme_h(a.id_abonnement, '2026-03-01') AS heures_consommees,
       GREATEST(quota_consomme_h(a.id_abonnement, '2026-03-01') - f.quota_salle_h, 0) AS heures_facturables
FROM abonnement a
JOIN utilisateur u ON u.id_utilisateur = a.id_utilisateur
JOIN formule f ON f.code_formule = a.code_formule
WHERE a.date_fin IS NULL
ORDER BY a.id_abonnement;

-- V-03 : places restantes (RG-18) — atelier 1 : 0 (complet), atelier 2 : 10
SELECT 'V-03 places restantes' AS verification, a.id_atelier, a.titre, a.places_max, places_restantes(a.id_atelier) AS restantes
FROM atelier a ORDER BY a.id_atelier;

-- V-04 : présents à Lille le 10/03 à 10:30 (même logique que v_presents_par_site, à instant fixé) — Salma en S-A, Thomas en P-01
SELECT 'V-04 présents Lille 10/03 10:30' AS verification, u.prenom, u.nom, e.code, r.debut, r.fin
FROM reservation r
JOIN espace e ON e.id_espace = r.id_espace
JOIN utilisateur u ON u.id_utilisateur = r.id_utilisateur
WHERE e.id_site = 1 AND r.statut = 'CONFIRMEE'
  AND r.debut <= '2026-03-10 10:30+01' AND '2026-03-10 10:30+01' < r.fin
ORDER BY e.code;

-- V-05 : totaux de factures calculés (jamais stockés) — 2026-000001 : 413,00 ; 000002 : 16,00 ; 000003 : 149,00
SELECT 'V-05 totaux factures' AS verification, numero, statut, nb_lignes, total_ht
FROM v_facture_total ORDER BY numero;

-- V-06 : cardinalité (1,n) HEBERGER non garantissable en SQL — sites sans espace (attendu : 0)
SELECT 'V-06 sites sans espace (attendu : 0)' AS verification, COUNT(*) AS resultat
FROM site s WHERE NOT EXISTS (SELECT 1 FROM espace e WHERE e.id_site = s.id_site);

-- V-07 : cardinalité (1,n) EXERCER — utilisateurs sans rôle (attendu : 0)
SELECT 'V-07 utilisateurs sans rôle (attendu : 0)' AS verification, COUNT(*) AS resultat
FROM utilisateur u WHERE NOT EXISTS (SELECT 1 FROM utilisateur_role r WHERE r.id_utilisateur = u.id_utilisateur);

-- V-08 : facture globale société — détail PAR COLLABORATEUR (RG-12) — Karim 214,00 ; Inès 199,00
SELECT 'V-08 détail par collaborateur' AS verification, f.numero, u.prenom, u.nom,
       SUM(l.quantite * l.prix_unitaire) AS total_collaborateur
FROM facture f
JOIN ligne_facture l ON l.id_facture = f.id_facture
JOIN utilisateur u ON u.id_utilisateur = l.id_utilisateur
WHERE f.id_societe = 1 AND f.periode = '2026-02-01'
GROUP BY f.numero, u.prenom, u.nom ORDER BY u.nom;

-- V-09 : taux d'occupation des postes de Tourcoing en avril (RG-16) — volume : 41 postes, 3 h réservées sur 40 → ~28 %
SELECT 'V-09 occupation Tourcoing avril' AS verification, jour, type_espace, heures_reservees, heures_disponibles, taux_pct
FROM v_taux_occupation_jour
WHERE id_site = 3 AND jour BETWEEN '2026-04-01' AND '2026-04-03'
ORDER BY jour;

-- V-10 : plan de la requête chaude (EXPLAIN — à lire, pas à comparer). Attendu : Index Scan sur l'index GiST
--        porté par ex_reservation_pas_de_chevauchement — la contrainte qui garantit la RG-04 sert aussi la recherche.
EXPLAIN (COSTS OFF)
SELECT id_reservation FROM reservation
WHERE id_espace = 6 AND statut = 'CONFIRMEE'
  AND tstzrange(debut, fin) && tstzrange('2026-03-10 08:00+01', '2026-03-10 20:00+01');
