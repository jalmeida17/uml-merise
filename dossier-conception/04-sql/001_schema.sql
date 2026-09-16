-- =============================================================================
-- CoWork'In — 001_schema.sql — PostgreSQL 16
-- Tables, clés primaires et étrangères, contraintes CHECK mono-ligne, index.
-- Part d'une base vide et s'exécute sans erreur du premier coup.
-- Inverse : 000_reset_dev.sql (développement uniquement).
-- Ordre : extensions → tables sans FK → tables dépendantes → jonctions → index.
-- Toutes les contraintes sont NOMMÉES : c'est ce nom qui apparaît dans les logs
-- et que l'application traduit en message utilisateur.
-- =============================================================================

-- 0. Extensions -----------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS btree_gist;   -- contraintes d'exclusion (RG-04, RG-08, tarifs)

-- 1. Tables sans clé étrangère --------------------------------------------------

CREATE TABLE site (
  id_site          BIGINT       GENERATED ALWAYS AS IDENTITY,
  nom              VARCHAR(60)  NOT NULL,
  ville            VARCHAR(60)  NOT NULL,
  adresse          TEXT         NOT NULL,
  heure_ouverture  TIME         NOT NULL,
  heure_fermeture  TIME         NOT NULL,
  CONSTRAINT pk_site          PRIMARY KEY (id_site),
  CONSTRAINT uq_site_nom      UNIQUE (nom),
  CONSTRAINT ck_site_horaires CHECK (heure_fermeture > heure_ouverture)
);
COMMENT ON TABLE site IS 'Bâtiment de coworking (Lille, Roubaix, Tourcoing). MCD : SITE.';

CREATE TABLE equipement (
  code_equipement  VARCHAR(20)  NOT NULL,
  libelle          VARCHAR(60)  NOT NULL,
  CONSTRAINT pk_equipement PRIMARY KEY (code_equipement)
);
COMMENT ON TABLE equipement IS 'Référentiel des équipements de salle. Issu de l''attribut multivalué equipements (1FN).';

CREATE TABLE societe (
  id_societe           BIGINT        GENERATED ALWAYS AS IDENTITY,
  raison_sociale       VARCHAR(120)  NOT NULL,
  siret                CHAR(14)      NOT NULL,
  adresse_facturation  TEXT          NOT NULL,
  email_facturation    VARCHAR(254)  NOT NULL,
  CONSTRAINT pk_societe               PRIMARY KEY (id_societe),
  CONSTRAINT uq_societe_siret         UNIQUE (siret),
  CONSTRAINT ck_societe_siret_format  CHECK (siret ~ '^[0-9]{14}$')
);
COMMENT ON TABLE societe IS 'Personne morale cliente, destinataire d''une facture globale (RG-12).';

CREATE TABLE role (
  code_role  VARCHAR(20)  NOT NULL,
  libelle    VARCHAR(60)  NOT NULL,
  CONSTRAINT pk_role      PRIMARY KEY (code_role),
  CONSTRAINT ck_role_code CHECK (code_role IN ('COWORKER', 'REFERENT_SOCIETE', 'HOTE_ACCUEIL', 'GERANT', 'ANIMATEUR'))
);
COMMENT ON TABLE role IS 'Rôles applicatifs. Un utilisateur en porte un ou plusieurs (utilisateur_role).';

CREATE TABLE formule (
  code_formule   VARCHAR(20)  NOT NULL,
  libelle        VARCHAR(60)  NOT NULL,
  quota_salle_h  SMALLINT     NOT NULL,
  actif          BOOLEAN      NOT NULL DEFAULT true,
  CONSTRAINT pk_formule                PRIMARY KEY (code_formule),
  CONSTRAINT ck_formule_quota_positif  CHECK (quota_salle_h >= 0)     -- RG-07
);
COMMENT ON TABLE formule IS 'Catalogue : Nomade, Résident, Team. Le prix est dans tarif (historisé).';

-- 2. Tables dépendantes, ordre topologique -------------------------------------

