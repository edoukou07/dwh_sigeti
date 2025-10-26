--
-- PostgreSQL database dump
--

-- Dumped from database version 13.18
-- Dumped by pg_dump version 13.18

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: cdc; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA cdc;


ALTER SCHEMA cdc OWNER TO postgres;

--
-- Name: dwh; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA dwh;


ALTER SCHEMA dwh OWNER TO postgres;

--
-- Name: etl; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA etl;


ALTER SCHEMA etl OWNER TO postgres;

--
-- Name: monitoring; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA monitoring;


ALTER SCHEMA monitoring OWNER TO postgres;

--
-- Name: staging; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA staging;


ALTER SCHEMA staging OWNER TO postgres;

--
-- Name: dblink; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS dblink WITH SCHEMA public;


--
-- Name: EXTENSION dblink; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION dblink IS 'connect to other PostgreSQL databases from within a database';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: cdc_config; Type: TABLE; Schema: cdc; Owner: postgres
--

CREATE TABLE cdc.cdc_config (
    id integer NOT NULL,
    table_source character varying(100),
    table_cible character varying(100),
    derniere_sync timestamp without time zone,
    mode_sync character varying(20) DEFAULT 'INCREMENTAL'::character varying,
    est_actif boolean DEFAULT true,
    date_creation timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE cdc.cdc_config OWNER TO postgres;

--
-- Name: cdc_config_id_seq; Type: SEQUENCE; Schema: cdc; Owner: postgres
--

CREATE SEQUENCE cdc.cdc_config_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE cdc.cdc_config_id_seq OWNER TO postgres;

--
-- Name: cdc_config_id_seq; Type: SEQUENCE OWNED BY; Schema: cdc; Owner: postgres
--

ALTER SEQUENCE cdc.cdc_config_id_seq OWNED BY cdc.cdc_config.id;


--
-- Name: cdc_logs; Type: TABLE; Schema: cdc; Owner: postgres
--

CREATE TABLE cdc.cdc_logs (
    id integer NOT NULL,
    config_id integer,
    date_sync timestamp without time zone,
    nb_lignes_sync integer,
    statut character varying(20),
    message text
);


ALTER TABLE cdc.cdc_logs OWNER TO postgres;

--
-- Name: cdc_logs_id_seq; Type: SEQUENCE; Schema: cdc; Owner: postgres
--

CREATE SEQUENCE cdc.cdc_logs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE cdc.cdc_logs_id_seq OWNER TO postgres;

--
-- Name: cdc_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: cdc; Owner: postgres
--

ALTER SEQUENCE cdc.cdc_logs_id_seq OWNED BY cdc.cdc_logs.id;


--
-- Name: cdc_sync_status; Type: TABLE; Schema: cdc; Owner: postgres
--

CREATE TABLE cdc.cdc_sync_status (
    id integer NOT NULL,
    table_name character varying(100),
    last_sync_time timestamp without time zone,
    sync_status character varying(20),
    error_message text,
    rows_processed integer DEFAULT 0,
    date_created timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE cdc.cdc_sync_status OWNER TO postgres;

--
-- Name: cdc_sync_status_id_seq; Type: SEQUENCE; Schema: cdc; Owner: postgres
--

CREATE SEQUENCE cdc.cdc_sync_status_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE cdc.cdc_sync_status_id_seq OWNER TO postgres;

--
-- Name: cdc_sync_status_id_seq; Type: SEQUENCE OWNED BY; Schema: cdc; Owner: postgres
--

ALTER SEQUENCE cdc.cdc_sync_status_id_seq OWNED BY cdc.cdc_sync_status.id;


--
-- Name: v_sync_monitoring; Type: VIEW; Schema: cdc; Owner: postgres
--

CREATE VIEW cdc.v_sync_monitoring AS
 SELECT cc.table_source,
    cc.table_cible,
    cc.derniere_sync,
    cc.mode_sync,
    cc.est_actif,
    COALESCE(cl.nb_lignes_sync, 0) AS dernier_nb_lignes,
    cl.statut AS dernier_statut,
    cl.date_sync AS derniere_execution
   FROM (cdc.cdc_config cc
     LEFT JOIN cdc.cdc_logs cl ON (((cc.id = cl.config_id) AND (cl.date_sync = ( SELECT max(cdc_logs.date_sync) AS max
           FROM cdc.cdc_logs
          WHERE (cdc_logs.config_id = cc.id))))));


ALTER TABLE cdc.v_sync_monitoring OWNER TO postgres;

--
-- Name: dim_entreprises; Type: TABLE; Schema: dwh; Owner: postgres
--

CREATE TABLE dwh.dim_entreprises (
    entreprise_key integer NOT NULL,
    entreprise_id integer,
    nom_entreprise character varying(200),
    forme_juridique character varying(100),
    secteur_activite character varying(100),
    taille_entreprise character varying(50),
    chiffre_affaires numeric(15,2),
    nb_employes integer,
    pays character varying(100),
    region character varying(100),
    date_creation_entreprise date,
    date_creation timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    date_modification timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE dwh.dim_entreprises OWNER TO postgres;

--
-- Name: dim_entreprises_entreprise_key_seq; Type: SEQUENCE; Schema: dwh; Owner: postgres
--

CREATE SEQUENCE dwh.dim_entreprises_entreprise_key_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dwh.dim_entreprises_entreprise_key_seq OWNER TO postgres;

--
-- Name: dim_entreprises_entreprise_key_seq; Type: SEQUENCE OWNED BY; Schema: dwh; Owner: postgres
--

ALTER SEQUENCE dwh.dim_entreprises_entreprise_key_seq OWNED BY dwh.dim_entreprises.entreprise_key;


--
-- Name: dim_lots; Type: TABLE; Schema: dwh; Owner: postgres
--

CREATE TABLE dwh.dim_lots (
    lot_key integer NOT NULL,
    lot_id integer,
    zone_key integer,
    numero_lot character varying(50),
    superficie numeric(10,2),
    prix_m2 numeric(10,2),
    statut_lot character varying(50),
    type_lot character varying(50),
    coordonnees_gps character varying(100),
    date_creation timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    date_modification timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE dwh.dim_lots OWNER TO postgres;

--
-- Name: dim_lots_lot_key_seq; Type: SEQUENCE; Schema: dwh; Owner: postgres
--

CREATE SEQUENCE dwh.dim_lots_lot_key_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dwh.dim_lots_lot_key_seq OWNER TO postgres;

--
-- Name: dim_lots_lot_key_seq; Type: SEQUENCE OWNED BY; Schema: dwh; Owner: postgres
--

ALTER SEQUENCE dwh.dim_lots_lot_key_seq OWNED BY dwh.dim_lots.lot_key;


--
-- Name: dim_operateurs; Type: TABLE; Schema: dwh; Owner: postgres
--

CREATE TABLE dwh.dim_operateurs (
    operateur_key integer NOT NULL,
    operateur_id integer,
    nom_operateur character varying(100),
    prenom_operateur character varying(100),
    fonction character varying(100),
    departement character varying(100),
    niveau_acces character varying(50),
    email character varying(200),
    telephone character varying(20),
    date_embauche date,
    est_actif boolean DEFAULT true,
    date_creation timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    date_modification timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE dwh.dim_operateurs OWNER TO postgres;

--
-- Name: dim_operateurs_operateur_key_seq; Type: SEQUENCE; Schema: dwh; Owner: postgres
--

CREATE SEQUENCE dwh.dim_operateurs_operateur_key_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dwh.dim_operateurs_operateur_key_seq OWNER TO postgres;

--
-- Name: dim_operateurs_operateur_key_seq; Type: SEQUENCE OWNED BY; Schema: dwh; Owner: postgres
--

ALTER SEQUENCE dwh.dim_operateurs_operateur_key_seq OWNED BY dwh.dim_operateurs.operateur_key;


--
-- Name: dim_statuts; Type: TABLE; Schema: dwh; Owner: postgres
--

CREATE TABLE dwh.dim_statuts (
    statut_key integer NOT NULL,
    statut_id integer,
    nom_statut character varying(100),
    description_statut text,
    couleur_statut character varying(10),
    ordre_affichage integer,
    est_actif boolean DEFAULT true,
    date_creation timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    date_modification timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE dwh.dim_statuts OWNER TO postgres;

--
-- Name: dim_statuts_statut_key_seq; Type: SEQUENCE; Schema: dwh; Owner: postgres
--

CREATE SEQUENCE dwh.dim_statuts_statut_key_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dwh.dim_statuts_statut_key_seq OWNER TO postgres;

--
-- Name: dim_statuts_statut_key_seq; Type: SEQUENCE OWNED BY; Schema: dwh; Owner: postgres
--

ALTER SEQUENCE dwh.dim_statuts_statut_key_seq OWNED BY dwh.dim_statuts.statut_key;


--
-- Name: dim_temps; Type: TABLE; Schema: dwh; Owner: postgres
--

CREATE TABLE dwh.dim_temps (
    temps_key integer NOT NULL,
    date_complete date NOT NULL,
    annee integer,
    mois integer,
    jour integer,
    trimestre integer,
    nom_mois character varying(20),
    nom_jour_semaine character varying(20),
    numero_semaine integer,
    est_week_end boolean DEFAULT false,
    est_jour_ferie boolean DEFAULT false,
    date_creation timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE dwh.dim_temps OWNER TO postgres;

--
-- Name: dim_temps_temps_key_seq; Type: SEQUENCE; Schema: dwh; Owner: postgres
--

CREATE SEQUENCE dwh.dim_temps_temps_key_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dwh.dim_temps_temps_key_seq OWNER TO postgres;

--
-- Name: dim_temps_temps_key_seq; Type: SEQUENCE OWNED BY; Schema: dwh; Owner: postgres
--

ALTER SEQUENCE dwh.dim_temps_temps_key_seq OWNED BY dwh.dim_temps.temps_key;


--
-- Name: dim_zones_industrielles; Type: TABLE; Schema: dwh; Owner: postgres
--

CREATE TABLE dwh.dim_zones_industrielles (
    zone_key integer NOT NULL,
    zone_id integer,
    nom_zone character varying(200),
    localisation character varying(200),
    superficie_totale numeric(12,2),
    nb_lots_total integer,
    statut_zone character varying(50),
    date_creation_zone date,
    responsable_zone character varying(100),
    date_creation timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    date_modification timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE dwh.dim_zones_industrielles OWNER TO postgres;

--
-- Name: dim_zones_industrielles_zone_key_seq; Type: SEQUENCE; Schema: dwh; Owner: postgres
--

CREATE SEQUENCE dwh.dim_zones_industrielles_zone_key_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dwh.dim_zones_industrielles_zone_key_seq OWNER TO postgres;

--
-- Name: dim_zones_industrielles_zone_key_seq; Type: SEQUENCE OWNED BY; Schema: dwh; Owner: postgres
--

ALTER SEQUENCE dwh.dim_zones_industrielles_zone_key_seq OWNED BY dwh.dim_zones_industrielles.zone_key;


--
-- Name: fait_demandes_attribution; Type: TABLE; Schema: dwh; Owner: postgres
--

CREATE TABLE dwh.fait_demandes_attribution (
    demande_key integer NOT NULL,
    temps_key integer,
    lot_key integer,
    entreprise_key integer,
    statut_key integer,
    operateur_key integer,
    montant_demande numeric(15,2),
    superficie_demandee numeric(10,2),
    duree_traitement_jours integer,
    nb_documents_fournis integer,
    score_evaluation numeric(5,2),
    date_demande date,
    date_traitement date,
    date_decision date,
    date_attribution date,
    date_creation timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    date_modification timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE dwh.fait_demandes_attribution OWNER TO postgres;

--
-- Name: fait_demandes_attribution_demande_key_seq; Type: SEQUENCE; Schema: dwh; Owner: postgres
--

CREATE SEQUENCE dwh.fait_demandes_attribution_demande_key_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dwh.fait_demandes_attribution_demande_key_seq OWNER TO postgres;

--
-- Name: fait_demandes_attribution_demande_key_seq; Type: SEQUENCE OWNED BY; Schema: dwh; Owner: postgres
--

ALTER SEQUENCE dwh.fait_demandes_attribution_demande_key_seq OWNED BY dwh.fait_demandes_attribution.demande_key;


--
-- Name: fait_factures_paiements; Type: TABLE; Schema: dwh; Owner: postgres
--

CREATE TABLE dwh.fait_factures_paiements (
    facture_key integer NOT NULL,
    temps_key integer,
    lot_key integer,
    entreprise_key integer,
    montant_facture numeric(15,2),
    montant_paye numeric(15,2),
    montant_restant numeric(15,2),
    taux_paiement_pct numeric(5,2),
    nb_jours_retard integer DEFAULT 0,
    type_facture character varying(50),
    statut_paiement character varying(50),
    mode_paiement character varying(50),
    date_facture date,
    date_echeance date,
    date_paiement date,
    date_creation timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE dwh.fait_factures_paiements OWNER TO postgres;

--
-- Name: fait_factures_paiements_facture_key_seq; Type: SEQUENCE; Schema: dwh; Owner: postgres
--

CREATE SEQUENCE dwh.fait_factures_paiements_facture_key_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dwh.fait_factures_paiements_facture_key_seq OWNER TO postgres;

--
-- Name: fait_factures_paiements_facture_key_seq; Type: SEQUENCE OWNED BY; Schema: dwh; Owner: postgres
--

ALTER SEQUENCE dwh.fait_factures_paiements_facture_key_seq OWNED BY dwh.fait_factures_paiements.facture_key;


--
-- Name: fait_occupation_lots; Type: TABLE; Schema: dwh; Owner: postgres
--

CREATE TABLE dwh.fait_occupation_lots (
    occupation_key integer NOT NULL,
    temps_key integer,
    lot_key integer,
    entreprise_key integer,
    taux_occupation_pct numeric(5,2),
    superficie_occupee numeric(10,2),
    superficie_disponible numeric(10,2),
    valeur_occupation numeric(15,2),
    nb_emplois_crees integer,
    investissement_realise numeric(15,2),
    date_debut_occupation date,
    date_fin_prevue date,
    date_creation timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE dwh.fait_occupation_lots OWNER TO postgres;

--
-- Name: fait_occupation_lots_occupation_key_seq; Type: SEQUENCE; Schema: dwh; Owner: postgres
--

CREATE SEQUENCE dwh.fait_occupation_lots_occupation_key_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dwh.fait_occupation_lots_occupation_key_seq OWNER TO postgres;

--
-- Name: fait_occupation_lots_occupation_key_seq; Type: SEQUENCE OWNED BY; Schema: dwh; Owner: postgres
--

ALTER SEQUENCE dwh.fait_occupation_lots_occupation_key_seq OWNED BY dwh.fait_occupation_lots.occupation_key;


--
-- Name: v_demandes_par_statut; Type: VIEW; Schema: dwh; Owner: postgres
--

CREATE VIEW dwh.v_demandes_par_statut AS
 SELECT ds.nom_statut,
    count(*) AS nb_demandes,
    round((((count(*))::numeric * 100.0) / sum(count(*)) OVER ()), 2) AS pourcentage,
    avg(fda.duree_traitement_jours) AS duree_moyenne,
    sum(fda.montant_demande) AS montant_total
   FROM (dwh.fait_demandes_attribution fda
     JOIN dwh.dim_statuts ds ON ((fda.statut_key = ds.statut_key)))
  GROUP BY ds.nom_statut, ds.ordre_affichage
  ORDER BY ds.ordre_affichage;


ALTER TABLE dwh.v_demandes_par_statut OWNER TO postgres;

--
-- Name: v_evolution_demandes; Type: VIEW; Schema: dwh; Owner: postgres
--

CREATE VIEW dwh.v_evolution_demandes AS
 SELECT dt.annee,
    dt.mois,
    ds.nom_statut,
    count(*) AS nb_demandes,
    avg(fda.duree_traitement_jours) AS duree_moyenne_jours,
    sum(fda.montant_demande) AS montant_total
   FROM ((dwh.fait_demandes_attribution fda
     JOIN dwh.dim_temps dt ON ((fda.temps_key = dt.temps_key)))
     JOIN dwh.dim_statuts ds ON ((fda.statut_key = ds.statut_key)))
  GROUP BY dt.annee, dt.mois, ds.nom_statut
  ORDER BY dt.annee, dt.mois, ds.nom_statut;


ALTER TABLE dwh.v_evolution_demandes OWNER TO postgres;

--
-- Name: v_taux_occupation_lots; Type: VIEW; Schema: dwh; Owner: postgres
--

CREATE VIEW dwh.v_taux_occupation_lots AS
 SELECT dzi.nom_zone,
    dl.numero_lot,
    avg(fol.taux_occupation_pct) AS taux_occupation_moyen,
    sum(fol.nb_emplois_crees) AS emplois_total,
    sum(fol.investissement_realise) AS investissement_total,
    max(dt.date_complete) AS derniere_maj
   FROM (((dwh.fait_occupation_lots fol
     JOIN dwh.dim_lots dl ON ((fol.lot_key = dl.lot_key)))
     JOIN dwh.dim_zones_industrielles dzi ON ((dl.zone_key = dzi.zone_key)))
     JOIN dwh.dim_temps dt ON ((fol.temps_key = dt.temps_key)))
  GROUP BY dzi.nom_zone, dl.numero_lot
  ORDER BY (avg(fol.taux_occupation_pct)) DESC;


ALTER TABLE dwh.v_taux_occupation_lots OWNER TO postgres;

--
-- Name: dwh_status; Type: TABLE; Schema: monitoring; Owner: postgres
--

CREATE TABLE monitoring.dwh_status (
    id integer NOT NULL,
    nom_table character varying(100),
    nb_lignes integer,
    derniere_maj timestamp without time zone,
    statut character varying(20),
    message text,
    date_controle timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE monitoring.dwh_status OWNER TO postgres;

--
-- Name: dwh_status_id_seq; Type: SEQUENCE; Schema: monitoring; Owner: postgres
--

CREATE SEQUENCE monitoring.dwh_status_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE monitoring.dwh_status_id_seq OWNER TO postgres;

--
-- Name: dwh_status_id_seq; Type: SEQUENCE OWNED BY; Schema: monitoring; Owner: postgres
--

ALTER SEQUENCE monitoring.dwh_status_id_seq OWNED BY monitoring.dwh_status.id;


--
-- Name: etl_logs; Type: TABLE; Schema: monitoring; Owner: postgres
--

CREATE TABLE monitoring.etl_logs (
    id integer NOT NULL,
    nom_processus character varying(100),
    date_debut timestamp without time zone,
    date_fin timestamp without time zone,
    statut character varying(20),
    nb_lignes_traitees integer,
    nb_erreurs integer,
    message_erreur text,
    duree_secondes integer
);


ALTER TABLE monitoring.etl_logs OWNER TO postgres;

--
-- Name: etl_logs_id_seq; Type: SEQUENCE; Schema: monitoring; Owner: postgres
--

CREATE SEQUENCE monitoring.etl_logs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE monitoring.etl_logs_id_seq OWNER TO postgres;

--
-- Name: etl_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: monitoring; Owner: postgres
--

ALTER SEQUENCE monitoring.etl_logs_id_seq OWNED BY monitoring.etl_logs.id;


--
-- Name: cdc_config id; Type: DEFAULT; Schema: cdc; Owner: postgres
--

ALTER TABLE ONLY cdc.cdc_config ALTER COLUMN id SET DEFAULT nextval('cdc.cdc_config_id_seq'::regclass);


--
-- Name: cdc_logs id; Type: DEFAULT; Schema: cdc; Owner: postgres
--

ALTER TABLE ONLY cdc.cdc_logs ALTER COLUMN id SET DEFAULT nextval('cdc.cdc_logs_id_seq'::regclass);


--
-- Name: cdc_sync_status id; Type: DEFAULT; Schema: cdc; Owner: postgres
--

ALTER TABLE ONLY cdc.cdc_sync_status ALTER COLUMN id SET DEFAULT nextval('cdc.cdc_sync_status_id_seq'::regclass);


--
-- Name: dim_entreprises entreprise_key; Type: DEFAULT; Schema: dwh; Owner: postgres
--

ALTER TABLE ONLY dwh.dim_entreprises ALTER COLUMN entreprise_key SET DEFAULT nextval('dwh.dim_entreprises_entreprise_key_seq'::regclass);


--
-- Name: dim_lots lot_key; Type: DEFAULT; Schema: dwh; Owner: postgres
--

ALTER TABLE ONLY dwh.dim_lots ALTER COLUMN lot_key SET DEFAULT nextval('dwh.dim_lots_lot_key_seq'::regclass);


--
-- Name: dim_operateurs operateur_key; Type: DEFAULT; Schema: dwh; Owner: postgres
--

ALTER TABLE ONLY dwh.dim_operateurs ALTER COLUMN operateur_key SET DEFAULT nextval('dwh.dim_operateurs_operateur_key_seq'::regclass);


--
-- Name: dim_statuts statut_key; Type: DEFAULT; Schema: dwh; Owner: postgres
--

ALTER TABLE ONLY dwh.dim_statuts ALTER COLUMN statut_key SET DEFAULT nextval('dwh.dim_statuts_statut_key_seq'::regclass);


--
-- Name: dim_temps temps_key; Type: DEFAULT; Schema: dwh; Owner: postgres
--

ALTER TABLE ONLY dwh.dim_temps ALTER COLUMN temps_key SET DEFAULT nextval('dwh.dim_temps_temps_key_seq'::regclass);


--
-- Name: dim_zones_industrielles zone_key; Type: DEFAULT; Schema: dwh; Owner: postgres
--

ALTER TABLE ONLY dwh.dim_zones_industrielles ALTER COLUMN zone_key SET DEFAULT nextval('dwh.dim_zones_industrielles_zone_key_seq'::regclass);


--
-- Name: fait_demandes_attribution demande_key; Type: DEFAULT; Schema: dwh; Owner: postgres
--

ALTER TABLE ONLY dwh.fait_demandes_attribution ALTER COLUMN demande_key SET DEFAULT nextval('dwh.fait_demandes_attribution_demande_key_seq'::regclass);


--
-- Name: fait_factures_paiements facture_key; Type: DEFAULT; Schema: dwh; Owner: postgres
--

ALTER TABLE ONLY dwh.fait_factures_paiements ALTER COLUMN facture_key SET DEFAULT nextval('dwh.fait_factures_paiements_facture_key_seq'::regclass);


--
-- Name: fait_occupation_lots occupation_key; Type: DEFAULT; Schema: dwh; Owner: postgres
--

ALTER TABLE ONLY dwh.fait_occupation_lots ALTER COLUMN occupation_key SET DEFAULT nextval('dwh.fait_occupation_lots_occupation_key_seq'::regclass);


--
-- Name: dwh_status id; Type: DEFAULT; Schema: monitoring; Owner: postgres
--

ALTER TABLE ONLY monitoring.dwh_status ALTER COLUMN id SET DEFAULT nextval('monitoring.dwh_status_id_seq'::regclass);


--
-- Name: etl_logs id; Type: DEFAULT; Schema: monitoring; Owner: postgres
--

ALTER TABLE ONLY monitoring.etl_logs ALTER COLUMN id SET DEFAULT nextval('monitoring.etl_logs_id_seq'::regclass);


--
-- Data for Name: cdc_config; Type: TABLE DATA; Schema: cdc; Owner: postgres
--

COPY cdc.cdc_config (id, table_source, table_cible, derniere_sync, mode_sync, est_actif, date_creation) FROM stdin;
1	zones_industrielles	dwh.dim_zones_industrielles	\N	INCREMENTAL	t	2025-10-26 13:41:15.657987
\.


--
-- Data for Name: cdc_logs; Type: TABLE DATA; Schema: cdc; Owner: postgres
--

COPY cdc.cdc_logs (id, config_id, date_sync, nb_lignes_sync, statut, message) FROM stdin;
\.


--
-- Data for Name: cdc_sync_status; Type: TABLE DATA; Schema: cdc; Owner: postgres
--

COPY cdc.cdc_sync_status (id, table_name, last_sync_time, sync_status, error_message, rows_processed, date_created) FROM stdin;
\.


--
-- Data for Name: dim_entreprises; Type: TABLE DATA; Schema: dwh; Owner: postgres
--

COPY dwh.dim_entreprises (entreprise_key, entreprise_id, nom_entreprise, forme_juridique, secteur_activite, taille_entreprise, chiffre_affaires, nb_employes, pays, region, date_creation_entreprise, date_creation, date_modification) FROM stdin;
2	1	SIVOICO	SA	Non spÃ©cifiÃ©	\N	\N	\N	\N	\N	\N	2025-10-03 00:00:00	2025-10-26 13:49:59.063149
3	2	TROPICA INDUS	SA	Non spÃ©cifiÃ©	\N	\N	\N	\N	\N	\N	2025-10-03 00:00:00	2025-10-26 13:49:59.063149
4	3	PHYTOTOP	SARL	Non spÃ©cifiÃ©	\N	\N	\N	\N	\N	\N	2025-10-03 00:00:00	2025-10-26 13:49:59.063149
5	4	DK INDUSTRIE	SARL	Non spÃ©cifiÃ©	\N	\N	\N	\N	\N	\N	2025-10-03 00:00:00	2025-10-26 13:49:59.063149
6	5	SAPCI	SA	Non spÃ©cifiÃ©	\N	\N	\N	\N	\N	\N	2025-10-03 00:00:00	2025-10-26 13:49:59.063149
7	6	BBB COMPANY	SAS	Non spÃ©cifiÃ©	\N	\N	\N	\N	\N	\N	2025-10-03 00:00:00	2025-10-26 13:49:59.063149
8	7	SERAQ	SA	Non spÃ©cifiÃ©	\N	\N	\N	\N	\N	\N	2025-10-03 00:00:00	2025-10-26 13:49:59.063149
9	8	ALUVOTEK	SA	Non spÃ©cifiÃ©	\N	\N	\N	\N	\N	\N	2025-10-03 00:00:00	2025-10-26 13:49:59.063149
10	9	KAFMAH	SARL	Non spÃ©cifiÃ©	\N	\N	\N	\N	\N	\N	2025-10-03 00:00:00	2025-10-26 13:49:59.063149
11	11	SARCI	SA	Non spÃ©cifiÃ©	\N	\N	\N	\N	\N	\N	2025-10-03 00:00:00	2025-10-26 13:49:59.063149
12	12	YVRYDRILING	SAS	Non spÃ©cifiÃ©	\N	\N	\N	\N	\N	\N	2025-10-03 00:00:00	2025-10-26 13:49:59.063149
13	13	SCE CHIMICAL	SARL	Non spÃ©cifiÃ©	\N	\N	\N	\N	\N	\N	2025-10-03 00:00:00	2025-10-26 13:49:59.063149
14	14	NestlÃ© CI SA	SA	Non spÃ©cifiÃ©	\N	\N	\N	\N	\N	\N	2025-10-03 00:00:00	2025-10-26 13:49:59.063149
15	15	Coca-Cola	SA	Non spÃ©cifiÃ©	\N	\N	\N	\N	\N	\N	2025-10-03 00:00:00	2025-10-26 13:49:59.063149
16	16	Unilever CI	SA	Non spÃ©cifiÃ©	\N	\N	\N	\N	\N	\N	2025-10-03 00:00:00	2025-10-26 13:49:59.063149
17	17	 TotalEnergies CI 	SA	Non spÃ©cifiÃ©	\N	\N	\N	\N	\N	\N	2025-10-03 00:00:00	2025-10-26 13:49:59.063149
18	18	Heineken Africa CI	SARL	Non spÃ©cifiÃ©	\N	\N	\N	\N	\N	\N	2025-10-03 00:00:00	2025-10-26 13:49:59.063149
\.


--
-- Data for Name: dim_lots; Type: TABLE DATA; Schema: dwh; Owner: postgres
--

COPY dwh.dim_lots (lot_key, lot_id, zone_key, numero_lot, superficie, prix_m2, statut_lot, type_lot, coordonnees_gps, date_creation, date_modification) FROM stdin;
\.


--
-- Data for Name: dim_operateurs; Type: TABLE DATA; Schema: dwh; Owner: postgres
--

COPY dwh.dim_operateurs (operateur_key, operateur_id, nom_operateur, prenom_operateur, fonction, departement, niveau_acces, email, telephone, date_embauche, est_actif, date_creation, date_modification) FROM stdin;
\.


--
-- Data for Name: dim_statuts; Type: TABLE DATA; Schema: dwh; Owner: postgres
--

COPY dwh.dim_statuts (statut_key, statut_id, nom_statut, description_statut, couleur_statut, ordre_affichage, est_actif, date_creation, date_modification) FROM stdin;
\.


--
-- Data for Name: dim_temps; Type: TABLE DATA; Schema: dwh; Owner: postgres
--

COPY dwh.dim_temps (temps_key, date_complete, annee, mois, jour, trimestre, nom_mois, nom_jour_semaine, numero_semaine, est_week_end, est_jour_ferie, date_creation) FROM stdin;
1	2025-10-26	2025	1	1	\N	\N	\N	\N	f	f	2025-10-26 13:41:15.013002
\.


--
-- Data for Name: dim_zones_industrielles; Type: TABLE DATA; Schema: dwh; Owner: postgres
--

COPY dwh.dim_zones_industrielles (zone_key, zone_id, nom_zone, localisation, superficie_totale, nb_lots_total, statut_zone, date_creation_zone, responsable_zone, date_creation, date_modification) FROM stdin;
2	1	Zone Industrielle de Vridi	Abidjan	120.00	132	actif	\N	\N	2025-10-26 13:49:31.399133	2025-10-26 13:49:31.399133
3	2	Zone Industrielle de Koumassi	Abidjan	120.00	296	actif	\N	\N	2025-10-26 13:49:31.399133	2025-10-26 13:49:31.399133
4	3	Zone Industrielle AkoupÃ©-Zeudji PK24	ABIDJAN	1000.00	0	actif	\N	\N	2025-10-26 13:49:31.399133	2025-10-26 13:49:31.399133
5	4	Zone Industrielle de Yopougon	Yopougon	469.00	400	actif	\N	\N	2025-10-26 13:49:31.399133	2025-10-26 13:49:31.399133
6	5	Zone Industrielle de BouakÃ©	BOUAKE	150.00	20	actif	\N	\N	2025-10-26 13:49:31.399133	2025-10-26 13:49:31.399133
7	19	Zone Test CDC 3 - Modifiée	Non spÃ©cifiÃ©e	400.25	0	actif	\N	\N	2025-10-26 13:49:31.399133	2025-10-26 13:49:31.399133
\.


--
-- Data for Name: fait_demandes_attribution; Type: TABLE DATA; Schema: dwh; Owner: postgres
--

COPY dwh.fait_demandes_attribution (demande_key, temps_key, lot_key, entreprise_key, statut_key, operateur_key, montant_demande, superficie_demandee, duree_traitement_jours, nb_documents_fournis, score_evaluation, date_demande, date_traitement, date_decision, date_attribution, date_creation, date_modification) FROM stdin;
\.


--
-- Data for Name: fait_factures_paiements; Type: TABLE DATA; Schema: dwh; Owner: postgres
--

COPY dwh.fait_factures_paiements (facture_key, temps_key, lot_key, entreprise_key, montant_facture, montant_paye, montant_restant, taux_paiement_pct, nb_jours_retard, type_facture, statut_paiement, mode_paiement, date_facture, date_echeance, date_paiement, date_creation) FROM stdin;
\.


--
-- Data for Name: fait_occupation_lots; Type: TABLE DATA; Schema: dwh; Owner: postgres
--

COPY dwh.fait_occupation_lots (occupation_key, temps_key, lot_key, entreprise_key, taux_occupation_pct, superficie_occupee, superficie_disponible, valeur_occupation, nb_emplois_crees, investissement_realise, date_debut_occupation, date_fin_prevue, date_creation) FROM stdin;
\.


--
-- Data for Name: dwh_status; Type: TABLE DATA; Schema: monitoring; Owner: postgres
--

COPY monitoring.dwh_status (id, nom_table, nb_lignes, derniere_maj, statut, message, date_controle) FROM stdin;
1	dwh.dim_zones_industrielles	\N	\N	ACTIF	\N	2025-10-26 13:41:15.996549
\.


--
-- Data for Name: etl_logs; Type: TABLE DATA; Schema: monitoring; Owner: postgres
--

COPY monitoring.etl_logs (id, nom_processus, date_debut, date_fin, statut, nb_lignes_traitees, nb_erreurs, message_erreur, duree_secondes) FROM stdin;
\.


--
-- Name: cdc_config_id_seq; Type: SEQUENCE SET; Schema: cdc; Owner: postgres
--

SELECT pg_catalog.setval('cdc.cdc_config_id_seq', 1, true);


--
-- Name: cdc_logs_id_seq; Type: SEQUENCE SET; Schema: cdc; Owner: postgres
--

SELECT pg_catalog.setval('cdc.cdc_logs_id_seq', 1, false);


--
-- Name: cdc_sync_status_id_seq; Type: SEQUENCE SET; Schema: cdc; Owner: postgres
--

SELECT pg_catalog.setval('cdc.cdc_sync_status_id_seq', 1, false);


--
-- Name: dim_entreprises_entreprise_key_seq; Type: SEQUENCE SET; Schema: dwh; Owner: postgres
--

SELECT pg_catalog.setval('dwh.dim_entreprises_entreprise_key_seq', 18, true);


--
-- Name: dim_lots_lot_key_seq; Type: SEQUENCE SET; Schema: dwh; Owner: postgres
--

SELECT pg_catalog.setval('dwh.dim_lots_lot_key_seq', 1, false);


--
-- Name: dim_operateurs_operateur_key_seq; Type: SEQUENCE SET; Schema: dwh; Owner: postgres
--

SELECT pg_catalog.setval('dwh.dim_operateurs_operateur_key_seq', 1, false);


--
-- Name: dim_statuts_statut_key_seq; Type: SEQUENCE SET; Schema: dwh; Owner: postgres
--

SELECT pg_catalog.setval('dwh.dim_statuts_statut_key_seq', 1, false);


--
-- Name: dim_temps_temps_key_seq; Type: SEQUENCE SET; Schema: dwh; Owner: postgres
--

SELECT pg_catalog.setval('dwh.dim_temps_temps_key_seq', 1, true);


--
-- Name: dim_zones_industrielles_zone_key_seq; Type: SEQUENCE SET; Schema: dwh; Owner: postgres
--

SELECT pg_catalog.setval('dwh.dim_zones_industrielles_zone_key_seq', 7, true);


--
-- Name: fait_demandes_attribution_demande_key_seq; Type: SEQUENCE SET; Schema: dwh; Owner: postgres
--

SELECT pg_catalog.setval('dwh.fait_demandes_attribution_demande_key_seq', 1, false);


--
-- Name: fait_factures_paiements_facture_key_seq; Type: SEQUENCE SET; Schema: dwh; Owner: postgres
--

SELECT pg_catalog.setval('dwh.fait_factures_paiements_facture_key_seq', 1, false);


--
-- Name: fait_occupation_lots_occupation_key_seq; Type: SEQUENCE SET; Schema: dwh; Owner: postgres
--

SELECT pg_catalog.setval('dwh.fait_occupation_lots_occupation_key_seq', 1, false);


--
-- Name: dwh_status_id_seq; Type: SEQUENCE SET; Schema: monitoring; Owner: postgres
--

SELECT pg_catalog.setval('monitoring.dwh_status_id_seq', 1, true);


--
-- Name: etl_logs_id_seq; Type: SEQUENCE SET; Schema: monitoring; Owner: postgres
--

SELECT pg_catalog.setval('monitoring.etl_logs_id_seq', 1, false);


--
-- Name: cdc_config cdc_config_pkey; Type: CONSTRAINT; Schema: cdc; Owner: postgres
--

ALTER TABLE ONLY cdc.cdc_config
    ADD CONSTRAINT cdc_config_pkey PRIMARY KEY (id);


--
-- Name: cdc_logs cdc_logs_pkey; Type: CONSTRAINT; Schema: cdc; Owner: postgres
--

ALTER TABLE ONLY cdc.cdc_logs
    ADD CONSTRAINT cdc_logs_pkey PRIMARY KEY (id);


--
-- Name: cdc_sync_status cdc_sync_status_pkey; Type: CONSTRAINT; Schema: cdc; Owner: postgres
--

ALTER TABLE ONLY cdc.cdc_sync_status
    ADD CONSTRAINT cdc_sync_status_pkey PRIMARY KEY (id);


--
-- Name: dim_entreprises dim_entreprises_entreprise_id_key; Type: CONSTRAINT; Schema: dwh; Owner: postgres
--

ALTER TABLE ONLY dwh.dim_entreprises
    ADD CONSTRAINT dim_entreprises_entreprise_id_key UNIQUE (entreprise_id);


--
-- Name: dim_entreprises dim_entreprises_pkey; Type: CONSTRAINT; Schema: dwh; Owner: postgres
--

ALTER TABLE ONLY dwh.dim_entreprises
    ADD CONSTRAINT dim_entreprises_pkey PRIMARY KEY (entreprise_key);


--
-- Name: dim_lots dim_lots_lot_id_key; Type: CONSTRAINT; Schema: dwh; Owner: postgres
--

ALTER TABLE ONLY dwh.dim_lots
    ADD CONSTRAINT dim_lots_lot_id_key UNIQUE (lot_id);


--
-- Name: dim_lots dim_lots_pkey; Type: CONSTRAINT; Schema: dwh; Owner: postgres
--

ALTER TABLE ONLY dwh.dim_lots
    ADD CONSTRAINT dim_lots_pkey PRIMARY KEY (lot_key);


--
-- Name: dim_operateurs dim_operateurs_operateur_id_key; Type: CONSTRAINT; Schema: dwh; Owner: postgres
--

ALTER TABLE ONLY dwh.dim_operateurs
    ADD CONSTRAINT dim_operateurs_operateur_id_key UNIQUE (operateur_id);


--
-- Name: dim_operateurs dim_operateurs_pkey; Type: CONSTRAINT; Schema: dwh; Owner: postgres
--

ALTER TABLE ONLY dwh.dim_operateurs
    ADD CONSTRAINT dim_operateurs_pkey PRIMARY KEY (operateur_key);


--
-- Name: dim_statuts dim_statuts_pkey; Type: CONSTRAINT; Schema: dwh; Owner: postgres
--

ALTER TABLE ONLY dwh.dim_statuts
    ADD CONSTRAINT dim_statuts_pkey PRIMARY KEY (statut_key);


--
-- Name: dim_statuts dim_statuts_statut_id_key; Type: CONSTRAINT; Schema: dwh; Owner: postgres
--

ALTER TABLE ONLY dwh.dim_statuts
    ADD CONSTRAINT dim_statuts_statut_id_key UNIQUE (statut_id);


--
-- Name: dim_temps dim_temps_date_complete_key; Type: CONSTRAINT; Schema: dwh; Owner: postgres
--

ALTER TABLE ONLY dwh.dim_temps
    ADD CONSTRAINT dim_temps_date_complete_key UNIQUE (date_complete);


--
-- Name: dim_temps dim_temps_pkey; Type: CONSTRAINT; Schema: dwh; Owner: postgres
--

ALTER TABLE ONLY dwh.dim_temps
    ADD CONSTRAINT dim_temps_pkey PRIMARY KEY (temps_key);


--
-- Name: dim_zones_industrielles dim_zones_industrielles_pkey; Type: CONSTRAINT; Schema: dwh; Owner: postgres
--

ALTER TABLE ONLY dwh.dim_zones_industrielles
    ADD CONSTRAINT dim_zones_industrielles_pkey PRIMARY KEY (zone_key);


--
-- Name: dim_zones_industrielles dim_zones_industrielles_zone_id_key; Type: CONSTRAINT; Schema: dwh; Owner: postgres
--

ALTER TABLE ONLY dwh.dim_zones_industrielles
    ADD CONSTRAINT dim_zones_industrielles_zone_id_key UNIQUE (zone_id);


--
-- Name: fait_demandes_attribution fait_demandes_attribution_pkey; Type: CONSTRAINT; Schema: dwh; Owner: postgres
--

ALTER TABLE ONLY dwh.fait_demandes_attribution
    ADD CONSTRAINT fait_demandes_attribution_pkey PRIMARY KEY (demande_key);


--
-- Name: fait_factures_paiements fait_factures_paiements_pkey; Type: CONSTRAINT; Schema: dwh; Owner: postgres
--

ALTER TABLE ONLY dwh.fait_factures_paiements
    ADD CONSTRAINT fait_factures_paiements_pkey PRIMARY KEY (facture_key);


--
-- Name: fait_occupation_lots fait_occupation_lots_pkey; Type: CONSTRAINT; Schema: dwh; Owner: postgres
--

ALTER TABLE ONLY dwh.fait_occupation_lots
    ADD CONSTRAINT fait_occupation_lots_pkey PRIMARY KEY (occupation_key);


--
-- Name: dwh_status dwh_status_pkey; Type: CONSTRAINT; Schema: monitoring; Owner: postgres
--

ALTER TABLE ONLY monitoring.dwh_status
    ADD CONSTRAINT dwh_status_pkey PRIMARY KEY (id);


--
-- Name: etl_logs etl_logs_pkey; Type: CONSTRAINT; Schema: monitoring; Owner: postgres
--

ALTER TABLE ONLY monitoring.etl_logs
    ADD CONSTRAINT etl_logs_pkey PRIMARY KEY (id);


--
-- Name: cdc_logs cdc_logs_config_id_fkey; Type: FK CONSTRAINT; Schema: cdc; Owner: postgres
--

ALTER TABLE ONLY cdc.cdc_logs
    ADD CONSTRAINT cdc_logs_config_id_fkey FOREIGN KEY (config_id) REFERENCES cdc.cdc_config(id);


--
-- Name: dim_lots dim_lots_zone_key_fkey; Type: FK CONSTRAINT; Schema: dwh; Owner: postgres
--

ALTER TABLE ONLY dwh.dim_lots
    ADD CONSTRAINT dim_lots_zone_key_fkey FOREIGN KEY (zone_key) REFERENCES dwh.dim_zones_industrielles(zone_key);


--
-- Name: fait_demandes_attribution fait_demandes_attribution_entreprise_key_fkey; Type: FK CONSTRAINT; Schema: dwh; Owner: postgres
--

ALTER TABLE ONLY dwh.fait_demandes_attribution
    ADD CONSTRAINT fait_demandes_attribution_entreprise_key_fkey FOREIGN KEY (entreprise_key) REFERENCES dwh.dim_entreprises(entreprise_key);


--
-- Name: fait_demandes_attribution fait_demandes_attribution_lot_key_fkey; Type: FK CONSTRAINT; Schema: dwh; Owner: postgres
--

ALTER TABLE ONLY dwh.fait_demandes_attribution
    ADD CONSTRAINT fait_demandes_attribution_lot_key_fkey FOREIGN KEY (lot_key) REFERENCES dwh.dim_lots(lot_key);


--
-- Name: fait_demandes_attribution fait_demandes_attribution_operateur_key_fkey; Type: FK CONSTRAINT; Schema: dwh; Owner: postgres
--

ALTER TABLE ONLY dwh.fait_demandes_attribution
    ADD CONSTRAINT fait_demandes_attribution_operateur_key_fkey FOREIGN KEY (operateur_key) REFERENCES dwh.dim_operateurs(operateur_key);


--
-- Name: fait_demandes_attribution fait_demandes_attribution_statut_key_fkey; Type: FK CONSTRAINT; Schema: dwh; Owner: postgres
--

ALTER TABLE ONLY dwh.fait_demandes_attribution
    ADD CONSTRAINT fait_demandes_attribution_statut_key_fkey FOREIGN KEY (statut_key) REFERENCES dwh.dim_statuts(statut_key);


--
-- Name: fait_demandes_attribution fait_demandes_attribution_temps_key_fkey; Type: FK CONSTRAINT; Schema: dwh; Owner: postgres
--

ALTER TABLE ONLY dwh.fait_demandes_attribution
    ADD CONSTRAINT fait_demandes_attribution_temps_key_fkey FOREIGN KEY (temps_key) REFERENCES dwh.dim_temps(temps_key);


--
-- Name: fait_factures_paiements fait_factures_paiements_entreprise_key_fkey; Type: FK CONSTRAINT; Schema: dwh; Owner: postgres
--

ALTER TABLE ONLY dwh.fait_factures_paiements
    ADD CONSTRAINT fait_factures_paiements_entreprise_key_fkey FOREIGN KEY (entreprise_key) REFERENCES dwh.dim_entreprises(entreprise_key);


--
-- Name: fait_factures_paiements fait_factures_paiements_lot_key_fkey; Type: FK CONSTRAINT; Schema: dwh; Owner: postgres
--

ALTER TABLE ONLY dwh.fait_factures_paiements
    ADD CONSTRAINT fait_factures_paiements_lot_key_fkey FOREIGN KEY (lot_key) REFERENCES dwh.dim_lots(lot_key);


--
-- Name: fait_factures_paiements fait_factures_paiements_temps_key_fkey; Type: FK CONSTRAINT; Schema: dwh; Owner: postgres
--

ALTER TABLE ONLY dwh.fait_factures_paiements
    ADD CONSTRAINT fait_factures_paiements_temps_key_fkey FOREIGN KEY (temps_key) REFERENCES dwh.dim_temps(temps_key);


--
-- Name: fait_occupation_lots fait_occupation_lots_entreprise_key_fkey; Type: FK CONSTRAINT; Schema: dwh; Owner: postgres
--

ALTER TABLE ONLY dwh.fait_occupation_lots
    ADD CONSTRAINT fait_occupation_lots_entreprise_key_fkey FOREIGN KEY (entreprise_key) REFERENCES dwh.dim_entreprises(entreprise_key);


--
-- Name: fait_occupation_lots fait_occupation_lots_lot_key_fkey; Type: FK CONSTRAINT; Schema: dwh; Owner: postgres
--

ALTER TABLE ONLY dwh.fait_occupation_lots
    ADD CONSTRAINT fait_occupation_lots_lot_key_fkey FOREIGN KEY (lot_key) REFERENCES dwh.dim_lots(lot_key);


--
-- Name: fait_occupation_lots fait_occupation_lots_temps_key_fkey; Type: FK CONSTRAINT; Schema: dwh; Owner: postgres
--

ALTER TABLE ONLY dwh.fait_occupation_lots
    ADD CONSTRAINT fait_occupation_lots_temps_key_fkey FOREIGN KEY (temps_key) REFERENCES dwh.dim_temps(temps_key);


--
-- PostgreSQL database dump complete
--

