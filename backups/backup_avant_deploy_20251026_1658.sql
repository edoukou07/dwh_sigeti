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
    nom_statut character varying(50),
    description_statut text,
    couleur_affichage character varying(7),
    ordre_affichage integer,
    date_creation timestamp without time zone DEFAULT CURRENT_TIMESTAMP
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
    nom_zone character varying(255),
    localisation character varying(255),
    superficie_totale numeric(10,2),
    nb_lots_total integer,
    statut_zone character varying(50),
    date_creation_zone date,
    description_zone text,
    coordonnees_gps character varying(100),
    gestionnaire character varying(100),
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
-- Name: v_monitoring_systeme; Type: VIEW; Schema: dwh; Owner: postgres
--

CREATE VIEW dwh.v_monitoring_systeme AS
 SELECT pg_stat_user_tables.schemaname AS schema_name,
    pg_stat_user_tables.relname AS table_name,
    pg_stat_user_tables.n_tup_ins AS insertions,
    pg_stat_user_tables.n_tup_upd AS modifications,
    pg_stat_user_tables.n_tup_del AS suppressions,
    ((pg_stat_user_tables.n_tup_ins + pg_stat_user_tables.n_tup_upd) + pg_stat_user_tables.n_tup_del) AS total_activite,
    pg_stat_user_tables.last_vacuum,
    pg_stat_user_tables.last_analyze
   FROM pg_stat_user_tables
  WHERE (pg_stat_user_tables.schemaname = ANY (ARRAY['dwh'::name, 'cdc'::name, 'staging'::name, 'etl'::name, 'monitoring'::name]))
  ORDER BY ((pg_stat_user_tables.n_tup_ins + pg_stat_user_tables.n_tup_upd) + pg_stat_user_tables.n_tup_del) DESC;


ALTER TABLE dwh.v_monitoring_systeme OWNER TO postgres;

--
-- Name: v_operateurs_par_fonction; Type: VIEW; Schema: dwh; Owner: postgres
--

CREATE VIEW dwh.v_operateurs_par_fonction AS
 SELECT count(DISTINCT opr.operateur_id) AS total_operateurs,
    opr.fonction,
    count(*) AS nb_operateurs_fonction,
    round((((count(*))::numeric * 100.0) / sum(count(*)) OVER ()), 2) AS pourcentage_fonction
   FROM dwh.dim_operateurs opr
  WHERE (opr.est_actif = true)
  GROUP BY opr.fonction
  ORDER BY (count(*)) DESC;


ALTER TABLE dwh.v_operateurs_par_fonction OWNER TO postgres;

--
-- Name: v_prix_lots_par_zone; Type: VIEW; Schema: dwh; Owner: postgres
--

CREATE VIEW dwh.v_prix_lots_par_zone AS
 SELECT dzi.nom_zone,
    dzi.zone_id,
    count(dl.lot_id) AS nb_lots,
    avg(dl.prix_m2) AS prix_moyen_m2,
    min(dl.prix_m2) AS prix_min_m2,
    max(dl.prix_m2) AS prix_max_m2,
    sum((dl.prix_m2 * dl.superficie)) AS valeur_totale_zone
   FROM (dwh.dim_lots dl
     JOIN dwh.dim_zones_industrielles dzi ON ((dl.zone_key = dzi.zone_key)))
  WHERE (dl.prix_m2 > (0)::numeric)
  GROUP BY dzi.zone_id, dzi.nom_zone
  ORDER BY (avg(dl.prix_m2)) DESC;


ALTER TABLE dwh.v_prix_lots_par_zone OWNER TO postgres;

--
-- Name: v_superficie_par_zone; Type: VIEW; Schema: dwh; Owner: postgres
--

CREATE VIEW dwh.v_superficie_par_zone AS
 SELECT dzi.nom_zone,
    dzi.zone_id,
    dzi.superficie_totale AS superficie_zone,
    sum(dl.superficie) AS superficie_lots_total,
    sum(
        CASE
            WHEN ((dl.statut_lot)::text = 'OCCUPE'::text) THEN dl.superficie
            ELSE (0)::numeric
        END) AS superficie_occupee,
    sum(
        CASE
            WHEN ((dl.statut_lot)::text = 'DISPONIBLE'::text) THEN dl.superficie
            ELSE (0)::numeric
        END) AS superficie_disponible,
    round(((sum(
        CASE
            WHEN ((dl.statut_lot)::text = 'OCCUPE'::text) THEN dl.superficie
            ELSE (0)::numeric
        END) * 100.0) / NULLIF(sum(dl.superficie), (0)::numeric)), 2) AS taux_occupation_superficie_pct
   FROM (dwh.dim_zones_industrielles dzi
     LEFT JOIN dwh.dim_lots dl ON ((dzi.zone_key = dl.zone_key)))
  GROUP BY dzi.zone_id, dzi.nom_zone, dzi.superficie_totale
  ORDER BY dzi.nom_zone;


ALTER TABLE dwh.v_superficie_par_zone OWNER TO postgres;

--
-- Name: v_taux_occupation_lots; Type: VIEW; Schema: dwh; Owner: postgres
--

CREATE VIEW dwh.v_taux_occupation_lots AS
 SELECT dzi.nom_zone,
    dzi.zone_id,
    count(*) AS total_lots,
    count(
        CASE
            WHEN ((dl.statut_lot)::text = 'OCCUPE'::text) THEN 1
            ELSE NULL::integer
        END) AS lots_occupes,
    count(
        CASE
            WHEN ((dl.statut_lot)::text = 'DISPONIBLE'::text) THEN 1
            ELSE NULL::integer
        END) AS lots_disponibles,
    round((((count(
        CASE
            WHEN ((dl.statut_lot)::text = 'OCCUPE'::text) THEN 1
            ELSE NULL::integer
        END))::numeric * 100.0) / (count(*))::numeric), 2) AS taux_occupation_pct
   FROM (dwh.dim_lots dl
     JOIN dwh.dim_zones_industrielles dzi ON ((dl.zone_key = dzi.zone_key)))
  GROUP BY dzi.zone_id, dzi.nom_zone
  ORDER BY (round((((count(
        CASE
            WHEN ((dl.statut_lot)::text = 'OCCUPE'::text) THEN 1
            ELSE NULL::integer
        END))::numeric * 100.0) / (count(*))::numeric), 2)) DESC;


ALTER TABLE dwh.v_taux_occupation_lots OWNER TO postgres;

--
-- Name: logs_etl; Type: TABLE; Schema: etl; Owner: postgres
--

CREATE TABLE etl.logs_etl (
    id integer NOT NULL,
    process_name character varying(100),
    start_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    end_time timestamp without time zone,
    status character varying(50),
    rows_processed integer DEFAULT 0,
    error_message text
);


ALTER TABLE etl.logs_etl OWNER TO postgres;

--
-- Name: logs_etl_id_seq; Type: SEQUENCE; Schema: etl; Owner: postgres
--

CREATE SEQUENCE etl.logs_etl_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE etl.logs_etl_id_seq OWNER TO postgres;

--
-- Name: logs_etl_id_seq; Type: SEQUENCE OWNED BY; Schema: etl; Owner: postgres
--

ALTER SEQUENCE etl.logs_etl_id_seq OWNED BY etl.logs_etl.id;


--
-- Name: dwh_status; Type: TABLE; Schema: monitoring; Owner: postgres
--