CREATE TABLE espace (
  id_espace    BIGINT       GENERATED ALWAYS AS IDENTITY,
  id_site      BIGINT       NOT NULL,
  code         VARCHAR(20)  NOT NULL,
  type_espace  VARCHAR(10)  NOT NULL,
  type_poste   VARCHAR(10),
  capacite     SMALLINT,
  statut       VARCHAR(15)  NOT NULL DEFAULT 'DISPONIBLE',
  CONSTRAINT pk_espace                 PRIMARY KEY (id_espace),
  CONSTRAINT fk_espace_site            FOREIGN KEY (id_site) REFERENCES site (id_site) ON DELETE RESTRICT,
  CONSTRAINT uq_espace_code_par_site   UNIQUE (id_site, code),                                   -- RG-21
  CONSTRAINT ck_espace_type            CHECK (type_espace IN ('POSTE', 'SALLE')),
  CONSTRAINT ck_espace_statut          CHECK (statut IN ('DISPONIBLE', 'MAINTENANCE', 'RETIRE')),  -- RG-14
  -- RG-11 : la capacité n'a de sens que pour une salle
  CONSTRAINT ck_espace_capacite_si_salle CHECK (
       (type_espace = 'SALLE' AND capacite IS NOT NULL AND capacite > 0)
    OR (type_espace = 'POSTE' AND capacite IS NULL)
  ),
  -- le type de poste n'a de sens que pour un poste
  CONSTRAINT ck_espace_type_poste_si_poste CHECK (
       (type_espace = 'POSTE' AND type_poste IN ('FLEX', 'DEDIE'))
    OR (type_espace = 'SALLE' AND type_poste IS NULL)
  )
);
CREATE INDEX ix_espace_site ON espace (id_site);
COMMENT ON TABLE espace IS 'Unité réservable. Héritage POSTE / SALLE_REUNION : table unique + discriminant type_espace.';

CREATE TABLE utilisateur (
  id_utilisateur  BIGINT        GENERATED ALWAYS AS IDENTITY,
  id_societe      BIGINT,
  nom             VARCHAR(80)   NOT NULL,
  prenom          VARCHAR(80)   NOT NULL,
  email           VARCHAR(254)  NOT NULL,
  telephone       VARCHAR(20),
  actif           BOOLEAN       NOT NULL DEFAULT true,
  cree_le         TIMESTAMPTZ   NOT NULL DEFAULT now(),
  CONSTRAINT pk_utilisateur               PRIMARY KEY (id_utilisateur),
  CONSTRAINT fk_utilisateur_societe       FOREIGN KEY (id_societe) REFERENCES societe (id_societe) ON DELETE SET NULL,
  CONSTRAINT ck_utilisateur_email_format  CHECK (position('@' IN email) > 1)
);
CREATE UNIQUE INDEX uq_utilisateur_email_lower ON utilisateur (lower(email));   -- RG-01
CREATE INDEX ix_utilisateur_societe ON utilisateur (id_societe);
COMMENT ON TABLE utilisateur IS 'Personne physique titulaire d''un compte. Données personnelles : anonymisation, jamais suppression (RG-22).';

CREATE TABLE tarif (
  id_tarif      BIGINT         GENERATED ALWAYS AS IDENTITY,
  code_formule  VARCHAR(20),
  prestation    VARCHAR(20)    NOT NULL,
  prix_ht       NUMERIC(10,2)  NOT NULL,
  date_debut    DATE           NOT NULL,
  date_fin      DATE,
  CONSTRAINT pk_tarif                PRIMARY KEY (id_tarif),
  CONSTRAINT fk_tarif_formule        FOREIGN KEY (code_formule) REFERENCES formule (code_formule) ON DELETE RESTRICT,
  CONSTRAINT ck_tarif_prestation     CHECK (prestation IN ('ABONNEMENT_MENSUEL', 'POSTE_HEURE', 'POSTE_JOUR', 'SALLE_HEURE')),
  CONSTRAINT ck_tarif_prix_positif   CHECK (prix_ht >= 0),
  CONSTRAINT ck_tarif_periode        CHECK (date_fin IS NULL OR date_fin > date_debut),
  CONSTRAINT ck_tarif_formule_si_abonnement CHECK (
       (prestation =  'ABONNEMENT_MENSUEL' AND code_formule IS NOT NULL)
    OR (prestation <> 'ABONNEMENT_MENSUEL' AND code_formule IS NULL)
  )
);
CREATE INDEX ix_tarif_formule ON tarif (code_formule);
COMMENT ON TABLE tarif IS 'Prix HT d''une prestation sur une période de validité (historisation). date_fin NULL = en vigueur.';

