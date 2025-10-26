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
-- Name: v_dashboard_principal; Type: VIEW; Schema: dwh; Owner: postgres
--

CREATE VIEW dwh.v_dashboard_principal AS
 SELECT 'Zones industrielles'::text AS indicateur,
    (count(DISTINCT dzi.zone_id))::text AS valeur,
    'zones'::text AS unite
   FROM dwh.dim_zones_industrielles dzi
  WHERE ((dzi.statut_zone)::text = 'actif'::text)
UNION ALL
 SELECT 'Entreprises enregistrÃ©es'::text AS indicateur,
    (count(*))::text AS valeur,
    'entreprises'::text AS unite
   FROM dwh.dim_entreprises de
UNION ALL
 SELECT 'Lots disponibles'::text AS indicateur,
    (count(*))::text AS valeur,
    'lots'::text AS unite
   FROM dwh.dim_lots dl
  WHERE ((dl.statut_lot)::text = 'DISPONIBLE'::text)
UNION ALL
 SELECT 'Demandes en cours'::text AS indicateur,
    (count(*))::text AS valeur,
    'demandes'::text AS unite
   FROM (dwh.fait_demandes_attribution fda
     JOIN dwh.dim_statuts ds ON ((fda.statut_key = ds.statut_key)))
  WHERE ((ds.nom_statut)::text = 'EN_ATTENTE'::text)
UNION ALL
 SELECT 'Taux occupation moyen'::text AS indicateur,
    (round(avg(
        CASE
            WHEN ((dl.statut_lot)::text = 'OCCUPE'::text) THEN 100.0
            ELSE 0.0
        END), 1))::text AS valeur,
    '%'::text AS unite
   FROM dwh.dim_lots dl
UNION ALL
 SELECT 'Revenus totaux'::text AS indicateur,
    COALESCE((sum(fda.montant_demande))::text, '0'::text) AS valeur,
    'FCFA'::text AS unite
   FROM (dwh.fait_demandes_attribution fda
     JOIN dwh.dim_statuts ds ON ((fda.statut_key = ds.statut_key)))
  WHERE ((ds.nom_statut)::text = 'APPROUVEE'::text);


ALTER TABLE dwh.v_dashboard_principal OWNER TO postgres;

--
-- Name: v_delais_traitement_demandes; Type: VIEW; Schema: dwh; Owner: postgres
--

CREATE VIEW dwh.v_delais_traitement_demandes AS
 SELECT ds.nom_statut,
    count(*) AS nb_demandes,
    avg(fda.duree_traitement_jours) AS delai_moyen_jours,
    min(fda.duree_traitement_jours) AS delai_min_jours,
    max(fda.duree_traitement_jours) AS delai_max_jours
   FROM (dwh.fait_demandes_attribution fda
     JOIN dwh.dim_statuts ds ON ((fda.statut_key = ds.statut_key)))
  WHERE (fda.date_traitement IS NOT NULL)
  GROUP BY ds.nom_statut, ds.statut_key
  ORDER BY (avg(fda.duree_traitement_jours));


ALTER TABLE dwh.v_delais_traitement_demandes OWNER TO postgres;

--
-- Name: v_demandes_par_entreprise; Type: VIEW; Schema: dwh; Owner: postgres
--

CREATE VIEW dwh.v_demandes_par_entreprise AS
 SELECT de.nom_entreprise,
    de.entreprise_id,
    de.secteur_activite,
    count(*) AS nb_demandes,
    sum(fda.montant_demande) AS montant_total_demandes,
    avg(fda.montant_demande) AS montant_moyen_demande
   FROM (dwh.fait_demandes_attribution fda
     JOIN dwh.dim_entreprises de ON ((fda.entreprise_key = de.entreprise_key)))
  GROUP BY de.entreprise_id, de.nom_entreprise, de.secteur_activite
  ORDER BY (count(*)) DESC;


ALTER TABLE dwh.v_demandes_par_entreprise OWNER TO postgres;

--
-- Name: v_demandes_par_statut; Type: VIEW; Schema: dwh; Owner: postgres
--

CREATE VIEW dwh.v_demandes_par_statut AS
 SELECT ds.nom_statut,
    count(*) AS nb_demandes,
    round((((count(*))::numeric * 100.0) / sum(count(*)) OVER ()), 2) AS pourcentage
   FROM (dwh.fait_demandes_attribution fda
     JOIN dwh.dim_statuts ds ON ((fda.statut_key = ds.statut_key)))
  GROUP BY ds.nom_statut, ds.statut_key
  ORDER BY (count(*)) DESC;


ALTER TABLE dwh.v_demandes_par_statut OWNER TO postgres;

--
-- Name: v_demandes_par_zone; Type: VIEW; Schema: dwh; Owner: postgres
--

CREATE VIEW dwh.v_demandes_par_zone AS
 SELECT dzi.nom_zone,
    dzi.zone_id,
    count(*) AS nb_demandes,
    sum(fda.montant_demande) AS montant_total_demandes
   FROM ((dwh.fait_demandes_attribution fda
     JOIN dwh.dim_lots dl ON ((fda.lot_key = dl.lot_key)))
     JOIN dwh.dim_zones_industrielles dzi ON ((dl.zone_key = dzi.zone_key)))
  GROUP BY dzi.zone_id, dzi.nom_zone
  ORDER BY (count(*)) DESC;


ALTER TABLE dwh.v_demandes_par_zone OWNER TO postgres;

--
-- Name: v_entreprises_par_secteur; Type: VIEW; Schema: dwh; Owner: postgres
--

CREATE VIEW dwh.v_entreprises_par_secteur AS
 SELECT de.secteur_activite,
    count(*) AS nb_entreprises,
    round((((count(*))::numeric * 100.0) / sum(count(*)) OVER ()), 2) AS pourcentage
   FROM dwh.dim_entreprises de
  GROUP BY de.secteur_activite
  ORDER BY (count(*)) DESC;


ALTER TABLE dwh.v_entreprises_par_secteur OWNER TO postgres;

--
-- Name: v_evolution_demandes; Type: VIEW; Schema: dwh; Owner: postgres
--

CREATE VIEW dwh.v_evolution_demandes AS
 SELECT dt.annee,
    dt.mois,
    dt.nom_mois,
    count(*) AS nb_demandes,
    sum(fda.montant_demande) AS montant_total,
    avg(fda.montant_demande) AS montant_moyen
   FROM (dwh.fait_demandes_attribution fda
     JOIN dwh.dim_temps dt ON ((fda.temps_key = dt.temps_key)))
  GROUP BY dt.annee, dt.mois, dt.nom_mois
  ORDER BY dt.annee DESC, dt.mois DESC;


ALTER TABLE dwh.v_evolution_demandes OWNER TO postgres;

--
-- Name: v_evolution_entreprises; Type: VIEW; Schema: dwh; Owner: postgres
--

CREATE VIEW dwh.v_evolution_entreprises AS
 SELECT date_part('year'::text, de.date_creation) AS annee_creation,
    count(*) AS nb_entreprises_creees,
    de.secteur_activite,
    sum(count(*)) OVER (ORDER BY (date_part('year'::text, de.date_creation))) AS cumul_entreprises
   FROM dwh.dim_entreprises de
  WHERE (de.date_creation IS NOT NULL)
  GROUP BY (date_part('year'::text, de.date_creation)), de.secteur_activite
  ORDER BY (date_part('year'::text, de.date_creation)) DESC;


ALTER TABLE dwh.v_evolution_entreprises OWNER TO postgres;

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
-- Name: v_revenus_par_entreprise; Type: VIEW; Schema: dwh; Owner: postgres
--

CREATE VIEW dwh.v_revenus_par_entreprise AS
 SELECT de.nom_entreprise,
    de.secteur_activite,
    count(*) AS nb_transactions,
    sum(fda.montant_demande) AS revenus_total,
    avg(fda.montant_demande) AS revenu_moyen_transaction
   FROM ((dwh.fait_demandes_attribution fda
     JOIN dwh.dim_entreprises de ON ((fda.entreprise_key = de.entreprise_key)))
     JOIN dwh.dim_statuts ds ON ((fda.statut_key = ds.statut_key)))
  WHERE ((ds.nom_statut)::text = 'APPROUVEE'::text)
  GROUP BY de.entreprise_id, de.nom_entreprise, de.secteur_activite
  ORDER BY (sum(fda.montant_demande)) DESC;


ALTER TABLE dwh.v_revenus_par_entreprise OWNER TO postgres;

--
-- Name: v_revenus_par_periode; Type: VIEW; Schema: dwh; Owner: postgres
--

CREATE VIEW dwh.v_revenus_par_periode AS
 SELECT dt.annee,
    dt.mois,
    dt.nom_mois,
    dzi.nom_zone,
    count(*) AS nb_paiements,
    sum(fda.montant_demande) AS revenus_total,
    avg(fda.montant_demande) AS revenu_moyen
   FROM ((((dwh.fait_demandes_attribution fda
     JOIN dwh.dim_temps dt ON ((fda.temps_key = dt.temps_key)))
     JOIN dwh.dim_lots dl ON ((fda.lot_key = dl.lot_key)))
     JOIN dwh.dim_zones_industrielles dzi ON ((dl.zone_key = dzi.zone_key)))
     JOIN dwh.dim_statuts ds ON ((fda.statut_key = ds.statut_key)))
  WHERE ((ds.nom_statut)::text = 'APPROUVEE'::text)
  GROUP BY dt.annee, dt.mois, dt.nom_mois, dzi.nom_zone, dzi.zone_id
  ORDER BY dt.annee DESC, dt.mois DESC, (sum(fda.montant_demande)) DESC;


ALTER TABLE dwh.v_revenus_par_periode OWNER TO postgres;

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
-- Name: v_synthese_geographique; Type: VIEW; Schema: dwh; Owner: postgres
--

CREATE VIEW dwh.v_synthese_geographique AS
 SELECT dzi.nom_zone,
    dzi.zone_id,
    dzi.superficie_totale,
    dzi.nb_lots_total,
    dzi.statut_zone,
    count(dl.lot_id) AS lots_references,
    count(fda.demande_key) AS nb_demandes,
    COALESCE(sum(dl.superficie), (0)::numeric) AS superficie_lots_totale,
    round((COALESCE(dzi.superficie_totale, (0)::numeric) / (NULLIF(dzi.nb_lots_total, 0))::numeric), 2) AS superficie_moyenne_lot
   FROM ((dwh.dim_zones_industrielles dzi
     LEFT JOIN dwh.dim_lots dl ON ((dzi.zone_key = dl.zone_key)))
     LEFT JOIN dwh.fait_demandes_attribution fda ON ((dl.lot_key = fda.lot_key)))
  GROUP BY dzi.zone_id, dzi.nom_zone, dzi.superficie_totale, dzi.nb_lots_total, dzi.statut_zone
  ORDER BY dzi.superficie_totale DESC;


ALTER TABLE dwh.v_synthese_geographique OWNER TO postgres;

--
-- Name: v_taux_acceptation_demandes; Type: VIEW; Schema: dwh; Owner: postgres
--

CREATE VIEW dwh.v_taux_acceptation_demandes AS
 SELECT count(*) AS total_demandes,
    count(
        CASE
            WHEN ((ds.nom_statut)::text = 'APPROUVEE'::text) THEN 1
            ELSE NULL::integer
        END) AS demandes_approuvees,
    count(
        CASE
            WHEN ((ds.nom_statut)::text = 'REJETEE'::text) THEN 1
            ELSE NULL::integer
        END) AS demandes_rejetees,
    round((((count(
        CASE
            WHEN ((ds.nom_statut)::text = 'APPROUVEE'::text) THEN 1
            ELSE NULL::integer
        END))::numeric * 100.0) / (count(*))::numeric), 2) AS taux_acceptation_pct,
    round((((count(
        CASE
            WHEN ((ds.nom_statut)::text = 'REJETEE'::text) THEN 1
            ELSE NULL::integer
        END))::numeric * 100.0) / (count(*))::numeric), 2) AS taux_rejet_pct
   FROM (dwh.fait_demandes_attribution fda
     JOIN dwh.dim_statuts ds ON ((fda.statut_key = ds.statut_key)));


ALTER TABLE dwh.v_taux_acceptation_demandes OWNER TO postgres;

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
-- Name: v_tendances_mensuelles; Type: VIEW; Schema: dwh; Owner: postgres
--

CREATE VIEW dwh.v_tendances_mensuelles AS
 SELECT dt.annee,
    dt.mois,
    dt.nom_mois,
    count(fda.demande_key) AS nb_demandes_mois,
    sum(fda.montant_demande) AS montant_total_mois,
    avg(fda.duree_traitement_jours) AS delai_moyen_traitement,
    count(
        CASE
            WHEN ((ds.nom_statut)::text = 'APPROUVEE'::text) THEN 1
            ELSE NULL::integer
        END) AS demandes_approuvees,
    lag(count(fda.demande_key)) OVER (ORDER BY dt.annee, dt.mois) AS nb_demandes_mois_precedent,
    round(((((count(fda.demande_key) - lag(count(fda.demande_key)) OVER (ORDER BY dt.annee, dt.mois)))::numeric * 100.0) / (NULLIF(lag(count(fda.demande_key)) OVER (ORDER BY dt.annee, dt.mois), 0))::numeric), 2) AS evolution_pct
   FROM ((dwh.fait_demandes_attribution fda
     JOIN dwh.dim_temps dt ON ((fda.temps_key = dt.temps_key)))
     JOIN dwh.dim_statuts ds ON ((fda.statut_key = ds.statut_key)))
  GROUP BY dt.annee, dt.mois, dt.nom_mois
  ORDER BY dt.annee DESC, dt.mois DESC;


ALTER TABLE dwh.v_tendances_mensuelles OWNER TO postgres;

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
-- Name: logs_etl id; Type: DEFAULT; Schema: etl; Owner: postgres
--

