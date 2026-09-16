-- =============================================================================
-- CoWork'In — 002_contraintes.sql — PostgreSQL 16
-- Ce que le MLD ne dit pas et qu'aucun CHECK mono-ligne ne peut tenir :
--   1. contraintes d'exclusion (règles multi-lignes)
--   2. fonctions de calcul (ce qu'on a refusé de stocker)
--   3. triggers (règles multi-tables)
--   4. vues (présents, occupation, consommation, totaux)
--   5. rôles de base (commentés : dépendent de l'environnement)
-- Prérequis : 001_schema.sql exécuté. Inverse : 000_reset_dev.sql.
-- =============================================================================

-- 1. Contraintes d'exclusion ----------------------------------------------------

-- RG-04 : deux réservations CONFIRMÉES ne se chevauchent jamais sur un même espace.
-- tstzrange(debut, fin) est semi-ouvert [debut, fin) : 9h-11h et 11h-12h sont jointives, pas chevauchantes.
-- C'est la seule implémentation qui tient face à deux requêtes simultanées sans verrou explicite.
ALTER TABLE reservation
  ADD CONSTRAINT ex_reservation_pas_de_chevauchement
  EXCLUDE USING gist (id_espace WITH =, tstzrange(debut, fin) WITH &&)
  WHERE (statut = 'CONFIRMEE');

-- RG-08 : un utilisateur n'a qu'un abonnement actif à la fois (périodes disjointes ; date_fin NULL = sans fin).
ALTER TABLE abonnement
  ADD CONSTRAINT ex_abonnement_un_seul_actif
  EXCLUDE USING gist (id_utilisateur WITH =, daterange(date_debut, date_fin, '[]') WITH &&);

-- Tarifs : pas deux prix en vigueur en même temps pour une même prestation (et une même formule).
ALTER TABLE tarif
  ADD CONSTRAINT ex_tarif_pas_de_chevauchement
  EXCLUDE USING gist (prestation WITH =, (COALESCE(code_formule, '')) WITH =, daterange(date_debut, date_fin, '[]') WITH &&);

-- 2. Fonctions de calcul (données refusées au stockage) -------------------------

-- RG-07 : heures de salle CONFIRMÉES imputées à un abonnement sur un mois calendaire.
CREATE OR REPLACE FUNCTION quota_consomme_h(p_id_abonnement BIGINT, p_periode DATE)
RETURNS NUMERIC
LANGUAGE sql STABLE AS $$
  SELECT COALESCE(SUM(EXTRACT(EPOCH FROM (r.fin - r.debut)) / 3600.0), 0)
  FROM abonnement a
  JOIN reservation r ON r.id_utilisateur = a.id_utilisateur
  JOIN espace e      ON e.id_espace = r.id_espace
  WHERE a.id_abonnement = p_id_abonnement
    AND e.type_espace = 'SALLE'
    AND r.statut = 'CONFIRMEE'
    AND r.debut >= date_trunc('month', p_periode)
    AND r.debut <  date_trunc('month', p_periode) + INTERVAL '1 month'
    AND r.debut::DATE BETWEEN a.date_debut AND COALESCE(a.date_fin, 'infinity'::DATE)
$$;
COMMENT ON FUNCTION quota_consomme_h(BIGINT, DATE) IS 'RG-07. Remplace la colonne calculable quota_consomme, refusée au MCD.';

-- RG-18 : places restantes d'un atelier = jauge - inscriptions confirmées.
CREATE OR REPLACE FUNCTION places_restantes(p_id_atelier BIGINT)
RETURNS INTEGER
LANGUAGE sql STABLE AS $$
  SELECT (a.places_max - (SELECT COUNT(*) FROM inscription i
                          WHERE i.id_atelier = a.id_atelier AND i.statut = 'CONFIRMEE'))::INTEGER
  FROM atelier a
  WHERE a.id_atelier = p_id_atelier
$$;
COMMENT ON FUNCTION places_restantes(BIGINT) IS 'RG-18. Remplace la colonne calculable nb_inscrits, refusée au MCD.';

-- 3. Triggers -------------------------------------------------------------------

-- RG-18 / RG-19 : jauge respectée, inscriptions ouvertes uniquement sur un atelier PUBLIÉ.
-- Le verrou FOR UPDATE sur la ligne atelier sérialise deux inscriptions simultanées sur la dernière place.
CREATE OR REPLACE FUNCTION trg_inscription_places_restantes()
RETURNS TRIGGER
LANGUAGE plpgsql AS $$
DECLARE
  v_places_max  SMALLINT;
  v_statut      VARCHAR(10);
  v_confirmees  BIGINT;
BEGIN
  IF NEW.statut <> 'CONFIRMEE' THEN
    RETURN NEW;                                   -- une annulation libère une place, rien à contrôler
  END IF;

  SELECT places_max, statut INTO v_places_max, v_statut
  FROM atelier WHERE id_atelier = NEW.id_atelier
  FOR UPDATE;

  IF v_statut <> 'PUBLIE' THEN
    RAISE EXCEPTION 'RG-19 : inscriptions closes, l''atelier % est au statut %', NEW.id_atelier, v_statut
      USING ERRCODE = 'check_violation', CONSTRAINT = 'tg_inscription_places_restantes';
  END IF;

  SELECT COUNT(*) INTO v_confirmees
  FROM inscription
  WHERE id_atelier = NEW.id_atelier
    AND statut = 'CONFIRMEE'
    AND id_utilisateur <> NEW.id_utilisateur;     -- exclut la ligne elle-même en cas d'UPDATE

  IF v_confirmees >= v_places_max THEN
    RAISE EXCEPTION 'RG-18 : atelier % complet (% places)', NEW.id_atelier, v_places_max
      USING ERRCODE = 'check_violation', CONSTRAINT = 'tg_inscription_places_restantes';
  END IF;

  RETURN NEW;
END $$;

CREATE TRIGGER tg_inscription_places_restantes
  BEFORE INSERT OR UPDATE OF statut ON inscription
  FOR EACH ROW EXECUTE FUNCTION trg_inscription_places_restantes();

-- RG-14 : aucune réservation vivante sur un espace en maintenance ou retiré.
CREATE OR REPLACE FUNCTION trg_reservation_espace_disponible()
RETURNS TRIGGER
LANGUAGE plpgsql AS $$
DECLARE
  v_statut_espace VARCHAR(15);
BEGIN
  IF NEW.statut IN ('EN_ATTENTE', 'CONFIRMEE') THEN
    SELECT statut INTO v_statut_espace FROM espace WHERE id_espace = NEW.id_espace;
    IF v_statut_espace <> 'DISPONIBLE' THEN
      RAISE EXCEPTION 'RG-14 : l''espace % est % : aucune nouvelle réservation', NEW.id_espace, v_statut_espace
        USING ERRCODE = 'check_violation', CONSTRAINT = 'tg_reservation_espace_disponible';
    END IF;
  END IF;
  RETURN NEW;
END $$;

CREATE TRIGGER tg_reservation_espace_disponible
  BEFORE INSERT OR UPDATE OF id_espace, statut ON reservation
  FOR EACH ROW EXECUTE FUNCTION trg_reservation_espace_disponible();

-- RG-17 : un atelier se tient dans une SALLE et son animateur porte le rôle ANIMATEUR.
CREATE OR REPLACE FUNCTION trg_atelier_salle_et_animateur()
RETURNS TRIGGER
LANGUAGE plpgsql AS $$
BEGIN
  IF (SELECT type_espace FROM espace WHERE id_espace = NEW.id_espace) <> 'SALLE' THEN
    RAISE EXCEPTION 'RG-17 : l''espace % n''est pas une salle', NEW.id_espace
      USING ERRCODE = 'check_violation', CONSTRAINT = 'tg_atelier_salle_et_animateur';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM utilisateur_role
                 WHERE id_utilisateur = NEW.id_animateur AND code_role = 'ANIMATEUR') THEN
    RAISE EXCEPTION 'RG-17 : l''utilisateur % ne porte pas le rôle ANIMATEUR', NEW.id_animateur
      USING ERRCODE = 'check_violation', CONSTRAINT = 'tg_atelier_salle_et_animateur';
  END IF;
  RETURN NEW;
END $$;

CREATE TRIGGER tg_atelier_salle_et_animateur
  BEFORE INSERT OR UPDATE OF id_espace, id_animateur ON atelier
  FOR EACH ROW EXECUTE FUNCTION trg_atelier_salle_et_animateur();

-- RG-10 : on ne rembourse qu'une réservation ANNULÉE, et jamais plus que son montant dû (cumul).
CREATE OR REPLACE FUNCTION trg_remboursement_plafond()
RETURNS TRIGGER
LANGUAGE plpgsql AS $$
DECLARE
  v_statut_resa  VARCHAR(12);
  v_montant_du   NUMERIC(10,2);
  v_deja         NUMERIC(10,2);
BEGIN
  SELECT statut, montant_du INTO v_statut_resa, v_montant_du
  FROM reservation WHERE id_reservation = NEW.id_reservation;

  IF v_statut_resa <> 'ANNULEE' THEN
    RAISE EXCEPTION 'RG-10 : la réservation % n''est pas annulée, remboursement impossible', NEW.id_reservation
      USING ERRCODE = 'check_violation', CONSTRAINT = 'tg_remboursement_plafond';
  END IF;

  SELECT COALESCE(SUM(montant), 0) INTO v_deja
  FROM remboursement
  WHERE id_reservation = NEW.id_reservation
    AND statut <> 'EN_ERREUR'
    AND id_remboursement IS DISTINCT FROM NEW.id_remboursement;

  IF v_deja + NEW.montant > v_montant_du THEN
    RAISE EXCEPTION 'RG-10 : remboursement % + déjà remboursé % > montant dû % (réservation %)',
      NEW.montant, v_deja, v_montant_du, NEW.id_reservation
      USING ERRCODE = 'check_violation', CONSTRAINT = 'tg_remboursement_plafond';
  END IF;

  RETURN NEW;
END $$;

CREATE TRIGGER tg_remboursement_plafond
  BEFORE INSERT OR UPDATE OF montant, statut ON remboursement
  FOR EACH ROW EXECUTE FUNCTION trg_remboursement_plafond();

-- RG-13 : une facture émise ne bouge plus (seul le statut peut évoluer : EMISE -> PAYEE / ANNULEE).
CREATE OR REPLACE FUNCTION trg_facture_immuable()
RETURNS TRIGGER
LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP = 'DELETE' THEN
    IF OLD.statut <> 'BROUILLON' THEN
      RAISE EXCEPTION 'RG-13 : la facture % est émise, suppression interdite', OLD.numero
        USING ERRCODE = 'check_violation', CONSTRAINT = 'tg_facture_immuable';
    END IF;
    RETURN OLD;
  END IF;

  IF OLD.statut <> 'BROUILLON'
     AND (NEW.numero, NEW.periode, NEW.date_emission, NEW.id_utilisateur, NEW.id_societe)
         IS DISTINCT FROM
         (OLD.numero, OLD.periode, OLD.date_emission, OLD.id_utilisateur, OLD.id_societe) THEN
    RAISE EXCEPTION 'RG-13 : la facture % est émise, modification interdite', OLD.numero
      USING ERRCODE = 'check_violation', CONSTRAINT = 'tg_facture_immuable';
  END IF;
  RETURN NEW;
END $$;

CREATE TRIGGER tg_facture_immuable
  BEFORE UPDATE OR DELETE ON facture
  FOR EACH ROW EXECUTE FUNCTION trg_facture_immuable();

-- RG-13 (suite) : les lignes d'une facture émise sont figées.
CREATE OR REPLACE FUNCTION trg_ligne_facture_immuable()
RETURNS TRIGGER
LANGUAGE plpgsql AS $$
DECLARE
  v_id_facture BIGINT := COALESCE(NEW.id_facture, OLD.id_facture);
  v_statut     VARCHAR(10);
BEGIN
  SELECT statut INTO v_statut FROM facture WHERE id_facture = v_id_facture;
  -- v_statut NULL = parent déjà supprimé par la cascade (facture BROUILLON) : on laisse passer
  IF COALESCE(v_statut, 'BROUILLON') <> 'BROUILLON' THEN
    RAISE EXCEPTION 'RG-13 : la facture % est émise, ses lignes sont figées', v_id_facture
      USING ERRCODE = 'check_violation', CONSTRAINT = 'tg_ligne_facture_immuable';
  END IF;
  IF TG_OP = 'DELETE' THEN RETURN OLD; END IF;
  RETURN NEW;
END $$;

CREATE TRIGGER tg_ligne_facture_immuable
  BEFORE INSERT OR UPDATE OR DELETE ON ligne_facture
  FOR EACH ROW EXECUTE FUNCTION trg_ligne_facture_immuable();

-- 4. Vues -----------------------------------------------------------------------

-- UC-06 / RG-15 (H3) : est présent quiconque a une réservation confirmée en cours sur le site.
-- Donnée de localisation indirecte : accès réservé au rôle hôte du site et au gérant, consultations journalisées.
CREATE OR REPLACE VIEW v_presents_par_site AS
SELECT s.id_site,
       s.nom            AS site,
       u.id_utilisateur,
       u.nom,
       u.prenom,
       e.code           AS espace,
       e.type_espace,
       r.debut,
       r.fin
FROM reservation r
JOIN espace      e ON e.id_espace = r.id_espace
JOIN site        s ON s.id_site = e.id_site
JOIN utilisateur u ON u.id_utilisateur = r.id_utilisateur
WHERE r.statut = 'CONFIRMEE'
  AND r.debut <= now()
  AND now() < r.fin;
COMMENT ON VIEW v_presents_par_site IS 'UC-06. Présence = réservation confirmée en cours (hypothèse H3).';

-- UC-08 : matérialisation SQL de l'interface IConsommationMensuelle (voir fiche de synthèse, point P1).
CREATE OR REPLACE VIEW v_consommation_mensuelle AS
SELECT date_trunc('month', r.debut)::DATE                 AS periode,
       r.id_utilisateur                                   AS id_beneficiaire,
       u.id_societe,
       r.id_reservation,
       e.type_espace,
       s.nom                                              AS site,
       e.code                                             AS espace,
       r.debut,
       r.fin,
       EXTRACT(EPOCH FROM (r.fin - r.debut)) / 3600.0     AS heures,
       r.montant_du
FROM reservation r
JOIN espace      e ON e.id_espace = r.id_espace
JOIN site        s ON s.id_site = e.id_site
JOIN utilisateur u ON u.id_utilisateur = r.id_utilisateur
WHERE r.statut = 'CONFIRMEE';
COMMENT ON VIEW v_consommation_mensuelle IS 'UC-08. Consommations confirmées par bénéficiaire et société : entrée de la clôture mensuelle.';

-- UC-08 / UC-14 : total calculé, jamais stocké.
CREATE OR REPLACE VIEW v_facture_total AS
SELECT f.id_facture,
       f.numero,
       f.periode,
       f.statut,
       f.id_utilisateur,
       f.id_societe,
       COUNT(l.num_ligne)                                 AS nb_lignes,
       COALESCE(SUM(l.quantite * l.prix_unitaire), 0)     AS total_ht
FROM facture f
LEFT JOIN ligne_facture l ON l.id_facture = f.id_facture
GROUP BY f.id_facture, f.numero, f.periode, f.statut, f.id_utilisateur, f.id_societe;
COMMENT ON VIEW v_facture_total IS 'UC-08, UC-14. Remplace la colonne calculable montant_total, refusée au MCD.';

-- UC-09 / RG-16 : taux d'occupation par site, jour et type d'espace.
CREATE OR REPLACE VIEW v_taux_occupation_jour AS
WITH heures AS (
  SELECT e.id_site,
         e.type_espace,
         (r.debut::DATE)                                          AS jour,
         SUM(EXTRACT(EPOCH FROM (r.fin - r.debut)) / 3600.0)      AS heures_reservees
  FROM reservation r
  JOIN espace e ON e.id_espace = r.id_espace
  WHERE r.statut = 'CONFIRMEE'
  GROUP BY e.id_site, e.type_espace, (r.debut::DATE)
),
capacite AS (
  SELECT e.id_site,
         e.type_espace,
         COUNT(*)                                                                    AS nb_espaces,
         EXTRACT(EPOCH FROM (s.heure_fermeture - s.heure_ouverture)) / 3600.0        AS heures_ouvrables
  FROM espace e
  JOIN site s ON s.id_site = e.id_site
  WHERE e.statut <> 'RETIRE'
  GROUP BY e.id_site, e.type_espace, s.heure_ouverture, s.heure_fermeture
)
SELECT h.id_site,
       s.nom                                                              AS site,
       h.type_espace,
       h.jour,
       h.heures_reservees,
       c.nb_espaces * c.heures_ouvrables                                  AS heures_disponibles,
       ROUND(100 * h.heures_reservees / (c.nb_espaces * c.heures_ouvrables), 1) AS taux_pct
FROM heures h
JOIN capacite c USING (id_site, type_espace)
JOIN site     s ON s.id_site = h.id_site;
COMMENT ON VIEW v_taux_occupation_jour IS 'UC-09. RG-16 : heures confirmées / (heures ouvrables x espaces non retirés).';

-- 5. Rôles de base (à adapter à l'environnement ; exécution manuelle) -----------
-- CREATE ROLE coworkin_app LOGIN PASSWORD '<secret hors du dépôt>';
-- GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO coworkin_app;
-- GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO coworkin_app;
-- GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO coworkin_app;
-- CREATE ROLE coworkin_accueil LOGIN PASSWORD '<secret hors du dépôt>';
-- GRANT SELECT ON v_presents_par_site TO coworkin_accueil;   -- et rien d'autre