-- 3. Tables de jonction ---------------------------------------------------------

CREATE TABLE salle_equipement (
  id_espace        BIGINT       NOT NULL,
  code_equipement  VARCHAR(20)  NOT NULL,
  CONSTRAINT pk_salle_equipement             PRIMARY KEY (id_espace, code_equipement),
  CONSTRAINT fk_salle_equipement_espace      FOREIGN KEY (id_espace) REFERENCES espace (id_espace) ON DELETE CASCADE,
  CONSTRAINT fk_salle_equipement_equipement  FOREIGN KEY (code_equipement) REFERENCES equipement (code_equipement) ON DELETE CASCADE
);
CREATE INDEX ix_salle_equipement_equipement ON salle_equipement (code_equipement);

CREATE TABLE utilisateur_role (
  id_utilisateur  BIGINT       NOT NULL,
  code_role       VARCHAR(20)  NOT NULL,
  CONSTRAINT pk_utilisateur_role              PRIMARY KEY (id_utilisateur, code_role),
  CONSTRAINT fk_utilisateur_role_utilisateur  FOREIGN KEY (id_utilisateur) REFERENCES utilisateur (id_utilisateur) ON DELETE CASCADE,
  CONSTRAINT fk_utilisateur_role_role         FOREIGN KEY (code_role) REFERENCES role (code_role) ON DELETE RESTRICT
);
CREATE INDEX ix_utilisateur_role_role ON utilisateur_role (code_role);
COMMENT ON TABLE utilisateur_role IS 'EXERCER (1,n)-(0,n). Le "au moins un rôle" est garanti par l''applicatif et vérifié par V-07.';

CREATE TABLE affectation (
  id_utilisateur  BIGINT  NOT NULL,
  id_site         BIGINT  NOT NULL,
  CONSTRAINT pk_affectation              PRIMARY KEY (id_utilisateur, id_site),
  CONSTRAINT fk_affectation_utilisateur  FOREIGN KEY (id_utilisateur) REFERENCES utilisateur (id_utilisateur) ON DELETE CASCADE,
  CONSTRAINT fk_affectation_site         FOREIGN KEY (id_site) REFERENCES site (id_site) ON DELETE RESTRICT
);
CREATE INDEX ix_affectation_site ON affectation (id_site);
COMMENT ON TABLE affectation IS 'Personnel d''accueil affecté à un site : donne son sens à la portée "site" de la matrice acteur x UC.';

-- 4. Abonnements, réservations, ateliers ---------------------------------------

CREATE TABLE abonnement (
  id_abonnement   BIGINT       GENERATED ALWAYS AS IDENTITY,
  id_utilisateur  BIGINT       NOT NULL,
  code_formule    VARCHAR(20)  NOT NULL,
  date_debut      DATE         NOT NULL,
  date_fin        DATE,
  CONSTRAINT pk_abonnement              PRIMARY KEY (id_abonnement),
  CONSTRAINT fk_abonnement_utilisateur  FOREIGN KEY (id_utilisateur) REFERENCES utilisateur (id_utilisateur) ON DELETE RESTRICT,
  CONSTRAINT fk_abonnement_formule      FOREIGN KEY (code_formule) REFERENCES formule (code_formule) ON DELETE RESTRICT,
  CONSTRAINT ck_abonnement_periode      CHECK (date_fin IS NULL OR date_fin >= date_debut)
);
CREATE INDEX ix_abonnement_utilisateur ON abonnement (id_utilisateur);
CREATE INDEX ix_abonnement_formule     ON abonnement (code_formule);
COMMENT ON TABLE abonnement IS 'Souscription bornée d''un utilisateur à une formule. Un seul actif à la fois (RG-08, exclusion dans 002).';

