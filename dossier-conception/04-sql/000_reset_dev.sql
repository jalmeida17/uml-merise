-- =============================================================================
-- CoWork'In — 000_reset_dev.sql
-- DÉVELOPPEMENT UNIQUEMENT. Remet la base à vide avant de rejouer la chaîne
-- 001 → 002 → 010. Ne fait PAS partie de la chaîne de migration : jamais sur
-- un environnement partagé.
-- =============================================================================

DROP VIEW IF EXISTS v_taux_occupation_jour;
DROP VIEW IF EXISTS v_consommation_mensuelle;
DROP VIEW IF EXISTS v_facture_total;
DROP VIEW IF EXISTS v_presents_par_site;

DROP TABLE IF EXISTS ligne_facture      CASCADE;
DROP TABLE IF EXISTS facture            CASCADE;
DROP TABLE IF EXISTS inscription        CASCADE;
DROP TABLE IF EXISTS atelier            CASCADE;
DROP TABLE IF EXISTS remboursement      CASCADE;
DROP TABLE IF EXISTS reservation        CASCADE;
DROP TABLE IF EXISTS abonnement         CASCADE;
DROP TABLE IF EXISTS affectation        CASCADE;
DROP TABLE IF EXISTS utilisateur_role   CASCADE;
DROP TABLE IF EXISTS salle_equipement   CASCADE;
DROP TABLE IF EXISTS tarif              CASCADE;
DROP TABLE IF EXISTS utilisateur        CASCADE;
DROP TABLE IF EXISTS espace             CASCADE;
DROP TABLE IF EXISTS formule            CASCADE;
DROP TABLE IF EXISTS role               CASCADE;
DROP TABLE IF EXISTS societe            CASCADE;
DROP TABLE IF EXISTS equipement         CASCADE;
DROP TABLE IF EXISTS site               CASCADE;

DROP FUNCTION IF EXISTS quota_consomme_h(BIGINT, DATE);
DROP FUNCTION IF EXISTS places_restantes(BIGINT);
DROP FUNCTION IF EXISTS trg_inscription_places_restantes();
DROP FUNCTION IF EXISTS trg_reservation_espace_disponible();
DROP FUNCTION IF EXISTS trg_atelier_salle_et_animateur();
DROP FUNCTION IF EXISTS trg_remboursement_plafond();
DROP FUNCTION IF EXISTS trg_facture_immuable();
DROP FUNCTION IF EXISTS trg_ligne_facture_immuable();