ALTER TABLE ONLY etl.logs_etl ALTER COLUMN id SET DEFAULT nextval('etl.logs_etl_id_seq'::regclass);


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
1	zones_industrielles	dwh.dim_zones_industrielles	\N	INCREMENTAL	t	2025-10-26 14:01:42.10782
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
1	1	SIVOICO	SA	Non spÃ©cifiÃ©	\N	\N	\N	\N	\N	\N	2025-10-03 00:00:00	2025-10-26 14:01:41.814649
2	2	TROPICA INDUS	SA	Non spÃ©cifiÃ©	\N	\N	\N	\N	\N	\N	2025-10-03 00:00:00	2025-10-26 14:01:41.814649
3	3	PHYTOTOP	SARL	Non spÃ©cifiÃ©	\N	\N	\N	\N	\N	\N	2025-10-03 00:00:00	2025-10-26 14:01:41.814649
4	4	DK INDUSTRIE	SARL	Non spÃ©cifiÃ©	\N	\N	\N	\N	\N	\N	2025-10-03 00:00:00	2025-10-26 14:01:41.814649
5	5	SAPCI	SA	Non spÃ©cifiÃ©	\N	\N	\N	\N	\N	\N	2025-10-03 00:00:00	2025-10-26 14:01:41.814649
6	6	BBB COMPANY	SAS	Non spÃ©cifiÃ©	\N	\N	\N	\N	\N	\N	2025-10-03 00:00:00	2025-10-26 14:01:41.814649
7	7	SERAQ	SA	Non spÃ©cifiÃ©	\N	\N	\N	\N	\N	\N	2025-10-03 00:00:00	2025-10-26 14:01:41.814649
8	8	ALUVOTEK	SA	Non spÃ©cifiÃ©	\N	\N	\N	\N	\N	\N	2025-10-03 00:00:00	2025-10-26 14:01:41.814649
9	9	KAFMAH	SARL	Non spÃ©cifiÃ©	\N	\N	\N	\N	\N	\N	2025-10-03 00:00:00	2025-10-26 14:01:41.814649
10	11	SARCI	SA	Non spÃ©cifiÃ©	\N	\N	\N	\N	\N	\N	2025-10-03 00:00:00	2025-10-26 14:01:41.814649
11	12	YVRYDRILING	SAS	Non spÃ©cifiÃ©	\N	\N	\N	\N	\N	\N	2025-10-03 00:00:00	2025-10-26 14:01:41.814649
12	13	SCE CHIMICAL	SARL	Non spÃ©cifiÃ©	\N	\N	\N	\N	\N	\N	2025-10-03 00:00:00	2025-10-26 14:01:41.814649
13	14	NestlÃ© CI SA	SA	Non spÃ©cifiÃ©	\N	\N	\N	\N	\N	\N	2025-10-03 00:00:00	2025-10-26 14:01:41.814649
14	15	Coca-Cola	SA	Non spÃ©cifiÃ©	\N	\N	\N	\N	\N	\N	2025-10-03 00:00:00	2025-10-26 14:01:41.814649
15	16	Unilever CI	SA	Non spÃ©cifiÃ©	\N	\N	\N	\N	\N	\N	2025-10-03 00:00:00	2025-10-26 14:01:41.814649
16	17	 TotalEnergies CI 	SA	Non spÃ©cifiÃ©	\N	\N	\N	\N	\N	\N	2025-10-03 00:00:00	2025-10-26 14:01:41.814649
17	18	Heineken Africa CI	SARL	Non spÃ©cifiÃ©	\N	\N	\N	\N	\N	\N	2025-10-03 00:00:00	2025-10-26 14:01:41.814649
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
1	2025-10-26	2025	1	1	\N	\N	\N	\N	f	f	2025-10-26 14:01:41.298491
2	2025-01-01	2025	1	1	1	Janvier	Mercredi	1	f	f	2025-10-26 17:20:46.965256
3	2025-01-02	2025	1	2	1	Janvier	Jeudi	1	f	f	2025-10-26 17:20:46.965256
4	2025-01-03	2025	1	3	1	Janvier	Vendredi	1	f	f	2025-10-26 17:20:46.965256
5	2025-01-04	2025	1	4	1	Janvier	Samedi	1	t	f	2025-10-26 17:20:46.965256
6	2025-01-05	2025	1	5	1	Janvier	Dimanche	1	t	f	2025-10-26 17:20:46.965256
7	2025-01-06	2025	1	6	1	Janvier	Lundi	2	f	f	2025-10-26 17:20:46.965256
8	2025-01-07	2025	1	7	1	Janvier	Mardi	2	f	f	2025-10-26 17:20:46.965256
9	2025-01-08	2025	1	8	1	Janvier	Mercredi	2	f	f	2025-10-26 17:20:46.965256
10	2025-01-09	2025	1	9	1	Janvier	Jeudi	2	f	f	2025-10-26 17:20:46.965256
11	2025-01-10	2025	1	10	1	Janvier	Vendredi	2	f	f	2025-10-26 17:20:46.965256
12	2025-01-11	2025	1	11	1	Janvier	Samedi	2	t	f	2025-10-26 17:20:46.965256
13	2025-01-12	2025	1	12	1	Janvier	Dimanche	2	t	f	2025-10-26 17:20:46.965256
14	2025-01-13	2025	1	13	1	Janvier	Lundi	3	f	f	2025-10-26 17:20:46.965256
15	2025-01-14	2025	1	14	1	Janvier	Mardi	3	f	f	2025-10-26 17:20:46.965256
16	2025-01-15	2025	1	15	1	Janvier	Mercredi	3	f	f	2025-10-26 17:20:46.965256
17	2025-01-16	2025	1	16	1	Janvier	Jeudi	3	f	f	2025-10-26 17:20:46.965256
18	2025-01-17	2025	1	17	1	Janvier	Vendredi	3	f	f	2025-10-26 17:20:46.965256
19	2025-01-18	2025	1	18	1	Janvier	Samedi	3	t	f	2025-10-26 17:20:46.965256
20	2025-01-19	2025	1	19	1	Janvier	Dimanche	3	t	f	2025-10-26 17:20:46.965256
21	2025-01-20	2025	1	20	1	Janvier	Lundi	4	f	f	2025-10-26 17:20:46.965256
22	2025-01-21	2025	1	21	1	Janvier	Mardi	4	f	f	2025-10-26 17:20:46.965256
23	2025-01-22	2025	1	22	1	Janvier	Mercredi	4	f	f	2025-10-26 17:20:46.965256
24	2025-01-23	2025	1	23	1	Janvier	Jeudi	4	f	f	2025-10-26 17:20:46.965256
25	2025-01-24	2025	1	24	1	Janvier	Vendredi	4	f	f	2025-10-26 17:20:46.965256
26	2025-01-25	2025	1	25	1	Janvier	Samedi	4	t	f	2025-10-26 17:20:46.965256
27	2025-01-26	2025	1	26	1	Janvier	Dimanche	4	t	f	2025-10-26 17:20:46.965256
28	2025-01-27	2025	1	27	1	Janvier	Lundi	5	f	f	2025-10-26 17:20:46.965256
29	2025-01-28	2025	1	28	1	Janvier	Mardi	5	f	f	2025-10-26 17:20:46.965256
30	2025-01-29	2025	1	29	1	Janvier	Mercredi	5	f	f	2025-10-26 17:20:46.965256
31	2025-01-30	2025	1	30	1	Janvier	Jeudi	5	f	f	2025-10-26 17:20:46.965256
32	2025-01-31	2025	1	31	1	Janvier	Vendredi	5	f	f	2025-10-26 17:20:46.965256
33	2025-02-01	2025	2	1	1	FÃ©vrier	Samedi	5	t	f	2025-10-26 17:20:46.965256
34	2025-02-02	2025	2	2	1	FÃ©vrier	Dimanche	5	t	f	2025-10-26 17:20:46.965256
35	2025-02-03	2025	2	3	1	FÃ©vrier	Lundi	6	f	f	2025-10-26 17:20:46.965256
36	2025-02-04	2025	2	4	1	FÃ©vrier	Mardi	6	f	f	2025-10-26 17:20:46.965256
37	2025-02-05	2025	2	5	1	FÃ©vrier	Mercredi	6	f	f	2025-10-26 17:20:46.965256
38	2025-02-06	2025	2	6	1	FÃ©vrier	Jeudi	6	f	f	2025-10-26 17:20:46.965256
39	2025-02-07	2025	2	7	1	FÃ©vrier	Vendredi	6	f	f	2025-10-26 17:20:46.965256
40	2025-02-08	2025	2	8	1	FÃ©vrier	Samedi	6	t	f	2025-10-26 17:20:46.965256
41	2025-02-09	2025	2	9	1	FÃ©vrier	Dimanche	6	t	f	2025-10-26 17:20:46.965256
42	2025-02-10	2025	2	10	1	FÃ©vrier	Lundi	7	f	f	2025-10-26 17:20:46.965256
43	2025-02-11	2025	2	11	1	FÃ©vrier	Mardi	7	f	f	2025-10-26 17:20:46.965256
44	2025-02-12	2025	2	12	1	FÃ©vrier	Mercredi	7	f	f	2025-10-26 17:20:46.965256
45	2025-02-13	2025	2	13	1	FÃ©vrier	Jeudi	7	f	f	2025-10-26 17:20:46.965256
46	2025-02-14	2025	2	14	1	FÃ©vrier	Vendredi	7	f	f	2025-10-26 17:20:46.965256
47	2025-02-15	2025	2	15	1	FÃ©vrier	Samedi	7	t	f	2025-10-26 17:20:46.965256
48	2025-02-16	2025	2	16	1	FÃ©vrier	Dimanche	7	t	f	2025-10-26 17:20:46.965256
49	2025-02-17	2025	2	17	1	FÃ©vrier	Lundi	8	f	f	2025-10-26 17:20:46.965256
50	2025-02-18	2025	2	18	1	FÃ©vrier	Mardi	8	f	f	2025-10-26 17:20:46.965256
51	2025-02-19	2025	2	19	1	FÃ©vrier	Mercredi	8	f	f	2025-10-26 17:20:46.965256
52	2025-02-20	2025	2	20	1	FÃ©vrier	Jeudi	8	f	f	2025-10-26 17:20:46.965256
53	2025-02-21	2025	2	21	1	FÃ©vrier	Vendredi	8	f	f	2025-10-26 17:20:46.965256
54	2025-02-22	2025	2	22	1	FÃ©vrier	Samedi	8	t	f	2025-10-26 17:20:46.965256
55	2025-02-23	2025	2	23	1	FÃ©vrier	Dimanche	8	t	f	2025-10-26 17:20:46.965256
56	2025-02-24	2025	2	24	1	FÃ©vrier	Lundi	9	f	f	2025-10-26 17:20:46.965256
57	2025-02-25	2025	2	25	1	FÃ©vrier	Mardi	9	f	f	2025-10-26 17:20:46.965256
58	2025-02-26	2025	2	26	1	FÃ©vrier	Mercredi	9	f	f	2025-10-26 17:20:46.965256
59	2025-02-27	2025	2	27	1	FÃ©vrier	Jeudi	9	f	f	2025-10-26 17:20:46.965256
60	2025-02-28	2025	2	28	1	FÃ©vrier	Vendredi	9	f	f	2025-10-26 17:20:46.965256
61	2025-03-01	2025	3	1	1	Mars	Samedi	9	t	f	2025-10-26 17:20:46.965256
62	2025-03-02	2025	3	2	1	Mars	Dimanche	9	t	f	2025-10-26 17:20:46.965256
63	2025-03-03	2025	3	3	1	Mars	Lundi	10	f	f	2025-10-26 17:20:46.965256
64	2025-03-04	2025	3	4	1	Mars	Mardi	10	f	f	2025-10-26 17:20:46.965256
65	2025-03-05	2025	3	5	1	Mars	Mercredi	10	f	f	2025-10-26 17:20:46.965256
66	2025-03-06	2025	3	6	1	Mars	Jeudi	10	f	f	2025-10-26 17:20:46.965256
67	2025-03-07	2025	3	7	1	Mars	Vendredi	10	f	f	2025-10-26 17:20:46.965256
68	2025-03-08	2025	3	8	1	Mars	Samedi	10	t	f	2025-10-26 17:20:46.965256
69	2025-03-09	2025	3	9	1	Mars	Dimanche	10	t	f	2025-10-26 17:20:46.965256
70	2025-03-10	2025	3	10	1	Mars	Lundi	11	f	f	2025-10-26 17:20:46.965256
71	2025-03-11	2025	3	11	1	Mars	Mardi	11	f	f	2025-10-26 17:20:46.965256
72	2025-03-12	2025	3	12	1	Mars	Mercredi	11	f	f	2025-10-26 17:20:46.965256
73	2025-03-13	2025	3	13	1	Mars	Jeudi	11	f	f	2025-10-26 17:20:46.965256
74	2025-03-14	2025	3	14	1	Mars	Vendredi	11	f	f	2025-10-26 17:20:46.965256
75	2025-03-15	2025	3	15	1	Mars	Samedi	11	t	f	2025-10-26 17:20:46.965256
76	2025-03-16	2025	3	16	1	Mars	Dimanche	11	t	f	2025-10-26 17:20:46.965256
77	2025-03-17	2025	3	17	1	Mars	Lundi	12	f	f	2025-10-26 17:20:46.965256
78	2025-03-18	2025	3	18	1	Mars	Mardi	12	f	f	2025-10-26 17:20:46.965256
79	2025-03-19	2025	3	19	1	Mars	Mercredi	12	f	f	2025-10-26 17:20:46.965256
80	2025-03-20	2025	3	20	1	Mars	Jeudi	12	f	f	2025-10-26 17:20:46.965256
81	2025-03-21	2025	3	21	1	Mars	Vendredi	12	f	f	2025-10-26 17:20:46.965256
82	2025-03-22	2025	3	22	1	Mars	Samedi	12	t	f	2025-10-26 17:20:46.965256
83	2025-03-23	2025	3	23	1	Mars	Dimanche	12	t	f	2025-10-26 17:20:46.965256
84	2025-03-24	2025	3	24	1	Mars	Lundi	13	f	f	2025-10-26 17:20:46.965256
85	2025-03-25	2025	3	25	1	Mars	Mardi	13	f	f	2025-10-26 17:20:46.965256
86	2025-03-26	2025	3	26	1	Mars	Mercredi	13	f	f	2025-10-26 17:20:46.965256
87	2025-03-27	2025	3	27	1	Mars	Jeudi	13	f	f	2025-10-26 17:20:46.965256
88	2025-03-28	2025	3	28	1	Mars	Vendredi	13	f	f	2025-10-26 17:20:46.965256
89	2025-03-29	2025	3	29	1	Mars	Samedi	13	t	f	2025-10-26 17:20:46.965256
90	2025-03-30	2025	3	30	1	Mars	Dimanche	13	t	f	2025-10-26 17:20:46.965256
91	2025-03-31	2025	3	31	1	Mars	Lundi	14	f	f	2025-10-26 17:20:46.965256
92	2025-04-01	2025	4	1	2	Avril	Mardi	14	f	f	2025-10-26 17:20:46.965256
93	2025-04-02	2025	4	2	2	Avril	Mercredi	14	f	f	2025-10-26 17:20:46.965256
94	2025-04-03	2025	4	3	2	Avril	Jeudi	14	f	f	2025-10-26 17:20:46.965256
95	2025-04-04	2025	4	4	2	Avril	Vendredi	14	f	f	2025-10-26 17:20:46.965256
96	2025-04-05	2025	4	5	2	Avril	Samedi	14	t	f	2025-10-26 17:20:46.965256
97	2025-04-06	2025	4	6	2	Avril	Dimanche	14	t	f	2025-10-26 17:20:46.965256
98	2025-04-07	2025	4	7	2	Avril	Lundi	15	f	f	2025-10-26 17:20:46.965256
99	2025-04-08	2025	4	8	2	Avril	Mardi	15	f	f	2025-10-26 17:20:46.965256
100	2025-04-09	2025	4	9	2	Avril	Mercredi	15	f	f	2025-10-26 17:20:46.965256
101	2025-04-10	2025	4	10	2	Avril	Jeudi	15	f	f	2025-10-26 17:20:46.965256
102	2025-04-11	2025	4	11	2	Avril	Vendredi	15	f	f	2025-10-26 17:20:46.965256
103	2025-04-12	2025	4	12	2	Avril	Samedi	15	t	f	2025-10-26 17:20:46.965256
104	2025-04-13	2025	4	13	2	Avril	Dimanche	15	t	f	2025-10-26 17:20:46.965256
105	2025-04-14	2025	4	14	2	Avril	Lundi	16	f	f	2025-10-26 17:20:46.965256
106	2025-04-15	2025	4	15	2	Avril	Mardi	16	f	f	2025-10-26 17:20:46.965256
107	2025-04-16	2025	4	16	2	Avril	Mercredi	16	f	f	2025-10-26 17:20:46.965256
108	2025-04-17	2025	4	17	2	Avril	Jeudi	16	f	f	2025-10-26 17:20:46.965256
109	2025-04-18	2025	4	18	2	Avril	Vendredi	16	f	f	2025-10-26 17:20:46.965256
110	2025-04-19	2025	4	19	2	Avril	Samedi	16	t	f	2025-10-26 17:20:46.965256
111	2025-04-20	2025	4	20	2	Avril	Dimanche	16	t	f	2025-10-26 17:20:46.965256
112	2025-04-21	2025	4	21	2	Avril	Lundi	17	f	f	2025-10-26 17:20:46.965256
113	2025-04-22	2025	4	22	2	Avril	Mardi	17	f	f	2025-10-26 17:20:46.965256
114	2025-04-23	2025	4	23	2	Avril	Mercredi	17	f	f	2025-10-26 17:20:46.965256
115	2025-04-24	2025	4	24	2	Avril	Jeudi	17	f	f	2025-10-26 17:20:46.965256
116	2025-04-25	2025	4	25	2	Avril	Vendredi	17	f	f	2025-10-26 17:20:46.965256
117	2025-04-26	2025	4	26	2	Avril	Samedi	17	t	f	2025-10-26 17:20:46.965256
118	2025-04-27	2025	4	27	2	Avril	Dimanche	17	t	f	2025-10-26 17:20:46.965256
119	2025-04-28	2025	4	28	2	Avril	Lundi	18	f	f	2025-10-26 17:20:46.965256
120	2025-04-29	2025	4	29	2	Avril	Mardi	18	f	f	2025-10-26 17:20:46.965256
121	2025-04-30	2025	4	30	2	Avril	Mercredi	18	f	f	2025-10-26 17:20:46.965256
122	2025-05-01	2025	5	1	2	Mai	Jeudi	18	f	f	2025-10-26 17:20:46.965256
123	2025-05-02	2025	5	2	2	Mai	Vendredi	18	f	f	2025-10-26 17:20:46.965256
124	2025-05-03	2025	5	3	2	Mai	Samedi	18	t	f	2025-10-26 17:20:46.965256
125	2025-05-04	2025	5	4	2	Mai	Dimanche	18	t	f	2025-10-26 17:20:46.965256
126	2025-05-05	2025	5	5	2	Mai	Lundi	19	f	f	2025-10-26 17:20:46.965256
127	2025-05-06	2025	5	6	2	Mai	Mardi	19	f	f	2025-10-26 17:20:46.965256
128	2025-05-07	2025	5	7	2	Mai	Mercredi	19	f	f	2025-10-26 17:20:46.965256
129	2025-05-08	2025	5	8	2	Mai	Jeudi	19	f	f	2025-10-26 17:20:46.965256
130	2025-05-09	2025	5	9	2	Mai	Vendredi	19	f	f	2025-10-26 17:20:46.965256
131	2025-05-10	2025	5	10	2	Mai	Samedi	19	t	f	2025-10-26 17:20:46.965256
132	2025-05-11	2025	5	11	2	Mai	Dimanche	19	t	f	2025-10-26 17:20:46.965256
133	2025-05-12	2025	5	12	2	Mai	Lundi	20	f	f	2025-10-26 17:20:46.965256
134	2025-05-13	2025	5	13	2	Mai	Mardi	20	f	f	2025-10-26 17:20:46.965256
135	2025-05-14	2025	5	14	2	Mai	Mercredi	20	f	f	2025-10-26 17:20:46.965256
136	2025-05-15	2025	5	15	2	Mai	Jeudi	20	f	f	2025-10-26 17:20:46.965256
137	2025-05-16	2025	5	16	2	Mai	Vendredi	20	f	f	2025-10-26 17:20:46.965256
138	2025-05-17	2025	5	17	2	Mai	Samedi	20	t	f	2025-10-26 17:20:46.965256
139	2025-05-18	2025	5	18	2	Mai	Dimanche	20	t	f	2025-10-26 17:20:46.965256
140	2025-05-19	2025	5	19	2	Mai	Lundi	21	f	f	2025-10-26 17:20:46.965256
141	2025-05-20	2025	5	20	2	Mai	Mardi	21	f	f	2025-10-26 17:20:46.965256
142	2025-05-21	2025	5	21	2	Mai	Mercredi	21	f	f	2025-10-26 17:20:46.965256
143	2025-05-22	2025	5	22	2	Mai	Jeudi	21	f	f	2025-10-26 17:20:46.965256
144	2025-05-23	2025	5	23	2	Mai	Vendredi	21	f	f	2025-10-26 17:20:46.965256
145	2025-05-24	2025	5	24	2	Mai	Samedi	21	t	f	2025-10-26 17:20:46.965256
146	2025-05-25	2025	5	25	2	Mai	Dimanche	21	t	f	2025-10-26 17:20:46.965256
147	2025-05-26	2025	5	26	2	Mai	Lundi	22	f	f	2025-10-26 17:20:46.965256
148	2025-05-27	2025	5	27	2	Mai	Mardi	22	f	f	2025-10-26 17:20:46.965256
149	2025-05-28	2025	5	28	2	Mai	Mercredi	22	f	f	2025-10-26 17:20:46.965256
150	2025-05-29	2025	5	29	2	Mai	Jeudi	22	f	f	2025-10-26 17:20:46.965256
151	2025-05-30	2025	5	30	2	Mai	Vendredi	22	f	f	2025-10-26 17:20:46.965256
152	2025-05-31	2025	5	31	2	Mai	Samedi	22	t	f	2025-10-26 17:20:46.965256
153	2025-06-01	2025	6	1	2	Juin	Dimanche	22	t	f	2025-10-26 17:20:46.965256
154	2025-06-02	2025	6	2	2	Juin	Lundi	23	f	f	2025-10-26 17:20:46.965256
155	2025-06-03	2025	6	3	2	Juin	Mardi	23	f	f	2025-10-26 17:20:46.965256
156	2025-06-04	2025	6	4	2	Juin	Mercredi	23	f	f	2025-10-26 17:20:46.965256
157	2025-06-05	2025	6	5	2	Juin	Jeudi	23	f	f	2025-10-26 17:20:46.965256
158	2025-06-06	2025	6	6	2	Juin	Vendredi	23	f	f	2025-10-26 17:20:46.965256
159	2025-06-07	2025	6	7	2	Juin	Samedi	23	t	f	2025-10-26 17:20:46.965256
160	2025-06-08	2025	6	8	2	Juin	Dimanche	23	t	f	2025-10-26 17:20:46.965256
161	2025-06-09	2025	6	9	2	Juin	Lundi	24	f	f	2025-10-26 17:20:46.965256
162	2025-06-10	2025	6	10	2	Juin	Mardi	24	f	f	2025-10-26 17:20:46.965256
163	2025-06-11	2025	6	11	2	Juin	Mercredi	24	f	f	2025-10-26 17:20:46.965256
164	2025-06-12	2025	6	12	2	Juin	Jeudi	24	f	f	2025-10-26 17:20:46.965256
165	2025-06-13	2025	6	13	2	Juin	Vendredi	24	f	f	2025-10-26 17:20:46.965256
166	2025-06-14	2025	6	14	2	Juin	Samedi	24	t	f	2025-10-26 17:20:46.965256
167	2025-06-15	2025	6	15	2	Juin	Dimanche	24	t	f	2025-10-26 17:20:46.965256
168	2025-06-16	2025	6	16	2	Juin	Lundi	25	f	f	2025-10-26 17:20:46.965256
169	2025-06-17	2025	6	17	2	Juin	Mardi	25	f	f	2025-10-26 17:20:46.965256
170	2025-06-18	2025	6	18	2	Juin	Mercredi	25	f	f	2025-10-26 17:20:46.965256
171	2025-06-19	2025	6	19	2	Juin	Jeudi	25	f	f	2025-10-26 17:20:46.965256
172	2025-06-20	2025	6	20	2	Juin	Vendredi	25	f	f	2025-10-26 17:20:46.965256
173	2025-06-21	2025	6	21	2	Juin	Samedi	25	t	f	2025-10-26 17:20:46.965256
174	2025-06-22	2025	6	22	2	Juin	Dimanche	25	t	f	2025-10-26 17:20:46.965256
175	2025-06-23	2025	6	23	2	Juin	Lundi	26	f	f	2025-10-26 17:20:46.965256
176	2025-06-24	2025	6	24	2	Juin	Mardi	26	f	f	2025-10-26 17:20:46.965256
177	2025-06-25	2025	6	25	2	Juin	Mercredi	26	f	f	2025-10-26 17:20:46.965256
178	2025-06-26	2025	6	26	2	Juin	Jeudi	26	f	f	2025-10-26 17:20:46.965256
179	2025-06-27	2025	6	27	2	Juin	Vendredi	26	f	f	2025-10-26 17:20:46.965256
180	2025-06-28	2025	6	28	2	Juin	Samedi	26	t	f	2025-10-26 17:20:46.965256
181	2025-06-29	2025	6	29	2	Juin	Dimanche	26	t	f	2025-10-26 17:20:46.965256
182	2025-06-30	2025	6	30	2	Juin	Lundi	27	f	f	2025-10-26 17:20:46.965256
183	2025-07-01	2025	7	1	3	Juillet	Mardi	27	f	f	2025-10-26 17:20:46.965256
184	2025-07-02	2025	7	2	3	Juillet	Mercredi	27	f	f	2025-10-26 17:20:46.965256
185	2025-07-03	2025	7	3	3	Juillet	Jeudi	27	f	f	2025-10-26 17:20:46.965256
186	2025-07-04	2025	7	4	3	Juillet	Vendredi	27	f	f	2025-10-26 17:20:46.965256
187	2025-07-05	2025	7	5	3	Juillet	Samedi	27	t	f	2025-10-26 17:20:46.965256
188	2025-07-06	2025	7	6	3	Juillet	Dimanche	27	t	f	2025-10-26 17:20:46.965256
189	2025-07-07	2025	7	7	3	Juillet	Lundi	28	f	f	2025-10-26 17:20:46.965256
190	2025-07-08	2025	7	8	3	Juillet	Mardi	28	f	f	2025-10-26 17:20:46.965256
191	2025-07-09	2025	7	9	3	Juillet	Mercredi	28	f	f	2025-10-26 17:20:46.965256
192	2025-07-10	2025	7	10	3	Juillet	Jeudi	28	f	f	2025-10-26 17:20:46.965256
193	2025-07-11	2025	7	11	3	Juillet	Vendredi	28	f	f	2025-10-26 17:20:46.965256
194	2025-07-12	2025	7	12	3	Juillet	Samedi	28	t	f	2025-10-26 17:20:46.965256
195	2025-07-13	2025	7	13	3	Juillet	Dimanche	28	t	f	2025-10-26 17:20:46.965256
196	2025-07-14	2025	7	14	3	Juillet	Lundi	29	f	f	2025-10-26 17:20:46.965256
197	2025-07-15	2025	7	15	3	Juillet	Mardi	29	f	f	2025-10-26 17:20:46.965256
198	2025-07-16	2025	7	16	3	Juillet	Mercredi	29	f	f	2025-10-26 17:20:46.965256
199	2025-07-17	2025	7	17	3	Juillet	Jeudi	29	f	f	2025-10-26 17:20:46.965256
200	2025-07-18	2025	7	18	3	Juillet	Vendredi	29	f	f	2025-10-26 17:20:46.965256
201	2025-07-19	2025	7	19	3	Juillet	Samedi	29	t	f	2025-10-26 17:20:46.965256
202	2025-07-20	2025	7	20	3	Juillet	Dimanche	29	t	f	2025-10-26 17:20:46.965256
203	2025-07-21	2025	7	21	3	Juillet	Lundi	30	f	f	2025-10-26 17:20:46.965256
204	2025-07-22	2025	7	22	3	Juillet	Mardi	30	f	f	2025-10-26 17:20:46.965256
205	2025-07-23	2025	7	23	3	Juillet	Mercredi	30	f	f	2025-10-26 17:20:46.965256
206	2025-07-24	2025	7	24	3	Juillet	Jeudi	30	f	f	2025-10-26 17:20:46.965256
207	2025-07-25	2025	7	25	3	Juillet	Vendredi	30	f	f	2025-10-26 17:20:46.965256
208	2025-07-26	2025	7	26	3	Juillet	Samedi	30	t	f	2025-10-26 17:20:46.965256
209	2025-07-27	2025	7	27	3	Juillet	Dimanche	30	t	f	2025-10-26 17:20:46.965256
210	2025-07-28	2025	7	28	3	Juillet	Lundi	31	f	f	2025-10-26 17:20:46.965256
211	2025-07-29	2025	7	29	3	Juillet	Mardi	31	f	f	2025-10-26 17:20:46.965256
212	2025-07-30	2025	7	30	3	Juillet	Mercredi	31	f	f	2025-10-26 17:20:46.965256
213	2025-07-31	2025	7	31	3	Juillet	Jeudi	31	f	f	2025-10-26 17:20:46.965256
214	2025-08-01	2025	8	1	3	AoÃ»t	Vendredi	31	f	f	2025-10-26 17:20:46.965256
215	2025-08-02	2025	8	2	3	AoÃ»t	Samedi	31	t	f	2025-10-26 17:20:46.965256
216	2025-08-03	2025	8	3	3	AoÃ»t	Dimanche	31	t	f	2025-10-26 17:20:46.965256
217	2025-08-04	2025	8	4	3	AoÃ»t	Lundi	32	f	f	2025-10-26 17:20:46.965256
218	2025-08-05	2025	8	5	3	AoÃ»t	Mardi	32	f	f	2025-10-26 17:20:46.965256
219	2025-08-06	2025	8	6	3	AoÃ»t	Mercredi	32	f	f	2025-10-26 17:20:46.965256
220	2025-08-07	2025	8	7	3	AoÃ»t	Jeudi	32	f	f	2025-10-26 17:20:46.965256
221	2025-08-08	2025	8	8	3	AoÃ»t	Vendredi	32	f	f	2025-10-26 17:20:46.965256
222	2025-08-09	2025	8	9	3	AoÃ»t	Samedi	32	t	f	2025-10-26 17:20:46.965256
223	2025-08-10	2025	8	10	3	AoÃ»t	Dimanche	32	t	f	2025-10-26 17:20:46.965256
224	2025-08-11	2025	8	11	3	AoÃ»t	Lundi	33	f	f	2025-10-26 17:20:46.965256
225	2025-08-12	2025	8	12	3	AoÃ»t	Mardi	33	f	f	2025-10-26 17:20:46.965256
226	2025-08-13	2025	8	13	3	AoÃ»t	Mercredi	33	f	f	2025-10-26 17:20:46.965256
227	2025-08-14	2025	8	14	3	AoÃ»t	Jeudi	33	f	f	2025-10-26 17:20:46.965256
228	2025-08-15	2025	8	15	3	AoÃ»t	Vendredi	33	f	f	2025-10-26 17:20:46.965256
229	2025-08-16	2025	8	16	3	AoÃ»t	Samedi	33	t	f	2025-10-26 17:20:46.965256
230	2025-08-17	2025	8	17	3	AoÃ»t	Dimanche	33	t	f	2025-10-26 17:20:46.965256
231	2025-08-18	2025	8	18	3	AoÃ»t	Lundi	34	f	f	2025-10-26 17:20:46.965256
232	2025-08-19	2025	8	19	3	AoÃ»t	Mardi	34	f	f	2025-10-26 17:20:46.965256
233	2025-08-20	2025	8	20	3	AoÃ»t	Mercredi	34	f	f	2025-10-26 17:20:46.965256
234	2025-08-21	2025	8	21	3	AoÃ»t	Jeudi	34	f	f	2025-10-26 17:20:46.965256
235	2025-08-22	2025	8	22	3	AoÃ»t	Vendredi	34	f	f	2025-10-26 17:20:46.965256
236	2025-08-23	2025	8	23	3	AoÃ»t	Samedi	34	t	f	2025-10-26 17:20:46.965256
237	2025-08-24	2025	8	24	3	AoÃ»t	Dimanche	34	t	f	2025-10-26 17:20:46.965256
238	2025-08-25	2025	8	25	3	AoÃ»t	Lundi	35	f	f	2025-10-26 17:20:46.965256
239	2025-08-26	2025	8	26	3	AoÃ»t	Mardi	35	f	f	2025-10-26 17:20:46.965256
240	2025-08-27	2025	8	27	3	AoÃ»t	Mercredi	35	f	f	2025-10-26 17:20:46.965256
241	2025-08-28	2025	8	28	3	AoÃ»t	Jeudi	35	f	f	2025-10-26 17:20:46.965256
242	2025-08-29	2025	8	29	3	AoÃ»t	Vendredi	35	f	f	2025-10-26 17:20:46.965256
243	2025-08-30	2025	8	30	3	AoÃ»t	Samedi	35	t	f	2025-10-26 17:20:46.965256
244	2025-08-31	2025	8	31	3	AoÃ»t	Dimanche	35	t	f	2025-10-26 17:20:46.965256
245	2025-09-01	2025	9	1	3	Septembre	Lundi	36	f	f	2025-10-26 17:20:46.965256
246	2025-09-02	2025	9	2	3	Septembre	Mardi	36	f	f	2025-10-26 17:20:46.965256
247	2025-09-03	2025	9	3	3	Septembre	Mercredi	36	f	f	2025-10-26 17:20:46.965256
248	2025-09-04	2025	9	4	3	Septembre	Jeudi	36	f	f	2025-10-26 17:20:46.965256
249	2025-09-05	2025	9	5	3	Septembre	Vendredi	36	f	f	2025-10-26 17:20:46.965256
250	2025-09-06	2025	9	6	3	Septembre	Samedi	36	t	f	2025-10-26 17:20:46.965256
251	2025-09-07	2025	9	7	3	Septembre	Dimanche	36	t	f	2025-10-26 17:20:46.965256
252	2025-09-08	2025	9	8	3	Septembre	Lundi	37	f	f	2025-10-26 17:20:46.965256
253	2025-09-09	2025	9	9	3	Septembre	Mardi	37	f	f	2025-10-26 17:20:46.965256
254	2025-09-10	2025	9	10	3	Septembre	Mercredi	37	f	f	2025-10-26 17:20:46.965256
255	2025-09-11	2025	9	11	3	Septembre	Jeudi	37	f	f	2025-10-26 17:20:46.965256
256	2025-09-12	2025	9	12	3	Septembre	Vendredi	37	f	f	2025-10-26 17:20:46.965256
257	2025-09-13	2025	9	13	3	Septembre	Samedi	37	t	f	2025-10-26 17:20:46.965256
258	2025-09-14	2025	9	14	3	Septembre	Dimanche	37	t	f	2025-10-26 17:20:46.965256
259	2025-09-15	2025	9	15	3	Septembre	Lundi	38	f	f	2025-10-26 17:20:46.965256
260	2025-09-16	2025	9	16	3	Septembre	Mardi	38	f	f	2025-10-26 17:20:46.965256
261	2025-09-17	2025	9	17	3	Septembre	Mercredi	38	f	f	2025-10-26 17:20:46.965256
262	2025-09-18	2025	9	18	3	Septembre	Jeudi	38	f	f	2025-10-26 17:20:46.965256
263	2025-09-19	2025	9	19	3	Septembre	Vendredi	38	f	f	2025-10-26 17:20:46.965256
264	2025-09-20	2025	9	20	3	Septembre	Samedi	38	t	f	2025-10-26 17:20:46.965256
265	2025-09-21	2025	9	21	3	Septembre	Dimanche	38	t	f	2025-10-26 17:20:46.965256
266	2025-09-22	2025	9	22	3	Septembre	Lundi	39	f	f	2025-10-26 17:20:46.965256
267	2025-09-23	2025	9	23	3	Septembre	Mardi	39	f	f	2025-10-26 17:20:46.965256
268	2025-09-24	2025	9	24	3	Septembre	Mercredi	39	f	f	2025-10-26 17:20:46.965256
269	2025-09-25	2025	9	25	3	Septembre	Jeudi	39	f	f	2025-10-26 17:20:46.965256
270	2025-09-26	2025	9	26	3	Septembre	Vendredi	39	f	f	2025-10-26 17:20:46.965256
271	2025-09-27	2025	9	27	3	Septembre	Samedi	39	t	f	2025-10-26 17:20:46.965256
272	2025-09-28	2025	9	28	3	Septembre	Dimanche	39	t	f	2025-10-26 17:20:46.965256
273	2025-09-29	2025	9	29	3	Septembre	Lundi	40	f	f	2025-10-26 17:20:46.965256
274	2025-09-30	2025	9	30	3	Septembre	Mardi	40	f	f	2025-10-26 17:20:46.965256
275	2025-10-01	2025	10	1	4	Octobre	Mercredi	40	f	f	2025-10-26 17:20:46.965256
276	2025-10-02	2025	10	2	4	Octobre	Jeudi	40	f	f	2025-10-26 17:20:46.965256
277	2025-10-03	2025	10	3	4	Octobre	Vendredi	40	f	f	2025-10-26 17:20:46.965256
278	2025-10-04	2025	10	4	4	Octobre	Samedi	40	t	f	2025-10-26 17:20:46.965256
279	2025-10-05	2025	10	5	4	Octobre	Dimanche	40	t	f	2025-10-26 17:20:46.965256
280	2025-10-06	2025	10	6	4	Octobre	Lundi	41	f	f	2025-10-26 17:20:46.965256
281	2025-10-07	2025	10	7	4	Octobre	Mardi	41	f	f	2025-10-26 17:20:46.965256
282	2025-10-08	2025	10	8	4	Octobre	Mercredi	41	f	f	2025-10-26 17:20:46.965256
283	2025-10-09	2025	10	9	4	Octobre	Jeudi	41	f	f	2025-10-26 17:20:46.965256
284	2025-10-10	2025	10	10	4	Octobre	Vendredi	41	f	f	2025-10-26 17:20:46.965256
285	2025-10-11	2025	10	11	4	Octobre	Samedi	41	t	f	2025-10-26 17:20:46.965256
286	2025-10-12	2025	10	12	4	Octobre	Dimanche	41	t	f	2025-10-26 17:20:46.965256
287	2025-10-13	2025	10	13	4	Octobre	Lundi	42	f	f	2025-10-26 17:20:46.965256
288	2025-10-14	2025	10	14	4	Octobre	Mardi	42	f	f	2025-10-26 17:20:46.965256
289	2025-10-15	2025	10	15	4	Octobre	Mercredi	42	f	f	2025-10-26 17:20:46.965256
290	2025-10-16	2025	10	16	4	Octobre	Jeudi	42	f	f	2025-10-26 17:20:46.965256
291	2025-10-17	2025	10	17	4	Octobre	Vendredi	42	f	f	2025-10-26 17:20:46.965256
292	2025-10-18	2025	10	18	4	Octobre	Samedi	42	t	f	2025-10-26 17:20:46.965256
293	2025-10-19	2025	10	19	4	Octobre	Dimanche	42	t	f	2025-10-26 17:20:46.965256
294	2025-10-20	2025	10	20	4	Octobre	Lundi	43	f	f	2025-10-26 17:20:46.965256
295	2025-10-21	2025	10	21	4	Octobre	Mardi	43	f	f	2025-10-26 17:20:46.965256
296	2025-10-22	2025	10	22	4	Octobre	Mercredi	43	f	f	2025-10-26 17:20:46.965256
297	2025-10-23	2025	10	23	4	Octobre	Jeudi	43	f	f	2025-10-26 17:20:46.965256
298	2025-10-24	2025	10	24	4	Octobre	Vendredi	43	f	f	2025-10-26 17:20:46.965256
299	2025-10-25	2025	10	25	4	Octobre	Samedi	43	t	f	2025-10-26 17:20:46.965256
301	2025-10-27	2025	10	27	4	Octobre	Lundi	44	f	f	2025-10-26 17:20:46.965256
302	2025-10-28	2025	10	28	4	Octobre	Mardi	44	f	f	2025-10-26 17:20:46.965256
303	2025-10-29	2025	10	29	4	Octobre	Mercredi	44	f	f	2025-10-26 17:20:46.965256
304	2025-10-30	2025	10	30	4	Octobre	Jeudi	44	f	f	2025-10-26 17:20:46.965256
305	2025-10-31	2025	10	31	4	Octobre	Vendredi	44	f	f	2025-10-26 17:20:46.965256
306	2025-11-01	2025	11	1	4	Novembre	Samedi	44	t	f	2025-10-26 17:20:46.965256
307	2025-11-02	2025	11	2	4	Novembre	Dimanche	44	t	f	2025-10-26 17:20:46.965256
308	2025-11-03	2025	11	3	4	Novembre	Lundi	45	f	f	2025-10-26 17:20:46.965256
309	2025-11-04	2025	11	4	4	Novembre	Mardi	45	f	f	2025-10-26 17:20:46.965256
310	2025-11-05	2025	11	5	4	Novembre	Mercredi	45	f	f	2025-10-26 17:20:46.965256
311	2025-11-06	2025	11	6	4	Novembre	Jeudi	45	f	f	2025-10-26 17:20:46.965256
312	2025-11-07	2025	11	7	4	Novembre	Vendredi	45	f	f	2025-10-26 17:20:46.965256
313	2025-11-08	2025	11	8	4	Novembre	Samedi	45	t	f	2025-10-26 17:20:46.965256
314	2025-11-09	2025	11	9	4	Novembre	Dimanche	45	t	f	2025-10-26 17:20:46.965256
315	2025-11-10	2025	11	10	4	Novembre	Lundi	46	f	f	2025-10-26 17:20:46.965256
316	2025-11-11	2025	11	11	4	Novembre	Mardi	46	f	f	2025-10-26 17:20:46.965256
317	2025-11-12	2025	11	12	4	Novembre	Mercredi	46	f	f	2025-10-26 17:20:46.965256
318	2025-11-13	2025	11	13	4	Novembre	Jeudi	46	f	f	2025-10-26 17:20:46.965256
319	2025-11-14	2025	11	14	4	Novembre	Vendredi	46	f	f	2025-10-26 17:20:46.965256
320	2025-11-15	2025	11	15	4	Novembre	Samedi	46	t	f	2025-10-26 17:20:46.965256
321	2025-11-16	2025	11	16	4	Novembre	Dimanche	46	t	f	2025-10-26 17:20:46.965256
322	2025-11-17	2025	11	17	4	Novembre	Lundi	47	f	f	2025-10-26 17:20:46.965256
323	2025-11-18	2025	11	18	4	Novembre	Mardi	47	f	f	2025-10-26 17:20:46.965256
324	2025-11-19	2025	11	19	4	Novembre	Mercredi	47	f	f	2025-10-26 17:20:46.965256
325	2025-11-20	2025	11	20	4	Novembre	Jeudi	47	f	f	2025-10-26 17:20:46.965256
326	2025-11-21	2025	11	21	4	Novembre	Vendredi	47	f	f	2025-10-26 17:20:46.965256
327	2025-11-22	2025	11	22	4	Novembre	Samedi	47	t	f	2025-10-26 17:20:46.965256
328	2025-11-23	2025	11	23	4	Novembre	Dimanche	47	t	f	2025-10-26 17:20:46.965256
329	2025-11-24	2025	11	24	4	Novembre	Lundi	48	f	f	2025-10-26 17:20:46.965256
330	2025-11-25	2025	11	25	4	Novembre	Mardi	48	f	f	2025-10-26 17:20:46.965256
331	2025-11-26	2025	11	26	4	Novembre	Mercredi	48	f	f	2025-10-26 17:20:46.965256
332	2025-11-27	2025	11	27	4	Novembre	Jeudi	48	f	f	2025-10-26 17:20:46.965256
333	2025-11-28	2025	11	28	4	Novembre	Vendredi	48	f	f	2025-10-26 17:20:46.965256
334	2025-11-29	2025	11	29	4	Novembre	Samedi	48	t	f	2025-10-26 17:20:46.965256
335	2025-11-30	2025	11	30	4	Novembre	Dimanche	48	t	f	2025-10-26 17:20:46.965256
336	2025-12-01	2025	12	1	4	DÃ©cembre	Lundi	49	f	f	2025-10-26 17:20:46.965256
337	2025-12-02	2025	12	2	4	DÃ©cembre	Mardi	49	f	f	2025-10-26 17:20:46.965256
338	2025-12-03	2025	12	3	4	DÃ©cembre	Mercredi	49	f	f	2025-10-26 17:20:46.965256
339	2025-12-04	2025	12	4	4	DÃ©cembre	Jeudi	49	f	f	2025-10-26 17:20:46.965256
340	2025-12-05	2025	12	5	4	DÃ©cembre	Vendredi	49	f	f	2025-10-26 17:20:46.965256
341	2025-12-06	2025	12	6	4	DÃ©cembre	Samedi	49	t	f	2025-10-26 17:20:46.965256
342	2025-12-07	2025	12	7	4	DÃ©cembre	Dimanche	49	t	f	2025-10-26 17:20:46.965256
343	2025-12-08	2025	12	8	4	DÃ©cembre	Lundi	50	f	f	2025-10-26 17:20:46.965256
344	2025-12-09	2025	12	9	4	DÃ©cembre	Mardi	50	f	f	2025-10-26 17:20:46.965256
345	2025-12-10	2025	12	10	4	DÃ©cembre	Mercredi	50	f	f	2025-10-26 17:20:46.965256
346	2025-12-11	2025	12	11	4	DÃ©cembre	Jeudi	50	f	f	2025-10-26 17:20:46.965256
347	2025-12-12	2025	12	12	4	DÃ©cembre	Vendredi	50	f	f	2025-10-26 17:20:46.965256
348	2025-12-13	2025	12	13	4	DÃ©cembre	Samedi	50	t	f	2025-10-26 17:20:46.965256
349	2025-12-14	2025	12	14	4	DÃ©cembre	Dimanche	50	t	f	2025-10-26 17:20:46.965256
350	2025-12-15	2025	12	15	4	DÃ©cembre	Lundi	51	f	f	2025-10-26 17:20:46.965256
351	2025-12-16	2025	12	16	4	DÃ©cembre	Mardi	51	f	f	2025-10-26 17:20:46.965256
352	2025-12-17	2025	12	17	4	DÃ©cembre	Mercredi	51	f	f	2025-10-26 17:20:46.965256
353	2025-12-18	2025	12	18	4	DÃ©cembre	Jeudi	51	f	f	2025-10-26 17:20:46.965256
354	2025-12-19	2025	12	19	4	DÃ©cembre	Vendredi	51	f	f	2025-10-26 17:20:46.965256
355	2025-12-20	2025	12	20	4	DÃ©cembre	Samedi	51	t	f	2025-10-26 17:20:46.965256
356	2025-12-21	2025	12	21	4	DÃ©cembre	Dimanche	51	t	f	2025-10-26 17:20:46.965256
357	2025-12-22	2025	12	22	4	DÃ©cembre	Lundi	52	f	f	2025-10-26 17:20:46.965256
358	2025-12-23	2025	12	23	4	DÃ©cembre	Mardi	52	f	f	2025-10-26 17:20:46.965256
359	2025-12-24	2025	12	24	4	DÃ©cembre	Mercredi	52	f	f	2025-10-26 17:20:46.965256
360	2025-12-25	2025	12	25	4	DÃ©cembre	Jeudi	52	f	f	2025-10-26 17:20:46.965256
361	2025-12-26	2025	12	26	4	DÃ©cembre	Vendredi	52	f	f	2025-10-26 17:20:46.965256
362	2025-12-27	2025	12	27	4	DÃ©cembre	Samedi	52	t	f	2025-10-26 17:20:46.965256
363	2025-12-28	2025	12	28	4	DÃ©cembre	Dimanche	52	t	f	2025-10-26 17:20:46.965256
364	2025-12-29	2025	12	29	4	DÃ©cembre	Lundi	1	f	f	2025-10-26 17:20:46.965256
365	2025-12-30	2025	12	30	4	DÃ©cembre	Mardi	1	f	f	2025-10-26 17:20:46.965256
366	2025-12-31	2025	12	31	4	DÃ©cembre	Mercredi	1	f	f	2025-10-26 17:20:46.965256
367	2026-01-01	2026	1	1	1	Janvier	Jeudi	1	f	f	2025-10-26 17:20:46.965256
368	2026-01-02	2026	1	2	1	Janvier	Vendredi	1	f	f	2025-10-26 17:20:46.965256
369	2026-01-03	2026	1	3	1	Janvier	Samedi	1	t	f	2025-10-26 17:20:46.965256
370	2026-01-04	2026	1	4	1	Janvier	Dimanche	1	t	f	2025-10-26 17:20:46.965256
371	2026-01-05	2026	1	5	1	Janvier	Lundi	2	f	f	2025-10-26 17:20:46.965256
372	2026-01-06	2026	1	6	1	Janvier	Mardi	2	f	f	2025-10-26 17:20:46.965256
373	2026-01-07	2026	1	7	1	Janvier	Mercredi	2	f	f	2025-10-26 17:20:46.965256
374	2026-01-08	2026	1	8	1	Janvier	Jeudi	2	f	f	2025-10-26 17:20:46.965256
375	2026-01-09	2026	1	9	1	Janvier	Vendredi	2	f	f	2025-10-26 17:20:46.965256
376	2026-01-10	2026	1	10	1	Janvier	Samedi	2	t	f	2025-10-26 17:20:46.965256
377	2026-01-11	2026	1	11	1	Janvier	Dimanche	2	t	f	2025-10-26 17:20:46.965256
378	2026-01-12	2026	1	12	1	Janvier	Lundi	3	f	f	2025-10-26 17:20:46.965256
379	2026-01-13	2026	1	13	1	Janvier	Mardi	3	f	f	2025-10-26 17:20:46.965256
380	2026-01-14	2026	1	14	1	Janvier	Mercredi	3	f	f	2025-10-26 17:20:46.965256
381	2026-01-15	2026	1	15	1	Janvier	Jeudi	3	f	f	2025-10-26 17:20:46.965256
382	2026-01-16	2026	1	16	1	Janvier	Vendredi	3	f	f	2025-10-26 17:20:46.965256
383	2026-01-17	2026	1	17	1	Janvier	Samedi	3	t	f	2025-10-26 17:20:46.965256
384	2026-01-18	2026	1	18	1	Janvier	Dimanche	3	t	f	2025-10-26 17:20:46.965256
385	2026-01-19	2026	1	19	1	Janvier	Lundi	4	f	f	2025-10-26 17:20:46.965256
386	2026-01-20	2026	1	20	1	Janvier	Mardi	4	f	f	2025-10-26 17:20:46.965256
387	2026-01-21	2026	1	21	1	Janvier	Mercredi	4	f	f	2025-10-26 17:20:46.965256
388	2026-01-22	2026	1	22	1	Janvier	Jeudi	4	f	f	2025-10-26 17:20:46.965256
389	2026-01-23	2026	1	23	1	Janvier	Vendredi	4	f	f	2025-10-26 17:20:46.965256
390	2026-01-24	2026	1	24	1	Janvier	Samedi	4	t	f	2025-10-26 17:20:46.965256
391	2026-01-25	2026	1	25	1	Janvier	Dimanche	4	t	f	2025-10-26 17:20:46.965256
392	2026-01-26	2026	1	26	1	Janvier	Lundi	5	f	f	2025-10-26 17:20:46.965256
393	2026-01-27	2026	1	27	1	Janvier	Mardi	5	f	f	2025-10-26 17:20:46.965256
394	2026-01-28	2026	1	28	1	Janvier	Mercredi	5	f	f	2025-10-26 17:20:46.965256
395	2026-01-29	2026	1	29	1	Janvier	Jeudi	5	f	f	2025-10-26 17:20:46.965256
396	2026-01-30	2026	1	30	1	Janvier	Vendredi	5	f	f	2025-10-26 17:20:46.965256
397	2026-01-31	2026	1	31	1	Janvier	Samedi	5	t	f	2025-10-26 17:20:46.965256
398	2026-02-01	2026	2	1	1	FÃ©vrier	Dimanche	5	t	f	2025-10-26 17:20:46.965256
399	2026-02-02	2026	2	2	1	FÃ©vrier	Lundi	6	f	f	2025-10-26 17:20:46.965256
400	2026-02-03	2026	2	3	1	FÃ©vrier	Mardi	6	f	f	2025-10-26 17:20:46.965256
401	2026-02-04	2026	2	4	1	FÃ©vrier	Mercredi	6	f	f	2025-10-26 17:20:46.965256
402	2026-02-05	2026	2	5	1	FÃ©vrier	Jeudi	6	f	f	2025-10-26 17:20:46.965256
403	2026-02-06	2026	2	6	1	FÃ©vrier	Vendredi	6	f	f	2025-10-26 17:20:46.965256
404	2026-02-07	2026	2	7	1	FÃ©vrier	Samedi	6	t	f	2025-10-26 17:20:46.965256
405	2026-02-08	2026	2	8	1	FÃ©vrier	Dimanche	6	t	f	2025-10-26 17:20:46.965256
406	2026-02-09	2026	2	9	1	FÃ©vrier	Lundi	7	f	f	2025-10-26 17:20:46.965256
407	2026-02-10	2026	2	10	1	FÃ©vrier	Mardi	7	f	f	2025-10-26 17:20:46.965256
408	2026-02-11	2026	2	11	1	FÃ©vrier	Mercredi	7	f	f	2025-10-26 17:20:46.965256
409	2026-02-12	2026	2	12	1	FÃ©vrier	Jeudi	7	f	f	2025-10-26 17:20:46.965256
410	2026-02-13	2026	2	13	1	FÃ©vrier	Vendredi	7	f	f	2025-10-26 17:20:46.965256
411	2026-02-14	2026	2	14	1	FÃ©vrier	Samedi	7	t	f	2025-10-26 17:20:46.965256
412	2026-02-15	2026	2	15	1	FÃ©vrier	Dimanche	7	t	f	2025-10-26 17:20:46.965256
413	2026-02-16	2026	2	16	1	FÃ©vrier	Lundi	8	f	f	2025-10-26 17:20:46.965256
414	2026-02-17	2026	2	17	1	FÃ©vrier	Mardi	8	f	f	2025-10-26 17:20:46.965256
415	2026-02-18	2026	2	18	1	FÃ©vrier	Mercredi	8	f	f	2025-10-26 17:20:46.965256
416	2026-02-19	2026	2	19	1	FÃ©vrier	Jeudi	8	f	f	2025-10-26 17:20:46.965256
417	2026-02-20	2026	2	20	1	FÃ©vrier	Vendredi	8	f	f	2025-10-26 17:20:46.965256
418	2026-02-21	2026	2	21	1	FÃ©vrier	Samedi	8	t	f	2025-10-26 17:20:46.965256
419	2026-02-22	2026	2	22	1	FÃ©vrier	Dimanche	8	t	f	2025-10-26 17:20:46.965256
420	2026-02-23	2026	2	23	1	FÃ©vrier	Lundi	9	f	f	2025-10-26 17:20:46.965256
421	2026-02-24	2026	2	24	1	FÃ©vrier	Mardi	9	f	f	2025-10-26 17:20:46.965256
422	2026-02-25	2026	2	25	1	FÃ©vrier	Mercredi	9	f	f	2025-10-26 17:20:46.965256
423	2026-02-26	2026	2	26	1	FÃ©vrier	Jeudi	9	f	f	2025-10-26 17:20:46.965256
424	2026-02-27	2026	2	27	1	FÃ©vrier	Vendredi	9	f	f	2025-10-26 17:20:46.965256
425	2026-02-28	2026	2	28	1	FÃ©vrier	Samedi	9	t	f	2025-10-26 17:20:46.965256
426	2026-03-01	2026	3	1	1	Mars	Dimanche	9	t	f	2025-10-26 17:20:46.965256
427	2026-03-02	2026	3	2	1	Mars	Lundi	10	f	f	2025-10-26 17:20:46.965256
428	2026-03-03	2026	3	3	1	Mars	Mardi	10	f	f	2025-10-26 17:20:46.965256
429	2026-03-04	2026	3	4	1	Mars	Mercredi	10	f	f	2025-10-26 17:20:46.965256
430	2026-03-05	2026	3	5	1	Mars	Jeudi	10	f	f	2025-10-26 17:20:46.965256
431	2026-03-06	2026	3	6	1	Mars	Vendredi	10	f	f	2025-10-26 17:20:46.965256
432	2026-03-07	2026	3	7	1	Mars	Samedi	10	t	f	2025-10-26 17:20:46.965256
433	2026-03-08	2026	3	8	1	Mars	Dimanche	10	t	f	2025-10-26 17:20:46.965256
434	2026-03-09	2026	3	9	1	Mars	Lundi	11	f	f	2025-10-26 17:20:46.965256
435	2026-03-10	2026	3	10	1	Mars	Mardi	11	f	f	2025-10-26 17:20:46.965256
436	2026-03-11	2026	3	11	1	Mars	Mercredi	11	f	f	2025-10-26 17:20:46.965256
437	2026-03-12	2026	3	12	1	Mars	Jeudi	11	f	f	2025-10-26 17:20:46.965256
438	2026-03-13	2026	3	13	1	Mars	Vendredi	11	f	f	2025-10-26 17:20:46.965256
439	2026-03-14	2026	3	14	1	Mars	Samedi	11	t	f	2025-10-26 17:20:46.965256
440	2026-03-15	2026	3	15	1	Mars	Dimanche	11	t	f	2025-10-26 17:20:46.965256
441	2026-03-16	2026	3	16	1	Mars	Lundi	12	f	f	2025-10-26 17:20:46.965256
442	2026-03-17	2026	3	17	1	Mars	Mardi	12	f	f	2025-10-26 17:20:46.965256
443	2026-03-18	2026	3	18	1	Mars	Mercredi	12	f	f	2025-10-26 17:20:46.965256
444	2026-03-19	2026	3	19	1	Mars	Jeudi	12	f	f	2025-10-26 17:20:46.965256
445	2026-03-20	2026	3	20	1	Mars	Vendredi	12	f	f	2025-10-26 17:20:46.965256
446	2026-03-21	2026	3	21	1	Mars	Samedi	12	t	f	2025-10-26 17:20:46.965256
447	2026-03-22	2026	3	22	1	Mars	Dimanche	12	t	f	2025-10-26 17:20:46.965256
448	2026-03-23	2026	3	23	1	Mars	Lundi	13	f	f	2025-10-26 17:20:46.965256
449	2026-03-24	2026	3	24	1	Mars	Mardi	13	f	f	2025-10-26 17:20:46.965256
450	2026-03-25	2026	3	25	1	Mars	Mercredi	13	f	f	2025-10-26 17:20:46.965256
451	2026-03-26	2026	3	26	1	Mars	Jeudi	13	f	f	2025-10-26 17:20:46.965256
452	2026-03-27	2026	3	27	1	Mars	Vendredi	13	f	f	2025-10-26 17:20:46.965256
453	2026-03-28	2026	3	28	1	Mars	Samedi	13	t	f	2025-10-26 17:20:46.965256
454	2026-03-29	2026	3	29	1	Mars	Dimanche	13	t	f	2025-10-26 17:20:46.965256
455	2026-03-30	2026	3	30	1	Mars	Lundi	14	f	f	2025-10-26 17:20:46.965256
456	2026-03-31	2026	3	31	1	Mars	Mardi	14	f	f	2025-10-26 17:20:46.965256
457	2026-04-01	2026	4	1	2	Avril	Mercredi	14	f	f	2025-10-26 17:20:46.965256
458	2026-04-02	2026	4	2	2	Avril	Jeudi	14	f	f	2025-10-26 17:20:46.965256
459	2026-04-03	2026	4	3	2	Avril	Vendredi	14	f	f	2025-10-26 17:20:46.965256
460	2026-04-04	2026	4	4	2	Avril	Samedi	14	t	f	2025-10-26 17:20:46.965256
461	2026-04-05	2026	4	5	2	Avril	Dimanche	14	t	f	2025-10-26 17:20:46.965256
462	2026-04-06	2026	4	6	2	Avril	Lundi	15	f	f	2025-10-26 17:20:46.965256
463	2026-04-07	2026	4	7	2	Avril	Mardi	15	f	f	2025-10-26 17:20:46.965256
464	2026-04-08	2026	4	8	2	Avril	Mercredi	15	f	f	2025-10-26 17:20:46.965256
465	2026-04-09	2026	4	9	2	Avril	Jeudi	15	f	f	2025-10-26 17:20:46.965256
466	2026-04-10	2026	4	10	2	Avril	Vendredi	15	f	f	2025-10-26 17:20:46.965256
467	2026-04-11	2026	4	11	2	Avril	Samedi	15	t	f	2025-10-26 17:20:46.965256
468	2026-04-12	2026	4	12	2	Avril	Dimanche	15	t	f	2025-10-26 17:20:46.965256
469	2026-04-13	2026	4	13	2	Avril	Lundi	16	f	f	2025-10-26 17:20:46.965256
470	2026-04-14	2026	4	14	2	Avril	Mardi	16	f	f	2025-10-26 17:20:46.965256
471	2026-04-15	2026	4	15	2	Avril	Mercredi	16	f	f	2025-10-26 17:20:46.965256
472	2026-04-16	2026	4	16	2	Avril	Jeudi	16	f	f	2025-10-26 17:20:46.965256
473	2026-04-17	2026	4	17	2	Avril	Vendredi	16	f	f	2025-10-26 17:20:46.965256
474	2026-04-18	2026	4	18	2	Avril	Samedi	16	t	f	2025-10-26 17:20:46.965256
475	2026-04-19	2026	4	19	2	Avril	Dimanche	16	t	f	2025-10-26 17:20:46.965256
476	2026-04-20	2026	4	20	2	Avril	Lundi	17	f	f	2025-10-26 17:20:46.965256
477	2026-04-21	2026	4	21	2	Avril	Mardi	17	f	f	2025-10-26 17:20:46.965256
478	2026-04-22	2026	4	22	2	Avril	Mercredi	17	f	f	2025-10-26 17:20:46.965256
479	2026-04-23	2026	4	23	2	Avril	Jeudi	17	f	f	2025-10-26 17:20:46.965256
480	2026-04-24	2026	4	24	2	Avril	Vendredi	17	f	f	2025-10-26 17:20:46.965256
481	2026-04-25	2026	4	25	2	Avril	Samedi	17	t	f	2025-10-26 17:20:46.965256
482	2026-04-26	2026	4	26	2	Avril	Dimanche	17	t	f	2025-10-26 17:20:46.965256
483	2026-04-27	2026	4	27	2	Avril	Lundi	18	f	f	2025-10-26 17:20:46.965256
484	2026-04-28	2026	4	28	2	Avril	Mardi	18	f	f	2025-10-26 17:20:46.965256
485	2026-04-29	2026	4	29	2	Avril	Mercredi	18	f	f	2025-10-26 17:20:46.965256
486	2026-04-30	2026	4	30	2	Avril	Jeudi	18	f	f	2025-10-26 17:20:46.965256
487	2026-05-01	2026	5	1	2	Mai	Vendredi	18	f	f	2025-10-26 17:20:46.965256
488	2026-05-02	2026	5	2	2	Mai	Samedi	18	t	f	2025-10-26 17:20:46.965256
489	2026-05-03	2026	5	3	2	Mai	Dimanche	18	t	f	2025-10-26 17:20:46.965256
490	2026-05-04	2026	5	4	2	Mai	Lundi	19	f	f	2025-10-26 17:20:46.965256
491	2026-05-05	2026	5	5	2	Mai	Mardi	19	f	f	2025-10-26 17:20:46.965256
492	2026-05-06	2026	5	6	2	Mai	Mercredi	19	f	f	2025-10-26 17:20:46.965256
493	2026-05-07	2026	5	7	2	Mai	Jeudi	19	f	f	2025-10-26 17:20:46.965256
494	2026-05-08	2026	5	8	2	Mai	Vendredi	19	f	f	2025-10-26 17:20:46.965256
495	2026-05-09	2026	5	9	2	Mai	Samedi	19	t	f	2025-10-26 17:20:46.965256
496	2026-05-10	2026	5	10	2	Mai	Dimanche	19	t	f	2025-10-26 17:20:46.965256
497	2026-05-11	2026	5	11	2	Mai	Lundi	20	f	f	2025-10-26 17:20:46.965256
498	2026-05-12	2026	5	12	2	Mai	Mardi	20	f	f	2025-10-26 17:20:46.965256
499	2026-05-13	2026	5	13	2	Mai	Mercredi	20	f	f	2025-10-26 17:20:46.965256
500	2026-05-14	2026	5	14	2	Mai	Jeudi	20	f	f	2025-10-26 17:20:46.965256
501	2026-05-15	2026	5	15	2	Mai	Vendredi	20	f	f	2025-10-26 17:20:46.965256
502	2026-05-16	2026	5	16	2	Mai	Samedi	20	t	f	2025-10-26 17:20:46.965256
503	2026-05-17	2026	5	17	2	Mai	Dimanche	20	t	f	2025-10-26 17:20:46.965256
504	2026-05-18	2026	5	18	2	Mai	Lundi	21	f	f	2025-10-26 17:20:46.965256
505	2026-05-19	2026	5	19	2	Mai	Mardi	21	f	f	2025-10-26 17:20:46.965256
506	2026-05-20	2026	5	20	2	Mai	Mercredi	21	f	f	2025-10-26 17:20:46.965256
507	2026-05-21	2026	5	21	2	Mai	Jeudi	21	f	f	2025-10-26 17:20:46.965256
508	2026-05-22	2026	5	22	2	Mai	Vendredi	21	f	f	2025-10-26 17:20:46.965256
509	2026-05-23	2026	5	23	2	Mai	Samedi	21	t	f	2025-10-26 17:20:46.965256
510	2026-05-24	2026	5	24	2	Mai	Dimanche	21	t	f	2025-10-26 17:20:46.965256
511	2026-05-25	2026	5	25	2	Mai	Lundi	22	f	f	2025-10-26 17:20:46.965256
512	2026-05-26	2026	5	26	2	Mai	Mardi	22	f	f	2025-10-26 17:20:46.965256
513	2026-05-27	2026	5	27	2	Mai	Mercredi	22	f	f	2025-10-26 17:20:46.965256
514	2026-05-28	2026	5	28	2	Mai	Jeudi	22	f	f	2025-10-26 17:20:46.965256
515	2026-05-29	2026	5	29	2	Mai	Vendredi	22	f	f	2025-10-26 17:20:46.965256
516	2026-05-30	2026	5	30	2	Mai	Samedi	22	t	f	2025-10-26 17:20:46.965256
517	2026-05-31	2026	5	31	2	Mai	Dimanche	22	t	f	2025-10-26 17:20:46.965256
518	2026-06-01	2026	6	1	2	Juin	Lundi	23	f	f	2025-10-26 17:20:46.965256
519	2026-06-02	2026	6	2	2	Juin	Mardi	23	f	f	2025-10-26 17:20:46.965256
520	2026-06-03	2026	6	3	2	Juin	Mercredi	23	f	f	2025-10-26 17:20:46.965256
521	2026-06-04	2026	6	4	2	Juin	Jeudi	23	f	f	2025-10-26 17:20:46.965256
522	2026-06-05	2026	6	5	2	Juin	Vendredi	23	f	f	2025-10-26 17:20:46.965256
523	2026-06-06	2026	6	6	2	Juin	Samedi	23	t	f	2025-10-26 17:20:46.965256
524	2026-06-07	2026	6	7	2	Juin	Dimanche	23	t	f	2025-10-26 17:20:46.965256
525	2026-06-08	2026	6	8	2	Juin	Lundi	24	f	f	2025-10-26 17:20:46.965256
526	2026-06-09	2026	6	9	2	Juin	Mardi	24	f	f	2025-10-26 17:20:46.965256
527	2026-06-10	2026	6	10	2	Juin	Mercredi	24	f	f	2025-10-26 17:20:46.965256
528	2026-06-11	2026	6	11	2	Juin	Jeudi	24	f	f	2025-10-26 17:20:46.965256
529	2026-06-12	2026	6	12	2	Juin	Vendredi	24	f	f	2025-10-26 17:20:46.965256
530	2026-06-13	2026	6	13	2	Juin	Samedi	24	t	f	2025-10-26 17:20:46.965256
531	2026-06-14	2026	6	14	2	Juin	Dimanche	24	t	f	2025-10-26 17:20:46.965256
532	2026-06-15	2026	6	15	2	Juin	Lundi	25	f	f	2025-10-26 17:20:46.965256
533	2026-06-16	2026	6	16	2	Juin	Mardi	25	f	f	2025-10-26 17:20:46.965256
534	2026-06-17	2026	6	17	2	Juin	Mercredi	25	f	f	2025-10-26 17:20:46.965256
535	2026-06-18	2026	6	18	2	Juin	Jeudi	25	f	f	2025-10-26 17:20:46.965256
536	2026-06-19	2026	6	19	2	Juin	Vendredi	25	f	f	2025-10-26 17:20:46.965256
537	2026-06-20	2026	6	20	2	Juin	Samedi	25	t	f	2025-10-26 17:20:46.965256
538	2026-06-21	2026	6	21	2	Juin	Dimanche	25	t	f	2025-10-26 17:20:46.965256
539	2026-06-22	2026	6	22	2	Juin	Lundi	26	f	f	2025-10-26 17:20:46.965256
540	2026-06-23	2026	6	23	2	Juin	Mardi	26	f	f	2025-10-26 17:20:46.965256
541	2026-06-24	2026	6	24	2	Juin	Mercredi	26	f	f	2025-10-26 17:20:46.965256
542	2026-06-25	2026	6	25	2	Juin	Jeudi	26	f	f	2025-10-26 17:20:46.965256
543	2026-06-26	2026	6	26	2	Juin	Vendredi	26	f	f	2025-10-26 17:20:46.965256
544	2026-06-27	2026	6	27	2	Juin	Samedi	26	t	f	2025-10-26 17:20:46.965256
545	2026-06-28	2026	6	28	2	Juin	Dimanche	26	t	f	2025-10-26 17:20:46.965256
546	2026-06-29	2026	6	29	2	Juin	Lundi	27	f	f	2025-10-26 17:20:46.965256
547	2026-06-30	2026	6	30	2	Juin	Mardi	27	f	f	2025-10-26 17:20:46.965256
548	2026-07-01	2026	7	1	3	Juillet	Mercredi	27	f	f	2025-10-26 17:20:46.965256
549	2026-07-02	2026	7	2	3	Juillet	Jeudi	27	f	f	2025-10-26 17:20:46.965256
550	2026-07-03	2026	7	3	3	Juillet	Vendredi	27	f	f	2025-10-26 17:20:46.965256
551	2026-07-04	2026	7	4	3	Juillet	Samedi	27	t	f	2025-10-26 17:20:46.965256
552	2026-07-05	2026	7	5	3	Juillet	Dimanche	27	t	f	2025-10-26 17:20:46.965256
553	2026-07-06	2026	7	6	3	Juillet	Lundi	28	f	f	2025-10-26 17:20:46.965256
554	2026-07-07	2026	7	7	3	Juillet	Mardi	28	f	f	2025-10-26 17:20:46.965256
555	2026-07-08	2026	7	8	3	Juillet	Mercredi	28	f	f	2025-10-26 17:20:46.965256
556	2026-07-09	2026	7	9	3	Juillet	Jeudi	28	f	f	2025-10-26 17:20:46.965256
557	2026-07-10	2026	7	10	3	Juillet	Vendredi	28	f	f	2025-10-26 17:20:46.965256
558	2026-07-11	2026	7	11	3	Juillet	Samedi	28	t	f	2025-10-26 17:20:46.965256
559	2026-07-12	2026	7	12	3	Juillet	Dimanche	28	t	f	2025-10-26 17:20:46.965256
560	2026-07-13	2026	7	13	3	Juillet	Lundi	29	f	f	2025-10-26 17:20:46.965256
561	2026-07-14	2026	7	14	3	Juillet	Mardi	29	f	f	2025-10-26 17:20:46.965256
562	2026-07-15	2026	7	15	3	Juillet	Mercredi	29	f	f	2025-10-26 17:20:46.965256
563	2026-07-16	2026	7	16	3	Juillet	Jeudi	29	f	f	2025-10-26 17:20:46.965256
564	2026-07-17	2026	7	17	3	Juillet	Vendredi	29	f	f	2025-10-26 17:20:46.965256
565	2026-07-18	2026	7	18	3	Juillet	Samedi	29	t	f	2025-10-26 17:20:46.965256
566	2026-07-19	2026	7	19	3	Juillet	Dimanche	29	t	f	2025-10-26 17:20:46.965256
567	2026-07-20	2026	7	20	3	Juillet	Lundi	30	f	f	2025-10-26 17:20:46.965256
568	2026-07-21	2026	7	21	3	Juillet	Mardi	30	f	f	2025-10-26 17:20:46.965256
569	2026-07-22	2026	7	22	3	Juillet	Mercredi	30	f	f	2025-10-26 17:20:46.965256
570	2026-07-23	2026	7	23	3	Juillet	Jeudi	30	f	f	2025-10-26 17:20:46.965256
571	2026-07-24	2026	7	24	3	Juillet	Vendredi	30	f	f	2025-10-26 17:20:46.965256
572	2026-07-25	2026	7	25	3	Juillet	Samedi	30	t	f	2025-10-26 17:20:46.965256
573	2026-07-26	2026	7	26	3	Juillet	Dimanche	30	t	f	2025-10-26 17:20:46.965256
574	2026-07-27	2026	7	27	3	Juillet	Lundi	31	f	f	2025-10-26 17:20:46.965256
575	2026-07-28	2026	7	28	3	Juillet	Mardi	31	f	f	2025-10-26 17:20:46.965256
576	2026-07-29	2026	7	29	3	Juillet	Mercredi	31	f	f	2025-10-26 17:20:46.965256
577	2026-07-30	2026	7	30	3	Juillet	Jeudi	31	f	f	2025-10-26 17:20:46.965256
578	2026-07-31	2026	7	31	3	Juillet	Vendredi	31	f	f	2025-10-26 17:20:46.965256
579	2026-08-01	2026	8	1	3	AoÃ»t	Samedi	31	t	f	2025-10-26 17:20:46.965256
580	2026-08-02	2026	8	2	3	AoÃ»t	Dimanche	31	t	f	2025-10-26 17:20:46.965256
581	2026-08-03	2026	8	3	3	AoÃ»t	Lundi	32	f	f	2025-10-26 17:20:46.965256
582	2026-08-04	2026	8	4	3	AoÃ»t	Mardi	32	f	f	2025-10-26 17:20:46.965256
583	2026-08-05	2026	8	5	3	AoÃ»t	Mercredi	32	f	f	2025-10-26 17:20:46.965256
584	2026-08-06	2026	8	6	3	AoÃ»t	Jeudi	32	f	f	2025-10-26 17:20:46.965256
585	2026-08-07	2026	8	7	3	AoÃ»t	Vendredi	32	f	f	2025-10-26 17:20:46.965256
586	2026-08-08	2026	8	8	3	AoÃ»t	Samedi	32	t	f	2025-10-26 17:20:46.965256
587	2026-08-09	2026	8	9	3	AoÃ»t	Dimanche	32	t	f	2025-10-26 17:20:46.965256
588	2026-08-10	2026	8	10	3	AoÃ»t	Lundi	33	f	f	2025-10-26 17:20:46.965256
589	2026-08-11	2026	8	11	3	AoÃ»t	Mardi	33	f	f	2025-10-26 17:20:46.965256
590	2026-08-12	2026	8	12	3	AoÃ»t	Mercredi	33	f	f	2025-10-26 17:20:46.965256
591	2026-08-13	2026	8	13	3	AoÃ»t	Jeudi	33	f	f	2025-10-26 17:20:46.965256
592	2026-08-14	2026	8	14	3	AoÃ»t	Vendredi	33	f	f	2025-10-26 17:20:46.965256
593	2026-08-15	2026	8	15	3	AoÃ»t	Samedi	33	t	f	2025-10-26 17:20:46.965256
594	2026-08-16	2026	8	16	3	AoÃ»t	Dimanche	33	t	f	2025-10-26 17:20:46.965256
595	2026-08-17	2026	8	17	3	AoÃ»t	Lundi	34	f	f	2025-10-26 17:20:46.965256
596	2026-08-18	2026	8	18	3	AoÃ»t	Mardi	34	f	f	2025-10-26 17:20:46.965256
597	2026-08-19	2026	8	19	3	AoÃ»t	Mercredi	34	f	f	2025-10-26 17:20:46.965256
598	2026-08-20	2026	8	20	3	AoÃ»t	Jeudi	34	f	f	2025-10-26 17:20:46.965256
599	2026-08-21	2026	8	21	3	AoÃ»t	Vendredi	34	f	f	2025-10-26 17:20:46.965256
600	2026-08-22	2026	8	22	3	AoÃ»t	Samedi	34	t	f	2025-10-26 17:20:46.965256
601	2026-08-23	2026	8	23	3	AoÃ»t	Dimanche	34	t	f	2025-10-26 17:20:46.965256
602	2026-08-24	2026	8	24	3	AoÃ»t	Lundi	35	f	f	2025-10-26 17:20:46.965256
603	2026-08-25	2026	8	25	3	AoÃ»t	Mardi	35	f	f	2025-10-26 17:20:46.965256
604	2026-08-26	2026	8	26	3	AoÃ»t	Mercredi	35	f	f	2025-10-26 17:20:46.965256
605	2026-08-27	2026	8	27	3	AoÃ»t	Jeudi	35	f	f	2025-10-26 17:20:46.965256
606	2026-08-28	2026	8	28	3	AoÃ»t	Vendredi	35	f	f	2025-10-26 17:20:46.965256
607	2026-08-29	2026	8	29	3	AoÃ»t	Samedi	35	t	f	2025-10-26 17:20:46.965256
608	2026-08-30	2026	8	30	3	AoÃ»t	Dimanche	35	t	f	2025-10-26 17:20:46.965256
609	2026-08-31	2026	8	31	3	AoÃ»t	Lundi	36	f	f	2025-10-26 17:20:46.965256
610	2026-09-01	2026	9	1	3	Septembre	Mardi	36	f	f	2025-10-26 17:20:46.965256
611	2026-09-02	2026	9	2	3	Septembre	Mercredi	36	f	f	2025-10-26 17:20:46.965256
612	2026-09-03	2026	9	3	3	Septembre	Jeudi	36	f	f	2025-10-26 17:20:46.965256
613	2026-09-04	2026	9	4	3	Septembre	Vendredi	36	f	f	2025-10-26 17:20:46.965256
614	2026-09-05	2026	9	5	3	Septembre	Samedi	36	t	f	2025-10-26 17:20:46.965256
615	2026-09-06	2026	9	6	3	Septembre	Dimanche	36	t	f	2025-10-26 17:20:46.965256
616	2026-09-07	2026	9	7	3	Septembre	Lundi	37	f	f	2025-10-26 17:20:46.965256
617	2026-09-08	2026	9	8	3	Septembre	Mardi	37	f	f	2025-10-26 17:20:46.965256
618	2026-09-09	2026	9	9	3	Septembre	Mercredi	37	f	f	2025-10-26 17:20:46.965256
619	2026-09-10	2026	9	10	3	Septembre	Jeudi	37	f	f	2025-10-26 17:20:46.965256
620	2026-09-11	2026	9	11	3	Septembre	Vendredi	37	f	f	2025-10-26 17:20:46.965256
621	2026-09-12	2026	9	12	3	Septembre	Samedi	37	t	f	2025-10-26 17:20:46.965256
622	2026-09-13	2026	9	13	3	Septembre	Dimanche	37	t	f	2025-10-26 17:20:46.965256
623	2026-09-14	2026	9	14	3	Septembre	Lundi	38	f	f	2025-10-26 17:20:46.965256
624	2026-09-15	2026	9	15	3	Septembre	Mardi	38	f	f	2025-10-26 17:20:46.965256
625	2026-09-16	2026	9	16	3	Septembre	Mercredi	38	f	f	2025-10-26 17:20:46.965256
626	2026-09-17	2026	9	17	3	Septembre	Jeudi	38	f	f	2025-10-26 17:20:46.965256
627	2026-09-18	2026	9	18	3	Septembre	Vendredi	38	f	f	2025-10-26 17:20:46.965256
628	2026-09-19	2026	9	19	3	Septembre	Samedi	38	t	f	2025-10-26 17:20:46.965256
629	2026-09-20	2026	9	20	3	Septembre	Dimanche	38	t	f	2025-10-26 17:20:46.965256
630	2026-09-21	2026	9	21	3	Septembre	Lundi	39	f	f	2025-10-26 17:20:46.965256
631	2026-09-22	2026	9	22	3	Septembre	Mardi	39	f	f	2025-10-26 17:20:46.965256
632	2026-09-23	2026	9	23	3	Septembre	Mercredi	39	f	f	2025-10-26 17:20:46.965256
633	2026-09-24	2026	9	24	3	Septembre	Jeudi	39	f	f	2025-10-26 17:20:46.965256
634	2026-09-25	2026	9	25	3	Septembre	Vendredi	39	f	f	2025-10-26 17:20:46.965256
635	2026-09-26	2026	9	26	3	Septembre	Samedi	39	t	f	2025-10-26 17:20:46.965256
636	2026-09-27	2026	9	27	3	Septembre	Dimanche	39	t	f	2025-10-26 17:20:46.965256
637	2026-09-28	2026	9	28	3	Septembre	Lundi	40	f	f	2025-10-26 17:20:46.965256
638	2026-09-29	2026	9	29	3	Septembre	Mardi	40	f	f	2025-10-26 17:20:46.965256
639	2026-09-30	2026	9	30	3	Septembre	Mercredi	40	f	f	2025-10-26 17:20:46.965256
640	2026-10-01	2026	10	1	4	Octobre	Jeudi	40	f	f	2025-10-26 17:20:46.965256
641	2026-10-02	2026	10	2	4	Octobre	Vendredi	40	f	f	2025-10-26 17:20:46.965256
642	2026-10-03	2026	10	3	4	Octobre	Samedi	40	t	f	2025-10-26 17:20:46.965256
643	2026-10-04	2026	10	4	4	Octobre	Dimanche	40	t	f	2025-10-26 17:20:46.965256
644	2026-10-05	2026	10	5	4	Octobre	Lundi	41	f	f	2025-10-26 17:20:46.965256
645	2026-10-06	2026	10	6	4	Octobre	Mardi	41	f	f	2025-10-26 17:20:46.965256
646	2026-10-07	2026	10	7	4	Octobre	Mercredi	41	f	f	2025-10-26 17:20:46.965256
647	2026-10-08	2026	10	8	4	Octobre	Jeudi	41	f	f	2025-10-26 17:20:46.965256
648	2026-10-09	2026	10	9	4	Octobre	Vendredi	41	f	f	2025-10-26 17:20:46.965256
649	2026-10-10	2026	10	10	4	Octobre	Samedi	41	t	f	2025-10-26 17:20:46.965256
650	2026-10-11	2026	10	11	4	Octobre	Dimanche	41	t	f	2025-10-26 17:20:46.965256
651	2026-10-12	2026	10	12	4	Octobre	Lundi	42	f	f	2025-10-26 17:20:46.965256
652	2026-10-13	2026	10	13	4	Octobre	Mardi	42	f	f	2025-10-26 17:20:46.965256
653	2026-10-14	2026	10	14	4	Octobre	Mercredi	42	f	f	2025-10-26 17:20:46.965256
654	2026-10-15	2026	10	15	4	Octobre	Jeudi	42	f	f	2025-10-26 17:20:46.965256
655	2026-10-16	2026	10	16	4	Octobre	Vendredi	42	f	f	2025-10-26 17:20:46.965256
656	2026-10-17	2026	10	17	4	Octobre	Samedi	42	t	f	2025-10-26 17:20:46.965256
657	2026-10-18	2026	10	18	4	Octobre	Dimanche	42	t	f	2025-10-26 17:20:46.965256
658	2026-10-19	2026	10	19	4	Octobre	Lundi	43	f	f	2025-10-26 17:20:46.965256
659	2026-10-20	2026	10	20	4	Octobre	Mardi	43	f	f	2025-10-26 17:20:46.965256
660	2026-10-21	2026	10	21	4	Octobre	Mercredi	43	f	f	2025-10-26 17:20:46.965256
661	2026-10-22	2026	10	22	4	Octobre	Jeudi	43	f	f	2025-10-26 17:20:46.965256
662	2026-10-23	2026	10	23	4	Octobre	Vendredi	43	f	f	2025-10-26 17:20:46.965256
663	2026-10-24	2026	10	24	4	Octobre	Samedi	43	t	f	2025-10-26 17:20:46.965256
664	2026-10-25	2026	10	25	4	Octobre	Dimanche	43	t	f	2025-10-26 17:20:46.965256
665	2026-10-26	2026	10	26	4	Octobre	Lundi	44	f	f	2025-10-26 17:20:46.965256
666	2026-10-27	2026	10	27	4	Octobre	Mardi	44	f	f	2025-10-26 17:20:46.965256
667	2026-10-28	2026	10	28	4	Octobre	Mercredi	44	f	f	2025-10-26 17:20:46.965256
668	2026-10-29	2026	10	29	4	Octobre	Jeudi	44	f	f	2025-10-26 17:20:46.965256
669	2026-10-30	2026	10	30	4	Octobre	Vendredi	44	f	f	2025-10-26 17:20:46.965256
670	2026-10-31	2026	10	31	4	Octobre	Samedi	44	t	f	2025-10-26 17:20:46.965256
671	2026-11-01	2026	11	1	4	Novembre	Dimanche	44	t	f	2025-10-26 17:20:46.965256
672	2026-11-02	2026	11	2	4	Novembre	Lundi	45	f	f	2025-10-26 17:20:46.965256
673	2026-11-03	2026	11	3	4	Novembre	Mardi	45	f	f	2025-10-26 17:20:46.965256
674	2026-11-04	2026	11	4	4	Novembre	Mercredi	45	f	f	2025-10-26 17:20:46.965256
675	2026-11-05	2026	11	5	4	Novembre	Jeudi	45	f	f	2025-10-26 17:20:46.965256
676	2026-11-06	2026	11	6	4	Novembre	Vendredi	45	f	f	2025-10-26 17:20:46.965256
677	2026-11-07	2026	11	7	4	Novembre	Samedi	45	t	f	2025-10-26 17:20:46.965256
678	2026-11-08	2026	11	8	4	Novembre	Dimanche	45	t	f	2025-10-26 17:20:46.965256
679	2026-11-09	2026	11	9	4	Novembre	Lundi	46	f	f	2025-10-26 17:20:46.965256
680	2026-11-10	2026	11	10	4	Novembre	Mardi	46	f	f	2025-10-26 17:20:46.965256
681	2026-11-11	2026	11	11	4	Novembre	Mercredi	46	f	f	2025-10-26 17:20:46.965256
682	2026-11-12	2026	11	12	4	Novembre	Jeudi	46	f	f	2025-10-26 17:20:46.965256
683	2026-11-13	2026	11	13	4	Novembre	Vendredi	46	f	f	2025-10-26 17:20:46.965256
684	2026-11-14	2026	11	14	4	Novembre	Samedi	46	t	f	2025-10-26 17:20:46.965256
685	2026-11-15	2026	11	15	4	Novembre	Dimanche	46	t	f	2025-10-26 17:20:46.965256
686	2026-11-16	2026	11	16	4	Novembre	Lundi	47	f	f	2025-10-26 17:20:46.965256
687	2026-11-17	2026	11	17	4	Novembre	Mardi	47	f	f	2025-10-26 17:20:46.965256
688	2026-11-18	2026	11	18	4	Novembre	Mercredi	47	f	f	2025-10-26 17:20:46.965256
689	2026-11-19	2026	11	19	4	Novembre	Jeudi	47	f	f	2025-10-26 17:20:46.965256
690	2026-11-20	2026	11	20	4	Novembre	Vendredi	47	f	f	2025-10-26 17:20:46.965256
691	2026-11-21	2026	11	21	4	Novembre	Samedi	47	t	f	2025-10-26 17:20:46.965256
692	2026-11-22	2026	11	22	4	Novembre	Dimanche	47	t	f	2025-10-26 17:20:46.965256
693	2026-11-23	2026	11	23	4	Novembre	Lundi	48	f	f	2025-10-26 17:20:46.965256
694	2026-11-24	2026	11	24	4	Novembre	Mardi	48	f	f	2025-10-26 17:20:46.965256
695	2026-11-25	2026	11	25	4	Novembre	Mercredi	48	f	f	2025-10-26 17:20:46.965256
696	2026-11-26	2026	11	26	4	Novembre	Jeudi	48	f	f	2025-10-26 17:20:46.965256
697	2026-11-27	2026	11	27	4	Novembre	Vendredi	48	f	f	2025-10-26 17:20:46.965256
698	2026-11-28	2026	11	28	4	Novembre	Samedi	48	t	f	2025-10-26 17:20:46.965256
699	2026-11-29	2026	11	29	4	Novembre	Dimanche	48	t	f	2025-10-26 17:20:46.965256
700	2026-11-30	2026	11	30	4	Novembre	Lundi	49	f	f	2025-10-26 17:20:46.965256
701	2026-12-01	2026	12	1	4	DÃ©cembre	Mardi	49	f	f	2025-10-26 17:20:46.965256
702	2026-12-02	2026	12	2	4	DÃ©cembre	Mercredi	49	f	f	2025-10-26 17:20:46.965256
703	2026-12-03	2026	12	3	4	DÃ©cembre	Jeudi	49	f	f	2025-10-26 17:20:46.965256
704	2026-12-04	2026	12	4	4	DÃ©cembre	Vendredi	49	f	f	2025-10-26 17:20:46.965256
705	2026-12-05	2026	12	5	4	DÃ©cembre	Samedi	49	t	f	2025-10-26 17:20:46.965256
706	2026-12-06	2026	12	6	4	DÃ©cembre	Dimanche	49	t	f	2025-10-26 17:20:46.965256
707	2026-12-07	2026	12	7	4	DÃ©cembre	Lundi	50	f	f	2025-10-26 17:20:46.965256
708	2026-12-08	2026	12	8	4	DÃ©cembre	Mardi	50	f	f	2025-10-26 17:20:46.965256
709	2026-12-09	2026	12	9	4	DÃ©cembre	Mercredi	50	f	f	2025-10-26 17:20:46.965256
710	2026-12-10	2026	12	10	4	DÃ©cembre	Jeudi	50	f	f	2025-10-26 17:20:46.965256
711	2026-12-11	2026	12	11	4	DÃ©cembre	Vendredi	50	f	f	2025-10-26 17:20:46.965256
712	2026-12-12	2026	12	12	4	DÃ©cembre	Samedi	50	t	f	2025-10-26 17:20:46.965256
713	2026-12-13	2026	12	13	4	DÃ©cembre	Dimanche	50	t	f	2025-10-26 17:20:46.965256
714	2026-12-14	2026	12	14	4	DÃ©cembre	Lundi	51	f	f	2025-10-26 17:20:46.965256
715	2026-12-15	2026	12	15	4	DÃ©cembre	Mardi	51	f	f	2025-10-26 17:20:46.965256
716	2026-12-16	2026	12	16	4	DÃ©cembre	Mercredi	51	f	f	2025-10-26 17:20:46.965256
717	2026-12-17	2026	12	17	4	DÃ©cembre	Jeudi	51	f	f	2025-10-26 17:20:46.965256
718	2026-12-18	2026	12	18	4	DÃ©cembre	Vendredi	51	f	f	2025-10-26 17:20:46.965256
719	2026-12-19	2026	12	19	4	DÃ©cembre	Samedi	51	t	f	2025-10-26 17:20:46.965256
720	2026-12-20	2026	12	20	4	DÃ©cembre	Dimanche	51	t	f	2025-10-26 17:20:46.965256
721	2026-12-21	2026	12	21	4	DÃ©cembre	Lundi	52	f	f	2025-10-26 17:20:46.965256
722	2026-12-22	2026	12	22	4	DÃ©cembre	Mardi	52	f	f	2025-10-26 17:20:46.965256
723	2026-12-23	2026	12	23	4	DÃ©cembre	Mercredi	52	f	f	2025-10-26 17:20:46.965256
724	2026-12-24	2026	12	24	4	DÃ©cembre	Jeudi	52	f	f	2025-10-26 17:20:46.965256
725	2026-12-25	2026	12	25	4	DÃ©cembre	Vendredi	52	f	f	2025-10-26 17:20:46.965256
726	2026-12-26	2026	12	26	4	DÃ©cembre	Samedi	52	t	f	2025-10-26 17:20:46.965256
727	2026-12-27	2026	12	27	4	DÃ©cembre	Dimanche	52	t	f	2025-10-26 17:20:46.965256
728	2026-12-28	2026	12	28	4	DÃ©cembre	Lundi	53	f	f	2025-10-26 17:20:46.965256
729	2026-12-29	2026	12	29	4	DÃ©cembre	Mardi	53	f	f	2025-10-26 17:20:46.965256
730	2026-12-30	2026	12	30	4	DÃ©cembre	Mercredi	53	f	f	2025-10-26 17:20:46.965256
731	2026-12-31	2026	12	31	4	DÃ©cembre	Jeudi	53	f	f	2025-10-26 17:20:46.965256
732	2027-01-01	2027	1	1	1	Janvier	Vendredi	53	f	f	2025-10-26 17:20:46.965256
733	2027-01-02	2027	1	2	1	Janvier	Samedi	53	t	f	2025-10-26 17:20:46.965256
734	2027-01-03	2027	1	3	1	Janvier	Dimanche	53	t	f	2025-10-26 17:20:46.965256
735	2027-01-04	2027	1	4	1	Janvier	Lundi	1	f	f	2025-10-26 17:20:46.965256
736	2027-01-05	2027	1	5	1	Janvier	Mardi	1	f	f	2025-10-26 17:20:46.965256
737	2027-01-06	2027	1	6	1	Janvier	Mercredi	1	f	f	2025-10-26 17:20:46.965256
738	2027-01-07	2027	1	7	1	Janvier	Jeudi	1	f	f	2025-10-26 17:20:46.965256
739	2027-01-08	2027	1	8	1	Janvier	Vendredi	1	f	f	2025-10-26 17:20:46.965256
740	2027-01-09	2027	1	9	1	Janvier	Samedi	1	t	f	2025-10-26 17:20:46.965256
741	2027-01-10	2027	1	10	1	Janvier	Dimanche	1	t	f	2025-10-26 17:20:46.965256
742	2027-01-11	2027	1	11	1	Janvier	Lundi	2	f	f	2025-10-26 17:20:46.965256
743	2027-01-12	2027	1	12	1	Janvier	Mardi	2	f	f	2025-10-26 17:20:46.965256
744	2027-01-13	2027	1	13	1	Janvier	Mercredi	2	f	f	2025-10-26 17:20:46.965256
745	2027-01-14	2027	1	14	1	Janvier	Jeudi	2	f	f	2025-10-26 17:20:46.965256
746	2027-01-15	2027	1	15	1	Janvier	Vendredi	2	f	f	2025-10-26 17:20:46.965256
747	2027-01-16	2027	1	16	1	Janvier	Samedi	2	t	f	2025-10-26 17:20:46.965256
748	2027-01-17	2027	1	17	1	Janvier	Dimanche	2	t	f	2025-10-26 17:20:46.965256
749	2027-01-18	2027	1	18	1	Janvier	Lundi	3	f	f	2025-10-26 17:20:46.965256
750	2027-01-19	2027	1	19	1	Janvier	Mardi	3	f	f	2025-10-26 17:20:46.965256
751	2027-01-20	2027	1	20	1	Janvier	Mercredi	3	f	f	2025-10-26 17:20:46.965256
752	2027-01-21	2027	1	21	1	Janvier	Jeudi	3	f	f	2025-10-26 17:20:46.965256
753	2027-01-22	2027	1	22	1	Janvier	Vendredi	3	f	f	2025-10-26 17:20:46.965256
754	2027-01-23	2027	1	23	1	Janvier	Samedi	3	t	f	2025-10-26 17:20:46.965256
755	2027-01-24	2027	1	24	1	Janvier	Dimanche	3	t	f	2025-10-26 17:20:46.965256
756	2027-01-25	2027	1	25	1	Janvier	Lundi	4	f	f	2025-10-26 17:20:46.965256
757	2027-01-26	2027	1	26	1	Janvier	Mardi	4	f	f	2025-10-26 17:20:46.965256
758	2027-01-27	2027	1	27	1	Janvier	Mercredi	4	f	f	2025-10-26 17:20:46.965256
759	2027-01-28	2027	1	28	1	Janvier	Jeudi	4	f	f	2025-10-26 17:20:46.965256
760	2027-01-29	2027	1	29	1	Janvier	Vendredi	4	f	f	2025-10-26 17:20:46.965256
761	2027-01-30	2027	1	30	1	Janvier	Samedi	4	t	f	2025-10-26 17:20:46.965256
762	2027-01-31	2027	1	31	1	Janvier	Dimanche	4	t	f	2025-10-26 17:20:46.965256
763	2027-02-01	2027	2	1	1	FÃ©vrier	Lundi	5	f	f	2025-10-26 17:20:46.965256
764	2027-02-02	2027	2	2	1	FÃ©vrier	Mardi	5	f	f	2025-10-26 17:20:46.965256
765	2027-02-03	2027	2	3	1	FÃ©vrier	Mercredi	5	f	f	2025-10-26 17:20:46.965256
766	2027-02-04	2027	2	4	1	FÃ©vrier	Jeudi	5	f	f	2025-10-26 17:20:46.965256
767	2027-02-05	2027	2	5	1	FÃ©vrier	Vendredi	5	f	f	2025-10-26 17:20:46.965256
768	2027-02-06	2027	2	6	1	FÃ©vrier	Samedi	5	t	f	2025-10-26 17:20:46.965256
769	2027-02-07	2027	2	7	1	FÃ©vrier	Dimanche	5	t	f	2025-10-26 17:20:46.965256
770	2027-02-08	2027	2	8	1	FÃ©vrier	Lundi	6	f	f	2025-10-26 17:20:46.965256
771	2027-02-09	2027	2	9	1	FÃ©vrier	Mardi	6	f	f	2025-10-26 17:20:46.965256
772	2027-02-10	2027	2	10	1	FÃ©vrier	Mercredi	6	f	f	2025-10-26 17:20:46.965256
773	2027-02-11	2027	2	11	1	FÃ©vrier	Jeudi	6	f	f	2025-10-26 17:20:46.965256
774	2027-02-12	2027	2	12	1	FÃ©vrier	Vendredi	6	f	f	2025-10-26 17:20:46.965256
775	2027-02-13	2027	2	13	1	FÃ©vrier	Samedi	6	t	f	2025-10-26 17:20:46.965256
776	2027-02-14	2027	2	14	1	FÃ©vrier	Dimanche	6	t	f	2025-10-26 17:20:46.965256
777	2027-02-15	2027	2	15	1	FÃ©vrier	Lundi	7	f	f	2025-10-26 17:20:46.965256
778	2027-02-16	2027	2	16	1	FÃ©vrier	Mardi	7	f	f	2025-10-26 17:20:46.965256
779	2027-02-17	2027	2	17	1	FÃ©vrier	Mercredi	7	f	f	2025-10-26 17:20:46.965256
780	2027-02-18	2027	2	18	1	FÃ©vrier	Jeudi	7	f	f	2025-10-26 17:20:46.965256
781	2027-02-19	2027	2	19	1	FÃ©vrier	Vendredi	7	f	f	2025-10-26 17:20:46.965256
782	2027-02-20	2027	2	20	1	FÃ©vrier	Samedi	7	t	f	2025-10-26 17:20:46.965256
783	2027-02-21	2027	2	21	1	FÃ©vrier	Dimanche	7	t	f	2025-10-26 17:20:46.965256
784	2027-02-22	2027	2	22	1	FÃ©vrier	Lundi	8	f	f	2025-10-26 17:20:46.965256
785	2027-02-23	2027	2	23	1	FÃ©vrier	Mardi	8	f	f	2025-10-26 17:20:46.965256
786	2027-02-24	2027	2	24	1	FÃ©vrier	Mercredi	8	f	f	2025-10-26 17:20:46.965256
787	2027-02-25	2027	2	25	1	FÃ©vrier	Jeudi	8	f	f	2025-10-26 17:20:46.965256
788	2027-02-26	2027	2	26	1	FÃ©vrier	Vendredi	8	f	f	2025-10-26 17:20:46.965256
789	2027-02-27	2027	2	27	1	FÃ©vrier	Samedi	8	t	f	2025-10-26 17:20:46.965256
790	2027-02-28	2027	2	28	1	FÃ©vrier	Dimanche	8	t	f	2025-10-26 17:20:46.965256
791	2027-03-01	2027	3	1	1	Mars	Lundi	9	f	f	2025-10-26 17:20:46.965256
792	2027-03-02	2027	3	2	1	Mars	Mardi	9	f	f	2025-10-26 17:20:46.965256
793	2027-03-03	2027	3	3	1	Mars	Mercredi	9	f	f	2025-10-26 17:20:46.965256
794	2027-03-04	2027	3	4	1	Mars	Jeudi	9	f	f	2025-10-26 17:20:46.965256
795	2027-03-05	2027	3	5	1	Mars	Vendredi	9	f	f	2025-10-26 17:20:46.965256
796	2027-03-06	2027	3	6	1	Mars	Samedi	9	t	f	2025-10-26 17:20:46.965256
797	2027-03-07	2027	3	7	1	Mars	Dimanche	9	t	f	2025-10-26 17:20:46.965256
798	2027-03-08	2027	3	8	1	Mars	Lundi	10	f	f	2025-10-26 17:20:46.965256
799	2027-03-09	2027	3	9	1	Mars	Mardi	10	f	f	2025-10-26 17:20:46.965256
800	2027-03-10	2027	3	10	1	Mars	Mercredi	10	f	f	2025-10-26 17:20:46.965256
801	2027-03-11	2027	3	11	1	Mars	Jeudi	10	f	f	2025-10-26 17:20:46.965256
802	2027-03-12	2027	3	12	1	Mars	Vendredi	10	f	f	2025-10-26 17:20:46.965256
803	2027-03-13	2027	3	13	1	Mars	Samedi	10	t	f	2025-10-26 17:20:46.965256
804	2027-03-14	2027	3	14	1	Mars	Dimanche	10	t	f	2025-10-26 17:20:46.965256
805	2027-03-15	2027	3	15	1	Mars	Lundi	11	f	f	2025-10-26 17:20:46.965256
806	2027-03-16	2027	3	16	1	Mars	Mardi	11	f	f	2025-10-26 17:20:46.965256
807	2027-03-17	2027	3	17	1	Mars	Mercredi	11	f	f	2025-10-26 17:20:46.965256
808	2027-03-18	2027	3	18	1	Mars	Jeudi	11	f	f	2025-10-26 17:20:46.965256
809	2027-03-19	2027	3	19	1	Mars	Vendredi	11	f	f	2025-10-26 17:20:46.965256
810	2027-03-20	2027	3	20	1	Mars	Samedi	11	t	f	2025-10-26 17:20:46.965256
811	2027-03-21	2027	3	21	1	Mars	Dimanche	11	t	f	2025-10-26 17:20:46.965256
812	2027-03-22	2027	3	22	1	Mars	Lundi	12	f	f	2025-10-26 17:20:46.965256
813	2027-03-23	2027	3	23	1	Mars	Mardi	12	f	f	2025-10-26 17:20:46.965256
814	2027-03-24	2027	3	24	1	Mars	Mercredi	12	f	f	2025-10-26 17:20:46.965256
815	2027-03-25	2027	3	25	1	Mars	Jeudi	12	f	f	2025-10-26 17:20:46.965256
816	2027-03-26	2027	3	26	1	Mars	Vendredi	12	f	f	2025-10-26 17:20:46.965256
817	2027-03-27	2027	3	27	1	Mars	Samedi	12	t	f	2025-10-26 17:20:46.965256
818	2027-03-28	2027	3	28	1	Mars	Dimanche	12	t	f	2025-10-26 17:20:46.965256
819	2027-03-29	2027	3	29	1	Mars	Lundi	13	f	f	2025-10-26 17:20:46.965256
820	2027-03-30	2027	3	30	1	Mars	Mardi	13	f	f	2025-10-26 17:20:46.965256
821	2027-03-31	2027	3	31	1	Mars	Mercredi	13	f	f	2025-10-26 17:20:46.965256
822	2027-04-01	2027	4	1	2	Avril	Jeudi	13	f	f	2025-10-26 17:20:46.965256
823	2027-04-02	2027	4	2	2	Avril	Vendredi	13	f	f	2025-10-26 17:20:46.965256
824	2027-04-03	2027	4	3	2	Avril	Samedi	13	t	f	2025-10-26 17:20:46.965256
825	2027-04-04	2027	4	4	2	Avril	Dimanche	13	t	f	2025-10-26 17:20:46.965256
826	2027-04-05	2027	4	5	2	Avril	Lundi	14	f	f	2025-10-26 17:20:46.965256
827	2027-04-06	2027	4	6	2	Avril	Mardi	14	f	f	2025-10-26 17:20:46.965256
828	2027-04-07	2027	4	7	2	Avril	Mercredi	14	f	f	2025-10-26 17:20:46.965256
829	2027-04-08	2027	4	8	2	Avril	Jeudi	14	f	f	2025-10-26 17:20:46.965256
830	2027-04-09	2027	4	9	2	Avril	Vendredi	14	f	f	2025-10-26 17:20:46.965256
831	2027-04-10	2027	4	10	2	Avril	Samedi	14	t	f	2025-10-26 17:20:46.965256
832	2027-04-11	2027	4	11	2	Avril	Dimanche	14	t	f	2025-10-26 17:20:46.965256
833	2027-04-12	2027	4	12	2	Avril	Lundi	15	f	f	2025-10-26 17:20:46.965256
834	2027-04-13	2027	4	13	2	Avril	Mardi	15	f	f	2025-10-26 17:20:46.965256
835	2027-04-14	2027	4	14	2	Avril	Mercredi	15	f	f	2025-10-26 17:20:46.965256
836	2027-04-15	2027	4	15	2	Avril	Jeudi	15	f	f	2025-10-26 17:20:46.965256
837	2027-04-16	2027	4	16	2	Avril	Vendredi	15	f	f	2025-10-26 17:20:46.965256
838	2027-04-17	2027	4	17	2	Avril	Samedi	15	t	f	2025-10-26 17:20:46.965256
839	2027-04-18	2027	4	18	2	Avril	Dimanche	15	t	f	2025-10-26 17:20:46.965256
840	2027-04-19	2027	4	19	2	Avril	Lundi	16	f	f	2025-10-26 17:20:46.965256
841	2027-04-20	2027	4	20	2	Avril	Mardi	16	f	f	2025-10-26 17:20:46.965256
842	2027-04-21	2027	4	21	2	Avril	Mercredi	16	f	f	2025-10-26 17:20:46.965256
843	2027-04-22	2027	4	22	2	Avril	Jeudi	16	f	f	2025-10-26 17:20:46.965256
844	2027-04-23	2027	4	23	2	Avril	Vendredi	16	f	f	2025-10-26 17:20:46.965256
845	2027-04-24	2027	4	24	2	Avril	Samedi	16	t	f	2025-10-26 17:20:46.965256
846	2027-04-25	2027	4	25	2	Avril	Dimanche	16	t	f	2025-10-26 17:20:46.965256
847	2027-04-26	2027	4	26	2	Avril	Lundi	17	f	f	2025-10-26 17:20:46.965256
848	2027-04-27	2027	4	27	2	Avril	Mardi	17	f	f	2025-10-26 17:20:46.965256
849	2027-04-28	2027	4	28	2	Avril	Mercredi	17	f	f	2025-10-26 17:20:46.965256
850	2027-04-29	2027	4	29	2	Avril	Jeudi	17	f	f	2025-10-26 17:20:46.965256
851	2027-04-30	2027	4	30	2	Avril	Vendredi	17	f	f	2025-10-26 17:20:46.965256
852	2027-05-01	2027	5	1	2	Mai	Samedi	17	t	f	2025-10-26 17:20:46.965256
853	2027-05-02	2027	5	2	2	Mai	Dimanche	17	t	f	2025-10-26 17:20:46.965256
854	2027-05-03	2027	5	3	2	Mai	Lundi	18	f	f	2025-10-26 17:20:46.965256
855	2027-05-04	2027	5	4	2	Mai	Mardi	18	f	f	2025-10-26 17:20:46.965256
856	2027-05-05	2027	5	5	2	Mai	Mercredi	18	f	f	2025-10-26 17:20:46.965256
857	2027-05-06	2027	5	6	2	Mai	Jeudi	18	f	f	2025-10-26 17:20:46.965256
858	2027-05-07	2027	5	7	2	Mai	Vendredi	18	f	f	2025-10-26 17:20:46.965256
859	2027-05-08	2027	5	8	2	Mai	Samedi	18	t	f	2025-10-26 17:20:46.965256
860	2027-05-09	2027	5	9	2	Mai	Dimanche	18	t	f	2025-10-26 17:20:46.965256
861	2027-05-10	2027	5	10	2	Mai	Lundi	19	f	f	2025-10-26 17:20:46.965256
862	2027-05-11	2027	5	11	2	Mai	Mardi	19	f	f	2025-10-26 17:20:46.965256
863	2027-05-12	2027	5	12	2	Mai	Mercredi	19	f	f	2025-10-26 17:20:46.965256
864	2027-05-13	2027	5	13	2	Mai	Jeudi	19	f	f	2025-10-26 17:20:46.965256
865	2027-05-14	2027	5	14	2	Mai	Vendredi	19	f	f	2025-10-26 17:20:46.965256
866	2027-05-15	2027	5	15	2	Mai	Samedi	19	t	f	2025-10-26 17:20:46.965256
867	2027-05-16	2027	5	16	2	Mai	Dimanche	19	t	f	2025-10-26 17:20:46.965256
868	2027-05-17	2027	5	17	2	Mai	Lundi	20	f	f	2025-10-26 17:20:46.965256
869	2027-05-18	2027	5	18	2	Mai	Mardi	20	f	f	2025-10-26 17:20:46.965256
870	2027-05-19	2027	5	19	2	Mai	Mercredi	20	f	f	2025-10-26 17:20:46.965256
871	2027-05-20	2027	5	20	2	Mai	Jeudi	20	f	f	2025-10-26 17:20:46.965256
872	2027-05-21	2027	5	21	2	Mai	Vendredi	20	f	f	2025-10-26 17:20:46.965256
873	2027-05-22	2027	5	22	2	Mai	Samedi	20	t	f	2025-10-26 17:20:46.965256
874	2027-05-23	2027	5	23	2	Mai	Dimanche	20	t	f	2025-10-26 17:20:46.965256
875	2027-05-24	2027	5	24	2	Mai	Lundi	21	f	f	2025-10-26 17:20:46.965256
876	2027-05-25	2027	5	25	2	Mai	Mardi	21	f	f	2025-10-26 17:20:46.965256
877	2027-05-26	2027	5	26	2	Mai	Mercredi	21	f	f	2025-10-26 17:20:46.965256
878	2027-05-27	2027	5	27	2	Mai	Jeudi	21	f	f	2025-10-26 17:20:46.965256
879	2027-05-28	2027	5	28	2	Mai	Vendredi	21	f	f	2025-10-26 17:20:46.965256
880	2027-05-29	2027	5	29	2	Mai	Samedi	21	t	f	2025-10-26 17:20:46.965256
881	2027-05-30	2027	5	30	2	Mai	Dimanche	21	t	f	2025-10-26 17:20:46.965256
882	2027-05-31	2027	5	31	2	Mai	Lundi	22	f	f	2025-10-26 17:20:46.965256
883	2027-06-01	2027	6	1	2	Juin	Mardi	22	f	f	2025-10-26 17:20:46.965256
884	2027-06-02	2027	6	2	2	Juin	Mercredi	22	f	f	2025-10-26 17:20:46.965256
885	2027-06-03	2027	6	3	2	Juin	Jeudi	22	f	f	2025-10-26 17:20:46.965256
886	2027-06-04	2027	6	4	2	Juin	Vendredi	22	f	f	2025-10-26 17:20:46.965256
887	2027-06-05	2027	6	5	2	Juin	Samedi	22	t	f	2025-10-26 17:20:46.965256
888	2027-06-06	2027	6	6	2	Juin	Dimanche	22	t	f	2025-10-26 17:20:46.965256
889	2027-06-07	2027	6	7	2	Juin	Lundi	23	f	f	2025-10-26 17:20:46.965256
890	2027-06-08	2027	6	8	2	Juin	Mardi	23	f	f	2025-10-26 17:20:46.965256
891	2027-06-09	2027	6	9	2	Juin	Mercredi	23	f	f	2025-10-26 17:20:46.965256
892	2027-06-10	2027	6	10	2	Juin	Jeudi	23	f	f	2025-10-26 17:20:46.965256
893	2027-06-11	2027	6	11	2	Juin	Vendredi	23	f	f	2025-10-26 17:20:46.965256
894	2027-06-12	2027	6	12	2	Juin	Samedi	23	t	f	2025-10-26 17:20:46.965256
895	2027-06-13	2027	6	13	2	Juin	Dimanche	23	t	f	2025-10-26 17:20:46.965256
896	2027-06-14	2027	6	14	2	Juin	Lundi	24	f	f	2025-10-26 17:20:46.965256
897	2027-06-15	2027	6	15	2	Juin	Mardi	24	f	f	2025-10-26 17:20:46.965256
898	2027-06-16	2027	6	16	2	Juin	Mercredi	24	f	f	2025-10-26 17:20:46.965256
899	2027-06-17	2027	6	17	2	Juin	Jeudi	24	f	f	2025-10-26 17:20:46.965256
900	2027-06-18	2027	6	18	2	Juin	Vendredi	24	f	f	2025-10-26 17:20:46.965256
901	2027-06-19	2027	6	19	2	Juin	Samedi	24	t	f	2025-10-26 17:20:46.965256
902	2027-06-20	2027	6	20	2	Juin	Dimanche	24	t	f	2025-10-26 17:20:46.965256
903	2027-06-21	2027	6	21	2	Juin	Lundi	25	f	f	2025-10-26 17:20:46.965256
904	2027-06-22	2027	6	22	2	Juin	Mardi	25	f	f	2025-10-26 17:20:46.965256
905	2027-06-23	2027	6	23	2	Juin	Mercredi	25	f	f	2025-10-26 17:20:46.965256
906	2027-06-24	2027	6	24	2	Juin	Jeudi	25	f	f	2025-10-26 17:20:46.965256
907	2027-06-25	2027	6	25	2	Juin	Vendredi	25	f	f	2025-10-26 17:20:46.965256
908	2027-06-26	2027	6	26	2	Juin	Samedi	25	t	f	2025-10-26 17:20:46.965256
909	2027-06-27	2027	6	27	2	Juin	Dimanche	25	t	f	2025-10-26 17:20:46.965256
910	2027-06-28	2027	6	28	2	Juin	Lundi	26	f	f	2025-10-26 17:20:46.965256
911	2027-06-29	2027	6	29	2	Juin	Mardi	26	f	f	2025-10-26 17:20:46.965256
912	2027-06-30	2027	6	30	2	Juin	Mercredi	26	f	f	2025-10-26 17:20:46.965256
913	2027-07-01	2027	7	1	3	Juillet	Jeudi	26	f	f	2025-10-26 17:20:46.965256
914	2027-07-02	2027	7	2	3	Juillet	Vendredi	26	f	f	2025-10-26 17:20:46.965256
915	2027-07-03	2027	7	3	3	Juillet	Samedi	26	t	f	2025-10-26 17:20:46.965256
916	2027-07-04	2027	7	4	3	Juillet	Dimanche	26	t	f	2025-10-26 17:20:46.965256
917	2027-07-05	2027	7	5	3	Juillet	Lundi	27	f	f	2025-10-26 17:20:46.965256
918	2027-07-06	2027	7	6	3	Juillet	Mardi	27	f	f	2025-10-26 17:20:46.965256
919	2027-07-07	2027	7	7	3	Juillet	Mercredi	27	f	f	2025-10-26 17:20:46.965256
920	2027-07-08	2027	7	8	3	Juillet	Jeudi	27	f	f	2025-10-26 17:20:46.965256
921	2027-07-09	2027	7	9	3	Juillet	Vendredi	27	f	f	2025-10-26 17:20:46.965256
922	2027-07-10	2027	7	10	3	Juillet	Samedi	27	t	f	2025-10-26 17:20:46.965256
923	2027-07-11	2027	7	11	3	Juillet	Dimanche	27	t	f	2025-10-26 17:20:46.965256
924	2027-07-12	2027	7	12	3	Juillet	Lundi	28	f	f	2025-10-26 17:20:46.965256
925	2027-07-13	2027	7	13	3	Juillet	Mardi	28	f	f	2025-10-26 17:20:46.965256
926	2027-07-14	2027	7	14	3	Juillet	Mercredi	28	f	f	2025-10-26 17:20:46.965256
927	2027-07-15	2027	7	15	3	Juillet	Jeudi	28	f	f	2025-10-26 17:20:46.965256
928	2027-07-16	2027	7	16	3	Juillet	Vendredi	28	f	f	2025-10-26 17:20:46.965256
929	2027-07-17	2027	7	17	3	Juillet	Samedi	28	t	f	2025-10-26 17:20:46.965256
930	2027-07-18	2027	7	18	3	Juillet	Dimanche	28	t	f	2025-10-26 17:20:46.965256
931	2027-07-19	2027	7	19	3	Juillet	Lundi	29	f	f	2025-10-26 17:20:46.965256
932	2027-07-20	2027	7	20	3	Juillet	Mardi	29	f	f	2025-10-26 17:20:46.965256
933	2027-07-21	2027	7	21	3	Juillet	Mercredi	29	f	f	2025-10-26 17:20:46.965256
934	2027-07-22	2027	7	22	3	Juillet	Jeudi	29	f	f	2025-10-26 17:20:46.965256
935	2027-07-23	2027	7	23	3	Juillet	Vendredi	29	f	f	2025-10-26 17:20:46.965256
936	2027-07-24	2027	7	24	3	Juillet	Samedi	29	t	f	2025-10-26 17:20:46.965256
937	2027-07-25	2027	7	25	3	Juillet	Dimanche	29	t	f	2025-10-26 17:20:46.965256
938	2027-07-26	2027	7	26	3	Juillet	Lundi	30	f	f	2025-10-26 17:20:46.965256
939	2027-07-27	2027	7	27	3	Juillet	Mardi	30	f	f	2025-10-26 17:20:46.965256
940	2027-07-28	2027	7	28	3	Juillet	Mercredi	30	f	f	2025-10-26 17:20:46.965256
941	2027-07-29	2027	7	29	3	Juillet	Jeudi	30	f	f	2025-10-26 17:20:46.965256
942	2027-07-30	2027	7	30	3	Juillet	Vendredi	30	f	f	2025-10-26 17:20:46.965256
943	2027-07-31	2027	7	31	3	Juillet	Samedi	30	t	f	2025-10-26 17:20:46.965256
944	2027-08-01	2027	8	1	3	AoÃ»t	Dimanche	30	t	f	2025-10-26 17:20:46.965256
945	2027-08-02	2027	8	2	3	AoÃ»t	Lundi	31	f	f	2025-10-26 17:20:46.965256
946	2027-08-03	2027	8	3	3	AoÃ»t	Mardi	31	f	f	2025-10-26 17:20:46.965256
947	2027-08-04	2027	8	4	3	AoÃ»t	Mercredi	31	f	f	2025-10-26 17:20:46.965256
948	2027-08-05	2027	8	5	3	AoÃ»t	Jeudi	31	f	f	2025-10-26 17:20:46.965256
949	2027-08-06	2027	8	6	3	AoÃ»t	Vendredi	31	f	f	2025-10-26 17:20:46.965256
950	2027-08-07	2027	8	7	3	AoÃ»t	Samedi	31	t	f	2025-10-26 17:20:46.965256
951	2027-08-08	2027	8	8	3	AoÃ»t	Dimanche	31	t	f	2025-10-26 17:20:46.965256
952	2027-08-09	2027	8	9	3	AoÃ»t	Lundi	32	f	f	2025-10-26 17:20:46.965256
953	2027-08-10	2027	8	10	3	AoÃ»t	Mardi	32	f	f	2025-10-26 17:20:46.965256
954	2027-08-11	2027	8	11	3	AoÃ»t	Mercredi	32	f	f	2025-10-26 17:20:46.965256
955	2027-08-12	2027	8	12	3	AoÃ»t	Jeudi	32	f	f	2025-10-26 17:20:46.965256
956	2027-08-13	2027	8	13	3	AoÃ»t	Vendredi	32	f	f	2025-10-26 17:20:46.965256
957	2027-08-14	2027	8	14	3	AoÃ»t	Samedi	32	t	f	2025-10-26 17:20:46.965256
958	2027-08-15	2027	8	15	3	AoÃ»t	Dimanche	32	t	f	2025-10-26 17:20:46.965256
959	2027-08-16	2027	8	16	3	AoÃ»t	Lundi	33	f	f	2025-10-26 17:20:46.965256
960	2027-08-17	2027	8	17	3	AoÃ»t	Mardi	33	f	f	2025-10-26 17:20:46.965256
961	2027-08-18	2027	8	18	3	AoÃ»t	Mercredi	33	f	f	2025-10-26 17:20:46.965256
962	2027-08-19	2027	8	19	3	AoÃ»t	Jeudi	33	f	f	2025-10-26 17:20:46.965256
963	2027-08-20	2027	8	20	3	AoÃ»t	Vendredi	33	f	f	2025-10-26 17:20:46.965256
964	2027-08-21	2027	8	21	3	AoÃ»t	Samedi	33	t	f	2025-10-26 17:20:46.965256
965	2027-08-22	2027	8	22	3	AoÃ»t	Dimanche	33	t	f	2025-10-26 17:20:46.965256
966	2027-08-23	2027	8	23	3	AoÃ»t	Lundi	34	f	f	2025-10-26 17:20:46.965256
967	2027-08-24	2027	8	24	3	AoÃ»t	Mardi	34	f	f	2025-10-26 17:20:46.965256
968	2027-08-25	2027	8	25	3	AoÃ»t	Mercredi	34	f	f	2025-10-26 17:20:46.965256
969	2027-08-26	2027	8	26	3	AoÃ»t	Jeudi	34	f	f	2025-10-26 17:20:46.965256
970	2027-08-27	2027	8	27	3	AoÃ»t	Vendredi	34	f	f	2025-10-26 17:20:46.965256
971	2027-08-28	2027	8	28	3	AoÃ»t	Samedi	34	t	f	2025-10-26 17:20:46.965256
972	2027-08-29	2027	8	29	3	AoÃ»t	Dimanche	34	t	f	2025-10-26 17:20:46.965256
973	2027-08-30	2027	8	30	3	AoÃ»t	Lundi	35	f	f	2025-10-26 17:20:46.965256
974	2027-08-31	2027	8	31	3	AoÃ»t	Mardi	35	f	f	2025-10-26 17:20:46.965256
975	2027-09-01	2027	9	1	3	Septembre	Mercredi	35	f	f	2025-10-26 17:20:46.965256
976	2027-09-02	2027	9	2	3	Septembre	Jeudi	35	f	f	2025-10-26 17:20:46.965256
977	2027-09-03	2027	9	3	3	Septembre	Vendredi	35	f	f	2025-10-26 17:20:46.965256
978	2027-09-04	2027	9	4	3	Septembre	Samedi	35	t	f	2025-10-26 17:20:46.965256
979	2027-09-05	2027	9	5	3	Septembre	Dimanche	35	t	f	2025-10-26 17:20:46.965256
980	2027-09-06	2027	9	6	3	Septembre	Lundi	36	f	f	2025-10-26 17:20:46.965256
981	2027-09-07	2027	9	7	3	Septembre	Mardi	36	f	f	2025-10-26 17:20:46.965256
982	2027-09-08	2027	9	8	3	Septembre	Mercredi	36	f	f	2025-10-26 17:20:46.965256
983	2027-09-09	2027	9	9	3	Septembre	Jeudi	36	f	f	2025-10-26 17:20:46.965256
984	2027-09-10	2027	9	10	3	Septembre	Vendredi	36	f	f	2025-10-26 17:20:46.965256
985	2027-09-11	2027	9	11	3	Septembre	Samedi	36	t	f	2025-10-26 17:20:46.965256
986	2027-09-12	2027	9	12	3	Septembre	Dimanche	36	t	f	2025-10-26 17:20:46.965256
987	2027-09-13	2027	9	13	3	Septembre	Lundi	37	f	f	2025-10-26 17:20:46.965256
988	2027-09-14	2027	9	14	3	Septembre	Mardi	37	f	f	2025-10-26 17:20:46.965256
989	2027-09-15	2027	9	15	3	Septembre	Mercredi	37	f	f	2025-10-26 17:20:46.965256
990	2027-09-16	2027	9	16	3	Septembre	Jeudi	37	f	f	2025-10-26 17:20:46.965256
991	2027-09-17	2027	9	17	3	Septembre	Vendredi	37	f	f	2025-10-26 17:20:46.965256
992	2027-09-18	2027	9	18	3	Septembre	Samedi	37	t	f	2025-10-26 17:20:46.965256
993	2027-09-19	2027	9	19	3	Septembre	Dimanche	37	t	f	2025-10-26 17:20:46.965256
994	2027-09-20	2027	9	20	3	Septembre	Lundi	38	f	f	2025-10-26 17:20:46.965256
995	2027-09-21	2027	9	21	3	Septembre	Mardi	38	f	f	2025-10-26 17:20:46.965256
996	2027-09-22	2027	9	22	3	Septembre	Mercredi	38	f	f	2025-10-26 17:20:46.965256
997	2027-09-23	2027	9	23	3	Septembre	Jeudi	38	f	f	2025-10-26 17:20:46.965256
998	2027-09-24	2027	9	24	3	Septembre	Vendredi	38	f	f	2025-10-26 17:20:46.965256
999	2027-09-25	2027	9	25	3	Septembre	Samedi	38	t	f	2025-10-26 17:20:46.965256
1000	2027-09-26	2027	9	26	3	Septembre	Dimanche	38	t	f	2025-10-26 17:20:46.965256
1001	2027-09-27	2027	9	27	3	Septembre	Lundi	39	f	f	2025-10-26 17:20:46.965256
1002	2027-09-28	2027	9	28	3	Septembre	Mardi	39	f	f	2025-10-26 17:20:46.965256
1003	2027-09-29	2027	9	29	3	Septembre	Mercredi	39	f	f	2025-10-26 17:20:46.965256
1004	2027-09-30	2027	9	30	3	Septembre	Jeudi	39	f	f	2025-10-26 17:20:46.965256
1005	2027-10-01	2027	10	1	4	Octobre	Vendredi	39	f	f	2025-10-26 17:20:46.965256
1006	2027-10-02	2027	10	2	4	Octobre	Samedi	39	t	f	2025-10-26 17:20:46.965256
1007	2027-10-03	2027	10	3	4	Octobre	Dimanche	39	t	f	2025-10-26 17:20:46.965256
1008	2027-10-04	2027	10	4	4	Octobre	Lundi	40	f	f	2025-10-26 17:20:46.965256
1009	2027-10-05	2027	10	5	4	Octobre	Mardi	40	f	f	2025-10-26 17:20:46.965256
1010	2027-10-06	2027	10	6	4	Octobre	Mercredi	40	f	f	2025-10-26 17:20:46.965256
1011	2027-10-07	2027	10	7	4	Octobre	Jeudi	40	f	f	2025-10-26 17:20:46.965256
1012	2027-10-08	2027	10	8	4	Octobre	Vendredi	40	f	f	2025-10-26 17:20:46.965256
1013	2027-10-09	2027	10	9	4	Octobre	Samedi	40	t	f	2025-10-26 17:20:46.965256
1014	2027-10-10	2027	10	10	4	Octobre	Dimanche	40	t	f	2025-10-26 17:20:46.965256
1015	2027-10-11	2027	10	11	4	Octobre	Lundi	41	f	f	2025-10-26 17:20:46.965256
1016	2027-10-12	2027	10	12	4	Octobre	Mardi	41	f	f	2025-10-26 17:20:46.965256
1017	2027-10-13	2027	10	13	4	Octobre	Mercredi	41	f	f	2025-10-26 17:20:46.965256
1018	2027-10-14	2027	10	14	4	Octobre	Jeudi	41	f	f	2025-10-26 17:20:46.965256
1019	2027-10-15	2027	10	15	4	Octobre	Vendredi	41	f	f	2025-10-26 17:20:46.965256
1020	2027-10-16	2027	10	16	4	Octobre	Samedi	41	t	f	2025-10-26 17:20:46.965256
1021	2027-10-17	2027	10	17	4	Octobre	Dimanche	41	t	f	2025-10-26 17:20:46.965256
1022	2027-10-18	2027	10	18	4	Octobre	Lundi	42	f	f	2025-10-26 17:20:46.965256
1023	2027-10-19	2027	10	19	4	Octobre	Mardi	42	f	f	2025-10-26 17:20:46.965256
1024	2027-10-20	2027	10	20	4	Octobre	Mercredi	42	f	f	2025-10-26 17:20:46.965256
1025	2027-10-21	2027	10	21	4	Octobre	Jeudi	42	f	f	2025-10-26 17:20:46.965256
1026	2027-10-22	2027	10	22	4	Octobre	Vendredi	42	f	f	2025-10-26 17:20:46.965256
1027	2027-10-23	2027	10	23	4	Octobre	Samedi	42	t	f	2025-10-26 17:20:46.965256
1028	2027-10-24	2027	10	24	4	Octobre	Dimanche	42	t	f	2025-10-26 17:20:46.965256
1029	2027-10-25	2027	10	25	4	Octobre	Lundi	43	f	f	2025-10-26 17:20:46.965256
1030	2027-10-26	2027	10	26	4	Octobre	Mardi	43	f	f	2025-10-26 17:20:46.965256
1031	2027-10-27	2027	10	27	4	Octobre	Mercredi	43	f	f	2025-10-26 17:20:46.965256
1032	2027-10-28	2027	10	28	4	Octobre	Jeudi	43	f	f	2025-10-26 17:20:46.965256
1033	2027-10-29	2027	10	29	4	Octobre	Vendredi	43	f	f	2025-10-26 17:20:46.965256
1034	2027-10-30	2027	10	30	4	Octobre	Samedi	43	t	f	2025-10-26 17:20:46.965256
1035	2027-10-31	2027	10	31	4	Octobre	Dimanche	43	t	f	2025-10-26 17:20:46.965256
1036	2027-11-01	2027	11	1	4	Novembre	Lundi	44	f	f	2025-10-26 17:20:46.965256
1037	2027-11-02	2027	11	2	4	Novembre	Mardi	44	f	f	2025-10-26 17:20:46.965256
1038	2027-11-03	2027	11	3	4	Novembre	Mercredi	44	f	f	2025-10-26 17:20:46.965256
1039	2027-11-04	2027	11	4	4	Novembre	Jeudi	44	f	f	2025-10-26 17:20:46.965256
1040	2027-11-05	2027	11	5	4	Novembre	Vendredi	44	f	f	2025-10-26 17:20:46.965256
1041	2027-11-06	2027	11	6	4	Novembre	Samedi	44	t	f	2025-10-26 17:20:46.965256
1042	2027-11-07	2027	11	7	4	Novembre	Dimanche	44	t	f	2025-10-26 17:20:46.965256
1043	2027-11-08	2027	11	8	4	Novembre	Lundi	45	f	f	2025-10-26 17:20:46.965256
1044	2027-11-09	2027	11	9	4	Novembre	Mardi	45	f	f	2025-10-26 17:20:46.965256
1045	2027-11-10	2027	11	10	4	Novembre	Mercredi	45	f	f	2025-10-26 17:20:46.965256
1046	2027-11-11	2027	11	11	4	Novembre	Jeudi	45	f	f	2025-10-26 17:20:46.965256
1047	2027-11-12	2027	11	12	4	Novembre	Vendredi	45	f	f	2025-10-26 17:20:46.965256
1048	2027-11-13	2027	11	13	4	Novembre	Samedi	45	t	f	2025-10-26 17:20:46.965256
1049	2027-11-14	2027	11	14	4	Novembre	Dimanche	45	t	f	2025-10-26 17:20:46.965256
1050	2027-11-15	2027	11	15	4	Novembre	Lundi	46	f	f	2025-10-26 17:20:46.965256
1051	2027-11-16	2027	11	16	4	Novembre	Mardi	46	f	f	2025-10-26 17:20:46.965256
1052	2027-11-17	2027	11	17	4	Novembre	Mercredi	46	f	f	2025-10-26 17:20:46.965256
1053	2027-11-18	2027	11	18	4	Novembre	Jeudi	46	f	f	2025-10-26 17:20:46.965256
1054	2027-11-19	2027	11	19	4	Novembre	Vendredi	46	f	f	2025-10-26 17:20:46.965256
1055	2027-11-20	2027	11	20	4	Novembre	Samedi	46	t	f	2025-10-26 17:20:46.965256
1056	2027-11-21	2027	11	21	4	Novembre	Dimanche	46	t	f	2025-10-26 17:20:46.965256
1057	2027-11-22	2027	11	22	4	Novembre	Lundi	47	f	f	2025-10-26 17:20:46.965256
1058	2027-11-23	2027	11	23	4	Novembre	Mardi	47	f	f	2025-10-26 17:20:46.965256
1059	2027-11-24	2027	11	24	4	Novembre	Mercredi	47	f	f	2025-10-26 17:20:46.965256
1060	2027-11-25	2027	11	25	4	Novembre	Jeudi	47	f	f	2025-10-26 17:20:46.965256
1061	2027-11-26	2027	11	26	4	Novembre	Vendredi	47	f	f	2025-10-26 17:20:46.965256
1062	2027-11-27	2027	11	27	4	Novembre	Samedi	47	t	f	2025-10-26 17:20:46.965256
1063	2027-11-28	2027	11	28	4	Novembre	Dimanche	47	t	f	2025-10-26 17:20:46.965256
1064	2027-11-29	2027	11	29	4	Novembre	Lundi	48	f	f	2025-10-26 17:20:46.965256
1065	2027-11-30	2027	11	30	4	Novembre	Mardi	48	f	f	2025-10-26 17:20:46.965256
1066	2027-12-01	2027	12	1	4	DÃ©cembre	Mercredi	48	f	f	2025-10-26 17:20:46.965256
1067	2027-12-02	2027	12	2	4	DÃ©cembre	Jeudi	48	f	f	2025-10-26 17:20:46.965256
1068	2027-12-03	2027	12	3	4	DÃ©cembre	Vendredi	48	f	f	2025-10-26 17:20:46.965256
1069	2027-12-04	2027	12	4	4	DÃ©cembre	Samedi	48	t	f	2025-10-26 17:20:46.965256
1070	2027-12-05	2027	12	5	4	DÃ©cembre	Dimanche	48	t	f	2025-10-26 17:20:46.965256
1071	2027-12-06	2027	12	6	4	DÃ©cembre	Lundi	49	f	f	2025-10-26 17:20:46.965256
1072	2027-12-07	2027	12	7	4	DÃ©cembre	Mardi	49	f	f	2025-10-26 17:20:46.965256
1073	2027-12-08	2027	12	8	4	DÃ©cembre	Mercredi	49	f	f	2025-10-26 17:20:46.965256
1074	2027-12-09	2027	12	9	4	DÃ©cembre	Jeudi	49	f	f	2025-10-26 17:20:46.965256
1075	2027-12-10	2027	12	10	4	DÃ©cembre	Vendredi	49	f	f	2025-10-26 17:20:46.965256
1076	2027-12-11	2027	12	11	4	DÃ©cembre	Samedi	49	t	f	2025-10-26 17:20:46.965256
1077	2027-12-12	2027	12	12	4	DÃ©cembre	Dimanche	49	t	f	2025-10-26 17:20:46.965256
1078	2027-12-13	2027	12	13	4	DÃ©cembre	Lundi	50	f	f	2025-10-26 17:20:46.965256
1079	2027-12-14	2027	12	14	4	DÃ©cembre	Mardi	50	f	f	2025-10-26 17:20:46.965256
1080	2027-12-15	2027	12	15	4	DÃ©cembre	Mercredi	50	f	f	2025-10-26 17:20:46.965256
1081	2027-12-16	2027	12	16	4	DÃ©cembre	Jeudi	50	f	f	2025-10-26 17:20:46.965256
1082	2027-12-17	2027	12	17	4	DÃ©cembre	Vendredi	50	f	f	2025-10-26 17:20:46.965256
1083	2027-12-18	2027	12	18	4	DÃ©cembre	Samedi	50	t	f	2025-10-26 17:20:46.965256
1084	2027-12-19	2027	12	19	4	DÃ©cembre	Dimanche	50	t	f	2025-10-26 17:20:46.965256
1085	2027-12-20	2027	12	20	4	DÃ©cembre	Lundi	51	f	f	2025-10-26 17:20:46.965256
1086	2027-12-21	2027	12	21	4	DÃ©cembre	Mardi	51	f	f	2025-10-26 17:20:46.965256
1087	2027-12-22	2027	12	22	4	DÃ©cembre	Mercredi	51	f	f	2025-10-26 17:20:46.965256
1088	2027-12-23	2027	12	23	4	DÃ©cembre	Jeudi	51	f	f	2025-10-26 17:20:46.965256
1089	2027-12-24	2027	12	24	4	DÃ©cembre	Vendredi	51	f	f	2025-10-26 17:20:46.965256
1090	2027-12-25	2027	12	25	4	DÃ©cembre	Samedi	51	t	f	2025-10-26 17:20:46.965256
1091	2027-12-26	2027	12	26	4	DÃ©cembre	Dimanche	51	t	f	2025-10-26 17:20:46.965256
1092	2027-12-27	2027	12	27	4	DÃ©cembre	Lundi	52	f	f	2025-10-26 17:20:46.965256
1093	2027-12-28	2027	12	28	4	DÃ©cembre	Mardi	52	f	f	2025-10-26 17:20:46.965256
1094	2027-12-29	2027	12	29	4	DÃ©cembre	Mercredi	52	f	f	2025-10-26 17:20:46.965256
1095	2027-12-30	2027	12	30	4	DÃ©cembre	Jeudi	52	f	f	2025-10-26 17:20:46.965256
1096	2027-12-31	2027	12	31	4	DÃ©cembre	Vendredi	52	f	f	2025-10-26 17:20:46.965256
\.