CREATE TABLE reservation (
  id_reservation    BIGINT         GENERATED ALWAYS AS IDENTITY,
  id_utilisateur    BIGINT         NOT NULL,
  id_espace         BIGINT         NOT NULL,
  debut             TIMESTAMPTZ    NOT NULL,
  fin               TIMESTAMPTZ    NOT NULL,
  statut            VARCHAR(12)    NOT NULL DEFAULT 'EN_ATTENTE',
  montant_du        NUMERIC(10,2)  NOT NULL DEFAULT 0,
  cree_le           TIMESTAMPTZ    NOT NULL DEFAULT now(),
  annulee_le        TIMESTAMPTZ,
  motif_annulation  VARCHAR(200),
  CONSTRAINT pk_reservation                    PRIMARY KEY (id_reservation),
  CONSTRAINT fk_reservation_utilisateur        FOREIGN KEY (id_utilisateur) REFERENCES utilisateur (id_utilisateur) ON DELETE RESTRICT,
  CONSTRAINT fk_reservation_espace             FOREIGN KEY (id_espace) REFERENCES espace (id_espace) ON DELETE RESTRICT,
  CONSTRAINT ck_reservation_statut             CHECK (statut IN ('EN_ATTENTE', 'CONFIRMEE', 'ANNULEE')),
  CONSTRAINT ck_reservation_fin_apres_debut    CHECK (fin > debut),                                        -- RG-03
  CONSTRAINT ck_reservation_duree_minimale     CHECK (fin - debut >= INTERVAL '1 hour'),                   -- RG-05
  CONSTRAINT ck_reservation_pas_30min          CHECK ((EXTRACT(EPOCH FROM (fin - debut))::BIGINT % 1800) = 0),  -- RG-05
  CONSTRAINT ck_reservation_montant_positif    CHECK (montant_du >= 0),
  CONSTRAINT ck_reservation_annulation_coherente CHECK ((statut = 'ANNULEE') = (annulee_le IS NOT NULL))
);
CREATE INDEX ix_reservation_utilisateur ON reservation (id_utilisateur);
CREATE INDEX ix_reservation_espace      ON reservation (id_espace);
-- la requête chaude : recherche de disponibilité
CREATE INDEX ix_reservation_espace_debut_confirmee      ON reservation (id_espace, debut)      WHERE statut = 'CONFIRMEE';
-- quota mensuel et "mes réservations"
CREATE INDEX ix_reservation_utilisateur_debut_confirmee ON reservation (id_utilisateur, debut) WHERE statut = 'CONFIRMEE';
-- balayage du planificateur : expiration à 15 min (RG-09)
CREATE INDEX ix_reservation_en_attente                  ON reservation (cree_le)               WHERE statut = 'EN_ATTENTE';
COMMENT ON TABLE reservation IS 'Occupation exclusive d''un espace sur un créneau. montant_du est FIGÉ à la confirmation (historisation). RG-04 : exclusion dans 002.';

CREATE TABLE remboursement (
  id_remboursement  BIGINT         GENERATED ALWAYS AS IDENTITY,
  id_reservation    BIGINT         NOT NULL,
  montant           NUMERIC(10,2)  NOT NULL,
  statut            VARCHAR(10)    NOT NULL DEFAULT 'DEMANDE',
  reference_psp     VARCHAR(64),
  demande_le        TIMESTAMPTZ    NOT NULL DEFAULT now(),
  effectue_le       TIMESTAMPTZ,
  CONSTRAINT pk_remboursement                   PRIMARY KEY (id_remboursement),
  CONSTRAINT fk_remboursement_reservation       FOREIGN KEY (id_reservation) REFERENCES reservation (id_reservation) ON DELETE RESTRICT,
  CONSTRAINT ck_remboursement_statut            CHECK (statut IN ('DEMANDE', 'EFFECTUE', 'EN_ERREUR')),
  CONSTRAINT ck_remboursement_montant_positif   CHECK (montant > 0),
  CONSTRAINT ck_remboursement_effectue_coherent CHECK ((statut = 'EFFECTUE') = (effectue_le IS NOT NULL))
);
CREATE INDEX ix_remboursement_reservation ON remboursement (id_reservation);
CREATE INDEX ix_remboursement_en_erreur   ON remboursement (demande_le) WHERE statut = 'EN_ERREUR';
COMMENT ON TABLE remboursement IS 'Suivi des demandes de remboursement au PSP (UC-04). Table technique justifiée par la séquence détaillée.';