CREATE TABLE monitoring.dwh_status (
    id integer NOT NULL,
    nom_table character varying(100),
    derniere_maj timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    nb_lignes integer DEFAULT 0,
    statut character varying(50) DEFAULT 'ACTIF'::character varying,
    commentaires text
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
-- Name: logs_etl id; Type: DEFAULT; Schema: etl; Owner: postgres
--

ALTER TABLE ONLY etl.logs_etl ALTER COLUMN id SET DEFAULT nextval('etl.logs_etl_id_seq'::regclass);


--
-- Name: dwh_status id; Type: DEFAULT; Schema: monitoring; Owner: postgres
--

ALTER TABLE ONLY monitoring.dwh_status ALTER COLUMN id SET DEFAULT nextval('monitoring.dwh_status_id_seq'::regclass);


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

COPY dwh.dim_statuts (statut_key, nom_statut, description_statut, couleur_affichage, ordre_affichage, date_creation) FROM stdin;
1	EN_ATTENTE	Demande en attente de traitement	#FFA500	1	2025-10-26 17:28:58.978127
2	EN_COURS	Demande en cours de traitement	#0066CC	2	2025-10-26 17:28:58.978127
3	APPROUVEE	Demande approuvÃ©e	#00AA00	3	2025-10-26 17:28:58.978127
4	REJETEE	Demande rejetÃ©e	#CC0000	4	2025-10-26 17:28:58.978127
5	SUSPENDUE	Demande suspendue	#800080	5	2025-10-26 17:28:58.978127
\.


--
-- Data for Name: dim_temps; Type: TABLE DATA; Schema: dwh; Owner: postgres
--

COPY dwh.dim_temps (temps_key, date_complete, annee, mois, jour, trimestre, nom_mois, nom_jour_semaine, numero_semaine, est_week_end, est_jour_ferie, date_creation) FROM stdin;
1	2025-01-01	2025	1	1	1	Janvier	Mercredi	1	f	f	2025-10-26 17:28:58.981278
2	2025-01-02	2025	1	2	1	Janvier	Jeudi	1	f	f	2025-10-26 17:28:58.981278
3	2025-01-03	2025	1	3	1	Janvier	Vendredi	1	f	f	2025-10-26 17:28:58.981278
4	2025-01-04	2025	1	4	1	Janvier	Samedi	1	t	f	2025-10-26 17:28:58.981278
5	2025-01-05	2025	1	5	1	Janvier	Dimanche	1	t	f	2025-10-26 17:28:58.981278
6	2025-01-06	2025	1	6	1	Janvier	Lundi	2	f	f	2025-10-26 17:28:58.981278
7	2025-01-07	2025	1	7	1	Janvier	Mardi	2	f	f	2025-10-26 17:28:58.981278
8	2025-01-08	2025	1	8	1	Janvier	Mercredi	2	f	f	2025-10-26 17:28:58.981278
9	2025-01-09	2025	1	9	1	Janvier	Jeudi	2	f	f	2025-10-26 17:28:58.981278
10	2025-01-10	2025	1	10	1	Janvier	Vendredi	2	f	f	2025-10-26 17:28:58.981278
11	2025-01-11	2025	1	11	1	Janvier	Samedi	2	t	f	2025-10-26 17:28:58.981278
12	2025-01-12	2025	1	12	1	Janvier	Dimanche	2	t	f	2025-10-26 17:28:58.981278
13	2025-01-13	2025	1	13	1	Janvier	Lundi	3	f	f	2025-10-26 17:28:58.981278
14	2025-01-14	2025	1	14	1	Janvier	Mardi	3	f	f	2025-10-26 17:28:58.981278
15	2025-01-15	2025	1	15	1	Janvier	Mercredi	3	f	f	2025-10-26 17:28:58.981278
16	2025-01-16	2025	1	16	1	Janvier	Jeudi	3	f	f	2025-10-26 17:28:58.981278
17	2025-01-17	2025	1	17	1	Janvier	Vendredi	3	f	f	2025-10-26 17:28:58.981278
18	2025-01-18	2025	1	18	1	Janvier	Samedi	3	t	f	2025-10-26 17:28:58.981278
19	2025-01-19	2025	1	19	1	Janvier	Dimanche	3	t	f	2025-10-26 17:28:58.981278
20	2025-01-20	2025	1	20	1	Janvier	Lundi	4	f	f	2025-10-26 17:28:58.981278
21	2025-01-21	2025	1	21	1	Janvier	Mardi	4	f	f	2025-10-26 17:28:58.981278
22	2025-01-22	2025	1	22	1	Janvier	Mercredi	4	f	f	2025-10-26 17:28:58.981278
23	2025-01-23	2025	1	23	1	Janvier	Jeudi	4	f	f	2025-10-26 17:28:58.981278
24	2025-01-24	2025	1	24	1	Janvier	Vendredi	4	f	f	2025-10-26 17:28:58.981278
25	2025-01-25	2025	1	25	1	Janvier	Samedi	4	t	f	2025-10-26 17:28:58.981278
26	2025-01-26	2025	1	26	1	Janvier	Dimanche	4	t	f	2025-10-26 17:28:58.981278
27	2025-01-27	2025	1	27	1	Janvier	Lundi	5	f	f	2025-10-26 17:28:58.981278
28	2025-01-28	2025	1	28	1	Janvier	Mardi	5	f	f	2025-10-26 17:28:58.981278
29	2025-01-29	2025	1	29	1	Janvier	Mercredi	5	f	f	2025-10-26 17:28:58.981278
30	2025-01-30	2025	1	30	1	Janvier	Jeudi	5	f	f	2025-10-26 17:28:58.981278
31	2025-01-31	2025	1	31	1	Janvier	Vendredi	5	f	f	2025-10-26 17:28:58.981278
32	2025-02-01	2025	2	1	1	FÃ©vrier	Samedi	5	t	f	2025-10-26 17:28:58.981278
33	2025-02-02	2025	2	2	1	FÃ©vrier	Dimanche	5	t	f	2025-10-26 17:28:58.981278
34	2025-02-03	2025	2	3	1	FÃ©vrier	Lundi	6	f	f	2025-10-26 17:28:58.981278
35	2025-02-04	2025	2	4	1	FÃ©vrier	Mardi	6	f	f	2025-10-26 17:28:58.981278
36	2025-02-05	2025	2	5	1	FÃ©vrier	Mercredi	6	f	f	2025-10-26 17:28:58.981278
37	2025-02-06	2025	2	6	1	FÃ©vrier	Jeudi	6	f	f	2025-10-26 17:28:58.981278
38	2025-02-07	2025	2	7	1	FÃ©vrier	Vendredi	6	f	f	2025-10-26 17:28:58.981278
39	2025-02-08	2025	2	8	1	FÃ©vrier	Samedi	6	t	f	2025-10-26 17:28:58.981278
40	2025-02-09	2025	2	9	1	FÃ©vrier	Dimanche	6	t	f	2025-10-26 17:28:58.981278
41	2025-02-10	2025	2	10	1	FÃ©vrier	Lundi	7	f	f	2025-10-26 17:28:58.981278
42	2025-02-11	2025	2	11	1	FÃ©vrier	Mardi	7	f	f	2025-10-26 17:28:58.981278
43	2025-02-12	2025	2	12	1	FÃ©vrier	Mercredi	7	f	f	2025-10-26 17:28:58.981278
44	2025-02-13	2025	2	13	1	FÃ©vrier	Jeudi	7	f	f	2025-10-26 17:28:58.981278
45	2025-02-14	2025	2	14	1	FÃ©vrier	Vendredi	7	f	f	2025-10-26 17:28:58.981278
46	2025-02-15	2025	2	15	1	FÃ©vrier	Samedi	7	t	f	2025-10-26 17:28:58.981278
47	2025-02-16	2025	2	16	1	FÃ©vrier	Dimanche	7	t	f	2025-10-26 17:28:58.981278
48	2025-02-17	2025	2	17	1	FÃ©vrier	Lundi	8	f	f	2025-10-26 17:28:58.981278
49	2025-02-18	2025	2	18	1	FÃ©vrier	Mardi	8	f	f	2025-10-26 17:28:58.981278
50	2025-02-19	2025	2	19	1	FÃ©vrier	Mercredi	8	f	f	2025-10-26 17:28:58.981278
51	2025-02-20	2025	2	20	1	FÃ©vrier	Jeudi	8	f	f	2025-10-26 17:28:58.981278
52	2025-02-21	2025	2	21	1	FÃ©vrier	Vendredi	8	f	f	2025-10-26 17:28:58.981278
53	2025-02-22	2025	2	22	1	FÃ©vrier	Samedi	8	t	f	2025-10-26 17:28:58.981278
54	2025-02-23	2025	2	23	1	FÃ©vrier	Dimanche	8	t	f	2025-10-26 17:28:58.981278
55	2025-02-24	2025	2	24	1	FÃ©vrier	Lundi	9	f	f	2025-10-26 17:28:58.981278
56	2025-02-25	2025	2	25	1	FÃ©vrier	Mardi	9	f	f	2025-10-26 17:28:58.981278
57	2025-02-26	2025	2	26	1	FÃ©vrier	Mercredi	9	f	f	2025-10-26 17:28:58.981278
58	2025-02-27	2025	2	27	1	FÃ©vrier	Jeudi	9	f	f	2025-10-26 17:28:58.981278
59	2025-02-28	2025	2	28	1	FÃ©vrier	Vendredi	9	f	f	2025-10-26 17:28:58.981278
60	2025-03-01	2025	3	1	1	Mars	Samedi	9	t	f	2025-10-26 17:28:58.981278
61	2025-03-02	2025	3	2	1	Mars	Dimanche	9	t	f	2025-10-26 17:28:58.981278
62	2025-03-03	2025	3	3	1	Mars	Lundi	10	f	f	2025-10-26 17:28:58.981278
63	2025-03-04	2025	3	4	1	Mars	Mardi	10	f	f	2025-10-26 17:28:58.981278
64	2025-03-05	2025	3	5	1	Mars	Mercredi	10	f	f	2025-10-26 17:28:58.981278
65	2025-03-06	2025	3	6	1	Mars	Jeudi	10	f	f	2025-10-26 17:28:58.981278
66	2025-03-07	2025	3	7	1	Mars	Vendredi	10	f	f	2025-10-26 17:28:58.981278
67	2025-03-08	2025	3	8	1	Mars	Samedi	10	t	f	2025-10-26 17:28:58.981278
68	2025-03-09	2025	3	9	1	Mars	Dimanche	10	t	f	2025-10-26 17:28:58.981278
69	2025-03-10	2025	3	10	1	Mars	Lundi	11	f	f	2025-10-26 17:28:58.981278
70	2025-03-11	2025	3	11	1	Mars	Mardi	11	f	f	2025-10-26 17:28:58.981278
71	2025-03-12	2025	3	12	1	Mars	Mercredi	11	f	f	2025-10-26 17:28:58.981278
72	2025-03-13	2025	3	13	1	Mars	Jeudi	11	f	f	2025-10-26 17:28:58.981278
73	2025-03-14	2025	3	14	1	Mars	Vendredi	11	f	f	2025-10-26 17:28:58.981278
74	2025-03-15	2025	3	15	1	Mars	Samedi	11	t	f	2025-10-26 17:28:58.981278
75	2025-03-16	2025	3	16	1	Mars	Dimanche	11	t	f	2025-10-26 17:28:58.981278
76	2025-03-17	2025	3	17	1	Mars	Lundi	12	f	f	2025-10-26 17:28:58.981278
77	2025-03-18	2025	3	18	1	Mars	Mardi	12	f	f	2025-10-26 17:28:58.981278
78	2025-03-19	2025	3	19	1	Mars	Mercredi	12	f	f	2025-10-26 17:28:58.981278
79	2025-03-20	2025	3	20	1	Mars	Jeudi	12	f	f	2025-10-26 17:28:58.981278
80	2025-03-21	2025	3	21	1	Mars	Vendredi	12	f	f	2025-10-26 17:28:58.981278
81	2025-03-22	2025	3	22	1	Mars	Samedi	12	t	f	2025-10-26 17:28:58.981278
82	2025-03-23	2025	3	23	1	Mars	Dimanche	12	t	f	2025-10-26 17:28:58.981278
83	2025-03-24	2025	3	24	1	Mars	Lundi	13	f	f	2025-10-26 17:28:58.981278
84	2025-03-25	2025	3	25	1	Mars	Mardi	13	f	f	2025-10-26 17:28:58.981278
85	2025-03-26	2025	3	26	1	Mars	Mercredi	13	f	f	2025-10-26 17:28:58.981278
86	2025-03-27	2025	3	27	1	Mars	Jeudi	13	f	f	2025-10-26 17:28:58.981278
87	2025-03-28	2025	3	28	1	Mars	Vendredi	13	f	f	2025-10-26 17:28:58.981278
88	2025-03-29	2025	3	29	1	Mars	Samedi	13	t	f	2025-10-26 17:28:58.981278
89	2025-03-30	2025	3	30	1	Mars	Dimanche	13	t	f	2025-10-26 17:28:58.981278
90	2025-03-31	2025	3	31	1	Mars	Lundi	14	f	f	2025-10-26 17:28:58.981278
91	2025-04-01	2025	4	1	2	Avril	Mardi	14	f	f	2025-10-26 17:28:58.981278
92	2025-04-02	2025	4	2	2	Avril	Mercredi	14	f	f	2025-10-26 17:28:58.981278
93	2025-04-03	2025	4	3	2	Avril	Jeudi	14	f	f	2025-10-26 17:28:58.981278
94	2025-04-04	2025	4	4	2	Avril	Vendredi	14	f	f	2025-10-26 17:28:58.981278
95	2025-04-05	2025	4	5	2	Avril	Samedi	14	t	f	2025-10-26 17:28:58.981278
96	2025-04-06	2025	4	6	2	Avril	Dimanche	14	t	f	2025-10-26 17:28:58.981278
97	2025-04-07	2025	4	7	2	Avril	Lundi	15	f	f	2025-10-26 17:28:58.981278
98	2025-04-08	2025	4	8	2	Avril	Mardi	15	f	f	2025-10-26 17:28:58.981278
99	2025-04-09	2025	4	9	2	Avril	Mercredi	15	f	f	2025-10-26 17:28:58.981278
100	2025-04-10	2025	4	10	2	Avril	Jeudi	15	f	f	2025-10-26 17:28:58.981278
101	2025-04-11	2025	4	11	2	Avril	Vendredi	15	f	f	2025-10-26 17:28:58.981278
102	2025-04-12	2025	4	12	2	Avril	Samedi	15	t	f	2025-10-26 17:28:58.981278
103	2025-04-13	2025	4	13	2	Avril	Dimanche	15	t	f	2025-10-26 17:28:58.981278
104	2025-04-14	2025	4	14	2	Avril	Lundi	16	f	f	2025-10-26 17:28:58.981278
105	2025-04-15	2025	4	15	2	Avril	Mardi	16	f	f	2025-10-26 17:28:58.981278
106	2025-04-16	2025	4	16	2	Avril	Mercredi	16	f	f	2025-10-26 17:28:58.981278
107	2025-04-17	2025	4	17	2	Avril	Jeudi	16	f	f	2025-10-26 17:28:58.981278
108	2025-04-18	2025	4	18	2	Avril	Vendredi	16	f	f	2025-10-26 17:28:58.981278
109	2025-04-19	2025	4	19	2	Avril	Samedi	16	t	f	2025-10-26 17:28:58.981278
110	2025-04-20	2025	4	20	2	Avril	Dimanche	16	t	f	2025-10-26 17:28:58.981278
111	2025-04-21	2025	4	21	2	Avril	Lundi	17	f	f	2025-10-26 17:28:58.981278
112	2025-04-22	2025	4	22	2	Avril	Mardi	17	f	f	2025-10-26 17:28:58.981278
113	2025-04-23	2025	4	23	2	Avril	Mercredi	17	f	f	2025-10-26 17:28:58.981278
114	2025-04-24	2025	4	24	2	Avril	Jeudi	17	f	f	2025-10-26 17:28:58.981278
115	2025-04-25	2025	4	25	2	Avril	Vendredi	17	f	f	2025-10-26 17:28:58.981278
116	2025-04-26	2025	4	26	2	Avril	Samedi	17	t	f	2025-10-26 17:28:58.981278
117	2025-04-27	2025	4	27	2	Avril	Dimanche	17	t	f	2025-10-26 17:28:58.981278
118	2025-04-28	2025	4	28	2	Avril	Lundi	18	f	f	2025-10-26 17:28:58.981278
119	2025-04-29	2025	4	29	2	Avril	Mardi	18	f	f	2025-10-26 17:28:58.981278
120	2025-04-30	2025	4	30	2	Avril	Mercredi	18	f	f	2025-10-26 17:28:58.981278
121	2025-05-01	2025	5	1	2	Mai	Jeudi	18	f	f	2025-10-26 17:28:58.981278
122	2025-05-02	2025	5	2	2	Mai	Vendredi	18	f	f	2025-10-26 17:28:58.981278
123	2025-05-03	2025	5	3	2	Mai	Samedi	18	t	f	2025-10-26 17:28:58.981278
124	2025-05-04	2025	5	4	2	Mai	Dimanche	18	t	f	2025-10-26 17:28:58.981278
125	2025-05-05	2025	5	5	2	Mai	Lundi	19	f	f	2025-10-26 17:28:58.981278
126	2025-05-06	2025	5	6	2	Mai	Mardi	19	f	f	2025-10-26 17:28:58.981278
127	2025-05-07	2025	5	7	2	Mai	Mercredi	19	f	f	2025-10-26 17:28:58.981278
128	2025-05-08	2025	5	8	2	Mai	Jeudi	19	f	f	2025-10-26 17:28:58.981278
129	2025-05-09	2025	5	9	2	Mai	Vendredi	19	f	f	2025-10-26 17:28:58.981278
130	2025-05-10	2025	5	10	2	Mai	Samedi	19	t	f	2025-10-26 17:28:58.981278
131	2025-05-11	2025	5	11	2	Mai	Dimanche	19	t	f	2025-10-26 17:28:58.981278
132	2025-05-12	2025	5	12	2	Mai	Lundi	20	f	f	2025-10-26 17:28:58.981278
133	2025-05-13	2025	5	13	2	Mai	Mardi	20	f	f	2025-10-26 17:28:58.981278
134	2025-05-14	2025	5	14	2	Mai	Mercredi	20	f	f	2025-10-26 17:28:58.981278
135	2025-05-15	2025	5	15	2	Mai	Jeudi	20	f	f	2025-10-26 17:28:58.981278
136	2025-05-16	2025	5	16	2	Mai	Vendredi	20	f	f	2025-10-26 17:28:58.981278
137	2025-05-17	2025	5	17	2	Mai	Samedi	20	t	f	2025-10-26 17:28:58.981278
138	2025-05-18	2025	5	18	2	Mai	Dimanche	20	t	f	2025-10-26 17:28:58.981278
139	2025-05-19	2025	5	19	2	Mai	Lundi	21	f	f	2025-10-26 17:28:58.981278
140	2025-05-20	2025	5	20	2	Mai	Mardi	21	f	f	2025-10-26 17:28:58.981278
141	2025-05-21	2025	5	21	2	Mai	Mercredi	21	f	f	2025-10-26 17:28:58.981278
142	2025-05-22	2025	5	22	2	Mai	Jeudi	21	f	f	2025-10-26 17:28:58.981278
143	2025-05-23	2025	5	23	2	Mai	Vendredi	21	f	f	2025-10-26 17:28:58.981278
144	2025-05-24	2025	5	24	2	Mai	Samedi	21	t	f	2025-10-26 17:28:58.981278
145	2025-05-25	2025	5	25	2	Mai	Dimanche	21	t	f	2025-10-26 17:28:58.981278
146	2025-05-26	2025	5	26	2	Mai	Lundi	22	f	f	2025-10-26 17:28:58.981278
147	2025-05-27	2025	5	27	2	Mai	Mardi	22	f	f	2025-10-26 17:28:58.981278
148	2025-05-28	2025	5	28	2	Mai	Mercredi	22	f	f	2025-10-26 17:28:58.981278
149	2025-05-29	2025	5	29	2	Mai	Jeudi	22	f	f	2025-10-26 17:28:58.981278
150	2025-05-30	2025	5	30	2	Mai	Vendredi	22	f	f	2025-10-26 17:28:58.981278
151	2025-05-31	2025	5	31	2	Mai	Samedi	22	t	f	2025-10-26 17:28:58.981278
152	2025-06-01	2025	6	1	2	Juin	Dimanche	22	t	f	2025-10-26 17:28:58.981278
153	2025-06-02	2025	6	2	2	Juin	Lundi	23	f	f	2025-10-26 17:28:58.981278
154	2025-06-03	2025	6	3	2	Juin	Mardi	23	f	f	2025-10-26 17:28:58.981278
155	2025-06-04	2025	6	4	2	Juin	Mercredi	23	f	f	2025-10-26 17:28:58.981278
156	2025-06-05	2025	6	5	2	Juin	Jeudi	23	f	f	2025-10-26 17:28:58.981278
157	2025-06-06	2025	6	6	2	Juin	Vendredi	23	f	f	2025-10-26 17:28:58.981278
158	2025-06-07	2025	6	7	2	Juin	Samedi	23	t	f	2025-10-26 17:28:58.981278
159	2025-06-08	2025	6	8	2	Juin	Dimanche	23	t	f	2025-10-26 17:28:58.981278
160	2025-06-09	2025	6	9	2	Juin	Lundi	24	f	f	2025-10-26 17:28:58.981278
161	2025-06-10	2025	6	10	2	Juin	Mardi	24	f	f	2025-10-26 17:28:58.981278
162	2025-06-11	2025	6	11	2	Juin	Mercredi	24	f	f	2025-10-26 17:28:58.981278
163	2025-06-12	2025	6	12	2	Juin	Jeudi	24	f	f	2025-10-26 17:28:58.981278
164	2025-06-13	2025	6	13	2	Juin	Vendredi	24	f	f	2025-10-26 17:28:58.981278
165	2025-06-14	2025	6	14	2	Juin	Samedi	24	t	f	2025-10-26 17:28:58.981278
166	2025-06-15	2025	6	15	2	Juin	Dimanche	24	t	f	2025-10-26 17:28:58.981278
167	2025-06-16	2025	6	16	2	Juin	Lundi	25	f	f	2025-10-26 17:28:58.981278
168	2025-06-17	2025	6	17	2	Juin	Mardi	25	f	f	2025-10-26 17:28:58.981278
169	2025-06-18	2025	6	18	2	Juin	Mercredi	25	f	f	2025-10-26 17:28:58.981278
170	2025-06-19	2025	6	19	2	Juin	Jeudi	25	f	f	2025-10-26 17:28:58.981278
171	2025-06-20	2025	6	20	2	Juin	Vendredi	25	f	f	2025-10-26 17:28:58.981278
172	2025-06-21	2025	6	21	2	Juin	Samedi	25	t	f	2025-10-26 17:28:58.981278
173	2025-06-22	2025	6	22	2	Juin	Dimanche	25	t	f	2025-10-26 17:28:58.981278
174	2025-06-23	2025	6	23	2	Juin	Lundi	26	f	f	2025-10-26 17:28:58.981278
175	2025-06-24	2025	6	24	2	Juin	Mardi	26	f	f	2025-10-26 17:28:58.981278
176	2025-06-25	2025	6	25	2	Juin	Mercredi	26	f	f	2025-10-26 17:28:58.981278
177	2025-06-26	2025	6	26	2	Juin	Jeudi	26	f	f	2025-10-26 17:28:58.981278
178	2025-06-27	2025	6	27	2	Juin	Vendredi	26	f	f	2025-10-26 17:28:58.981278
179	2025-06-28	2025	6	28	2	Juin	Samedi	26	t	f	2025-10-26 17:28:58.981278
180	2025-06-29	2025	6	29	2	Juin	Dimanche	26	t	f	2025-10-26 17:28:58.981278
181	2025-06-30	2025	6	30	2	Juin	Lundi	27	f	f	2025-10-26 17:28:58.981278
182	2025-07-01	2025	7	1	3	Juillet	Mardi	27	f	f	2025-10-26 17:28:58.981278
183	2025-07-02	2025	7	2	3	Juillet	Mercredi	27	f	f	2025-10-26 17:28:58.981278
184	2025-07-03	2025	7	3	3	Juillet	Jeudi	27	f	f	2025-10-26 17:28:58.981278
185	2025-07-04	2025	7	4	3	Juillet	Vendredi	27	f	f	2025-10-26 17:28:58.981278
186	2025-07-05	2025	7	5	3	Juillet	Samedi	27	t	f	2025-10-26 17:28:58.981278
187	2025-07-06	2025	7	6	3	Juillet	Dimanche	27	t	f	2025-10-26 17:28:58.981278
188	2025-07-07	2025	7	7	3	Juillet	Lundi	28	f	f	2025-10-26 17:28:58.981278
189	2025-07-08	2025	7	8	3	Juillet	Mardi	28	f	f	2025-10-26 17:28:58.981278
190	2025-07-09	2025	7	9	3	Juillet	Mercredi	28	f	f	2025-10-26 17:28:58.981278
191	2025-07-10	2025	7	10	3	Juillet	Jeudi	28	f	f	2025-10-26 17:28:58.981278
192	2025-07-11	2025	7	11	3	Juillet	Vendredi	28	f	f	2025-10-26 17:28:58.981278
193	2025-07-12	2025	7	12	3	Juillet	Samedi	28	t	f	2025-10-26 17:28:58.981278
194	2025-07-13	2025	7	13	3	Juillet	Dimanche	28	t	f	2025-10-26 17:28:58.981278
195	2025-07-14	2025	7	14	3	Juillet	Lundi	29	f	f	2025-10-26 17:28:58.981278
196	2025-07-15	2025	7	15	3	Juillet	Mardi	29	f	f	2025-10-26 17:28:58.981278
197	2025-07-16	2025	7	16	3	Juillet	Mercredi	29	f	f	2025-10-26 17:28:58.981278
198	2025-07-17	2025	7	17	3	Juillet	Jeudi	29	f	f	2025-10-26 17:28:58.981278
199	2025-07-18	2025	7	18	3	Juillet	Vendredi	29	f	f	2025-10-26 17:28:58.981278
200	2025-07-19	2025	7	19	3	Juillet	Samedi	29	t	f	2025-10-26 17:28:58.981278
201	2025-07-20	2025	7	20	3	Juillet	Dimanche	29	t	f	2025-10-26 17:28:58.981278
202	2025-07-21	2025	7	21	3	Juillet	Lundi	30	f	f	2025-10-26 17:28:58.981278
203	2025-07-22	2025	7	22	3	Juillet	Mardi	30	f	f	2025-10-26 17:28:58.981278
204	2025-07-23	2025	7	23	3	Juillet	Mercredi	30	f	f	2025-10-26 17:28:58.981278
205	2025-07-24	2025	7	24	3	Juillet	Jeudi	30	f	f	2025-10-26 17:28:58.981278
206	2025-07-25	2025	7	25	3	Juillet	Vendredi	30	f	f	2025-10-26 17:28:58.981278
207	2025-07-26	2025	7	26	3	Juillet	Samedi	30	t	f	2025-10-26 17:28:58.981278
208	2025-07-27	2025	7	27	3	Juillet	Dimanche	30	t	f	2025-10-26 17:28:58.981278
209	2025-07-28	2025	7	28	3	Juillet	Lundi	31	f	f	2025-10-26 17:28:58.981278
210	2025-07-29	2025	7	29	3	Juillet	Mardi	31	f	f	2025-10-26 17:28:58.981278
211	2025-07-30	2025	7	30	3	Juillet	Mercredi	31	f	f	2025-10-26 17:28:58.981278
212	2025-07-31	2025	7	31	3	Juillet	Jeudi	31	f	f	2025-10-26 17:28:58.981278
213	2025-08-01	2025	8	1	3	AoÃ»t	Vendredi	31	f	f	2025-10-26 17:28:58.981278
214	2025-08-02	2025	8	2	3	AoÃ»t	Samedi	31	t	f	2025-10-26 17:28:58.981278
215	2025-08-03	2025	8	3	3	AoÃ»t	Dimanche	31	t	f	2025-10-26 17:28:58.981278
216	2025-08-04	2025	8	4	3	AoÃ»t	Lundi	32	f	f	2025-10-26 17:28:58.981278
217	2025-08-05	2025	8	5	3	AoÃ»t	Mardi	32	f	f	2025-10-26 17:28:58.981278
218	2025-08-06	2025	8	6	3	AoÃ»t	Mercredi	32	f	f	2025-10-26 17:28:58.981278
219	2025-08-07	2025	8	7	3	AoÃ»t	Jeudi	32	f	f	2025-10-26 17:28:58.981278
220	2025-08-08	2025	8	8	3	AoÃ»t	Vendredi	32	f	f	2025-10-26 17:28:58.981278
221	2025-08-09	2025	8	9	3	AoÃ»t	Samedi	32	t	f	2025-10-26 17:28:58.981278
222	2025-08-10	2025	8	10	3	AoÃ»t	Dimanche	32	t	f	2025-10-26 17:28:58.981278
223	2025-08-11	2025	8	11	3	AoÃ»t	Lundi	33	f	f	2025-10-26 17:28:58.981278
224	2025-08-12	2025	8	12	3	AoÃ»t	Mardi	33	f	f	2025-10-26 17:28:58.981278
225	2025-08-13	2025	8	13	3	AoÃ»t	Mercredi	33	f	f	2025-10-26 17:28:58.981278
226	2025-08-14	2025	8	14	3	AoÃ»t	Jeudi	33	f	f	2025-10-26 17:28:58.981278
227	2025-08-15	2025	8	15	3	AoÃ»t	Vendredi	33	f	f	2025-10-26 17:28:58.981278
228	2025-08-16	2025	8	16	3	AoÃ»t	Samedi	33	t	f	2025-10-26 17:28:58.981278
229	2025-08-17	2025	8	17	3	AoÃ»t	Dimanche	33	t	f	2025-10-26 17:28:58.981278
230	2025-08-18	2025	8	18	3	AoÃ»t	Lundi	34	f	f	2025-10-26 17:28:58.981278
231	2025-08-19	2025	8	19	3	AoÃ»t	Mardi	34	f	f	2025-10-26 17:28:58.981278
232	2025-08-20	2025	8	20	3	AoÃ»t	Mercredi	34	f	f	2025-10-26 17:28:58.981278
233	2025-08-21	2025	8	21	3	AoÃ»t	Jeudi	34	f	f	2025-10-26 17:28:58.981278
234	2025-08-22	2025	8	22	3	AoÃ»t	Vendredi	34	f	f	2025-10-26 17:28:58.981278
235	2025-08-23	2025	8	23	3	AoÃ»t	Samedi	34	t	f	2025-10-26 17:28:58.981278
236	2025-08-24	2025	8	24	3	AoÃ»t	Dimanche	34	t	f	2025-10-26 17:28:58.981278
237	2025-08-25	2025	8	25	3	AoÃ»t	Lundi	35	f	f	2025-10-26 17:28:58.981278
238	2025-08-26	2025	8	26	3	AoÃ»t	Mardi	35	f	f	2025-10-26 17:28:58.981278
239	2025-08-27	2025	8	27	3	AoÃ»t	Mercredi	35	f	f	2025-10-26 17:28:58.981278
240	2025-08-28	2025	8	28	3	AoÃ»t	Jeudi	35	f	f	2025-10-26 17:28:58.981278
241	2025-08-29	2025	8	29	3	AoÃ»t	Vendredi	35	f	f	2025-10-26 17:28:58.981278
242	2025-08-30	2025	8	30	3	AoÃ»t	Samedi	35	t	f	2025-10-26 17:28:58.981278
243	2025-08-31	2025	8	31	3	AoÃ»t	Dimanche	35	t	f	2025-10-26 17:28:58.981278
244	2025-09-01	2025	9	1	3	Septembre	Lundi	36	f	f	2025-10-26 17:28:58.981278
245	2025-09-02	2025	9	2	3	Septembre	Mardi	36	f	f	2025-10-26 17:28:58.981278
246	2025-09-03	2025	9	3	3	Septembre	Mercredi	36	f	f	2025-10-26 17:28:58.981278
247	2025-09-04	2025	9	4	3	Septembre	Jeudi	36	f	f	2025-10-26 17:28:58.981278
248	2025-09-05	2025	9	5	3	Septembre	Vendredi	36	f	f	2025-10-26 17:28:58.981278
249	2025-09-06	2025	9	6	3	Septembre	Samedi	36	t	f	2025-10-26 17:28:58.981278
250	2025-09-07	2025	9	7	3	Septembre	Dimanche	36	t	f	2025-10-26 17:28:58.981278
251	2025-09-08	2025	9	8	3	Septembre	Lundi	37	f	f	2025-10-26 17:28:58.981278
252	2025-09-09	2025	9	9	3	Septembre	Mardi	37	f	f	2025-10-26 17:28:58.981278
253	2025-09-10	2025	9	10	3	Septembre	Mercredi	37	f	f	2025-10-26 17:28:58.981278
254	2025-09-11	2025	9	11	3	Septembre	Jeudi	37	f	f	2025-10-26 17:28:58.981278
255	2025-09-12	2025	9	12	3	Septembre	Vendredi	37	f	f	2025-10-26 17:28:58.981278
256	2025-09-13	2025	9	13	3	Septembre	Samedi	37	t	f	2025-10-26 17:28:58.981278
257	2025-09-14	2025	9	14	3	Septembre	Dimanche	37	t	f	2025-10-26 17:28:58.981278
258	2025-09-15	2025	9	15	3	Septembre	Lundi	38	f	f	2025-10-26 17:28:58.981278
259	2025-09-16	2025	9	16	3	Septembre	Mardi	38	f	f	2025-10-26 17:28:58.981278
260	2025-09-17	2025	9	17	3	Septembre	Mercredi	38	f	f	2025-10-26 17:28:58.981278
261	2025-09-18	2025	9	18	3	Septembre	Jeudi	38	f	f	2025-10-26 17:28:58.981278
262	2025-09-19	2025	9	19	3	Septembre	Vendredi	38	f	f	2025-10-26 17:28:58.981278
263	2025-09-20	2025	9	20	3	Septembre	Samedi	38	t	f	2025-10-26 17:28:58.981278
264	2025-09-21	2025	9	21	3	Septembre	Dimanche	38	t	f	2025-10-26 17:28:58.981278
265	2025-09-22	2025	9	22	3	Septembre	Lundi	39	f	f	2025-10-26 17:28:58.981278
266	2025-09-23	2025	9	23	3	Septembre	Mardi	39	f	f	2025-10-26 17:28:58.981278
267	2025-09-24	2025	9	24	3	Septembre	Mercredi	39	f	f	2025-10-26 17:28:58.981278
268	2025-09-25	2025	9	25	3	Septembre	Jeudi	39	f	f	2025-10-26 17:28:58.981278
269	2025-09-26	2025	9	26	3	Septembre	Vendredi	39	f	f	2025-10-26 17:28:58.981278
270	2025-09-27	2025	9	27	3	Septembre	Samedi	39	t	f	2025-10-26 17:28:58.981278
271	2025-09-28	2025	9	28	3	Septembre	Dimanche	39	t	f	2025-10-26 17:28:58.981278
272	2025-09-29	2025	9	29	3	Septembre	Lundi	40	f	f	2025-10-26 17:28:58.981278
273	2025-09-30	2025	9	30	3	Septembre	Mardi	40	f	f	2025-10-26 17:28:58.981278
274	2025-10-01	2025	10	1	4	Octobre	Mercredi	40	f	f	2025-10-26 17:28:58.981278
275	2025-10-02	2025	10	2	4	Octobre	Jeudi	40	f	f	2025-10-26 17:28:58.981278
276	2025-10-03	2025	10	3	4	Octobre	Vendredi	40	f	f	2025-10-26 17:28:58.981278
277	2025-10-04	2025	10	4	4	Octobre	Samedi	40	t	f	2025-10-26 17:28:58.981278
278	2025-10-05	2025	10	5	4	Octobre	Dimanche	40	t	f	2025-10-26 17:28:58.981278
279	2025-10-06	2025	10	6	4	Octobre	Lundi	41	f	f	2025-10-26 17:28:58.981278
280	2025-10-07	2025	10	7	4	Octobre	Mardi	41	f	f	2025-10-26 17:28:58.981278
281	2025-10-08	2025	10	8	4	Octobre	Mercredi	41	f	f	2025-10-26 17:28:58.981278
282	2025-10-09	2025	10	9	4	Octobre	Jeudi	41	f	f	2025-10-26 17:28:58.981278
283	2025-10-10	2025	10	10	4	Octobre	Vendredi	41	f	f	2025-10-26 17:28:58.981278
284	2025-10-11	2025	10	11	4	Octobre	Samedi	41	t	f	2025-10-26 17:28:58.981278
285	2025-10-12	2025	10	12	4	Octobre	Dimanche	41	t	f	2025-10-26 17:28:58.981278
286	2025-10-13	2025	10	13	4	Octobre	Lundi	42	f	f	2025-10-26 17:28:58.981278
287	2025-10-14	2025	10	14	4	Octobre	Mardi	42	f	f	2025-10-26 17:28:58.981278
288	2025-10-15	2025	10	15	4	Octobre	Mercredi	42	f	f	2025-10-26 17:28:58.981278
289	2025-10-16	2025	10	16	4	Octobre	Jeudi	42	f	f	2025-10-26 17:28:58.981278
290	2025-10-17	2025	10	17	4	Octobre	Vendredi	42	f	f	2025-10-26 17:28:58.981278
291	2025-10-18	2025	10	18	4	Octobre	Samedi	42	t	f	2025-10-26 17:28:58.981278
292	2025-10-19	2025	10	19	4	Octobre	Dimanche	42	t	f	2025-10-26 17:28:58.981278
293	2025-10-20	2025	10	20	4	Octobre	Lundi	43	f	f	2025-10-26 17:28:58.981278
294	2025-10-21	2025	10	21	4	Octobre	Mardi	43	f	f	2025-10-26 17:28:58.981278
295	2025-10-22	2025	10	22	4	Octobre	Mercredi	43	f	f	2025-10-26 17:28:58.981278
296	2025-10-23	2025	10	23	4	Octobre	Jeudi	43	f	f	2025-10-26 17:28:58.981278
297	2025-10-24	2025	10	24	4	Octobre	Vendredi	43	f	f	2025-10-26 17:28:58.981278
298	2025-10-25	2025	10	25	4	Octobre	Samedi	43	t	f	2025-10-26 17:28:58.981278
299	2025-10-26	2025	10	26	4	Octobre	Dimanche	43	t	f	2025-10-26 17:28:58.981278
300	2025-10-27	2025	10	27	4	Octobre	Lundi	44	f	f	2025-10-26 17:28:58.981278
301	2025-10-28	2025	10	28	4	Octobre	Mardi	44	f	f	2025-10-26 17:28:58.981278
302	2025-10-29	2025	10	29	4	Octobre	Mercredi	44	f	f	2025-10-26 17:28:58.981278
303	2025-10-30	2025	10	30	4	Octobre	Jeudi	44	f	f	2025-10-26 17:28:58.981278
304	2025-10-31	2025	10	31	4	Octobre	Vendredi	44	f	f	2025-10-26 17:28:58.981278
305	2025-11-01	2025	11	1	4	Novembre	Samedi	44	t	f	2025-10-26 17:28:58.981278
306	2025-11-02	2025	11	2	4	Novembre	Dimanche	44	t	f	2025-10-26 17:28:58.981278
307	2025-11-03	2025	11	3	4	Novembre	Lundi	45	f	f	2025-10-26 17:28:58.981278
308	2025-11-04	2025	11	4	4	Novembre	Mardi	45	f	f	2025-10-26 17:28:58.981278
309	2025-11-05	2025	11	5	4	Novembre	Mercredi	45	f	f	2025-10-26 17:28:58.981278
310	2025-11-06	2025	11	6	4	Novembre	Jeudi	45	f	f	2025-10-26 17:28:58.981278
311	2025-11-07	2025	11	7	4	Novembre	Vendredi	45	f	f	2025-10-26 17:28:58.981278
312	2025-11-08	2025	11	8	4	Novembre	Samedi	45	t	f	2025-10-26 17:28:58.981278
313	2025-11-09	2025	11	9	4	Novembre	Dimanche	45	t	f	2025-10-26 17:28:58.981278
314	2025-11-10	2025	11	10	4	Novembre	Lundi	46	f	f	2025-10-26 17:28:58.981278
315	2025-11-11	2025	11	11	4	Novembre	Mardi	46	f	f	2025-10-26 17:28:58.981278
316	2025-11-12	2025	11	12	4	Novembre	Mercredi	46	f	f	2025-10-26 17:28:58.981278
317	2025-11-13	2025	11	13	4	Novembre	Jeudi	46	f	f	2025-10-26 17:28:58.981278
318	2025-11-14	2025	11	14	4	Novembre	Vendredi	46	f	f	2025-10-26 17:28:58.981278
319	2025-11-15	2025	11	15	4	Novembre	Samedi	46	t	f	2025-10-26 17:28:58.981278
320	2025-11-16	2025	11	16	4	Novembre	Dimanche	46	t	f	2025-10-26 17:28:58.981278
321	2025-11-17	2025	11	17	4	Novembre	Lundi	47	f	f	2025-10-26 17:28:58.981278
322	2025-11-18	2025	11	18	4	Novembre	Mardi	47	f	f	2025-10-26 17:28:58.981278
323	2025-11-19	2025	11	19	4	Novembre	Mercredi	47	f	f	2025-10-26 17:28:58.981278
324	2025-11-20	2025	11	20	4	Novembre	Jeudi	47	f	f	2025-10-26 17:28:58.981278
325	2025-11-21	2025	11	21	4	Novembre	Vendredi	47	f	f	2025-10-26 17:28:58.981278
326	2025-11-22	2025	11	22	4	Novembre	Samedi	47	t	f	2025-10-26 17:28:58.981278
327	2025-11-23	2025	11	23	4	Novembre	Dimanche	47	t	f	2025-10-26 17:28:58.981278
328	2025-11-24	2025	11	24	4	Novembre	Lundi	48	f	f	2025-10-26 17:28:58.981278
329	2025-11-25	2025	11	25	4	Novembre	Mardi	48	f	f	2025-10-26 17:28:58.981278
330	2025-11-26	2025	11	26	4	Novembre	Mercredi	48	f	f	2025-10-26 17:28:58.981278
331	2025-11-27	2025	11	27	4	Novembre	Jeudi	48	f	f	2025-10-26 17:28:58.981278
332	2025-11-28	2025	11	28	4	Novembre	Vendredi	48	f	f	2025-10-26 17:28:58.981278
333	2025-11-29	2025	11	29	4	Novembre	Samedi	48	t	f	2025-10-26 17:28:58.981278
334	2025-11-30	2025	11	30	4	Novembre	Dimanche	48	t	f	2025-10-26 17:28:58.981278
335	2025-12-01	2025	12	1	4	DÃ©cembre	Lundi	49	f	f	2025-10-26 17:28:58.981278
336	2025-12-02	2025	12	2	4	DÃ©cembre	Mardi	49	f	f	2025-10-26 17:28:58.981278
337	2025-12-03	2025	12	3	4	DÃ©cembre	Mercredi	49	f	f	2025-10-26 17:28:58.981278
338	2025-12-04	2025	12	4	4	DÃ©cembre	Jeudi	49	f	f	2025-10-26 17:28:58.981278
339	2025-12-05	2025	12	5	4	DÃ©cembre	Vendredi	49	f	f	2025-10-26 17:28:58.981278
340	2025-12-06	2025	12	6	4	DÃ©cembre	Samedi	49	t	f	2025-10-26 17:28:58.981278
341	2025-12-07	2025	12	7	4	DÃ©cembre	Dimanche	49	t	f	2025-10-26 17:28:58.981278
342	2025-12-08	2025	12	8	4	DÃ©cembre	Lundi	50	f	f	2025-10-26 17:28:58.981278
343	2025-12-09	2025	12	9	4	DÃ©cembre	Mardi	50	f	f	2025-10-26 17:28:58.981278
344	2025-12-10	2025	12	10	4	DÃ©cembre	Mercredi	50	f	f	2025-10-26 17:28:58.981278
345	2025-12-11	2025	12	11	4	DÃ©cembre	Jeudi	50	f	f	2025-10-26 17:28:58.981278
346	2025-12-12	2025	12	12	4	DÃ©cembre	Vendredi	50	f	f	2025-10-26 17:28:58.981278
347	2025-12-13	2025	12	13	4	DÃ©cembre	Samedi	50	t	f	2025-10-26 17:28:58.981278
348	2025-12-14	2025	12	14	4	DÃ©cembre	Dimanche	50	t	f	2025-10-26 17:28:58.981278
349	2025-12-15	2025	12	15	4	DÃ©cembre	Lundi	51	f	f	2025-10-26 17:28:58.981278
350	2025-12-16	2025	12	16	4	DÃ©cembre	Mardi	51	f	f	2025-10-26 17:28:58.981278
351	2025-12-17	2025	12	17	4	DÃ©cembre	Mercredi	51	f	f	2025-10-26 17:28:58.981278
352	2025-12-18	2025	12	18	4	DÃ©cembre	Jeudi	51	f	f	2025-10-26 17:28:58.981278
353	2025-12-19	2025	12	19	4	DÃ©cembre	Vendredi	51	f	f	2025-10-26 17:28:58.981278
354	2025-12-20	2025	12	20	4	DÃ©cembre	Samedi	51	t	f	2025-10-26 17:28:58.981278
355	2025-12-21	2025	12	21	4	DÃ©cembre	Dimanche	51	t	f	2025-10-26 17:28:58.981278
356	2025-12-22	2025	12	22	4	DÃ©cembre	Lundi	52	f	f	2025-10-26 17:28:58.981278
357	2025-12-23	2025	12	23	4	DÃ©cembre	Mardi	52	f	f	2025-10-26 17:28:58.981278
358	2025-12-24	2025	12	24	4	DÃ©cembre	Mercredi	52	f	f	2025-10-26 17:28:58.981278
359	2025-12-25	2025	12	25	4	DÃ©cembre	Jeudi	52	f	f	2025-10-26 17:28:58.981278
360	2025-12-26	2025	12	26	4	DÃ©cembre	Vendredi	52	f	f	2025-10-26 17:28:58.981278
361	2025-12-27	2025	12	27	4	DÃ©cembre	Samedi	52	t	f	2025-10-26 17:28:58.981278
362	2025-12-28	2025	12	28	4	DÃ©cembre	Dimanche	52	t	f	2025-10-26 17:28:58.981278
363	2025-12-29	2025	12	29	4	DÃ©cembre	Lundi	1	f	f	2025-10-26 17:28:58.981278
364	2025-12-30	2025	12	30	4	DÃ©cembre	Mardi	1	f	f	2025-10-26 17:28:58.981278
365	2025-12-31	2025	12	31	4	DÃ©cembre	Mercredi	1	f	f	2025-10-26 17:28:58.981278
366	2026-01-01	2026	1	1	1	Janvier	Jeudi	1	f	f	2025-10-26 17:28:58.981278
367	2026-01-02	2026	1	2	1	Janvier	Vendredi	1	f	f	2025-10-26 17:28:58.981278
368	2026-01-03	2026	1	3	1	Janvier	Samedi	1	t	f	2025-10-26 17:28:58.981278
369	2026-01-04	2026	1	4	1	Janvier	Dimanche	1	t	f	2025-10-26 17:28:58.981278
370	2026-01-05	2026	1	5	1	Janvier	Lundi	2	f	f	2025-10-26 17:28:58.981278
371	2026-01-06	2026	1	6	1	Janvier	Mardi	2	f	f	2025-10-26 17:28:58.981278
372	2026-01-07	2026	1	7	1	Janvier	Mercredi	2	f	f	2025-10-26 17:28:58.981278
373	2026-01-08	2026	1	8	1	Janvier	Jeudi	2	f	f	2025-10-26 17:28:58.981278
374	2026-01-09	2026	1	9	1	Janvier	Vendredi	2	f	f	2025-10-26 17:28:58.981278
375	2026-01-10	2026	1	10	1	Janvier	Samedi	2	t	f	2025-10-26 17:28:58.981278
376	2026-01-11	2026	1	11	1	Janvier	Dimanche	2	t	f	2025-10-26 17:28:58.981278
377	2026-01-12	2026	1	12	1	Janvier	Lundi	3	f	f	2025-10-26 17:28:58.981278
378	2026-01-13	2026	1	13	1	Janvier	Mardi	3	f	f	2025-10-26 17:28:58.981278
379	2026-01-14	2026	1	14	1	Janvier	Mercredi	3	f	f	2025-10-26 17:28:58.981278
380	2026-01-15	2026	1	15	1	Janvier	Jeudi	3	f	f	2025-10-26 17:28:58.981278
381	2026-01-16	2026	1	16	1	Janvier	Vendredi	3	f	f	2025-10-26 17:28:58.981278
382	2026-01-17	2026	1	17	1	Janvier	Samedi	3	t	f	2025-10-26 17:28:58.981278
383	2026-01-18	2026	1	18	1	Janvier	Dimanche	3	t	f	2025-10-26 17:28:58.981278
384	2026-01-19	2026	1	19	1	Janvier	Lundi	4	f	f	2025-10-26 17:28:58.981278
385	2026-01-20	2026	1	20	1	Janvier	Mardi	4	f	f	2025-10-26 17:28:58.981278
386	2026-01-21	2026	1	21	1	Janvier	Mercredi	4	f	f	2025-10-26 17:28:58.981278
387	2026-01-22	2026	1	22	1	Janvier	Jeudi	4	f	f	2025-10-26 17:28:58.981278
388	2026-01-23	2026	1	23	1	Janvier	Vendredi	4	f	f	2025-10-26 17:28:58.981278
389	2026-01-24	2026	1	24	1	Janvier	Samedi	4	t	f	2025-10-26 17:28:58.981278
390	2026-01-25	2026	1	25	1	Janvier	Dimanche	4	t	f	2025-10-26 17:28:58.981278
391	2026-01-26	2026	1	26	1	Janvier	Lundi	5	f	f	2025-10-26 17:28:58.981278
392	2026-01-27	2026	1	27	1	Janvier	Mardi	5	f	f	2025-10-26 17:28:58.981278
393	2026-01-28	2026	1	28	1	Janvier	Mercredi	5	f	f	2025-10-26 17:28:58.981278
394	2026-01-29	2026	1	29	1	Janvier	Jeudi	5	f	f	2025-10-26 17:28:58.981278
395	2026-01-30	2026	1	30	1	Janvier	Vendredi	5	f	f	2025-10-26 17:28:58.981278
396	2026-01-31	2026	1	31	1	Janvier	Samedi	5	t	f	2025-10-26 17:28:58.981278
397	2026-02-01	2026	2	1	1	FÃ©vrier	Dimanche	5	t	f	2025-10-26 17:28:58.981278
398	2026-02-02	2026	2	2	1	FÃ©vrier	Lundi	6	f	f	2025-10-26 17:28:58.981278
399	2026-02-03	2026	2	3	1	FÃ©vrier	Mardi	6	f	f	2025-10-26 17:28:58.981278
400	2026-02-04	2026	2	4	1	FÃ©vrier	Mercredi	6	f	f	2025-10-26 17:28:58.981278
401	2026-02-05	2026	2	5	1	FÃ©vrier	Jeudi	6	f	f	2025-10-26 17:28:58.981278
402	2026-02-06	2026	2	6	1	FÃ©vrier	Vendredi	6	f	f	2025-10-26 17:28:58.981278
403	2026-02-07	2026	2	7	1	FÃ©vrier	Samedi	6	t	f	2025-10-26 17:28:58.981278
404	2026-02-08	2026	2	8	1	FÃ©vrier	Dimanche	6	t	f	2025-10-26 17:28:58.981278
405	2026-02-09	2026	2	9	1	FÃ©vrier	Lundi	7	f	f	2025-10-26 17:28:58.981278
406	2026-02-10	2026	2	10	1	FÃ©vrier	Mardi	7	f	f	2025-10-26 17:28:58.981278
407	2026-02-11	2026	2	11	1	FÃ©vrier	Mercredi	7	f	f	2025-10-26 17:28:58.981278
408	2026-02-12	2026	2	12	1	FÃ©vrier	Jeudi	7	f	f	2025-10-26 17:28:58.981278
409	2026-02-13	2026	2	13	1	FÃ©vrier	Vendredi	7	f	f	2025-10-26 17:28:58.981278
410	2026-02-14	2026	2	14	1	FÃ©vrier	Samedi	7	t	f	2025-10-26 17:28:58.981278
411	2026-02-15	2026	2	15	1	FÃ©vrier	Dimanche	7	t	f	2025-10-26 17:28:58.981278
412	2026-02-16	2026	2	16	1	FÃ©vrier	Lundi	8	f	f	2025-10-26 17:28:58.981278
413	2026-02-17	2026	2	17	1	FÃ©vrier	Mardi	8	f	f	2025-10-26 17:28:58.981278
414	2026-02-18	2026	2	18	1	FÃ©vrier	Mercredi	8	f	f	2025-10-26 17:28:58.981278
415	2026-02-19	2026	2	19	1	FÃ©vrier	Jeudi	8	f	f	2025-10-26 17:28:58.981278
416	2026-02-20	2026	2	20	1	FÃ©vrier	Vendredi	8	f	f	2025-10-26 17:28:58.981278
417	2026-02-21	2026	2	21	1	FÃ©vrier	Samedi	8	t	f	2025-10-26 17:28:58.981278
418	2026-02-22	2026	2	22	1	FÃ©vrier	Dimanche	8	t	f	2025-10-26 17:28:58.981278
419	2026-02-23	2026	2	23	1	FÃ©vrier	Lundi	9	f	f	2025-10-26 17:28:58.981278
420	2026-02-24	2026	2	24	1	FÃ©vrier	Mardi	9	f	f	2025-10-26 17:28:58.981278
421	2026-02-25	2026	2	25	1	FÃ©vrier	Mercredi	9	f	f	2025-10-26 17:28:58.981278
422	2026-02-26	2026	2	26	1	FÃ©vrier	Jeudi	9	f	f	2025-10-26 17:28:58.981278
423	2026-02-27	2026	2	27	1	FÃ©vrier	Vendredi	9	f	f	2025-10-26 17:28:58.981278
424	2026-02-28	2026	2	28	1	FÃ©vrier	Samedi	9	t	f	2025-10-26 17:28:58.981278
425	2026-03-01	2026	3	1	1	Mars	Dimanche	9	t	f	2025-10-26 17:28:58.981278
426	2026-03-02	2026	3	2	1	Mars	Lundi	10	f	f	2025-10-26 17:28:58.981278
427	2026-03-03	2026	3	3	1	Mars	Mardi	10	f	f	2025-10-26 17:28:58.981278
428	2026-03-04	2026	3	4	1	Mars	Mercredi	10	f	f	2025-10-26 17:28:58.981278
429	2026-03-05	2026	3	5	1	Mars	Jeudi	10	f	f	2025-10-26 17:28:58.981278
430	2026-03-06	2026	3	6	1	Mars	Vendredi	10	f	f	2025-10-26 17:28:58.981278
431	2026-03-07	2026	3	7	1	Mars	Samedi	10	t	f	2025-10-26 17:28:58.981278
432	2026-03-08	2026	3	8	1	Mars	Dimanche	10	t	f	2025-10-26 17:28:58.981278
433	2026-03-09	2026	3	9	1	Mars	Lundi	11	f	f	2025-10-26 17:28:58.981278
434	2026-03-10	2026	3	10	1	Mars	Mardi	11	f	f	2025-10-26 17:28:58.981278
435	2026-03-11	2026	3	11	1	Mars	Mercredi	11	f	f	2025-10-26 17:28:58.981278
436	2026-03-12	2026	3	12	1	Mars	Jeudi	11	f	f	2025-10-26 17:28:58.981278
437	2026-03-13	2026	3	13	1	Mars	Vendredi	11	f	f	2025-10-26 17:28:58.981278
438	2026-03-14	2026	3	14	1	Mars	Samedi	11	t	f	2025-10-26 17:28:58.981278
439	2026-03-15	2026	3	15	1	Mars	Dimanche	11	t	f	2025-10-26 17:28:58.981278
440	2026-03-16	2026	3	16	1	Mars	Lundi	12	f	f	2025-10-26 17:28:58.981278
441	2026-03-17	2026	3	17	1	Mars	Mardi	12	f	f	2025-10-26 17:28:58.981278
442	2026-03-18	2026	3	18	1	Mars	Mercredi	12	f	f	2025-10-26 17:28:58.981278
443	2026-03-19	2026	3	19	1	Mars	Jeudi	12	f	f	2025-10-26 17:28:58.981278
444	2026-03-20	2026	3	20	1	Mars	Vendredi	12	f	f	2025-10-26 17:28:58.981278
445	2026-03-21	2026	3	21	1	Mars	Samedi	12	t	f	2025-10-26 17:28:58.981278
446	2026-03-22	2026	3	22	1	Mars	Dimanche	12	t	f	2025-10-26 17:28:58.981278
447	2026-03-23	2026	3	23	1	Mars	Lundi	13	f	f	2025-10-26 17:28:58.981278
448	2026-03-24	2026	3	24	1	Mars	Mardi	13	f	f	2025-10-26 17:28:58.981278
449	2026-03-25	2026	3	25	1	Mars	Mercredi	13	f	f	2025-10-26 17:28:58.981278
450	2026-03-26	2026	3	26	1	Mars	Jeudi	13	f	f	2025-10-26 17:28:58.981278
451	2026-03-27	2026	3	27	1	Mars	Vendredi	13	f	f	2025-10-26 17:28:58.981278
452	2026-03-28	2026	3	28	1	Mars	Samedi	13	t	f	2025-10-26 17:28:58.981278
453	2026-03-29	2026	3	29	1	Mars	Dimanche	13	t	f	2025-10-26 17:28:58.981278
454	2026-03-30	2026	3	30	1	Mars	Lundi	14	f	f	2025-10-26 17:28:58.981278
455	2026-03-31	2026	3	31	1	Mars	Mardi	14	f	f	2025-10-26 17:28:58.981278
456	2026-04-01	2026	4	1	2	Avril	Mercredi	14	f	f	2025-10-26 17:28:58.981278
457	2026-04-02	2026	4	2	2	Avril	Jeudi	14	f	f	2025-10-26 17:28:58.981278
458	2026-04-03	2026	4	3	2	Avril	Vendredi	14	f	f	2025-10-26 17:28:58.981278
459	2026-04-04	2026	4	4	2	Avril	Samedi	14	t	f	2025-10-26 17:28:58.981278
460	2026-04-05	2026	4	5	2	Avril	Dimanche	14	t	f	2025-10-26 17:28:58.981278
461	2026-04-06	2026	4	6	2	Avril	Lundi	15	f	f	2025-10-26 17:28:58.981278
462	2026-04-07	2026	4	7	2	Avril	Mardi	15	f	f	2025-10-26 17:28:58.981278
463	2026-04-08	2026	4	8	2	Avril	Mercredi	15	f	f	2025-10-26 17:28:58.981278
464	2026-04-09	2026	4	9	2	Avril	Jeudi	15	f	f	2025-10-26 17:28:58.981278
465	2026-04-10	2026	4	10	2	Avril	Vendredi	15	f	f	2025-10-26 17:28:58.981278
466	2026-04-11	2026	4	11	2	Avril	Samedi	15	t	f	2025-10-26 17:28:58.981278
467	2026-04-12	2026	4	12	2	Avril	Dimanche	15	t	f	2025-10-26 17:28:58.981278
468	2026-04-13	2026	4	13	2	Avril	Lundi	16	f	f	2025-10-26 17:28:58.981278
469	2026-04-14	2026	4	14	2	Avril	Mardi	16	f	f	2025-10-26 17:28:58.981278
470	2026-04-15	2026	4	15	2	Avril	Mercredi	16	f	f	2025-10-26 17:28:58.981278
471	2026-04-16	2026	4	16	2	Avril	Jeudi	16	f	f	2025-10-26 17:28:58.981278
472	2026-04-17	2026	4	17	2	Avril	Vendredi	16	f	f	2025-10-26 17:28:58.981278
473	2026-04-18	2026	4	18	2	Avril	Samedi	16	t	f	2025-10-26 17:28:58.981278
474	2026-04-19	2026	4	19	2	Avril	Dimanche	16	t	f	2025-10-26 17:28:58.981278
475	2026-04-20	2026	4	20	2	Avril	Lundi	17	f	f	2025-10-26 17:28:58.981278
476	2026-04-21	2026	4	21	2	Avril	Mardi	17	f	f	2025-10-26 17:28:58.981278
477	2026-04-22	2026	4	22	2	Avril	Mercredi	17	f	f	2025-10-26 17:28:58.981278
478	2026-04-23	2026	4	23	2	Avril	Jeudi	17	f	f	2025-10-26 17:28:58.981278
479	2026-04-24	2026	4	24	2	Avril	Vendredi	17	f	f	2025-10-26 17:28:58.981278
480	2026-04-25	2026	4	25	2	Avril	Samedi	17	t	f	2025-10-26 17:28:58.981278
481	2026-04-26	2026	4	26	2	Avril	Dimanche	17	t	f	2025-10-26 17:28:58.981278
482	2026-04-27	2026	4	27	2	Avril	Lundi	18	f	f	2025-10-26 17:28:58.981278
483	2026-04-28	2026	4	28	2	Avril	Mardi	18	f	f	2025-10-26 17:28:58.981278
484	2026-04-29	2026	4	29	2	Avril	Mercredi	18	f	f	2025-10-26 17:28:58.981278
485	2026-04-30	2026	4	30	2	Avril	Jeudi	18	f	f	2025-10-26 17:28:58.981278
486	2026-05-01	2026	5	1	2	Mai	Vendredi	18	f	f	2025-10-26 17:28:58.981278
487	2026-05-02	2026	5	2	2	Mai	Samedi	18	t	f	2025-10-26 17:28:58.981278
488	2026-05-03	2026	5	3	2	Mai	Dimanche	18	t	f	2025-10-26 17:28:58.981278
489	2026-05-04	2026	5	4	2	Mai	Lundi	19	f	f	2025-10-26 17:28:58.981278
490	2026-05-05	2026	5	5	2	Mai	Mardi	19	f	f	2025-10-26 17:28:58.981278
491	2026-05-06	2026	5	6	2	Mai	Mercredi	19	f	f	2025-10-26 17:28:58.981278
492	2026-05-07	2026	5	7	2	Mai	Jeudi	19	f	f	2025-10-26 17:28:58.981278
493	2026-05-08	2026	5	8	2	Mai	Vendredi	19	f	f	2025-10-26 17:28:58.981278
494	2026-05-09	2026	5	9	2	Mai	Samedi	19	t	f	2025-10-26 17:28:58.981278
495	2026-05-10	2026	5	10	2	Mai	Dimanche	19	t	f	2025-10-26 17:28:58.981278
496	2026-05-11	2026	5	11	2	Mai	Lundi	20	f	f	2025-10-26 17:28:58.981278
497	2026-05-12	2026	5	12	2	Mai	Mardi	20	f	f	2025-10-26 17:28:58.981278
498	2026-05-13	2026	5	13	2	Mai	Mercredi	20	f	f	2025-10-26 17:28:58.981278
499	2026-05-14	2026	5	14	2	Mai	Jeudi	20	f	f	2025-10-26 17:28:58.981278
500	2026-05-15	2026	5	15	2	Mai	Vendredi	20	f	f	2025-10-26 17:28:58.981278
501	2026-05-16	2026	5	16	2	Mai	Samedi	20	t	f	2025-10-26 17:28:58.981278
502	2026-05-17	2026	5	17	2	Mai	Dimanche	20	t	f	2025-10-26 17:28:58.981278
503	2026-05-18	2026	5	18	2	Mai	Lundi	21	f	f	2025-10-26 17:28:58.981278
504	2026-05-19	2026	5	19	2	Mai	Mardi	21	f	f	2025-10-26 17:28:58.981278
505	2026-05-20	2026	5	20	2	Mai	Mercredi	21	f	f	2025-10-26 17:28:58.981278
506	2026-05-21	2026	5	21	2	Mai	Jeudi	21	f	f	2025-10-26 17:28:58.981278
507	2026-05-22	2026	5	22	2	Mai	Vendredi	21	f	f	2025-10-26 17:28:58.981278
508	2026-05-23	2026	5	23	2	Mai	Samedi	21	t	f	2025-10-26 17:28:58.981278
509	2026-05-24	2026	5	24	2	Mai	Dimanche	21	t	f	2025-10-26 17:28:58.981278
510	2026-05-25	2026	5	25	2	Mai	Lundi	22	f	f	2025-10-26 17:28:58.981278
511	2026-05-26	2026	5	26	2	Mai	Mardi	22	f	f	2025-10-26 17:28:58.981278
512	2026-05-27	2026	5	27	2	Mai	Mercredi	22	f	f	2025-10-26 17:28:58.981278
513	2026-05-28	2026	5	28	2	Mai	Jeudi	22	f	f	2025-10-26 17:28:58.981278
514	2026-05-29	2026	5	29	2	Mai	Vendredi	22	f	f	2025-10-26 17:28:58.981278
515	2026-05-30	2026	5	30	2	Mai	Samedi	22	t	f	2025-10-26 17:28:58.981278
516	2026-05-31	2026	5	31	2	Mai	Dimanche	22	t	f	2025-10-26 17:28:58.981278
517	2026-06-01	2026	6	1	2	Juin	Lundi	23	f	f	2025-10-26 17:28:58.981278
518	2026-06-02	2026	6	2	2	Juin	Mardi	23	f	f	2025-10-26 17:28:58.981278
519	2026-06-03	2026	6	3	2	Juin	Mercredi	23	f	f	2025-10-26 17:28:58.981278
520	2026-06-04	2026	6	4	2	Juin	Jeudi	23	f	f	2025-10-26 17:28:58.981278
521	2026-06-05	2026	6	5	2	Juin	Vendredi	23	f	f	2025-10-26 17:28:58.981278
522	2026-06-06	2026	6	6	2	Juin	Samedi	23	t	f	2025-10-26 17:28:58.981278
523	2026-06-07	2026	6	7	2	Juin	Dimanche	23	t	f	2025-10-26 17:28:58.981278
524	2026-06-08	2026	6	8	2	Juin	Lundi	24	f	f	2025-10-26 17:28:58.981278
525	2026-06-09	2026	6	9	2	Juin	Mardi	24	f	f	2025-10-26 17:28:58.981278
526	2026-06-10	2026	6	10	2	Juin	Mercredi	24	f	f	2025-10-26 17:28:58.981278
527	2026-06-11	2026	6	11	2	Juin	Jeudi	24	f	f	2025-10-26 17:28:58.981278
528	2026-06-12	2026	6	12	2	Juin	Vendredi	24	f	f	2025-10-26 17:28:58.981278
529	2026-06-13	2026	6	13	2	Juin	Samedi	24	t	f	2025-10-26 17:28:58.981278
530	2026-06-14	2026	6	14	2	Juin	Dimanche	24	t	f	2025-10-26 17:28:58.981278
531	2026-06-15	2026	6	15	2	Juin	Lundi	25	f	f	2025-10-26 17:28:58.981278
532	2026-06-16	2026	6	16	2	Juin	Mardi	25	f	f	2025-10-26 17:28:58.981278
533	2026-06-17	2026	6	17	2	Juin	Mercredi	25	f	f	2025-10-26 17:28:58.981278
534	2026-06-18	2026	6	18	2	Juin	Jeudi	25	f	f	2025-10-26 17:28:58.981278
535	2026-06-19	2026	6	19	2	Juin	Vendredi	25	f	f	2025-10-26 17:28:58.981278
536	2026-06-20	2026	6	20	2	Juin	Samedi	25	t	f	2025-10-26 17:28:58.981278
537	2026-06-21	2026	6	21	2	Juin	Dimanche	25	t	f	2025-10-26 17:28:58.981278
538	2026-06-22	2026	6	22	2	Juin	Lundi	26	f	f	2025-10-26 17:28:58.981278
539	2026-06-23	2026	6	23	2	Juin	Mardi	26	f	f	2025-10-26 17:28:58.981278
540	2026-06-24	2026	6	24	2	Juin	Mercredi	26	f	f	2025-10-26 17:28:58.981278
541	2026-06-25	2026	6	25	2	Juin	Jeudi	26	f	f	2025-10-26 17:28:58.981278
542	2026-06-26	2026	6	26	2	Juin	Vendredi	26	f	f	2025-10-26 17:28:58.981278
543	2026-06-27	2026	6	27	2	Juin	Samedi	26	t	f	2025-10-26 17:28:58.981278
544	2026-06-28	2026	6	28	2	Juin	Dimanche	26	t	f	2025-10-26 17:28:58.981278
545	2026-06-29	2026	6	29	2	Juin	Lundi	27	f	f	2025-10-26 17:28:58.981278
546	2026-06-30	2026	6	30	2	Juin	Mardi	27	f	f	2025-10-26 17:28:58.981278
547	2026-07-01	2026	7	1	3	Juillet	Mercredi	27	f	f	2025-10-26 17:28:58.981278
548	2026-07-02	2026	7	2	3	Juillet	Jeudi	27	f	f	2025-10-26 17:28:58.981278
549	2026-07-03	2026	7	3	3	Juillet	Vendredi	27	f	f	2025-10-26 17:28:58.981278
550	2026-07-04	2026	7	4	3	Juillet	Samedi	27	t	f	2025-10-26 17:28:58.981278
551	2026-07-05	2026	7	5	3	Juillet	Dimanche	27	t	f	2025-10-26 17:28:58.981278
552	2026-07-06	2026	7	6	3	Juillet	Lundi	28	f	f	2025-10-26 17:28:58.981278
553	2026-07-07	2026	7	7	3	Juillet	Mardi	28	f	f	2025-10-26 17:28:58.981278
554	2026-07-08	2026	7	8	3	Juillet	Mercredi	28	f	f	2025-10-26 17:28:58.981278
555	2026-07-09	2026	7	9	3	Juillet	Jeudi	28	f	f	2025-10-26 17:28:58.981278
556	2026-07-10	2026	7	10	3	Juillet	Vendredi	28	f	f	2025-10-26 17:28:58.981278
557	2026-07-11	2026	7	11	3	Juillet	Samedi	28	t	f	2025-10-26 17:28:58.981278
558	2026-07-12	2026	7	12	3	Juillet	Dimanche	28	t	f	2025-10-26 17:28:58.981278
559	2026-07-13	2026	7	13	3	Juillet	Lundi	29	f	f	2025-10-26 17:28:58.981278
560	2026-07-14	2026	7	14	3	Juillet	Mardi	29	f	f	2025-10-26 17:28:58.981278
561	2026-07-15	2026	7	15	3	Juillet	Mercredi	29	f	f	2025-10-26 17:28:58.981278
562	2026-07-16	2026	7	16	3	Juillet	Jeudi	29	f	f	2025-10-26 17:28:58.981278
563	2026-07-17	2026	7	17	3	Juillet	Vendredi	29	f	f	2025-10-26 17:28:58.981278
564	2026-07-18	2026	7	18	3	Juillet	Samedi	29	t	f	2025-10-26 17:28:58.981278
565	2026-07-19	2026	7	19	3	Juillet	Dimanche	29	t	f	2025-10-26 17:28:58.981278
566	2026-07-20	2026	7	20	3	Juillet	Lundi	30	f	f	2025-10-26 17:28:58.981278
567	2026-07-21	2026	7	21	3	Juillet	Mardi	30	f	f	2025-10-26 17:28:58.981278
568	2026-07-22	2026	7	22	3	Juillet	Mercredi	30	f	f	2025-10-26 17:28:58.981278
569	2026-07-23	2026	7	23	3	Juillet	Jeudi	30	f	f	2025-10-26 17:28:58.981278
570	2026-07-24	2026	7	24	3	Juillet	Vendredi	30	f	f	2025-10-26 17:28:58.981278
571	2026-07-25	2026	7	25	3	Juillet	Samedi	30	t	f	2025-10-26 17:28:58.981278
572	2026-07-26	2026	7	26	3	Juillet	Dimanche	30	t	f	2025-10-26 17:28:58.981278
573	2026-07-27	2026	7	27	3	Juillet	Lundi	31	f	f	2025-10-26 17:28:58.981278
574	2026-07-28	2026	7	28	3	Juillet	Mardi	31	f	f	2025-10-26 17:28:58.981278
575	2026-07-29	2026	7	29	3	Juillet	Mercredi	31	f	f	2025-10-26 17:28:58.981278
576	2026-07-30	2026	7	30	3	Juillet	Jeudi	31	f	f	2025-10-26 17:28:58.981278
577	2026-07-31	2026	7	31	3	Juillet	Vendredi	31	f	f	2025-10-26 17:28:58.981278
578	2026-08-01	2026	8	1	3	AoÃ»t	Samedi	31	t	f	2025-10-26 17:28:58.981278
579	2026-08-02	2026	8	2	3	AoÃ»t	Dimanche	31	t	f	2025-10-26 17:28:58.981278
580	2026-08-03	2026	8	3	3	AoÃ»t	Lundi	32	f	f	2025-10-26 17:28:58.981278
581	2026-08-04	2026	8	4	3	AoÃ»t	Mardi	32	f	f	2025-10-26 17:28:58.981278
582	2026-08-05	2026	8	5	3	AoÃ»t	Mercredi	32	f	f	2025-10-26 17:28:58.981278
583	2026-08-06	2026	8	6	3	AoÃ»t	Jeudi	32	f	f	2025-10-26 17:28:58.981278
584	2026-08-07	2026	8	7	3	AoÃ»t	Vendredi	32	f	f	2025-10-26 17:28:58.981278
585	2026-08-08	2026	8	8	3	AoÃ»t	Samedi	32	t	f	2025-10-26 17:28:58.981278
586	2026-08-09	2026	8	9	3	AoÃ»t	Dimanche	32	t	f	2025-10-26 17:28:58.981278
587	2026-08-10	2026	8	10	3	AoÃ»t	Lundi	33	f	f	2025-10-26 17:28:58.981278
588	2026-08-11	2026	8	11	3	AoÃ»t	Mardi	33	f	f	2025-10-26 17:28:58.981278
589	2026-08-12	2026	8	12	3	AoÃ»t	Mercredi	33	f	f	2025-10-26 17:28:58.981278
590	2026-08-13	2026	8	13	3	AoÃ»t	Jeudi	33	f	f	2025-10-26 17:28:58.981278
591	2026-08-14	2026	8	14	3	AoÃ»t	Vendredi	33	f	f	2025-10-26 17:28:58.981278
592	2026-08-15	2026	8	15	3	AoÃ»t	Samedi	33	t	f	2025-10-26 17:28:58.981278
593	2026-08-16	2026	8	16	3	AoÃ»t	Dimanche	33	t	f	2025-10-26 17:28:58.981278
594	2026-08-17	2026	8	17	3	AoÃ»t	Lundi	34	f	f	2025-10-26 17:28:58.981278
595	2026-08-18	2026	8	18	3	AoÃ»t	Mardi	34	f	f	2025-10-26 17:28:58.981278
596	2026-08-19	2026	8	19	3	AoÃ»t	Mercredi	34	f	f	2025-10-26 17:28:58.981278
597	2026-08-20	2026	8	20	3	AoÃ»t	Jeudi	34	f	f	2025-10-26 17:28:58.981278
598	2026-08-21	2026	8	21	3	AoÃ»t	Vendredi	34	f	f	2025-10-26 17:28:58.981278
599	2026-08-22	2026	8	22	3	AoÃ»t	Samedi	34	t	f	2025-10-26 17:28:58.981278
600	2026-08-23	2026	8	23	3	AoÃ»t	Dimanche	34	t	f	2025-10-26 17:28:58.981278
601	2026-08-24	2026	8	24	3	AoÃ»t	Lundi	35	f	f	2025-10-26 17:28:58.981278
602	2026-08-25	2026	8	25	3	AoÃ»t	Mardi	35	f	f	2025-10-26 17:28:58.981278
603	2026-08-26	2026	8	26	3	AoÃ»t	Mercredi	35	f	f	2025-10-26 17:28:58.981278
604	2026-08-27	2026	8	27	3	AoÃ»t	Jeudi	35	f	f	2025-10-26 17:28:58.981278
605	2026-08-28	2026	8	28	3	AoÃ»t	Vendredi	35	f	f	2025-10-26 17:28:58.981278
606	2026-08-29	2026	8	29	3	AoÃ»t	Samedi	35	t	f	2025-10-26 17:28:58.981278
607	2026-08-30	2026	8	30	3	AoÃ»t	Dimanche	35	t	f	2025-10-26 17:28:58.981278
608	2026-08-31	2026	8	31	3	AoÃ»t	Lundi	36	f	f	2025-10-26 17:28:58.981278
609	2026-09-01	2026	9	1	3	Septembre	Mardi	36	f	f	2025-10-26 17:28:58.981278
610	2026-09-02	2026	9	2	3	Septembre	Mercredi	36	f	f	2025-10-26 17:28:58.981278
611	2026-09-03	2026	9	3	3	Septembre	Jeudi	36	f	f	2025-10-26 17:28:58.981278
612	2026-09-04	2026	9	4	3	Septembre	Vendredi	36	f	f	2025-10-26 17:28:58.981278
613	2026-09-05	2026	9	5	3	Septembre	Samedi	36	t	f	2025-10-26 17:28:58.981278
614	2026-09-06	2026	9	6	3	Septembre	Dimanche	36	t	f	2025-10-26 17:28:58.981278
615	2026-09-07	2026	9	7	3	Septembre	Lundi	37	f	f	2025-10-26 17:28:58.981278
616	2026-09-08	2026	9	8	3	Septembre	Mardi	37	f	f	2025-10-26 17:28:58.981278
617	2026-09-09	2026	9	9	3	Septembre	Mercredi	37	f	f	2025-10-26 17:28:58.981278
618	2026-09-10	2026	9	10	3	Septembre	Jeudi	37	f	f	2025-10-26 17:28:58.981278
619	2026-09-11	2026	9	11	3	Septembre	Vendredi	37	f	f	2025-10-26 17:28:58.981278
620	2026-09-12	2026	9	12	3	Septembre	Samedi	37	t	f	2025-10-26 17:28:58.981278
621	2026-09-13	2026	9	13	3	Septembre	Dimanche	37	t	f	2025-10-26 17:28:58.981278
622	2026-09-14	2026	9	14	3	Septembre	Lundi	38	f	f	2025-10-26 17:28:58.981278
623	2026-09-15	2026	9	15	3	Septembre	Mardi	38	f	f	2025-10-26 17:28:58.981278
624	2026-09-16	2026	9	16	3	Septembre	Mercredi	38	f	f	2025-10-26 17:28:58.981278
625	2026-09-17	2026	9	17	3	Septembre	Jeudi	38	f	f	2025-10-26 17:28:58.981278
626	2026-09-18	2026	9	18	3	Septembre	Vendredi	38	f	f	2025-10-26 17:28:58.981278
627	2026-09-19	2026	9	19	3	Septembre	Samedi	38	t	f	2025-10-26 17:28:58.981278
628	2026-09-20	2026	9	20	3	Septembre	Dimanche	38	t	f	2025-10-26 17:28:58.981278
629	2026-09-21	2026	9	21	3	Septembre	Lundi	39	f	f	2025-10-26 17:28:58.981278
630	2026-09-22	2026	9	22	3	Septembre	Mardi	39	f	f	2025-10-26 17:28:58.981278
631	2026-09-23	2026	9	23	3	Septembre	Mercredi	39	f	f	2025-10-26 17:28:58.981278
632	2026-09-24	2026	9	24	3	Septembre	Jeudi	39	f	f	2025-10-26 17:28:58.981278
633	2026-09-25	2026	9	25	3	Septembre	Vendredi	39	f	f	2025-10-26 17:28:58.981278
634	2026-09-26	2026	9	26	3	Septembre	Samedi	39	t	f	2025-10-26 17:28:58.981278
635	2026-09-27	2026	9	27	3	Septembre	Dimanche	39	t	f	2025-10-26 17:28:58.981278
636	2026-09-28	2026	9	28	3	Septembre	Lundi	40	f	f	2025-10-26 17:28:58.981278
637	2026-09-29	2026	9	29	3	Septembre	Mardi	40	f	f	2025-10-26 17:28:58.981278
638	2026-09-30	2026	9	30	3	Septembre	Mercredi	40	f	f	2025-10-26 17:28:58.981278
639	2026-10-01	2026	10	1	4	Octobre	Jeudi	40	f	f	2025-10-26 17:28:58.981278
640	2026-10-02	2026	10	2	4	Octobre	Vendredi	40	f	f	2025-10-26 17:28:58.981278
641	2026-10-03	2026	10	3	4	Octobre	Samedi	40	t	f	2025-10-26 17:28:58.981278
642	2026-10-04	2026	10	4	4	Octobre	Dimanche	40	t	f	2025-10-26 17:28:58.981278
643	2026-10-05	2026	10	5	4	Octobre	Lundi	41	f	f	2025-10-26 17:28:58.981278
644	2026-10-06	2026	10	6	4	Octobre	Mardi	41	f	f	2025-10-26 17:28:58.981278
645	2026-10-07	2026	10	7	4	Octobre	Mercredi	41	f	f	2025-10-26 17:28:58.981278
646	2026-10-08	2026	10	8	4	Octobre	Jeudi	41	f	f	2025-10-26 17:28:58.981278
647	2026-10-09	2026	10	9	4	Octobre	Vendredi	41	f	f	2025-10-26 17:28:58.981278
648	2026-10-10	2026	10	10	4	Octobre	Samedi	41	t	f	2025-10-26 17:28:58.981278
649	2026-10-11	2026	10	11	4	Octobre	Dimanche	41	t	f	2025-10-26 17:28:58.981278
650	2026-10-12	2026	10	12	4	Octobre	Lundi	42	f	f	2025-10-26 17:28:58.981278
651	2026-10-13	2026	10	13	4	Octobre	Mardi	42	f	f	2025-10-26 17:28:58.981278
652	2026-10-14	2026	10	14	4	Octobre	Mercredi	42	f	f	2025-10-26 17:28:58.981278
653	2026-10-15	2026	10	15	4	Octobre	Jeudi	42	f	f	2025-10-26 17:28:58.981278
654	2026-10-16	2026	10	16	4	Octobre	Vendredi	42	f	f	2025-10-26 17:28:58.981278
655	2026-10-17	2026	10	17	4	Octobre	Samedi	42	t	f	2025-10-26 17:28:58.981278
656	2026-10-18	2026	10	18	4	Octobre	Dimanche	42	t	f	2025-10-26 17:28:58.981278
657	2026-10-19	2026	10	19	4	Octobre	Lundi	43	f	f	2025-10-26 17:28:58.981278
658	2026-10-20	2026	10	20	4	Octobre	Mardi	43	f	f	2025-10-26 17:28:58.981278
659	2026-10-21	2026	10	21	4	Octobre	Mercredi	43	f	f	2025-10-26 17:28:58.981278
660	2026-10-22	2026	10	22	4	Octobre	Jeudi	43	f	f	2025-10-26 17:28:58.981278
661	2026-10-23	2026	10	23	4	Octobre	Vendredi	43	f	f	2025-10-26 17:28:58.981278
662	2026-10-24	2026	10	24	4	Octobre	Samedi	43	t	f	2025-10-26 17:28:58.981278
663	2026-10-25	2026	10	25	4	Octobre	Dimanche	43	t	f	2025-10-26 17:28:58.981278
664	2026-10-26	2026	10	26	4	Octobre	Lundi	44	f	f	2025-10-26 17:28:58.981278
665	2026-10-27	2026	10	27	4	Octobre	Mardi	44	f	f	2025-10-26 17:28:58.981278
666	2026-10-28	2026	10	28	4	Octobre	Mercredi	44	f	f	2025-10-26 17:28:58.981278
667	2026-10-29	2026	10	29	4	Octobre	Jeudi	44	f	f	2025-10-26 17:28:58.981278
668	2026-10-30	2026	10	30	4	Octobre	Vendredi	44	f	f	2025-10-26 17:28:58.981278
669	2026-10-31	2026	10	31	4	Octobre	Samedi	44	t	f	2025-10-26 17:28:58.981278
670	2026-11-01	2026	11	1	4	Novembre	Dimanche	44	t	f	2025-10-26 17:28:58.981278
671	2026-11-02	2026	11	2	4	Novembre	Lundi	45	f	f	2025-10-26 17:28:58.981278
672	2026-11-03	2026	11	3	4	Novembre	Mardi	45	f	f	2025-10-26 17:28:58.981278
673	2026-11-04	2026	11	4	4	Novembre	Mercredi	45	f	f	2025-10-26 17:28:58.981278
674	2026-11-05	2026	11	5	4	Novembre	Jeudi	45	f	f	2025-10-26 17:28:58.981278
675	2026-11-06	2026	11	6	4	Novembre	Vendredi	45	f	f	2025-10-26 17:28:58.981278
676	2026-11-07	2026	11	7	4	Novembre	Samedi	45	t	f	2025-10-26 17:28:58.981278
677	2026-11-08	2026	11	8	4	Novembre	Dimanche	45	t	f	2025-10-26 17:28:58.981278
678	2026-11-09	2026	11	9	4	Novembre	Lundi	46	f	f	2025-10-26 17:28:58.981278
679	2026-11-10	2026	11	10	4	Novembre	Mardi	46	f	f	2025-10-26 17:28:58.981278
680	2026-11-11	2026	11	11	4	Novembre	Mercredi	46	f	f	2025-10-26 17:28:58.981278
681	2026-11-12	2026	11	12	4	Novembre	Jeudi	46	f	f	2025-10-26 17:28:58.981278
682	2026-11-13	2026	11	13	4	Novembre	Vendredi	46	f	f	2025-10-26 17:28:58.981278
683	2026-11-14	2026	11	14	4	Novembre	Samedi	46	t	f	2025-10-26 17:28:58.981278
684	2026-11-15	2026	11	15	4	Novembre	Dimanche	46	t	f	2025-10-26 17:28:58.981278
685	2026-11-16	2026	11	16	4	Novembre	Lundi	47	f	f	2025-10-26 17:28:58.981278
686	2026-11-17	2026	11	17	4	Novembre	Mardi	47	f	f	2025-10-26 17:28:58.981278
687	2026-11-18	2026	11	18	4	Novembre	Mercredi	47	f	f	2025-10-26 17:28:58.981278
688	2026-11-19	2026	11	19	4	Novembre	Jeudi	47	f	f	2025-10-26 17:28:58.981278
689	2026-11-20	2026	11	20	4	Novembre	Vendredi	47	f	f	2025-10-26 17:28:58.981278
690	2026-11-21	2026	11	21	4	Novembre	Samedi	47	t	f	2025-10-26 17:28:58.981278
691	2026-11-22	2026	11	22	4	Novembre	Dimanche	47	t	f	2025-10-26 17:28:58.981278
692	2026-11-23	2026	11	23	4	Novembre	Lundi	48	f	f	2025-10-26 17:28:58.981278
693	2026-11-24	2026	11	24	4	Novembre	Mardi	48	f	f	2025-10-26 17:28:58.981278
694	2026-11-25	2026	11	25	4	Novembre	Mercredi	48	f	f	2025-10-26 17:28:58.981278
695	2026-11-26	2026	11	26	4	Novembre	Jeudi	48	f	f	2025-10-26 17:28:58.981278
696	2026-11-27	2026	11	27	4	Novembre	Vendredi	48	f	f	2025-10-26 17:28:58.981278
697	2026-11-28	2026	11	28	4	Novembre	Samedi	48	t	f	2025-10-26 17:28:58.981278
698	2026-11-29	2026	11	29	4	Novembre	Dimanche	48	t	f	2025-10-26 17:28:58.981278
699	2026-11-30	2026	11	30	4	Novembre	Lundi	49	f	f	2025-10-26 17:28:58.981278
700	2026-12-01	2026	12	1	4	DÃ©cembre	Mardi	49	f	f	2025-10-26 17:28:58.981278
701	2026-12-02	2026	12	2	4	DÃ©cembre	Mercredi	49	f	f	2025-10-26 17:28:58.981278
702	2026-12-03	2026	12	3	4	DÃ©cembre	Jeudi	49	f	f	2025-10-26 17:28:58.981278
703	2026-12-04	2026	12	4	4	DÃ©cembre	Vendredi	49	f	f	2025-10-26 17:28:58.981278
704	2026-12-05	2026	12	5	4	DÃ©cembre	Samedi	49	t	f	2025-10-26 17:28:58.981278
705	2026-12-06	2026	12	6	4	DÃ©cembre	Dimanche	49	t	f	2025-10-26 17:28:58.981278
706	2026-12-07	2026	12	7	4	DÃ©cembre	Lundi	50	f	f	2025-10-26 17:28:58.981278
707	2026-12-08	2026	12	8	4	DÃ©cembre	Mardi	50	f	f	2025-10-26 17:28:58.981278
708	2026-12-09	2026	12	9	4	DÃ©cembre	Mercredi	50	f	f	2025-10-26 17:28:58.981278
709	2026-12-10	2026	12	10	4	DÃ©cembre	Jeudi	50	f	f	2025-10-26 17:28:58.981278
710	2026-12-11	2026	12	11	4	DÃ©cembre	Vendredi	50	f	f	2025-10-26 17:28:58.981278
711	2026-12-12	2026	12	12	4	DÃ©cembre	Samedi	50	t	f	2025-10-26 17:28:58.981278
712	2026-12-13	2026	12	13	4	DÃ©cembre	Dimanche	50	t	f	2025-10-26 17:28:58.981278
713	2026-12-14	2026	12	14	4	DÃ©cembre	Lundi	51	f	f	2025-10-26 17:28:58.981278
714	2026-12-15	2026	12	15	4	DÃ©cembre	Mardi	51	f	f	2025-10-26 17:28:58.981278
715	2026-12-16	2026	12	16	4	DÃ©cembre	Mercredi	51	f	f	2025-10-26 17:28:58.981278
716	2026-12-17	2026	12	17	4	DÃ©cembre	Jeudi	51	f	f	2025-10-26 17:28:58.981278
717	2026-12-18	2026	12	18	4	DÃ©cembre	Vendredi	51	f	f	2025-10-26 17:28:58.981278
718	2026-12-19	2026	12	19	4	DÃ©cembre	Samedi	51	t	f	2025-10-26 17:28:58.981278
719	2026-12-20	2026	12	20	4	DÃ©cembre	Dimanche	51	t	f	2025-10-26 17:28:58.981278
720	2026-12-21	2026	12	21	4	DÃ©cembre	Lundi	52	f	f	2025-10-26 17:28:58.981278
721	2026-12-22	2026	12	22	4	DÃ©cembre	Mardi	52	f	f	2025-10-26 17:28:58.981278
722	2026-12-23	2026	12	23	4	DÃ©cembre	Mercredi	52	f	f	2025-10-26 17:28:58.981278
723	2026-12-24	2026	12	24	4	DÃ©cembre	Jeudi	52	f	f	2025-10-26 17:28:58.981278
724	2026-12-25	2026	12	25	4	DÃ©cembre	Vendredi	52	f	f	2025-10-26 17:28:58.981278
725	2026-12-26	2026	12	26	4	DÃ©cembre	Samedi	52	t	f	2025-10-26 17:28:58.981278
726	2026-12-27	2026	12	27	4	DÃ©cembre	Dimanche	52	t	f	2025-10-26 17:28:58.981278
727	2026-12-28	2026	12	28	4	DÃ©cembre	Lundi	53	f	f	2025-10-26 17:28:58.981278
728	2026-12-29	2026	12	29	4	DÃ©cembre	Mardi	53	f	f	2025-10-26 17:28:58.981278
729	2026-12-30	2026	12	30	4	DÃ©cembre	Mercredi	53	f	f	2025-10-26 17:28:58.981278
730	2026-12-31	2026	12	31	4	DÃ©cembre	Jeudi	53	f	f	2025-10-26 17:28:58.981278
731	2027-01-01	2027	1	1	1	Janvier	Vendredi	53	f	f	2025-10-26 17:28:58.981278
732	2027-01-02	2027	1	2	1	Janvier	Samedi	53	t	f	2025-10-26 17:28:58.981278
733	2027-01-03	2027	1	3	1	Janvier	Dimanche	53	t	f	2025-10-26 17:28:58.981278
734	2027-01-04	2027	1	4	1	Janvier	Lundi	1	f	f	2025-10-26 17:28:58.981278
735	2027-01-05	2027	1	5	1	Janvier	Mardi	1	f	f	2025-10-26 17:28:58.981278
736	2027-01-06	2027	1	6	1	Janvier	Mercredi	1	f	f	2025-10-26 17:28:58.981278
737	2027-01-07	2027	1	7	1	Janvier	Jeudi	1	f	f	2025-10-26 17:28:58.981278
738	2027-01-08	2027	1	8	1	Janvier	Vendredi	1	f	f	2025-10-26 17:28:58.981278
739	2027-01-09	2027	1	9	1	Janvier	Samedi	1	t	f	2025-10-26 17:28:58.981278
740	2027-01-10	2027	1	10	1	Janvier	Dimanche	1	t	f	2025-10-26 17:28:58.981278
741	2027-01-11	2027	1	11	1	Janvier	Lundi	2	f	f	2025-10-26 17:28:58.981278
742	2027-01-12	2027	1	12	1	Janvier	Mardi	2	f	f	2025-10-26 17:28:58.981278
743	2027-01-13	2027	1	13	1	Janvier	Mercredi	2	f	f	2025-10-26 17:28:58.981278
744	2027-01-14	2027	1	14	1	Janvier	Jeudi	2	f	f	2025-10-26 17:28:58.981278
745	2027-01-15	2027	1	15	1	Janvier	Vendredi	2	f	f	2025-10-26 17:28:58.981278
746	2027-01-16	2027	1	16	1	Janvier	Samedi	2	t	f	2025-10-26 17:28:58.981278
747	2027-01-17	2027	1	17	1	Janvier	Dimanche	2	t	f	2025-10-26 17:28:58.981278
748	2027-01-18	2027	1	18	1	Janvier	Lundi	3	f	f	2025-10-26 17:28:58.981278
749	2027-01-19	2027	1	19	1	Janvier	Mardi	3	f	f	2025-10-26 17:28:58.981278
750	2027-01-20	2027	1	20	1	Janvier	Mercredi	3	f	f	2025-10-26 17:28:58.981278
751	2027-01-21	2027	1	21	1	Janvier	Jeudi	3	f	f	2025-10-26 17:28:58.981278
752	2027-01-22	2027	1	22	1	Janvier	Vendredi	3	f	f	2025-10-26 17:28:58.981278
753	2027-01-23	2027	1	23	1	Janvier	Samedi	3	t	f	2025-10-26 17:28:58.981278
754	2027-01-24	2027	1	24	1	Janvier	Dimanche	3	t	f	2025-10-26 17:28:58.981278
755	2027-01-25	2027	1	25	1	Janvier	Lundi	4	f	f	2025-10-26 17:28:58.981278
756	2027-01-26	2027	1	26	1	Janvier	Mardi	4	f	f	2025-10-26 17:28:58.981278
757	2027-01-27	2027	1	27	1	Janvier	Mercredi	4	f	f	2025-10-26 17:28:58.981278
758	2027-01-28	2027	1	28	1	Janvier	Jeudi	4	f	f	2025-10-26 17:28:58.981278
759	2027-01-29	2027	1	29	1	Janvier	Vendredi	4	f	f	2025-10-26 17:28:58.981278
760	2027-01-30	2027	1	30	1	Janvier	Samedi	4	t	f	2025-10-26 17:28:58.981278
761	2027-01-31	2027	1	31	1	Janvier	Dimanche	4	t	f	2025-10-26 17:28:58.981278
762	2027-02-01	2027	2	1	1	FÃ©vrier	Lundi	5	f	f	2025-10-26 17:28:58.981278
763	2027-02-02	2027	2	2	1	FÃ©vrier	Mardi	5	f	f	2025-10-26 17:28:58.981278
764	2027-02-03	2027	2	3	1	FÃ©vrier	Mercredi	5	f	f	2025-10-26 17:28:58.981278
765	2027-02-04	2027	2	4	1	FÃ©vrier	Jeudi	5	f	f	2025-10-26 17:28:58.981278
766	2027-02-05	2027	2	5	1	FÃ©vrier	Vendredi	5	f	f	2025-10-26 17:28:58.981278
767	2027-02-06	2027	2	6	1	FÃ©vrier	Samedi	5	t	f	2025-10-26 17:28:58.981278
768	2027-02-07	2027	2	7	1	FÃ©vrier	Dimanche	5	t	f	2025-10-26 17:28:58.981278
769	2027-02-08	2027	2	8	1	FÃ©vrier	Lundi	6	f	f	2025-10-26 17:28:58.981278
770	2027-02-09	2027	2	9	1	FÃ©vrier	Mardi	6	f	f	2025-10-26 17:28:58.981278
771	2027-02-10	2027	2	10	1	FÃ©vrier	Mercredi	6	f	f	2025-10-26 17:28:58.981278
772	2027-02-11	2027	2	11	1	FÃ©vrier	Jeudi	6	f	f	2025-10-26 17:28:58.981278
773	2027-02-12	2027	2	12	1	FÃ©vrier	Vendredi	6	f	f	2025-10-26 17:28:58.981278
774	2027-02-13	2027	2	13	1	FÃ©vrier	Samedi	6	t	f	2025-10-26 17:28:58.981278
775	2027-02-14	2027	2	14	1	FÃ©vrier	Dimanche	6	t	f	2025-10-26 17:28:58.981278
776	2027-02-15	2027	2	15	1	FÃ©vrier	Lundi	7	f	f	2025-10-26 17:28:58.981278
777	2027-02-16	2027	2	16	1	FÃ©vrier	Mardi	7	f	f	2025-10-26 17:28:58.981278
778	2027-02-17	2027	2	17	1	FÃ©vrier	Mercredi	7	f	f	2025-10-26 17:28:58.981278
779	2027-02-18	2027	2	18	1	FÃ©vrier	Jeudi	7	f	f	2025-10-26 17:28:58.981278
780	2027-02-19	2027	2	19	1	FÃ©vrier	Vendredi	7	f	f	2025-10-26 17:28:58.981278
781	2027-02-20	2027	2	20	1	FÃ©vrier	Samedi	7	t	f	2025-10-26 17:28:58.981278
782	2027-02-21	2027	2	21	1	FÃ©vrier	Dimanche	7	t	f	2025-10-26 17:28:58.981278
783	2027-02-22	2027	2	22	1	FÃ©vrier	Lundi	8	f	f	2025-10-26 17:28:58.981278
784	2027-02-23	2027	2	23	1	FÃ©vrier	Mardi	8	f	f	2025-10-26 17:28:58.981278
785	2027-02-24	2027	2	24	1	FÃ©vrier	Mercredi	8	f	f	2025-10-26 17:28:58.981278
786	2027-02-25	2027	2	25	1	FÃ©vrier	Jeudi	8	f	f	2025-10-26 17:28:58.981278
787	2027-02-26	2027	2	26	1	FÃ©vrier	Vendredi	8	f	f	2025-10-26 17:28:58.981278
788	2027-02-27	2027	2	27	1	FÃ©vrier	Samedi	8	t	f	2025-10-26 17:28:58.981278
789	2027-02-28	2027	2	28	1	FÃ©vrier	Dimanche	8	t	f	2025-10-26 17:28:58.981278
790	2027-03-01	2027	3	1	1	Mars	Lundi	9	f	f	2025-10-26 17:28:58.981278
791	2027-03-02	2027	3	2	1	Mars	Mardi	9	f	f	2025-10-26 17:28:58.981278
792	2027-03-03	2027	3	3	1	Mars	Mercredi	9	f	f	2025-10-26 17:28:58.981278
793	2027-03-04	2027	3	4	1	Mars	Jeudi	9	f	f	2025-10-26 17:28:58.981278
794	2027-03-05	2027	3	5	1	Mars	Vendredi	9	f	f	2025-10-26 17:28:58.981278
795	2027-03-06	2027	3	6	1	Mars	Samedi	9	t	f	2025-10-26 17:28:58.981278
796	2027-03-07	2027	3	7	1	Mars	Dimanche	9	t	f	2025-10-26 17:28:58.981278
797	2027-03-08	2027	3	8	1	Mars	Lundi	10	f	f	2025-10-26 17:28:58.981278
798	2027-03-09	2027	3	9	1	Mars	Mardi	10	f	f	2025-10-26 17:28:58.981278
799	2027-03-10	2027	3	10	1	Mars	Mercredi	10	f	f	2025-10-26 17:28:58.981278
800	2027-03-11	2027	3	11	1	Mars	Jeudi	10	f	f	2025-10-26 17:28:58.981278
801	2027-03-12	2027	3	12	1	Mars	Vendredi	10	f	f	2025-10-26 17:28:58.981278
802	2027-03-13	2027	3	13	1	Mars	Samedi	10	t	f	2025-10-26 17:28:58.981278
803	2027-03-14	2027	3	14	1	Mars	Dimanche	10	t	f	2025-10-26 17:28:58.981278
804	2027-03-15	2027	3	15	1	Mars	Lundi	11	f	f	2025-10-26 17:28:58.981278
805	2027-03-16	2027	3	16	1	Mars	Mardi	11	f	f	2025-10-26 17:28:58.981278
806	2027-03-17	2027	3	17	1	Mars	Mercredi	11	f	f	2025-10-26 17:28:58.981278
807	2027-03-18	2027	3	18	1	Mars	Jeudi	11	f	f	2025-10-26 17:28:58.981278
808	2027-03-19	2027	3	19	1	Mars	Vendredi	11	f	f	2025-10-26 17:28:58.981278
809	2027-03-20	2027	3	20	1	Mars	Samedi	11	t	f	2025-10-26 17:28:58.981278
810	2027-03-21	2027	3	21	1	Mars	Dimanche	11	t	f	2025-10-26 17:28:58.981278
811	2027-03-22	2027	3	22	1	Mars	Lundi	12	f	f	2025-10-26 17:28:58.981278
812	2027-03-23	2027	3	23	1	Mars	Mardi	12	f	f	2025-10-26 17:28:58.981278
813	2027-03-24	2027	3	24	1	Mars	Mercredi	12	f	f	2025-10-26 17:28:58.981278
814	2027-03-25	2027	3	25	1	Mars	Jeudi	12	f	f	2025-10-26 17:28:58.981278
815	2027-03-26	2027	3	26	1	Mars	Vendredi	12	f	f	2025-10-26 17:28:58.981278
816	2027-03-27	2027	3	27	1	Mars	Samedi	12	t	f	2025-10-26 17:28:58.981278
817	2027-03-28	2027	3	28	1	Mars	Dimanche	12	t	f	2025-10-26 17:28:58.981278
818	2027-03-29	2027	3	29	1	Mars	Lundi	13	f	f	2025-10-26 17:28:58.981278
819	2027-03-30	2027	3	30	1	Mars	Mardi	13	f	f	2025-10-26 17:28:58.981278
820	2027-03-31	2027	3	31	1	Mars	Mercredi	13	f	f	2025-10-26 17:28:58.981278
821	2027-04-01	2027	4	1	2	Avril	Jeudi	13	f	f	2025-10-26 17:28:58.981278
822	2027-04-02	2027	4	2	2	Avril	Vendredi	13	f	f	2025-10-26 17:28:58.981278
823	2027-04-03	2027	4	3	2	Avril	Samedi	13	t	f	2025-10-26 17:28:58.981278
824	2027-04-04	2027	4	4	2	Avril	Dimanche	13	t	f	2025-10-26 17:28:58.981278
825	2027-04-05	2027	4	5	2	Avril	Lundi	14	f	f	2025-10-26 17:28:58.981278
826	2027-04-06	2027	4	6	2	Avril	Mardi	14	f	f	2025-10-26 17:28:58.981278
827	2027-04-07	2027	4	7	2	Avril	Mercredi	14	f	f	2025-10-26 17:28:58.981278
828	2027-04-08	2027	4	8	2	Avril	Jeudi	14	f	f	2025-10-26 17:28:58.981278
829	2027-04-09	2027	4	9	2	Avril	Vendredi	14	f	f	2025-10-26 17:28:58.981278
830	2027-04-10	2027	4	10	2	Avril	Samedi	14	t	f	2025-10-26 17:28:58.981278
831	2027-04-11	2027	4	11	2	Avril	Dimanche	14	t	f	2025-10-26 17:28:58.981278
832	2027-04-12	2027	4	12	2	Avril	Lundi	15	f	f	2025-10-26 17:28:58.981278
833	2027-04-13	2027	4	13	2	Avril	Mardi	15	f	f	2025-10-26 17:28:58.981278
834	2027-04-14	2027	4	14	2	Avril	Mercredi	15	f	f	2025-10-26 17:28:58.981278
835	2027-04-15	2027	4	15	2	Avril	Jeudi	15	f	f	2025-10-26 17:28:58.981278
836	2027-04-16	2027	4	16	2	Avril	Vendredi	15	f	f	2025-10-26 17:28:58.981278
837	2027-04-17	2027	4	17	2	Avril	Samedi	15	t	f	2025-10-26 17:28:58.981278
838	2027-04-18	2027	4	18	2	Avril	Dimanche	15	t	f	2025-10-26 17:28:58.981278
839	2027-04-19	2027	4	19	2	Avril	Lundi	16	f	f	2025-10-26 17:28:58.981278
840	2027-04-20	2027	4	20	2	Avril	Mardi	16	f	f	2025-10-26 17:28:58.981278
841	2027-04-21	2027	4	21	2	Avril	Mercredi	16	f	f	2025-10-26 17:28:58.981278
842	2027-04-22	2027	4	22	2	Avril	Jeudi	16	f	f	2025-10-26 17:28:58.981278
843	2027-04-23	2027	4	23	2	Avril	Vendredi	16	f	f	2025-10-26 17:28:58.981278
844	2027-04-24	2027	4	24	2	Avril	Samedi	16	t	f	2025-10-26 17:28:58.981278
845	2027-04-25	2027	4	25	2	Avril	Dimanche	16	t	f	2025-10-26 17:28:58.981278
846	2027-04-26	2027	4	26	2	Avril	Lundi	17	f	f	2025-10-26 17:28:58.981278
847	2027-04-27	2027	4	27	2	Avril	Mardi	17	f	f	2025-10-26 17:28:58.981278
848	2027-04-28	2027	4	28	2	Avril	Mercredi	17	f	f	2025-10-26 17:28:58.981278
849	2027-04-29	2027	4	29	2	Avril	Jeudi	17	f	f	2025-10-26 17:28:58.981278
850	2027-04-30	2027	4	30	2	Avril	Vendredi	17	f	f	2025-10-26 17:28:58.981278
851	2027-05-01	2027	5	1	2	Mai	Samedi	17	t	f	2025-10-26 17:28:58.981278
852	2027-05-02	2027	5	2	2	Mai	Dimanche	17	t	f	2025-10-26 17:28:58.981278
853	2027-05-03	2027	5	3	2	Mai	Lundi	18	f	f	2025-10-26 17:28:58.981278
854	2027-05-04	2027	5	4	2	Mai	Mardi	18	f	f	2025-10-26 17:28:58.981278
855	2027-05-05	2027	5	5	2	Mai	Mercredi	18	f	f	2025-10-26 17:28:58.981278
856	2027-05-06	2027	5	6	2	Mai	Jeudi	18	f	f	2025-10-26 17:28:58.981278
857	2027-05-07	2027	5	7	2	Mai	Vendredi	18	f	f	2025-10-26 17:28:58.981278
858	2027-05-08	2027	5	8	2	Mai	Samedi	18	t	f	2025-10-26 17:28:58.981278
859	2027-05-09	2027	5	9	2	Mai	Dimanche	18	t	f	2025-10-26 17:28:58.981278
860	2027-05-10	2027	5	10	2	Mai	Lundi	19	f	f	2025-10-26 17:28:58.981278
861	2027-05-11	2027	5	11	2	Mai	Mardi	19	f	f	2025-10-26 17:28:58.981278
862	2027-05-12	2027	5	12	2	Mai	Mercredi	19	f	f	2025-10-26 17:28:58.981278
863	2027-05-13	2027	5	13	2	Mai	Jeudi	19	f	f	2025-10-26 17:28:58.981278
864	2027-05-14	2027	5	14	2	Mai	Vendredi	19	f	f	2025-10-26 17:28:58.981278
865	2027-05-15	2027	5	15	2	Mai	Samedi	19	t	f	2025-10-26 17:28:58.981278
866	2027-05-16	2027	5	16	2	Mai	Dimanche	19	t	f	2025-10-26 17:28:58.981278
867	2027-05-17	2027	5	17	2	Mai	Lundi	20	f	f	2025-10-26 17:28:58.981278
868	2027-05-18	2027	5	18	2	Mai	Mardi	20	f	f	2025-10-26 17:28:58.981278
869	2027-05-19	2027	5	19	2	Mai	Mercredi	20	f	f	2025-10-26 17:28:58.981278
870	2027-05-20	2027	5	20	2	Mai	Jeudi	20	f	f	2025-10-26 17:28:58.981278
871	2027-05-21	2027	5	21	2	Mai	Vendredi	20	f	f	2025-10-26 17:28:58.981278
872	2027-05-22	2027	5	22	2	Mai	Samedi	20	t	f	2025-10-26 17:28:58.981278
873	2027-05-23	2027	5	23	2	Mai	Dimanche	20	t	f	2025-10-26 17:28:58.981278
874	2027-05-24	2027	5	24	2	Mai	Lundi	21	f	f	2025-10-26 17:28:58.981278
875	2027-05-25	2027	5	25	2	Mai	Mardi	21	f	f	2025-10-26 17:28:58.981278
876	2027-05-26	2027	5	26	2	Mai	Mercredi	21	f	f	2025-10-26 17:28:58.981278
877	2027-05-27	2027	5	27	2	Mai	Jeudi	21	f	f	2025-10-26 17:28:58.981278
878	2027-05-28	2027	5	28	2	Mai	Vendredi	21	f	f	2025-10-26 17:28:58.981278
879	2027-05-29	2027	5	29	2	Mai	Samedi	21	t	f	2025-10-26 17:28:58.981278
880	2027-05-30	2027	5	30	2	Mai	Dimanche	21	t	f	2025-10-26 17:28:58.981278
881	2027-05-31	2027	5	31	2	Mai	Lundi	22	f	f	2025-10-26 17:28:58.981278
882	2027-06-01	2027	6	1	2	Juin	Mardi	22	f	f	2025-10-26 17:28:58.981278
883	2027-06-02	2027	6	2	2	Juin	Mercredi	22	f	f	2025-10-26 17:28:58.981278
884	2027-06-03	2027	6	3	2	Juin	Jeudi	22	f	f	2025-10-26 17:28:58.981278
885	2027-06-04	2027	6	4	2	Juin	Vendredi	22	f	f	2025-10-26 17:28:58.981278
886	2027-06-05	2027	6	5	2	Juin	Samedi	22	t	f	2025-10-26 17:28:58.981278
887	2027-06-06	2027	6	6	2	Juin	Dimanche	22	t	f	2025-10-26 17:28:58.981278
888	2027-06-07	2027	6	7	2	Juin	Lundi	23	f	f	2025-10-26 17:28:58.981278
889	2027-06-08	2027	6	8	2	Juin	Mardi	23	f	f	2025-10-26 17:28:58.981278
890	2027-06-09	2027	6	9	2	Juin	Mercredi	23	f	f	2025-10-26 17:28:58.981278
891	2027-06-10	2027	6	10	2	Juin	Jeudi	23	f	f	2025-10-26 17:28:58.981278
892	2027-06-11	2027	6	11	2	Juin	Vendredi	23	f	f	2025-10-26 17:28:58.981278
893	2027-06-12	2027	6	12	2	Juin	Samedi	23	t	f	2025-10-26 17:28:58.981278
894	2027-06-13	2027	6	13	2	Juin	Dimanche	23	t	f	2025-10-26 17:28:58.981278
895	2027-06-14	2027	6	14	2	Juin	Lundi	24	f	f	2025-10-26 17:28:58.981278
896	2027-06-15	2027	6	15	2	Juin	Mardi	24	f	f	2025-10-26 17:28:58.981278
897	2027-06-16	2027	6	16	2	Juin	Mercredi	24	f	f	2025-10-26 17:28:58.981278
898	2027-06-17	2027	6	17	2	Juin	Jeudi	24	f	f	2025-10-26 17:28:58.981278
899	2027-06-18	2027	6	18	2	Juin	Vendredi	24	f	f	2025-10-26 17:28:58.981278
900	2027-06-19	2027	6	19	2	Juin	Samedi	24	t	f	2025-10-26 17:28:58.981278
901	2027-06-20	2027	6	20	2	Juin	Dimanche	24	t	f	2025-10-26 17:28:58.981278
902	2027-06-21	2027	6	21	2	Juin	Lundi	25	f	f	2025-10-26 17:28:58.981278
903	2027-06-22	2027	6	22	2	Juin	Mardi	25	f	f	2025-10-26 17:28:58.981278
904	2027-06-23	2027	6	23	2	Juin	Mercredi	25	f	f	2025-10-26 17:28:58.981278
905	2027-06-24	2027	6	24	2	Juin	Jeudi	25	f	f	2025-10-26 17:28:58.981278
906	2027-06-25	2027	6	25	2	Juin	Vendredi	25	f	f	2025-10-26 17:28:58.981278
907	2027-06-26	2027	6	26	2	Juin	Samedi	25	t	f	2025-10-26 17:28:58.981278
908	2027-06-27	2027	6	27	2	Juin	Dimanche	25	t	f	2025-10-26 17:28:58.981278
909	2027-06-28	2027	6	28	2	Juin	Lundi	26	f	f	2025-10-26 17:28:58.981278
910	2027-06-29	2027	6	29	2	Juin	Mardi	26	f	f	2025-10-26 17:28:58.981278
911	2027-06-30	2027	6	30	2	Juin	Mercredi	26	f	f	2025-10-26 17:28:58.981278
912	2027-07-01	2027	7	1	3	Juillet	Jeudi	26	f	f	2025-10-26 17:28:58.981278
913	2027-07-02	2027	7	2	3	Juillet	Vendredi	26	f	f	2025-10-26 17:28:58.981278
914	2027-07-03	2027	7	3	3	Juillet	Samedi	26	t	f	2025-10-26 17:28:58.981278
915	2027-07-04	2027	7	4	3	Juillet	Dimanche	26	t	f	2025-10-26 17:28:58.981278
916	2027-07-05	2027	7	5	3	Juillet	Lundi	27	f	f	2025-10-26 17:28:58.981278
917	2027-07-06	2027	7	6	3	Juillet	Mardi	27	f	f	2025-10-26 17:28:58.981278
918	2027-07-07	2027	7	7	3	Juillet	Mercredi	27	f	f	2025-10-26 17:28:58.981278
919	2027-07-08	2027	7	8	3	Juillet	Jeudi	27	f	f	2025-10-26 17:28:58.981278
920	2027-07-09	2027	7	9	3	Juillet	Vendredi	27	f	f	2025-10-26 17:28:58.981278
921	2027-07-10	2027	7	10	3	Juillet	Samedi	27	t	f	2025-10-26 17:28:58.981278
922	2027-07-11	2027	7	11	3	Juillet	Dimanche	27	t	f	2025-10-26 17:28:58.981278
923	2027-07-12	2027	7	12	3	Juillet	Lundi	28	f	f	2025-10-26 17:28:58.981278
924	2027-07-13	2027	7	13	3	Juillet	Mardi	28	f	f	2025-10-26 17:28:58.981278
925	2027-07-14	2027	7	14	3	Juillet	Mercredi	28	f	f	2025-10-26 17:28:58.981278
926	2027-07-15	2027	7	15	3	Juillet	Jeudi	28	f	f	2025-10-26 17:28:58.981278
927	2027-07-16	2027	7	16	3	Juillet	Vendredi	28	f	f	2025-10-26 17:28:58.981278
928	2027-07-17	2027	7	17	3	Juillet	Samedi	28	t	f	2025-10-26 17:28:58.981278
929	2027-07-18	2027	7	18	3	Juillet	Dimanche	28	t	f	2025-10-26 17:28:58.981278
930	2027-07-19	2027	7	19	3	Juillet	Lundi	29	f	f	2025-10-26 17:28:58.981278
931	2027-07-20	2027	7	20	3	Juillet	Mardi	29	f	f	2025-10-26 17:28:58.981278
932	2027-07-21	2027	7	21	3	Juillet	Mercredi	29	f	f	2025-10-26 17:28:58.981278
933	2027-07-22	2027	7	22	3	Juillet	Jeudi	29	f	f	2025-10-26 17:28:58.981278
934	2027-07-23	2027	7	23	3	Juillet	Vendredi	29	f	f	2025-10-26 17:28:58.981278
935	2027-07-24	2027	7	24	3	Juillet	Samedi	29	t	f	2025-10-26 17:28:58.981278
936	2027-07-25	2027	7	25	3	Juillet	Dimanche	29	t	f	2025-10-26 17:28:58.981278
937	2027-07-26	2027	7	26	3	Juillet	Lundi	30	f	f	2025-10-26 17:28:58.981278
938	2027-07-27	2027	7	27	3	Juillet	Mardi	30	f	f	2025-10-26 17:28:58.981278
939	2027-07-28	2027	7	28	3	Juillet	Mercredi	30	f	f	2025-10-26 17:28:58.981278
940	2027-07-29	2027	7	29	3	Juillet	Jeudi	30	f	f	2025-10-26 17:28:58.981278
941	2027-07-30	2027	7	30	3	Juillet	Vendredi	30	f	f	2025-10-26 17:28:58.981278
942	2027-07-31	2027	7	31	3	Juillet	Samedi	30	t	f	2025-10-26 17:28:58.981278
943	2027-08-01	2027	8	1	3	AoÃ»t	Dimanche	30	t	f	2025-10-26 17:28:58.981278
944	2027-08-02	2027	8	2	3	AoÃ»t	Lundi	31	f	f	2025-10-26 17:28:58.981278
945	2027-08-03	2027	8	3	3	AoÃ»t	Mardi	31	f	f	2025-10-26 17:28:58.981278
946	2027-08-04	2027	8	4	3	AoÃ»t	Mercredi	31	f	f	2025-10-26 17:28:58.981278
947	2027-08-05	2027	8	5	3	AoÃ»t	Jeudi	31	f	f	2025-10-26 17:28:58.981278
948	2027-08-06	2027	8	6	3	AoÃ»t	Vendredi	31	f	f	2025-10-26 17:28:58.981278
949	2027-08-07	2027	8	7	3	AoÃ»t	Samedi	31	t	f	2025-10-26 17:28:58.981278
950	2027-08-08	2027	8	8	3	AoÃ»t	Dimanche	31	t	f	2025-10-26 17:28:58.981278
951	2027-08-09	2027	8	9	3	AoÃ»t	Lundi	32	f	f	2025-10-26 17:28:58.981278
952	2027-08-10	2027	8	10	3	AoÃ»t	Mardi	32	f	f	2025-10-26 17:28:58.981278
953	2027-08-11	2027	8	11	3	AoÃ»t	Mercredi	32	f	f	2025-10-26 17:28:58.981278
954	2027-08-12	2027	8	12	3	AoÃ»t	Jeudi	32	f	f	2025-10-26 17:28:58.981278
955	2027-08-13	2027	8	13	3	AoÃ»t	Vendredi	32	f	f	2025-10-26 17:28:58.981278
956	2027-08-14	2027	8	14	3	AoÃ»t	Samedi	32	t	f	2025-10-26 17:28:58.981278
957	2027-08-15	2027	8	15	3	AoÃ»t	Dimanche	32	t	f	2025-10-26 17:28:58.981278
958	2027-08-16	2027	8	16	3	AoÃ»t	Lundi	33	f	f	2025-10-26 17:28:58.981278
959	2027-08-17	2027	8	17	3	AoÃ»t	Mardi	33	f	f	2025-10-26 17:28:58.981278
960	2027-08-18	2027	8	18	3	AoÃ»t	Mercredi	33	f	f	2025-10-26 17:28:58.981278
961	2027-08-19	2027	8	19	3	AoÃ»t	Jeudi	33	f	f	2025-10-26 17:28:58.981278
962	2027-08-20	2027	8	20	3	AoÃ»t	Vendredi	33	f	f	2025-10-26 17:28:58.981278
963	2027-08-21	2027	8	21	3	AoÃ»t	Samedi	33	t	f	2025-10-26 17:28:58.981278
964	2027-08-22	2027	8	22	3	AoÃ»t	Dimanche	33	t	f	2025-10-26 17:28:58.981278
965	2027-08-23	2027	8	23	3	AoÃ»t	Lundi	34	f	f	2025-10-26 17:28:58.981278
966	2027-08-24	2027	8	24	3	AoÃ»t	Mardi	34	f	f	2025-10-26 17:28:58.981278
967	2027-08-25	2027	8	25	3	AoÃ»t	Mercredi	34	f	f	2025-10-26 17:28:58.981278
968	2027-08-26	2027	8	26	3	AoÃ»t	Jeudi	34	f	f	2025-10-26 17:28:58.981278
969	2027-08-27	2027	8	27	3	AoÃ»t	Vendredi	34	f	f	2025-10-26 17:28:58.981278
970	2027-08-28	2027	8	28	3	AoÃ»t	Samedi	34	t	f	2025-10-26 17:28:58.981278
971	2027-08-29	2027	8	29	3	AoÃ»t	Dimanche	34	t	f	2025-10-26 17:28:58.981278
972	2027-08-30	2027	8	30	3	AoÃ»t	Lundi	35	f	f	2025-10-26 17:28:58.981278
973	2027-08-31	2027	8	31	3	AoÃ»t	Mardi	35	f	f	2025-10-26 17:28:58.981278
974	2027-09-01	2027	9	1	3	Septembre	Mercredi	35	f	f	2025-10-26 17:28:58.981278
975	2027-09-02	2027	9	2	3	Septembre	Jeudi	35	f	f	2025-10-26 17:28:58.981278
976	2027-09-03	2027	9	3	3	Septembre	Vendredi	35	f	f	2025-10-26 17:28:58.981278
977	2027-09-04	2027	9	4	3	Septembre	Samedi	35	t	f	2025-10-26 17:28:58.981278
978	2027-09-05	2027	9	5	3	Septembre	Dimanche	35	t	f	2025-10-26 17:28:58.981278
979	2027-09-06	2027	9	6	3	Septembre	Lundi	36	f	f	2025-10-26 17:28:58.981278
980	2027-09-07	2027	9	7	3	Septembre	Mardi	36	f	f	2025-10-26 17:28:58.981278
981	2027-09-08	2027	9	8	3	Septembre	Mercredi	36	f	f	2025-10-26 17:28:58.981278
982	2027-09-09	2027	9	9	3	Septembre	Jeudi	36	f	f	2025-10-26 17:28:58.981278
983	2027-09-10	2027	9	10	3	Septembre	Vendredi	36	f	f	2025-10-26 17:28:58.981278
984	2027-09-11	2027	9	11	3	Septembre	Samedi	36	t	f	2025-10-26 17:28:58.981278
985	2027-09-12	2027	9	12	3	Septembre	Dimanche	36	t	f	2025-10-26 17:28:58.981278
986	2027-09-13	2027	9	13	3	Septembre	Lundi	37	f	f	2025-10-26 17:28:58.981278
987	2027-09-14	2027	9	14	3	Septembre	Mardi	37	f	f	2025-10-26 17:28:58.981278
988	2027-09-15	2027	9	15	3	Septembre	Mercredi	37	f	f	2025-10-26 17:28:58.981278
989	2027-09-16	2027	9	16	3	Septembre	Jeudi	37	f	f	2025-10-26 17:28:58.981278
990	2027-09-17	2027	9	17	3	Septembre	Vendredi	37	f	f	2025-10-26 17:28:58.981278
991	2027-09-18	2027	9	18	3	Septembre	Samedi	37	t	f	2025-10-26 17:28:58.981278
992	2027-09-19	2027	9	19	3	Septembre	Dimanche	37	t	f	2025-10-26 17:28:58.981278
993	2027-09-20	2027	9	20	3	Septembre	Lundi	38	f	f	2025-10-26 17:28:58.981278
994	2027-09-21	2027	9	21	3	Septembre	Mardi	38	f	f	2025-10-26 17:28:58.981278
995	2027-09-22	2027	9	22	3	Septembre	Mercredi	38	f	f	2025-10-26 17:28:58.981278
996	2027-09-23	2027	9	23	3	Septembre	Jeudi	38	f	f	2025-10-26 17:28:58.981278
997	2027-09-24	2027	9	24	3	Septembre	Vendredi	38	f	f	2025-10-26 17:28:58.981278
998	2027-09-25	2027	9	25	3	Septembre	Samedi	38	t	f	2025-10-26 17:28:58.981278
999	2027-09-26	2027	9	26	3	Septembre	Dimanche	38	t	f	2025-10-26 17:28:58.981278
1000	2027-09-27	2027	9	27	3	Septembre	Lundi	39	f	f	2025-10-26 17:28:58.981278
1001	2027-09-28	2027	9	28	3	Septembre	Mardi	39	f	f	2025-10-26 17:28:58.981278
1002	2027-09-29	2027	9	29	3	Septembre	Mercredi	39	f	f	2025-10-26 17:28:58.981278
1003	2027-09-30	2027	9	30	3	Septembre	Jeudi	39	f	f	2025-10-26 17:28:58.981278
1004	2027-10-01	2027	10	1	4	Octobre	Vendredi	39	f	f	2025-10-26 17:28:58.981278
1005	2027-10-02	2027	10	2	4	Octobre	Samedi	39	t	f	2025-10-26 17:28:58.981278
1006	2027-10-03	2027	10	3	4	Octobre	Dimanche	39	t	f	2025-10-26 17:28:58.981278
1007	2027-10-04	2027	10	4	4	Octobre	Lundi	40	f	f	2025-10-26 17:28:58.981278
1008	2027-10-05	2027	10	5	4	Octobre	Mardi	40	f	f	2025-10-26 17:28:58.981278
1009	2027-10-06	2027	10	6	4	Octobre	Mercredi	40	f	f	2025-10-26 17:28:58.981278
1010	2027-10-07	2027	10	7	4	Octobre	Jeudi	40	f	f	2025-10-26 17:28:58.981278
1011	2027-10-08	2027	10	8	4	Octobre	Vendredi	40	f	f	2025-10-26 17:28:58.981278
1012	2027-10-09	2027	10	9	4	Octobre	Samedi	40	t	f	2025-10-26 17:28:58.981278
1013	2027-10-10	2027	10	10	4	Octobre	Dimanche	40	t	f	2025-10-26 17:28:58.981278
1014	2027-10-11	2027	10	11	4	Octobre	Lundi	41	f	f	2025-10-26 17:28:58.981278
1015	2027-10-12	2027	10	12	4	Octobre	Mardi	41	f	f	2025-10-26 17:28:58.981278
1016	2027-10-13	2027	10	13	4	Octobre	Mercredi	41	f	f	2025-10-26 17:28:58.981278
1017	2027-10-14	2027	10	14	4	Octobre	Jeudi	41	f	f	2025-10-26 17:28:58.981278
1018	2027-10-15	2027	10	15	4	Octobre	Vendredi	41	f	f	2025-10-26 17:28:58.981278
1019	2027-10-16	2027	10	16	4	Octobre	Samedi	41	t	f	2025-10-26 17:28:58.981278
1020	2027-10-17	2027	10	17	4	Octobre	Dimanche	41	t	f	2025-10-26 17:28:58.981278
1021	2027-10-18	2027	10	18	4	Octobre	Lundi	42	f	f	2025-10-26 17:28:58.981278
1022	2027-10-19	2027	10	19	4	Octobre	Mardi	42	f	f	2025-10-26 17:28:58.981278
1023	2027-10-20	2027	10	20	4	Octobre	Mercredi	42	f	f	2025-10-26 17:28:58.981278
1024	2027-10-21	2027	10	21	4	Octobre	Jeudi	42	f	f	2025-10-26 17:28:58.981278
1025	2027-10-22	2027	10	22	4	Octobre	Vendredi	42	f	f	2025-10-26 17:28:58.981278
1026	2027-10-23	2027	10	23	4	Octobre	Samedi	42	t	f	2025-10-26 17:28:58.981278
1027	2027-10-24	2027	10	24	4	Octobre	Dimanche	42	t	f	2025-10-26 17:28:58.981278
1028	2027-10-25	2027	10	25	4	Octobre	Lundi	43	f	f	2025-10-26 17:28:58.981278
1029	2027-10-26	2027	10	26	4	Octobre	Mardi	43	f	f	2025-10-26 17:28:58.981278
1030	2027-10-27	2027	10	27	4	Octobre	Mercredi	43	f	f	2025-10-26 17:28:58.981278
1031	2027-10-28	2027	10	28	4	Octobre	Jeudi	43	f	f	2025-10-26 17:28:58.981278
1032	2027-10-29	2027	10	29	4	Octobre	Vendredi	43	f	f	2025-10-26 17:28:58.981278
1033	2027-10-30	2027	10	30	4	Octobre	Samedi	43	t	f	2025-10-26 17:28:58.981278
1034	2027-10-31	2027	10	31	4	Octobre	Dimanche	43	t	f	2025-10-26 17:28:58.981278
1035	2027-11-01	2027	11	1	4	Novembre	Lundi	44	f	f	2025-10-26 17:28:58.981278
1036	2027-11-02	2027	11	2	4	Novembre	Mardi	44	f	f	2025-10-26 17:28:58.981278
1037	2027-11-03	2027	11	3	4	Novembre	Mercredi	44	f	f	2025-10-26 17:28:58.981278
1038	2027-11-04	2027	11	4	4	Novembre	Jeudi	44	f	f	2025-10-26 17:28:58.981278
1039	2027-11-05	2027	11	5	4	Novembre	Vendredi	44	f	f	2025-10-26 17:28:58.981278
1040	2027-11-06	2027	11	6	4	Novembre	Samedi	44	t	f	2025-10-26 17:28:58.981278
1041	2027-11-07	2027	11	7	4	Novembre	Dimanche	44	t	f	2025-10-26 17:28:58.981278
1042	2027-11-08	2027	11	8	4	Novembre	Lundi	45	f	f	2025-10-26 17:28:58.981278
1043	2027-11-09	2027	11	9	4	Novembre	Mardi	45	f	f	2025-10-26 17:28:58.981278
1044	2027-11-10	2027	11	10	4	Novembre	Mercredi	45	f	f	2025-10-26 17:28:58.981278
1045	2027-11-11	2027	11	11	4	Novembre	Jeudi	45	f	f	2025-10-26 17:28:58.981278
1046	2027-11-12	2027	11	12	4	Novembre	Vendredi	45	f	f	2025-10-26 17:28:58.981278
1047	2027-11-13	2027	11	13	4	Novembre	Samedi	45	t	f	2025-10-26 17:28:58.981278
1048	2027-11-14	2027	11	14	4	Novembre	Dimanche	45	t	f	2025-10-26 17:28:58.981278
1049	2027-11-15	2027	11	15	4	Novembre	Lundi	46	f	f	2025-10-26 17:28:58.981278
1050	2027-11-16	2027	11	16	4	Novembre	Mardi	46	f	f	2025-10-26 17:28:58.981278
1051	2027-11-17	2027	11	17	4	Novembre	Mercredi	46	f	f	2025-10-26 17:28:58.981278
1052	2027-11-18	2027	11	18	4	Novembre	Jeudi	46	f	f	2025-10-26 17:28:58.981278
1053	2027-11-19	2027	11	19	4	Novembre	Vendredi	46	f	f	2025-10-26 17:28:58.981278
1054	2027-11-20	2027	11	20	4	Novembre	Samedi	46	t	f	2025-10-26 17:28:58.981278
1055	2027-11-21	2027	11	21	4	Novembre	Dimanche	46	t	f	2025-10-26 17:28:58.981278
1056	2027-11-22	2027	11	22	4	Novembre	Lundi	47	f	f	2025-10-26 17:28:58.981278
1057	2027-11-23	2027	11	23	4	Novembre	Mardi	47	f	f	2025-10-26 17:28:58.981278
1058	2027-11-24	2027	11	24	4	Novembre	Mercredi	47	f	f	2025-10-26 17:28:58.981278
1059	2027-11-25	2027	11	25	4	Novembre	Jeudi	47	f	f	2025-10-26 17:28:58.981278
1060	2027-11-26	2027	11	26	4	Novembre	Vendredi	47	f	f	2025-10-26 17:28:58.981278
1061	2027-11-27	2027	11	27	4	Novembre	Samedi	47	t	f	2025-10-26 17:28:58.981278
1062	2027-11-28	2027	11	28	4	Novembre	Dimanche	47	t	f	2025-10-26 17:28:58.981278
1063	2027-11-29	2027	11	29	4	Novembre	Lundi	48	f	f	2025-10-26 17:28:58.981278
1064	2027-11-30	2027	11	30	4	Novembre	Mardi	48	f	f	2025-10-26 17:28:58.981278
1065	2027-12-01	2027	12	1	4	DÃ©cembre	Mercredi	48	f	f	2025-10-26 17:28:58.981278
1066	2027-12-02	2027	12	2	4	DÃ©cembre	Jeudi	48	f	f	2025-10-26 17:28:58.981278
1067	2027-12-03	2027	12	3	4	DÃ©cembre	Vendredi	48	f	f	2025-10-26 17:28:58.981278
1068	2027-12-04	2027	12	4	4	DÃ©cembre	Samedi	48	t	f	2025-10-26 17:28:58.981278
1069	2027-12-05	2027	12	5	4	DÃ©cembre	Dimanche	48	t	f	2025-10-26 17:28:58.981278
1070	2027-12-06	2027	12	6	4	DÃ©cembre	Lundi	49	f	f	2025-10-26 17:28:58.981278
1071	2027-12-07	2027	12	7	4	DÃ©cembre	Mardi	49	f	f	2025-10-26 17:28:58.981278
1072	2027-12-08	2027	12	8	4	DÃ©cembre	Mercredi	49	f	f	2025-10-26 17:28:58.981278
1073	2027-12-09	2027	12	9	4	DÃ©cembre	Jeudi	49	f	f	2025-10-26 17:28:58.981278
1074	2027-12-10	2027	12	10	4	DÃ©cembre	Vendredi	49	f	f	2025-10-26 17:28:58.981278
1075	2027-12-11	2027	12	11	4	DÃ©cembre	Samedi	49	t	f	2025-10-26 17:28:58.981278
1076	2027-12-12	2027	12	12	4	DÃ©cembre	Dimanche	49	t	f	2025-10-26 17:28:58.981278
1077	2027-12-13	2027	12	13	4	DÃ©cembre	Lundi	50	f	f	2025-10-26 17:28:58.981278
1078	2027-12-14	2027	12	14	4	DÃ©cembre	Mardi	50	f	f	2025-10-26 17:28:58.981278
1079	2027-12-15	2027	12	15	4	DÃ©cembre	Mercredi	50	f	f	2025-10-26 17:28:58.981278
1080	2027-12-16	2027	12	16	4	DÃ©cembre	Jeudi	50	f	f	2025-10-26 17:28:58.981278
1081	2027-12-17	2027	12	17	4	DÃ©cembre	Vendredi	50	f	f	2025-10-26 17:28:58.981278
1082	2027-12-18	2027	12	18	4	DÃ©cembre	Samedi	50	t	f	2025-10-26 17:28:58.981278
1083	2027-12-19	2027	12	19	4	DÃ©cembre	Dimanche	50	t	f	2025-10-26 17:28:58.981278
1084	2027-12-20	2027	12	20	4	DÃ©cembre	Lundi	51	f	f	2025-10-26 17:28:58.981278
1085	2027-12-21	2027	12	21	4	DÃ©cembre	Mardi	51	f	f	2025-10-26 17:28:58.981278
1086	2027-12-22	2027	12	22	4	DÃ©cembre	Mercredi	51	f	f	2025-10-26 17:28:58.981278
1087	2027-12-23	2027	12	23	4	DÃ©cembre	Jeudi	51	f	f	2025-10-26 17:28:58.981278
1088	2027-12-24	2027	12	24	4	DÃ©cembre	Vendredi	51	f	f	2025-10-26 17:28:58.981278
1089	2027-12-25	2027	12	25	4	DÃ©cembre	Samedi	51	t	f	2025-10-26 17:28:58.981278
1090	2027-12-26	2027	12	26	4	DÃ©cembre	Dimanche	51	t	f	2025-10-26 17:28:58.981278
1091	2027-12-27	2027	12	27	4	DÃ©cembre	Lundi	52	f	f	2025-10-26 17:28:58.981278
1092	2027-12-28	2027	12	28	4	DÃ©cembre	Mardi	52	f	f	2025-10-26 17:28:58.981278
1093	2027-12-29	2027	12	29	4	DÃ©cembre	Mercredi	52	f	f	2025-10-26 17:28:58.981278
1094	2027-12-30	2027	12	30	4	DÃ©cembre	Jeudi	52	f	f	2025-10-26 17:28:58.981278
1095	2027-12-31	2027	12	31	4	DÃ©cembre	Vendredi	52	f	f	2025-10-26 17:28:58.981278
\.


--
-- Data for Name: dim_zones_industrielles; Type: TABLE DATA; Schema: dwh; Owner: postgres
--

COPY dwh.dim_zones_industrielles (zone_key, zone_id, nom_zone, localisation, superficie_totale, nb_lots_total, statut_zone, date_creation_zone, description_zone, coordonnees_gps, gestionnaire, date_creation, date_modification) FROM stdin;
\.


--
-- Data for Name: logs_etl; Type: TABLE DATA; Schema: etl; Owner: postgres
--

COPY etl.logs_etl (id, process_name, start_time, end_time, status, rows_processed, error_message) FROM stdin;
\.


--
-- Data for Name: dwh_status; Type: TABLE DATA; Schema: monitoring; Owner: postgres
--

COPY monitoring.dwh_status (id, nom_table, derniere_maj, nb_lignes, statut, commentaires) FROM stdin;
1	dwh.dim_zones_industrielles	2025-10-26 17:28:59.989352	0	ACTIF	\N
\.


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

SELECT pg_catalog.setval('dwh.dim_statuts_statut_key_seq', 10, true);


--
-- Name: dim_temps_temps_key_seq; Type: SEQUENCE SET; Schema: dwh; Owner: postgres
--

SELECT pg_catalog.setval('dwh.dim_temps_temps_key_seq', 2190, true);


--
-- Name: dim_zones_industrielles_zone_key_seq; Type: SEQUENCE SET; Schema: dwh; Owner: postgres
--

SELECT pg_catalog.setval('dwh.dim_zones_industrielles_zone_key_seq', 1, false);


--
-- Name: logs_etl_id_seq; Type: SEQUENCE SET; Schema: etl; Owner: postgres
--

SELECT pg_catalog.setval('etl.logs_etl_id_seq', 1, false);


--
-- Name: dwh_status_id_seq; Type: SEQUENCE SET; Schema: monitoring; Owner: postgres
--

SELECT pg_catalog.setval('monitoring.dwh_status_id_seq', 1, true);


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
-- Name: dim_statuts dim_statuts_nom_statut_key; Type: CONSTRAINT; Schema: dwh; Owner: postgres
--

ALTER TABLE ONLY dwh.dim_statuts
    ADD CONSTRAINT dim_statuts_nom_statut_key UNIQUE (nom_statut);


--
-- Name: dim_statuts dim_statuts_pkey; Type: CONSTRAINT; Schema: dwh; Owner: postgres
--

ALTER TABLE ONLY dwh.dim_statuts
    ADD CONSTRAINT dim_statuts_pkey PRIMARY KEY (statut_key);


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
-- Name: logs_etl logs_etl_pkey; Type: CONSTRAINT; Schema: etl; Owner: postgres
--

ALTER TABLE ONLY etl.logs_etl
    ADD CONSTRAINT logs_etl_pkey PRIMARY KEY (id);


--
-- Name: dwh_status dwh_status_pkey; Type: CONSTRAINT; Schema: monitoring; Owner: postgres
--

ALTER TABLE ONLY monitoring.dwh_status
    ADD CONSTRAINT dwh_status_pkey PRIMARY KEY (id);


--
-- Name: dim_lots dim_lots_zone_key_fkey; Type: FK CONSTRAINT; Schema: dwh; Owner: postgres
--

ALTER TABLE ONLY dwh.dim_lots
    ADD CONSTRAINT dim_lots_zone_key_fkey FOREIGN KEY (zone_key) REFERENCES dwh.dim_zones_industrielles(zone_key);


--
-- PostgreSQL database dump complete
--