--
-- Data for Name: dim_zones_industrielles; Type: TABLE DATA; Schema: dwh; Owner: postgres
--

COPY dwh.dim_zones_industrielles (zone_key, zone_id, nom_zone, localisation, superficie_totale, nb_lots_total, statut_zone, date_creation_zone, responsable_zone, date_creation, date_modification) FROM stdin;
1	1	Zone Industrielle de Vridi	Abidjan	120.00	132	actif	\N	\N	2025-10-26 14:01:41.639845	2025-10-26 14:01:41.639845
2	2	Zone Industrielle de Koumassi	Abidjan	120.00	296	actif	\N	\N	2025-10-26 14:01:41.639845	2025-10-26 14:01:41.639845
3	3	Zone Industrielle AkoupÃ©-Zeudji PK24	ABIDJAN	1000.00	0	actif	\N	\N	2025-10-26 14:01:41.639845	2025-10-26 14:01:41.639845
4	4	Zone Industrielle de Yopougon	Yopougon	469.00	400	actif	\N	\N	2025-10-26 14:01:41.639845	2025-10-26 14:01:41.639845
5	5	Zone Industrielle de BouakÃ©	BOUAKE	150.00	20	actif	\N	\N	2025-10-26 14:01:41.639845	2025-10-26 14:01:41.639845
6	19	Zone Test CDC 3 - Modifiée	Non spÃ©cifiÃ©e	400.25	0	actif	\N	\N	2025-10-26 14:01:41.639845	2025-10-26 14:01:41.639845
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
-- Data for Name: logs_etl; Type: TABLE DATA; Schema: etl; Owner: postgres
--

COPY etl.logs_etl (id, process_name, start_time, end_time, status, rows_processed, error_message) FROM stdin;
\.


--
-- Data for Name: dwh_status; Type: TABLE DATA; Schema: monitoring; Owner: postgres
--

COPY monitoring.dwh_status (id, nom_table, nb_lignes, derniere_maj, statut, message, date_controle) FROM stdin;
1	dwh.dim_zones_industrielles	\N	\N	ACTIF	\N	2025-10-26 14:01:42.335292
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

SELECT pg_catalog.setval('dwh.dim_entreprises_entreprise_key_seq', 17, true);


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

SELECT pg_catalog.setval('dwh.dim_temps_temps_key_seq', 1096, true);


--
-- Name: dim_zones_industrielles_zone_key_seq; Type: SEQUENCE SET; Schema: dwh; Owner: postgres
--

SELECT pg_catalog.setval('dwh.dim_zones_industrielles_zone_key_seq', 6, true);


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
-- Name: logs_etl_id_seq; Type: SEQUENCE SET; Schema: etl; Owner: postgres
--

SELECT pg_catalog.setval('etl.logs_etl_id_seq', 1, false);


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