CREATE TABLE atelier (
  id_atelier    BIGINT        GENERATED ALWAYS AS IDENTITY,
  id_espace     BIGINT        NOT NULL,
  id_animateur  BIGINT        NOT NULL,
  titre         VARCHAR(120)  NOT NULL,
  description   TEXT,
  debut         TIMESTAMPTZ   NOT NULL,
  fin           TIMESTAMPTZ   NOT NULL,
  places_max    SMALLINT      NOT NULL,
  statut        VARCHAR(10)   NOT NULL DEFAULT 'BROUILLON',
  CONSTRAINT pk_atelier                 PRIMARY KEY (id_atelier),
  CONSTRAINT fk_atelier_espace          FOREIGN KEY (id_espace) REFERENCES espace (id_espace) ON DELETE RESTRICT,
  CONSTRAINT fk_atelier_animateur       FOREIGN KEY (id_animateur) REFERENCES utilisateur (id_utilisateur) ON DELETE RESTRICT,
  CONSTRAINT ck_atelier_fin_apres_debut CHECK (fin > debut),
  CONSTRAINT ck_atelier_places_positif  CHECK (places_max > 0),                                   -- RG-17
  CONSTRAINT ck_atelier_statut          CHECK (statut IN ('BROUILLON', 'PUBLIE', 'ANNULE', 'TERMINE'))
);
CREATE INDEX ix_atelier_espace       ON atelier (id_espace);
CREATE INDEX ix_atelier_animateur    ON atelier (id_animateur);
CREATE INDEX ix_atelier_debut_publie ON atelier (debut) WHERE statut = 'PUBLIE';
COMMENT ON TABLE atelier IS 'Événement animé dans une salle, avec jauge. Ex-ternaire ANIMER éclatée en entité (cas délicat 2).';

CREATE TABLE inscription (
  id_utilisateur    BIGINT       NOT NULL,
  id_atelier        BIGINT       NOT NULL,
  date_inscription  TIMESTAMPTZ  NOT NULL DEFAULT now(),
  statut            VARCHAR(10)  NOT NULL DEFAULT 'CONFIRMEE',
  CONSTRAINT pk_inscription              PRIMARY KEY (id_utilisateur, id_atelier),      -- RG-18 : une inscription par personne et par atelier
  CONSTRAINT fk_inscription_utilisateur  FOREIGN KEY (id_utilisateur) REFERENCES utilisateur (id_utilisateur) ON DELETE RESTRICT,
  CONSTRAINT fk_inscription_atelier      FOREIGN KEY (id_atelier) REFERENCES atelier (id_atelier) ON DELETE RESTRICT,
  CONSTRAINT ck_inscription_statut       CHECK (statut IN ('CONFIRMEE', 'ANNULEE'))
);
CREATE INDEX ix_inscription_atelier_confirmee ON inscription (id_atelier) WHERE statut = 'CONFIRMEE';
COMMENT ON TABLE inscription IS 'Relation porteuse S''INSCRIRE. La jauge (RG-18) est tenue par le trigger tg_inscription_places_restantes.';

-- 5. Facturation ----------------------------------------------------------------

CREATE TABLE facture (
  id_facture      BIGINT       GENERATED ALWAYS AS IDENTITY,
  id_utilisateur  BIGINT,
  id_societe      BIGINT,
  numero          VARCHAR(20)  NOT NULL,
  periode         DATE         NOT NULL,
  date_emission   DATE,
  statut          VARCHAR(10)  NOT NULL DEFAULT 'BROUILLON',
  CONSTRAINT pk_facture                        PRIMARY KEY (id_facture),
  CONSTRAINT fk_facture_utilisateur            FOREIGN KEY (id_utilisateur) REFERENCES utilisateur (id_utilisateur) ON DELETE RESTRICT,
  CONSTRAINT fk_facture_societe                FOREIGN KEY (id_societe) REFERENCES societe (id_societe) ON DELETE RESTRICT,
  CONSTRAINT uq_facture_numero                 UNIQUE (numero),
  CONSTRAINT ck_facture_statut                 CHECK (statut IN ('BROUILLON', 'EMISE', 'PAYEE', 'ANNULEE')),
  -- RG-12 : exactement un destinataire
  CONSTRAINT ck_facture_destinataire_unique    CHECK ((id_utilisateur IS NULL) <> (id_societe IS NULL)),
  CONSTRAINT ck_facture_periode_premier_du_mois CHECK (periode = date_trunc('month', periode)::DATE),
  CONSTRAINT ck_facture_emission_coherente     CHECK (statut = 'BROUILLON' OR date_emission IS NOT NULL)
);
CREATE INDEX ix_facture_utilisateur ON facture (id_utilisateur);
CREATE INDEX ix_facture_societe     ON facture (id_societe);
-- RG-20 : une facture (non annulée) par destinataire et par période
CREATE UNIQUE INDEX uq_facture_utilisateur_periode ON facture (id_utilisateur, periode) WHERE id_utilisateur IS NOT NULL AND statut <> 'ANNULEE';
CREATE UNIQUE INDEX uq_facture_societe_periode     ON facture (id_societe, periode)     WHERE id_societe     IS NOT NULL AND statut <> 'ANNULEE';
COMMENT ON TABLE facture IS 'Facture mensuelle, adressée à un utilisateur OU à une société (RG-12). Immuable après émission (RG-13, trigger dans 002).';

CREATE TABLE ligne_facture (
  id_facture      BIGINT         NOT NULL,
  num_ligne       SMALLINT       NOT NULL,
  id_utilisateur  BIGINT         NOT NULL,      -- bénéficiaire : le collaborateur (détail par collaborateur, RG-12)
  id_reservation  BIGINT,
  libelle         VARCHAR(200)   NOT NULL,      -- RECOPIÉ à l'émission (RG-13)
  quantite        NUMERIC(8,2)   NOT NULL,
  unite           VARCHAR(10)    NOT NULL,
  prix_unitaire   NUMERIC(10,2)  NOT NULL,      -- RECOPIÉ du tarif en vigueur : historisation, pas redondance
  CONSTRAINT pk_ligne_facture                   PRIMARY KEY (id_facture, num_ligne),       -- identification relative (règle 6)
  CONSTRAINT fk_ligne_facture_facture           FOREIGN KEY (id_facture) REFERENCES facture (id_facture) ON DELETE CASCADE,   -- la seule composition vraie
  CONSTRAINT fk_ligne_facture_utilisateur       FOREIGN KEY (id_utilisateur) REFERENCES utilisateur (id_utilisateur) ON DELETE RESTRICT,
  CONSTRAINT fk_ligne_facture_reservation       FOREIGN KEY (id_reservation) REFERENCES reservation (id_reservation) ON DELETE RESTRICT,
  CONSTRAINT uq_ligne_facture_reservation       UNIQUE (id_reservation),                  -- règle 5 : une réservation facturée au plus une fois
  CONSTRAINT ck_ligne_facture_num_positif       CHECK (num_ligne > 0),
  CONSTRAINT ck_ligne_facture_quantite_positive CHECK (quantite > 0),
  CONSTRAINT ck_ligne_facture_unite             CHECK (unite IN ('HEURE', 'JOUR', 'MOIS')),
  CONSTRAINT ck_ligne_facture_prix_positif      CHECK (prix_unitaire >= 0)
);
CREATE INDEX ix_ligne_facture_utilisateur ON ligne_facture (id_utilisateur);
COMMENT ON TABLE ligne_facture IS 'Entité faible identifiée par (id_facture, num_ligne). Libellé et prix recopiés à l''émission.';
