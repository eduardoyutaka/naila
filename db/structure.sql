SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


--
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION postgis IS 'PostGIS geometry and geography spatial types and functions';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: alert_notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.alert_notifications (
    id bigint NOT NULL,
    alert_id bigint NOT NULL,
    channel character varying NOT NULL,
    recipient character varying,
    status character varying DEFAULT 'pending'::character varying,
    sent_at timestamp(6) without time zone,
    delivered_at timestamp(6) without time zone,
    failure_reason text,
    metadata jsonb DEFAULT '{}'::jsonb,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: alert_notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.alert_notifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: alert_notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.alert_notifications_id_seq OWNED BY public.alert_notifications.id;


--
-- Name: alert_thresholds; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.alert_thresholds (
    id bigint NOT NULL,
    parameter character varying NOT NULL,
    threshold_type character varying NOT NULL,
    severity integer NOT NULL,
    value double precision NOT NULL,
    unit character varying NOT NULL,
    comparison character varying NOT NULL,
    river_basin_id bigint,
    river_id bigint,
    active boolean DEFAULT true,
    cooldown_minutes integer DEFAULT 60,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: alert_thresholds_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.alert_thresholds_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: alert_thresholds_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.alert_thresholds_id_seq OWNED BY public.alert_thresholds.id;


--
-- Name: alerts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.alerts (
    id bigint NOT NULL,
    title character varying NOT NULL,
    description text NOT NULL,
    instructions text,
    severity integer NOT NULL,
    alert_type character varying NOT NULL,
    status character varying DEFAULT 'active'::character varying,
    river_basin_id bigint,
    neighborhood_id bigint,
    river_id bigint,
    alert_threshold_id bigint,
    created_by_id bigint,
    resolved_by_id bigint,
    affected_area public.geometry(Polygon,4326),
    activated_at timestamp(6) without time zone,
    acknowledged_at timestamp(6) without time zone,
    resolved_at timestamp(6) without time zone,
    expires_at timestamp(6) without time zone,
    trigger_data jsonb DEFAULT '{}'::jsonb,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: alerts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.alerts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: alerts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.alerts_id_seq OWNED BY public.alerts.id;


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: data_sources; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.data_sources (
    id bigint NOT NULL,
    name character varying NOT NULL,
    source_type character varying NOT NULL,
    base_url character varying,
    status character varying DEFAULT 'active'::character varying,
    last_successful_fetch_at timestamp(6) without time zone,
    last_failed_fetch_at timestamp(6) without time zone,
    consecutive_failures integer DEFAULT 0,
    fetch_interval_seconds integer DEFAULT 600,
    configuration jsonb DEFAULT '{}'::jsonb,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: data_sources_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.data_sources_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: data_sources_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.data_sources_id_seq OWNED BY public.data_sources.id;


--
-- Name: escalation_rules; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.escalation_rules (
    id bigint NOT NULL,
    from_severity integer NOT NULL,
    to_severity integer NOT NULL,
    escalation_after_minutes integer NOT NULL,
    notify_supervisor boolean DEFAULT false,
    supervisor_contact character varying,
    active boolean DEFAULT true,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: escalation_rules_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.escalation_rules_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: escalation_rules_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.escalation_rules_id_seq OWNED BY public.escalation_rules.id;


--
-- Name: evacuation_routes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.evacuation_routes (
    id bigint NOT NULL,
    name character varying NOT NULL,
    description text,
    path public.geometry(LineString,4326),
    river_basin_id bigint,
    destination_name character varying,
    destination_point public.geometry(Point,4326),
    active boolean DEFAULT true,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: evacuation_routes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.evacuation_routes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: evacuation_routes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.evacuation_routes_id_seq OWNED BY public.evacuation_routes.id;


--
-- Name: monitoring_stations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.monitoring_stations (
    id bigint NOT NULL,
    external_id character varying NOT NULL,
    name character varying NOT NULL,
    data_source character varying NOT NULL,
    location public.geometry(Point,4326),
    elevation_m double precision,
    neighborhood_id bigint,
    river_basin_id bigint,
    river_id bigint,
    status character varying DEFAULT 'active'::character varying,
    last_reading_at timestamp(6) without time zone,
    last_reading_value double precision,
    metadata jsonb DEFAULT '{}'::jsonb,
    api_token_digest character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: monitoring_stations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.monitoring_stations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: monitoring_stations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.monitoring_stations_id_seq OWNED BY public.monitoring_stations.id;


--
-- Name: neighborhoods; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.neighborhoods (
    id bigint NOT NULL,
    name character varying NOT NULL,
    code character varying NOT NULL,
    region_id bigint,
    boundary public.geometry(Polygon,4326),
    area_km2 double precision,
    population integer,
    current_risk_level integer DEFAULT 0,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: neighborhoods_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.neighborhoods_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: neighborhoods_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.neighborhoods_id_seq OWNED BY public.neighborhoods.id;


--
-- Name: regions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.regions (
    id bigint NOT NULL,
    name character varying NOT NULL,
    code character varying NOT NULL,
    boundary public.geometry(Polygon,4326),
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: regions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.regions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: regions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.regions_id_seq OWNED BY public.regions.id;


--
-- Name: risk_assessments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.risk_assessments (
    id bigint NOT NULL,
    river_basin_id bigint NOT NULL,
    assessed_at timestamp(6) without time zone NOT NULL,
    risk_level integer NOT NULL,
    risk_score double precision NOT NULL,
    precipitation_score double precision,
    river_level_score double precision,
    soil_moisture_score double precision,
    forecast_score double precision,
    contributing_factors jsonb DEFAULT '{}'::jsonb,
    sensor_data_snapshot jsonb DEFAULT '{}'::jsonb,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: risk_assessments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.risk_assessments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: risk_assessments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.risk_assessments_id_seq OWNED BY public.risk_assessments.id;


--
-- Name: river_basins; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.river_basins (
    id bigint NOT NULL,
    name character varying NOT NULL,
    geometry public.geometry(Polygon,4326),
    base_risk_level integer DEFAULT 0,
    current_risk_level integer DEFAULT 0,
    current_risk_score double precision,
    risk_factors jsonb DEFAULT '{}'::jsonb,
    risk_updated_at timestamp(6) without time zone,
    active boolean DEFAULT true,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    description text,
    area_km2 double precision
);


--
-- Name: river_basins_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.river_basins_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: river_basins_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.river_basins_id_seq OWNED BY public.river_basins.id;


--
-- Name: rivers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rivers (
    id bigint NOT NULL,
    name character varying NOT NULL,
    course public.geometry(LineString,4326),
    river_basin_id bigint,
    length_km double precision,
    normal_level_m double precision,
    alert_level_m double precision,
    flood_level_m double precision,
    overflow_level_m double precision,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: rivers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.rivers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rivers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.rivers_id_seq OWNED BY public.rivers.id;


--
-- Name: satellite_observations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.satellite_observations (
    id bigint NOT NULL,
    source character varying NOT NULL,
    coverage_area public.geometry(Polygon,4326),
    captured_at timestamp(6) without time zone NOT NULL,
    observation_type character varying NOT NULL,
    value double precision,
    unit character varying,
    image_url character varying,
    metadata jsonb DEFAULT '{}'::jsonb,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: satellite_observations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.satellite_observations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: satellite_observations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.satellite_observations_id_seq OWNED BY public.satellite_observations.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: sensor_readings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sensor_readings (
    id bigint NOT NULL,
    recorded_at timestamp with time zone NOT NULL,
    value double precision NOT NULL,
    unit character varying(20) NOT NULL,
    reading_type character varying(30) NOT NULL,
    quality_flag character varying(10) DEFAULT 'ok'::character varying,
    raw_payload jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    sensor_id bigint NOT NULL
)
PARTITION BY RANGE (recorded_at);


--
-- Name: sensor_readings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sensor_readings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sensor_readings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sensor_readings_id_seq OWNED BY public.sensor_readings.id;


--
-- Name: sensor_readings_2026_01; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sensor_readings_2026_01 (
    id bigint DEFAULT nextval('public.sensor_readings_id_seq'::regclass) NOT NULL,
    recorded_at timestamp with time zone NOT NULL,
    value double precision NOT NULL,
    unit character varying(20) NOT NULL,
    reading_type character varying(30) NOT NULL,
    quality_flag character varying(10) DEFAULT 'ok'::character varying,
    raw_payload jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    sensor_id bigint NOT NULL
);


--
-- Name: sensor_readings_2026_02; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sensor_readings_2026_02 (
    id bigint DEFAULT nextval('public.sensor_readings_id_seq'::regclass) NOT NULL,
    recorded_at timestamp with time zone NOT NULL,
    value double precision NOT NULL,
    unit character varying(20) NOT NULL,
    reading_type character varying(30) NOT NULL,
    quality_flag character varying(10) DEFAULT 'ok'::character varying,
    raw_payload jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    sensor_id bigint NOT NULL
);


--
-- Name: sensor_readings_2026_03; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sensor_readings_2026_03 (
    id bigint DEFAULT nextval('public.sensor_readings_id_seq'::regclass) NOT NULL,
    recorded_at timestamp with time zone NOT NULL,
    value double precision NOT NULL,
    unit character varying(20) NOT NULL,
    reading_type character varying(30) NOT NULL,
    quality_flag character varying(10) DEFAULT 'ok'::character varying,
    raw_payload jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    sensor_id bigint NOT NULL
);


--
-- Name: sensor_readings_2026_04; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sensor_readings_2026_04 (
    id bigint DEFAULT nextval('public.sensor_readings_id_seq'::regclass) NOT NULL,
    recorded_at timestamp with time zone NOT NULL,
    value double precision NOT NULL,
    unit character varying(20) NOT NULL,
    reading_type character varying(30) NOT NULL,
    quality_flag character varying(10) DEFAULT 'ok'::character varying,
    raw_payload jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    sensor_id bigint NOT NULL
);


--
-- Name: sensor_readings_2026_05; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sensor_readings_2026_05 (
    id bigint DEFAULT nextval('public.sensor_readings_id_seq'::regclass) NOT NULL,
    recorded_at timestamp with time zone NOT NULL,
    value double precision NOT NULL,
    unit character varying(20) NOT NULL,
    reading_type character varying(30) NOT NULL,
    quality_flag character varying(10) DEFAULT 'ok'::character varying,
    raw_payload jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    sensor_id bigint NOT NULL
);


--
-- Name: sensor_readings_2026_06; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sensor_readings_2026_06 (
    id bigint DEFAULT nextval('public.sensor_readings_id_seq'::regclass) NOT NULL,
    recorded_at timestamp with time zone NOT NULL,
    value double precision NOT NULL,
    unit character varying(20) NOT NULL,
    reading_type character varying(30) NOT NULL,
    quality_flag character varying(10) DEFAULT 'ok'::character varying,
    raw_payload jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    sensor_id bigint NOT NULL
);


--
-- Name: sensor_readings_2026_07; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sensor_readings_2026_07 (
    id bigint DEFAULT nextval('public.sensor_readings_id_seq'::regclass) NOT NULL,
    recorded_at timestamp with time zone NOT NULL,
    value double precision NOT NULL,
    unit character varying(20) NOT NULL,
    reading_type character varying(30) NOT NULL,
    quality_flag character varying(10) DEFAULT 'ok'::character varying,
    raw_payload jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    sensor_id bigint NOT NULL
);


--
-- Name: sensor_readings_2026_08; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sensor_readings_2026_08 (
    id bigint DEFAULT nextval('public.sensor_readings_id_seq'::regclass) NOT NULL,
    recorded_at timestamp with time zone NOT NULL,
    value double precision NOT NULL,
    unit character varying(20) NOT NULL,
    reading_type character varying(30) NOT NULL,
    quality_flag character varying(10) DEFAULT 'ok'::character varying,
    raw_payload jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    sensor_id bigint NOT NULL
);


--
-- Name: sensor_readings_2026_09; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sensor_readings_2026_09 (
    id bigint DEFAULT nextval('public.sensor_readings_id_seq'::regclass) NOT NULL,
    recorded_at timestamp with time zone NOT NULL,
    value double precision NOT NULL,
    unit character varying(20) NOT NULL,
    reading_type character varying(30) NOT NULL,
    quality_flag character varying(10) DEFAULT 'ok'::character varying,
    raw_payload jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    sensor_id bigint NOT NULL
);


--
-- Name: sensor_readings_2026_10; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sensor_readings_2026_10 (
    id bigint DEFAULT nextval('public.sensor_readings_id_seq'::regclass) NOT NULL,
    recorded_at timestamp with time zone NOT NULL,
    value double precision NOT NULL,
    unit character varying(20) NOT NULL,
    reading_type character varying(30) NOT NULL,
    quality_flag character varying(10) DEFAULT 'ok'::character varying,
    raw_payload jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    sensor_id bigint NOT NULL
);


--
-- Name: sensor_readings_2026_11; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sensor_readings_2026_11 (
    id bigint DEFAULT nextval('public.sensor_readings_id_seq'::regclass) NOT NULL,
    recorded_at timestamp with time zone NOT NULL,
    value double precision NOT NULL,
    unit character varying(20) NOT NULL,
    reading_type character varying(30) NOT NULL,
    quality_flag character varying(10) DEFAULT 'ok'::character varying,
    raw_payload jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    sensor_id bigint NOT NULL
);


--
-- Name: sensor_readings_2026_12; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sensor_readings_2026_12 (
    id bigint DEFAULT nextval('public.sensor_readings_id_seq'::regclass) NOT NULL,
    recorded_at timestamp with time zone NOT NULL,
    value double precision NOT NULL,
    unit character varying(20) NOT NULL,
    reading_type character varying(30) NOT NULL,
    quality_flag character varying(10) DEFAULT 'ok'::character varying,
    raw_payload jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    sensor_id bigint NOT NULL
);


--
-- Name: sensor_readings_2027_01; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sensor_readings_2027_01 (
    id bigint DEFAULT nextval('public.sensor_readings_id_seq'::regclass) NOT NULL,
    recorded_at timestamp with time zone NOT NULL,
    value double precision NOT NULL,
    unit character varying(20) NOT NULL,
    reading_type character varying(30) NOT NULL,
    quality_flag character varying(10) DEFAULT 'ok'::character varying,
    raw_payload jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    sensor_id bigint NOT NULL
);


--
-- Name: sensor_readings_2027_02; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sensor_readings_2027_02 (
    id bigint DEFAULT nextval('public.sensor_readings_id_seq'::regclass) NOT NULL,
    recorded_at timestamp with time zone NOT NULL,
    value double precision NOT NULL,
    unit character varying(20) NOT NULL,
    reading_type character varying(30) NOT NULL,
    quality_flag character varying(10) DEFAULT 'ok'::character varying,
    raw_payload jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    sensor_id bigint NOT NULL
);


--
-- Name: sensor_readings_2027_03; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sensor_readings_2027_03 (
    id bigint DEFAULT nextval('public.sensor_readings_id_seq'::regclass) NOT NULL,
    recorded_at timestamp with time zone NOT NULL,
    value double precision NOT NULL,
    unit character varying(20) NOT NULL,
    reading_type character varying(30) NOT NULL,
    quality_flag character varying(10) DEFAULT 'ok'::character varying,
    raw_payload jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    sensor_id bigint NOT NULL
);


--
-- Name: sensor_readings_2027_04; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sensor_readings_2027_04 (
    id bigint DEFAULT nextval('public.sensor_readings_id_seq'::regclass) NOT NULL,
    recorded_at timestamp with time zone NOT NULL,
    value double precision NOT NULL,
    unit character varying(20) NOT NULL,
    reading_type character varying(30) NOT NULL,
    quality_flag character varying(10) DEFAULT 'ok'::character varying,
    raw_payload jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    sensor_id bigint NOT NULL
);


--
-- Name: sensor_readings_2027_05; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sensor_readings_2027_05 (
    id bigint DEFAULT nextval('public.sensor_readings_id_seq'::regclass) NOT NULL,
    recorded_at timestamp with time zone NOT NULL,
    value double precision NOT NULL,
    unit character varying(20) NOT NULL,
    reading_type character varying(30) NOT NULL,
    quality_flag character varying(10) DEFAULT 'ok'::character varying,
    raw_payload jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    sensor_id bigint NOT NULL
);


--
-- Name: sensor_readings_2027_06; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sensor_readings_2027_06 (
    id bigint DEFAULT nextval('public.sensor_readings_id_seq'::regclass) NOT NULL,
    recorded_at timestamp with time zone NOT NULL,
    value double precision NOT NULL,
    unit character varying(20) NOT NULL,
    reading_type character varying(30) NOT NULL,
    quality_flag character varying(10) DEFAULT 'ok'::character varying,
    raw_payload jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    sensor_id bigint NOT NULL
);


--
-- Name: sensor_readings_2027_07; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sensor_readings_2027_07 (
    id bigint DEFAULT nextval('public.sensor_readings_id_seq'::regclass) NOT NULL,
    recorded_at timestamp with time zone NOT NULL,
    value double precision NOT NULL,
    unit character varying(20) NOT NULL,
    reading_type character varying(30) NOT NULL,
    quality_flag character varying(10) DEFAULT 'ok'::character varying,
    raw_payload jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    sensor_id bigint NOT NULL
);


--
-- Name: sensor_readings_2027_08; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sensor_readings_2027_08 (
    id bigint DEFAULT nextval('public.sensor_readings_id_seq'::regclass) NOT NULL,
    recorded_at timestamp with time zone NOT NULL,
    value double precision NOT NULL,
    unit character varying(20) NOT NULL,
    reading_type character varying(30) NOT NULL,
    quality_flag character varying(10) DEFAULT 'ok'::character varying,
    raw_payload jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    sensor_id bigint NOT NULL
);


--
-- Name: sensor_readings_2027_09; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sensor_readings_2027_09 (
    id bigint DEFAULT nextval('public.sensor_readings_id_seq'::regclass) NOT NULL,
    recorded_at timestamp with time zone NOT NULL,
    value double precision NOT NULL,
    unit character varying(20) NOT NULL,
    reading_type character varying(30) NOT NULL,
    quality_flag character varying(10) DEFAULT 'ok'::character varying,
    raw_payload jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    sensor_id bigint NOT NULL
);


--
-- Name: sensor_readings_2027_10; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sensor_readings_2027_10 (
    id bigint DEFAULT nextval('public.sensor_readings_id_seq'::regclass) NOT NULL,
    recorded_at timestamp with time zone NOT NULL,
    value double precision NOT NULL,
    unit character varying(20) NOT NULL,
    reading_type character varying(30) NOT NULL,
    quality_flag character varying(10) DEFAULT 'ok'::character varying,
    raw_payload jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    sensor_id bigint NOT NULL
);


--
-- Name: sensor_readings_2027_11; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sensor_readings_2027_11 (
    id bigint DEFAULT nextval('public.sensor_readings_id_seq'::regclass) NOT NULL,
    recorded_at timestamp with time zone NOT NULL,
    value double precision NOT NULL,
    unit character varying(20) NOT NULL,
    reading_type character varying(30) NOT NULL,
    quality_flag character varying(10) DEFAULT 'ok'::character varying,
    raw_payload jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    sensor_id bigint NOT NULL
);


--
-- Name: sensor_readings_2027_12; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sensor_readings_2027_12 (
    id bigint DEFAULT nextval('public.sensor_readings_id_seq'::regclass) NOT NULL,
    recorded_at timestamp with time zone NOT NULL,
    value double precision NOT NULL,
    unit character varying(20) NOT NULL,
    reading_type character varying(30) NOT NULL,
    quality_flag character varying(10) DEFAULT 'ok'::character varying,
    raw_payload jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    sensor_id bigint NOT NULL
);


--
-- Name: sensors; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sensors (
    id bigint NOT NULL,
    monitoring_station_id bigint NOT NULL,
    sensor_type character varying NOT NULL,
    external_id character varying NOT NULL,
    unit character varying(20),
    reading_type character varying(30),
    status character varying DEFAULT 'active'::character varying,
    last_reading_at timestamp(6) without time zone,
    last_reading_value double precision,
    metadata jsonb DEFAULT '{}'::jsonb,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: sensors_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sensors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sensors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sensors_id_seq OWNED BY public.sensors.id;


--
-- Name: sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sessions (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    token character varying NOT NULL,
    ip_address character varying,
    user_agent character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: sessions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sessions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sessions_id_seq OWNED BY public.sessions.id;


--
-- Name: solid_queue_blocked_executions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_blocked_executions (
    id bigint NOT NULL,
    job_id bigint NOT NULL,
    queue_name character varying NOT NULL,
    priority integer DEFAULT 0 NOT NULL,
    concurrency_key character varying NOT NULL,
    expires_at timestamp(6) without time zone NOT NULL,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: solid_queue_blocked_executions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_blocked_executions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_blocked_executions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_blocked_executions_id_seq OWNED BY public.solid_queue_blocked_executions.id;


--
-- Name: solid_queue_claimed_executions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_claimed_executions (
    id bigint NOT NULL,
    job_id bigint NOT NULL,
    process_id bigint,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: solid_queue_claimed_executions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_claimed_executions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_claimed_executions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_claimed_executions_id_seq OWNED BY public.solid_queue_claimed_executions.id;


--
-- Name: solid_queue_failed_executions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_failed_executions (
    id bigint NOT NULL,
    job_id bigint NOT NULL,
    error text,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: solid_queue_failed_executions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_failed_executions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_failed_executions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_failed_executions_id_seq OWNED BY public.solid_queue_failed_executions.id;


--
-- Name: solid_queue_jobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_jobs (
    id bigint NOT NULL,
    queue_name character varying NOT NULL,
    class_name character varying NOT NULL,
    arguments text,
    priority integer DEFAULT 0 NOT NULL,
    active_job_id character varying,
    scheduled_at timestamp(6) without time zone,
    finished_at timestamp(6) without time zone,
    concurrency_key character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: solid_queue_jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_jobs_id_seq OWNED BY public.solid_queue_jobs.id;


--
-- Name: solid_queue_pauses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_pauses (
    id bigint NOT NULL,
    queue_name character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: solid_queue_pauses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_pauses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_pauses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_pauses_id_seq OWNED BY public.solid_queue_pauses.id;


--
-- Name: solid_queue_processes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_processes (
    id bigint NOT NULL,
    kind character varying NOT NULL,
    last_heartbeat_at timestamp(6) without time zone NOT NULL,
    supervisor_id bigint,
    pid integer NOT NULL,
    hostname character varying,
    metadata text,
    created_at timestamp(6) without time zone NOT NULL,
    name character varying NOT NULL
);


--
-- Name: solid_queue_processes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_processes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_processes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_processes_id_seq OWNED BY public.solid_queue_processes.id;


--
-- Name: solid_queue_ready_executions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_ready_executions (
    id bigint NOT NULL,
    job_id bigint NOT NULL,
    queue_name character varying NOT NULL,
    priority integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: solid_queue_ready_executions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_ready_executions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_ready_executions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_ready_executions_id_seq OWNED BY public.solid_queue_ready_executions.id;


--
-- Name: solid_queue_recurring_executions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_recurring_executions (
    id bigint NOT NULL,
    job_id bigint NOT NULL,
    task_key character varying NOT NULL,
    run_at timestamp(6) without time zone NOT NULL,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: solid_queue_recurring_executions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_recurring_executions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_recurring_executions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_recurring_executions_id_seq OWNED BY public.solid_queue_recurring_executions.id;


--
-- Name: solid_queue_recurring_tasks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_recurring_tasks (
    id bigint NOT NULL,
    key character varying NOT NULL,
    schedule character varying NOT NULL,
    command character varying(2048),
    class_name character varying,
    arguments text,
    queue_name character varying,
    priority integer DEFAULT 0,
    static boolean DEFAULT true NOT NULL,
    description text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: solid_queue_recurring_tasks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_recurring_tasks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_recurring_tasks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_recurring_tasks_id_seq OWNED BY public.solid_queue_recurring_tasks.id;


--
-- Name: solid_queue_scheduled_executions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_scheduled_executions (
    id bigint NOT NULL,
    job_id bigint NOT NULL,
    queue_name character varying NOT NULL,
    priority integer DEFAULT 0 NOT NULL,
    scheduled_at timestamp(6) without time zone NOT NULL,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: solid_queue_scheduled_executions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_scheduled_executions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_scheduled_executions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_scheduled_executions_id_seq OWNED BY public.solid_queue_scheduled_executions.id;


--
-- Name: solid_queue_semaphores; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_semaphores (
    id bigint NOT NULL,
    key character varying NOT NULL,
    value integer DEFAULT 1 NOT NULL,
    expires_at timestamp(6) without time zone NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: solid_queue_semaphores_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_semaphores_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_semaphores_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_semaphores_id_seq OWNED BY public.solid_queue_semaphores.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    email_address character varying NOT NULL,
    password_digest character varying NOT NULL,
    name character varying NOT NULL,
    role character varying DEFAULT 'operator'::character varying NOT NULL,
    phone_number character varying,
    department character varying,
    active boolean DEFAULT true,
    receives_sms_alerts boolean DEFAULT true,
    notification_preferences jsonb DEFAULT '{}'::jsonb,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: weather_forecasts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.weather_forecasts (
    id bigint NOT NULL,
    source character varying NOT NULL,
    location public.geometry(Point,4326),
    issued_at timestamp(6) without time zone NOT NULL,
    valid_from timestamp(6) without time zone NOT NULL,
    valid_until timestamp(6) without time zone NOT NULL,
    precipitation_mm double precision,
    precipitation_probability double precision,
    temperature_max_c double precision,
    temperature_min_c double precision,
    severity character varying,
    raw_data jsonb DEFAULT '{}'::jsonb,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: weather_forecasts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.weather_forecasts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: weather_forecasts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.weather_forecasts_id_seq OWNED BY public.weather_forecasts.id;


--
-- Name: weather_observations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.weather_observations (
    id bigint NOT NULL,
    source character varying NOT NULL,
    station_code character varying,
    location public.geometry(Point,4326),
    observed_at timestamp(6) without time zone NOT NULL,
    temperature_c double precision,
    humidity_pct double precision,
    pressure_hpa double precision,
    wind_speed_ms double precision,
    wind_direction_deg double precision,
    precipitation_mm double precision,
    precipitation_rate_mm_h double precision,
    weather_condition character varying,
    raw_data jsonb DEFAULT '{}'::jsonb,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: weather_observations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.weather_observations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: weather_observations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.weather_observations_id_seq OWNED BY public.weather_observations.id;


--
-- Name: sensor_readings_2026_01; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sensor_readings ATTACH PARTITION public.sensor_readings_2026_01 FOR VALUES FROM ('2025-12-31 21:00:00-03') TO ('2026-01-31 21:00:00-03');


--
-- Name: sensor_readings_2026_02; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sensor_readings ATTACH PARTITION public.sensor_readings_2026_02 FOR VALUES FROM ('2026-01-31 21:00:00-03') TO ('2026-02-28 21:00:00-03');


--
-- Name: sensor_readings_2026_03; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sensor_readings ATTACH PARTITION public.sensor_readings_2026_03 FOR VALUES FROM ('2026-02-28 21:00:00-03') TO ('2026-03-31 21:00:00-03');


--
-- Name: sensor_readings_2026_04; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sensor_readings ATTACH PARTITION public.sensor_readings_2026_04 FOR VALUES FROM ('2026-03-31 21:00:00-03') TO ('2026-04-30 21:00:00-03');


--
-- Name: sensor_readings_2026_05; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sensor_readings ATTACH PARTITION public.sensor_readings_2026_05 FOR VALUES FROM ('2026-04-30 21:00:00-03') TO ('2026-05-31 21:00:00-03');


--
-- Name: sensor_readings_2026_06; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sensor_readings ATTACH PARTITION public.sensor_readings_2026_06 FOR VALUES FROM ('2026-05-31 21:00:00-03') TO ('2026-06-30 21:00:00-03');


--
-- Name: sensor_readings_2026_07; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sensor_readings ATTACH PARTITION public.sensor_readings_2026_07 FOR VALUES FROM ('2026-06-30 21:00:00-03') TO ('2026-07-31 21:00:00-03');


--
-- Name: sensor_readings_2026_08; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sensor_readings ATTACH PARTITION public.sensor_readings_2026_08 FOR VALUES FROM ('2026-07-31 21:00:00-03') TO ('2026-08-31 21:00:00-03');


--
-- Name: sensor_readings_2026_09; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sensor_readings ATTACH PARTITION public.sensor_readings_2026_09 FOR VALUES FROM ('2026-08-31 21:00:00-03') TO ('2026-09-30 21:00:00-03');


--
-- Name: sensor_readings_2026_10; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sensor_readings ATTACH PARTITION public.sensor_readings_2026_10 FOR VALUES FROM ('2026-09-30 21:00:00-03') TO ('2026-10-31 21:00:00-03');


--
-- Name: sensor_readings_2026_11; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sensor_readings ATTACH PARTITION public.sensor_readings_2026_11 FOR VALUES FROM ('2026-10-31 21:00:00-03') TO ('2026-11-30 21:00:00-03');


--
-- Name: sensor_readings_2026_12; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sensor_readings ATTACH PARTITION public.sensor_readings_2026_12 FOR VALUES FROM ('2026-11-30 21:00:00-03') TO ('2026-12-31 21:00:00-03');


--
-- Name: sensor_readings_2027_01; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sensor_readings ATTACH PARTITION public.sensor_readings_2027_01 FOR VALUES FROM ('2026-12-31 21:00:00-03') TO ('2027-01-31 21:00:00-03');


--
-- Name: sensor_readings_2027_02; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sensor_readings ATTACH PARTITION public.sensor_readings_2027_02 FOR VALUES FROM ('2027-01-31 21:00:00-03') TO ('2027-02-28 21:00:00-03');


--
-- Name: sensor_readings_2027_03; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sensor_readings ATTACH PARTITION public.sensor_readings_2027_03 FOR VALUES FROM ('2027-02-28 21:00:00-03') TO ('2027-03-31 21:00:00-03');


--
-- Name: sensor_readings_2027_04; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sensor_readings ATTACH PARTITION public.sensor_readings_2027_04 FOR VALUES FROM ('2027-03-31 21:00:00-03') TO ('2027-04-30 21:00:00-03');


--
-- Name: sensor_readings_2027_05; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sensor_readings ATTACH PARTITION public.sensor_readings_2027_05 FOR VALUES FROM ('2027-04-30 21:00:00-03') TO ('2027-05-31 21:00:00-03');


--
-- Name: sensor_readings_2027_06; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sensor_readings ATTACH PARTITION public.sensor_readings_2027_06 FOR VALUES FROM ('2027-05-31 21:00:00-03') TO ('2027-06-30 21:00:00-03');


--
-- Name: sensor_readings_2027_07; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sensor_readings ATTACH PARTITION public.sensor_readings_2027_07 FOR VALUES FROM ('2027-06-30 21:00:00-03') TO ('2027-07-31 21:00:00-03');


--
-- Name: sensor_readings_2027_08; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sensor_readings ATTACH PARTITION public.sensor_readings_2027_08 FOR VALUES FROM ('2027-07-31 21:00:00-03') TO ('2027-08-31 21:00:00-03');


--
-- Name: sensor_readings_2027_09; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sensor_readings ATTACH PARTITION public.sensor_readings_2027_09 FOR VALUES FROM ('2027-08-31 21:00:00-03') TO ('2027-09-30 21:00:00-03');


--
-- Name: sensor_readings_2027_10; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sensor_readings ATTACH PARTITION public.sensor_readings_2027_10 FOR VALUES FROM ('2027-09-30 21:00:00-03') TO ('2027-10-31 21:00:00-03');


--
-- Name: sensor_readings_2027_11; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sensor_readings ATTACH PARTITION public.sensor_readings_2027_11 FOR VALUES FROM ('2027-10-31 21:00:00-03') TO ('2027-11-30 21:00:00-03');


--
-- Name: sensor_readings_2027_12; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sensor_readings ATTACH PARTITION public.sensor_readings_2027_12 FOR VALUES FROM ('2027-11-30 21:00:00-03') TO ('2027-12-31 21:00:00-03');


--
-- Name: alert_notifications id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alert_notifications ALTER COLUMN id SET DEFAULT nextval('public.alert_notifications_id_seq'::regclass);


--
-- Name: alert_thresholds id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alert_thresholds ALTER COLUMN id SET DEFAULT nextval('public.alert_thresholds_id_seq'::regclass);


--
-- Name: alerts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alerts ALTER COLUMN id SET DEFAULT nextval('public.alerts_id_seq'::regclass);


--
-- Name: data_sources id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_sources ALTER COLUMN id SET DEFAULT nextval('public.data_sources_id_seq'::regclass);


--
-- Name: escalation_rules id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.escalation_rules ALTER COLUMN id SET DEFAULT nextval('public.escalation_rules_id_seq'::regclass);


--
-- Name: evacuation_routes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evacuation_routes ALTER COLUMN id SET DEFAULT nextval('public.evacuation_routes_id_seq'::regclass);


--
-- Name: monitoring_stations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.monitoring_stations ALTER COLUMN id SET DEFAULT nextval('public.monitoring_stations_id_seq'::regclass);


--
-- Name: neighborhoods id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.neighborhoods ALTER COLUMN id SET DEFAULT nextval('public.neighborhoods_id_seq'::regclass);


--
-- Name: regions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.regions ALTER COLUMN id SET DEFAULT nextval('public.regions_id_seq'::regclass);


--
-- Name: risk_assessments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.risk_assessments ALTER COLUMN id SET DEFAULT nextval('public.risk_assessments_id_seq'::regclass);


--
-- Name: river_basins id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.river_basins ALTER COLUMN id SET DEFAULT nextval('public.river_basins_id_seq'::regclass);


--
-- Name: rivers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rivers ALTER COLUMN id SET DEFAULT nextval('public.rivers_id_seq'::regclass);


--
-- Name: satellite_observations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.satellite_observations ALTER COLUMN id SET DEFAULT nextval('public.satellite_observations_id_seq'::regclass);


--
-- Name: sensor_readings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sensor_readings ALTER COLUMN id SET DEFAULT nextval('public.sensor_readings_id_seq'::regclass);


--
-- Name: sensors id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sensors ALTER COLUMN id SET DEFAULT nextval('public.sensors_id_seq'::regclass);


--
-- Name: sessions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions ALTER COLUMN id SET DEFAULT nextval('public.sessions_id_seq'::regclass);


--
-- Name: solid_queue_blocked_executions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_blocked_executions ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_blocked_executions_id_seq'::regclass);


--
-- Name: solid_queue_claimed_executions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_claimed_executions ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_claimed_executions_id_seq'::regclass);


--
-- Name: solid_queue_failed_executions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_failed_executions ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_failed_executions_id_seq'::regclass);


--
-- Name: solid_queue_jobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_jobs ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_jobs_id_seq'::regclass);


--
-- Name: solid_queue_pauses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_pauses ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_pauses_id_seq'::regclass);


--
-- Name: solid_queue_processes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_processes ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_processes_id_seq'::regclass);


--
-- Name: solid_queue_ready_executions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_ready_executions ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_ready_executions_id_seq'::regclass);


--
-- Name: solid_queue_recurring_executions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_recurring_executions ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_recurring_executions_id_seq'::regclass);


--
-- Name: solid_queue_recurring_tasks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_recurring_tasks ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_recurring_tasks_id_seq'::regclass);


--
-- Name: solid_queue_scheduled_executions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_scheduled_executions ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_scheduled_executions_id_seq'::regclass);


--
-- Name: solid_queue_semaphores id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_semaphores ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_semaphores_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: weather_forecasts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.weather_forecasts ALTER COLUMN id SET DEFAULT nextval('public.weather_forecasts_id_seq'::regclass);


--
-- Name: weather_observations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.weather_observations ALTER COLUMN id SET DEFAULT nextval('public.weather_observations_id_seq'::regclass);


--
-- Name: alert_notifications alert_notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alert_notifications
    ADD CONSTRAINT alert_notifications_pkey PRIMARY KEY (id);


--
-- Name: alert_thresholds alert_thresholds_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alert_thresholds
    ADD CONSTRAINT alert_thresholds_pkey PRIMARY KEY (id);


--
-- Name: alerts alerts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alerts
    ADD CONSTRAINT alerts_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: data_sources data_sources_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_sources
    ADD CONSTRAINT data_sources_pkey PRIMARY KEY (id);


--
-- Name: escalation_rules escalation_rules_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.escalation_rules
    ADD CONSTRAINT escalation_rules_pkey PRIMARY KEY (id);


--
-- Name: evacuation_routes evacuation_routes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evacuation_routes
    ADD CONSTRAINT evacuation_routes_pkey PRIMARY KEY (id);


--
-- Name: monitoring_stations monitoring_stations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.monitoring_stations
    ADD CONSTRAINT monitoring_stations_pkey PRIMARY KEY (id);


--
-- Name: neighborhoods neighborhoods_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.neighborhoods
    ADD CONSTRAINT neighborhoods_pkey PRIMARY KEY (id);


--
-- Name: regions regions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.regions
    ADD CONSTRAINT regions_pkey PRIMARY KEY (id);


--
-- Name: risk_assessments risk_assessments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.risk_assessments
    ADD CONSTRAINT risk_assessments_pkey PRIMARY KEY (id);


--
-- Name: river_basins river_basins_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.river_basins
    ADD CONSTRAINT river_basins_pkey PRIMARY KEY (id);


--
-- Name: rivers rivers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rivers
    ADD CONSTRAINT rivers_pkey PRIMARY KEY (id);


--
-- Name: satellite_observations satellite_observations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.satellite_observations
    ADD CONSTRAINT satellite_observations_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: sensor_readings sensor_readings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sensor_readings
    ADD CONSTRAINT sensor_readings_pkey PRIMARY KEY (id, recorded_at);


--
-- Name: sensor_readings_2026_01 sensor_readings_2026_01_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sensor_readings_2026_01
    ADD CONSTRAINT sensor_readings_2026_01_pkey PRIMARY KEY (id, recorded_at);


--
-- Name: sensor_readings_2026_02 sensor_readings_2026_02_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sensor_readings_2026_02
    ADD CONSTRAINT sensor_readings_2026_02_pkey PRIMARY KEY (id, recorded_at);


--
-- Name: sensor_readings_2026_03 sensor_readings_2026_03_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sensor_readings_2026_03
    ADD CONSTRAINT sensor_readings_2026_03_pkey PRIMARY KEY (id, recorded_at);


--
-- Name: sensor_readings_2026_04 sensor_readings_2026_04_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sensor_readings_2026_04
    ADD CONSTRAINT sensor_readings_2026_04_pkey PRIMARY KEY (id, recorded_at);


--
-- Name: sensor_readings_2026_05 sensor_readings_2026_05_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sensor_readings_2026_05
    ADD CONSTRAINT sensor_readings_2026_05_pkey PRIMARY KEY (id, recorded_at);


--
-- Name: sensor_readings_2026_06 sensor_readings_2026_06_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sensor_readings_2026_06
    ADD CONSTRAINT sensor_readings_2026_06_pkey PRIMARY KEY (id, recorded_at);


--
-- Name: sensor_readings_2026_07 sensor_readings_2026_07_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sensor_readings_2026_07
    ADD CONSTRAINT sensor_readings_2026_07_pkey PRIMARY KEY (id, recorded_at);


--
-- Name: sensor_readings_2026_08 sensor_readings_2026_08_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sensor_readings_2026_08
    ADD CONSTRAINT sensor_readings_2026_08_pkey PRIMARY KEY (id, recorded_at);


--
-- Name: sensor_readings_2026_09 sensor_readings_2026_09_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sensor_readings_2026_09
    ADD CONSTRAINT sensor_readings_2026_09_pkey PRIMARY KEY (id, recorded_at);


--
-- Name: sensor_readings_2026_10 sensor_readings_2026_10_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sensor_readings_2026_10
    ADD CONSTRAINT sensor_readings_2026_10_pkey PRIMARY KEY (id, recorded_at);


--
-- Name: sensor_readings_2026_11 sensor_readings_2026_11_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sensor_readings_2026_11
    ADD CONSTRAINT sensor_readings_2026_11_pkey PRIMARY KEY (id, recorded_at);


--
-- Name: sensor_readings_2026_12 sensor_readings_2026_12_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sensor_readings_2026_12
    ADD CONSTRAINT sensor_readings_2026_12_pkey PRIMARY KEY (id, recorded_at);


--
-- Name: sensor_readings_2027_01 sensor_readings_2027_01_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sensor_readings_2027_01
    ADD CONSTRAINT sensor_readings_2027_01_pkey PRIMARY KEY (id, recorded_at);


--
-- Name: sensor_readings_2027_02 sensor_readings_2027_02_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sensor_readings_2027_02
    ADD CONSTRAINT sensor_readings_2027_02_pkey PRIMARY KEY (id, recorded_at);


--
-- Name: sensor_readings_2027_03 sensor_readings_2027_03_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sensor_readings_2027_03
    ADD CONSTRAINT sensor_readings_2027_03_pkey PRIMARY KEY (id, recorded_at);


--
-- Name: sensor_readings_2027_04 sensor_readings_2027_04_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sensor_readings_2027_04
    ADD CONSTRAINT sensor_readings_2027_04_pkey PRIMARY KEY (id, recorded_at);


--
-- Name: sensor_readings_2027_05 sensor_readings_2027_05_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sensor_readings_2027_05
    ADD CONSTRAINT sensor_readings_2027_05_pkey PRIMARY KEY (id, recorded_at);


--
-- Name: sensor_readings_2027_06 sensor_readings_2027_06_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sensor_readings_2027_06
    ADD CONSTRAINT sensor_readings_2027_06_pkey PRIMARY KEY (id, recorded_at);


--
-- Name: sensor_readings_2027_07 sensor_readings_2027_07_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sensor_readings_2027_07
    ADD CONSTRAINT sensor_readings_2027_07_pkey PRIMARY KEY (id, recorded_at);


--
-- Name: sensor_readings_2027_08 sensor_readings_2027_08_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sensor_readings_2027_08
    ADD CONSTRAINT sensor_readings_2027_08_pkey PRIMARY KEY (id, recorded_at);


--
-- Name: sensor_readings_2027_09 sensor_readings_2027_09_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sensor_readings_2027_09
    ADD CONSTRAINT sensor_readings_2027_09_pkey PRIMARY KEY (id, recorded_at);


--
-- Name: sensor_readings_2027_10 sensor_readings_2027_10_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sensor_readings_2027_10
    ADD CONSTRAINT sensor_readings_2027_10_pkey PRIMARY KEY (id, recorded_at);


--
-- Name: sensor_readings_2027_11 sensor_readings_2027_11_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sensor_readings_2027_11
    ADD CONSTRAINT sensor_readings_2027_11_pkey PRIMARY KEY (id, recorded_at);


--
-- Name: sensor_readings_2027_12 sensor_readings_2027_12_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sensor_readings_2027_12
    ADD CONSTRAINT sensor_readings_2027_12_pkey PRIMARY KEY (id, recorded_at);


--
-- Name: sensors sensors_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sensors
    ADD CONSTRAINT sensors_pkey PRIMARY KEY (id);


--
-- Name: sessions sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_blocked_executions solid_queue_blocked_executions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_blocked_executions
    ADD CONSTRAINT solid_queue_blocked_executions_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_claimed_executions solid_queue_claimed_executions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_claimed_executions
    ADD CONSTRAINT solid_queue_claimed_executions_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_failed_executions solid_queue_failed_executions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_failed_executions
    ADD CONSTRAINT solid_queue_failed_executions_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_jobs solid_queue_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_jobs
    ADD CONSTRAINT solid_queue_jobs_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_pauses solid_queue_pauses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_pauses
    ADD CONSTRAINT solid_queue_pauses_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_processes solid_queue_processes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_processes
    ADD CONSTRAINT solid_queue_processes_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_ready_executions solid_queue_ready_executions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_ready_executions
    ADD CONSTRAINT solid_queue_ready_executions_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_recurring_executions solid_queue_recurring_executions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_recurring_executions
    ADD CONSTRAINT solid_queue_recurring_executions_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_recurring_tasks solid_queue_recurring_tasks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_recurring_tasks
    ADD CONSTRAINT solid_queue_recurring_tasks_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_scheduled_executions solid_queue_scheduled_executions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_scheduled_executions
    ADD CONSTRAINT solid_queue_scheduled_executions_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_semaphores solid_queue_semaphores_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_semaphores
    ADD CONSTRAINT solid_queue_semaphores_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: weather_forecasts weather_forecasts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.weather_forecasts
    ADD CONSTRAINT weather_forecasts_pkey PRIMARY KEY (id);


--
-- Name: weather_observations weather_observations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.weather_observations
    ADD CONSTRAINT weather_observations_pkey PRIMARY KEY (id);


--
-- Name: idx_weather_fc_dedup; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_weather_fc_dedup ON public.weather_forecasts USING btree (source, valid_from, valid_until);


--
-- Name: idx_weather_obs_dedup; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_weather_obs_dedup ON public.weather_observations USING btree (source, station_code, observed_at);


--
-- Name: index_alert_notifications_on_alert_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_alert_notifications_on_alert_id ON public.alert_notifications USING btree (alert_id);


--
-- Name: index_alert_notifications_on_alert_id_and_channel; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_alert_notifications_on_alert_id_and_channel ON public.alert_notifications USING btree (alert_id, channel);


--
-- Name: index_alert_notifications_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_alert_notifications_on_status ON public.alert_notifications USING btree (status);


--
-- Name: index_alert_thresholds_on_river_basin_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_alert_thresholds_on_river_basin_id ON public.alert_thresholds USING btree (river_basin_id);


--
-- Name: index_alert_thresholds_on_river_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_alert_thresholds_on_river_id ON public.alert_thresholds USING btree (river_id);


--
-- Name: index_alerts_on_affected_area; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_alerts_on_affected_area ON public.alerts USING gist (affected_area);


--
-- Name: index_alerts_on_alert_threshold_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_alerts_on_alert_threshold_id ON public.alerts USING btree (alert_threshold_id);


--
-- Name: index_alerts_on_created_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_alerts_on_created_by_id ON public.alerts USING btree (created_by_id);


--
-- Name: index_alerts_on_neighborhood_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_alerts_on_neighborhood_id ON public.alerts USING btree (neighborhood_id);


--
-- Name: index_alerts_on_resolved_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_alerts_on_resolved_by_id ON public.alerts USING btree (resolved_by_id);


--
-- Name: index_alerts_on_river_basin_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_alerts_on_river_basin_id ON public.alerts USING btree (river_basin_id);


--
-- Name: index_alerts_on_river_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_alerts_on_river_id ON public.alerts USING btree (river_id);


--
-- Name: index_alerts_on_severity; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_alerts_on_severity ON public.alerts USING btree (severity);


--
-- Name: index_alerts_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_alerts_on_status ON public.alerts USING btree (status);


--
-- Name: index_alerts_on_status_and_severity; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_alerts_on_status_and_severity ON public.alerts USING btree (status, severity);


--
-- Name: index_evacuation_routes_on_path; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_evacuation_routes_on_path ON public.evacuation_routes USING gist (path);


--
-- Name: index_evacuation_routes_on_river_basin_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_evacuation_routes_on_river_basin_id ON public.evacuation_routes USING btree (river_basin_id);


--
-- Name: index_monitoring_stations_on_external_id_and_data_source; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_monitoring_stations_on_external_id_and_data_source ON public.monitoring_stations USING btree (external_id, data_source);


--
-- Name: index_monitoring_stations_on_location; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_monitoring_stations_on_location ON public.monitoring_stations USING gist (location);


--
-- Name: index_monitoring_stations_on_neighborhood_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_monitoring_stations_on_neighborhood_id ON public.monitoring_stations USING btree (neighborhood_id);


--
-- Name: index_monitoring_stations_on_river_basin_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_monitoring_stations_on_river_basin_id ON public.monitoring_stations USING btree (river_basin_id);


--
-- Name: index_monitoring_stations_on_river_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_monitoring_stations_on_river_id ON public.monitoring_stations USING btree (river_id);


--
-- Name: index_monitoring_stations_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_monitoring_stations_on_status ON public.monitoring_stations USING btree (status);


--
-- Name: index_neighborhoods_on_boundary; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_neighborhoods_on_boundary ON public.neighborhoods USING gist (boundary);


--
-- Name: index_neighborhoods_on_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_neighborhoods_on_code ON public.neighborhoods USING btree (code);


--
-- Name: index_neighborhoods_on_current_risk_level; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_neighborhoods_on_current_risk_level ON public.neighborhoods USING btree (current_risk_level);


--
-- Name: index_neighborhoods_on_region_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_neighborhoods_on_region_id ON public.neighborhoods USING btree (region_id);


--
-- Name: index_regions_on_boundary; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_regions_on_boundary ON public.regions USING gist (boundary);


--
-- Name: index_regions_on_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_regions_on_code ON public.regions USING btree (code);


--
-- Name: index_risk_assessments_on_risk_level; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_risk_assessments_on_risk_level ON public.risk_assessments USING btree (risk_level);


--
-- Name: index_risk_assessments_on_river_basin_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_risk_assessments_on_river_basin_id ON public.risk_assessments USING btree (river_basin_id);


--
-- Name: index_risk_assessments_on_river_basin_id_and_assessed_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_risk_assessments_on_river_basin_id_and_assessed_at ON public.risk_assessments USING btree (river_basin_id, assessed_at);


--
-- Name: index_river_basins_on_current_risk_level; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_river_basins_on_current_risk_level ON public.river_basins USING btree (current_risk_level);


--
-- Name: index_river_basins_on_geometry; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_river_basins_on_geometry ON public.river_basins USING gist (geometry);


--
-- Name: index_rivers_on_course; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_rivers_on_course ON public.rivers USING gist (course);


--
-- Name: index_rivers_on_river_basin_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_rivers_on_river_basin_id ON public.rivers USING btree (river_basin_id);


--
-- Name: index_satellite_observations_on_coverage_area; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_satellite_observations_on_coverage_area ON public.satellite_observations USING gist (coverage_area);


--
-- Name: index_satellite_observations_on_source_and_captured_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_satellite_observations_on_source_and_captured_at ON public.satellite_observations USING btree (source, captured_at);


--
-- Name: index_sensor_readings_on_reading_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sensor_readings_on_reading_type ON ONLY public.sensor_readings USING btree (reading_type);


--
-- Name: index_sensor_readings_on_sensor_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sensor_readings_on_sensor_id ON ONLY public.sensor_readings USING btree (sensor_id);


--
-- Name: index_sensor_readings_on_sensor_id_and_recorded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sensor_readings_on_sensor_id_and_recorded_at ON ONLY public.sensor_readings USING btree (sensor_id, recorded_at);


--
-- Name: index_sensors_on_external_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_sensors_on_external_id ON public.sensors USING btree (external_id);


--
-- Name: index_sensors_on_monitoring_station_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sensors_on_monitoring_station_id ON public.sensors USING btree (monitoring_station_id);


--
-- Name: index_sensors_on_sensor_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sensors_on_sensor_type ON public.sensors USING btree (sensor_type);


--
-- Name: index_sensors_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sensors_on_status ON public.sensors USING btree (status);


--
-- Name: index_sessions_on_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_sessions_on_token ON public.sessions USING btree (token);


--
-- Name: index_sessions_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sessions_on_user_id ON public.sessions USING btree (user_id);


--
-- Name: index_solid_queue_blocked_executions_for_maintenance; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_blocked_executions_for_maintenance ON public.solid_queue_blocked_executions USING btree (expires_at, concurrency_key);


--
-- Name: index_solid_queue_blocked_executions_for_release; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_blocked_executions_for_release ON public.solid_queue_blocked_executions USING btree (concurrency_key, priority, job_id);


--
-- Name: index_solid_queue_blocked_executions_on_job_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_blocked_executions_on_job_id ON public.solid_queue_blocked_executions USING btree (job_id);


--
-- Name: index_solid_queue_claimed_executions_on_job_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_claimed_executions_on_job_id ON public.solid_queue_claimed_executions USING btree (job_id);


--
-- Name: index_solid_queue_claimed_executions_on_process_id_and_job_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_claimed_executions_on_process_id_and_job_id ON public.solid_queue_claimed_executions USING btree (process_id, job_id);


--
-- Name: index_solid_queue_dispatch_all; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_dispatch_all ON public.solid_queue_scheduled_executions USING btree (scheduled_at, priority, job_id);


--
-- Name: index_solid_queue_failed_executions_on_job_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_failed_executions_on_job_id ON public.solid_queue_failed_executions USING btree (job_id);


--
-- Name: index_solid_queue_jobs_for_alerting; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_jobs_for_alerting ON public.solid_queue_jobs USING btree (scheduled_at, finished_at);


--
-- Name: index_solid_queue_jobs_for_filtering; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_jobs_for_filtering ON public.solid_queue_jobs USING btree (queue_name, finished_at);


--
-- Name: index_solid_queue_jobs_on_active_job_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_jobs_on_active_job_id ON public.solid_queue_jobs USING btree (active_job_id);


--
-- Name: index_solid_queue_jobs_on_class_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_jobs_on_class_name ON public.solid_queue_jobs USING btree (class_name);


--
-- Name: index_solid_queue_jobs_on_finished_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_jobs_on_finished_at ON public.solid_queue_jobs USING btree (finished_at);


--
-- Name: index_solid_queue_pauses_on_queue_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_pauses_on_queue_name ON public.solid_queue_pauses USING btree (queue_name);


--
-- Name: index_solid_queue_poll_all; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_poll_all ON public.solid_queue_ready_executions USING btree (priority, job_id);


--
-- Name: index_solid_queue_poll_by_queue; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_poll_by_queue ON public.solid_queue_ready_executions USING btree (queue_name, priority, job_id);


--
-- Name: index_solid_queue_processes_on_last_heartbeat_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_processes_on_last_heartbeat_at ON public.solid_queue_processes USING btree (last_heartbeat_at);


--
-- Name: index_solid_queue_processes_on_name_and_supervisor_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_processes_on_name_and_supervisor_id ON public.solid_queue_processes USING btree (name, supervisor_id);


--
-- Name: index_solid_queue_processes_on_supervisor_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_processes_on_supervisor_id ON public.solid_queue_processes USING btree (supervisor_id);


--
-- Name: index_solid_queue_ready_executions_on_job_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_ready_executions_on_job_id ON public.solid_queue_ready_executions USING btree (job_id);


--
-- Name: index_solid_queue_recurring_executions_on_job_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_recurring_executions_on_job_id ON public.solid_queue_recurring_executions USING btree (job_id);


--
-- Name: index_solid_queue_recurring_executions_on_task_key_and_run_at; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_recurring_executions_on_task_key_and_run_at ON public.solid_queue_recurring_executions USING btree (task_key, run_at);


--
-- Name: index_solid_queue_recurring_tasks_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_recurring_tasks_on_key ON public.solid_queue_recurring_tasks USING btree (key);


--
-- Name: index_solid_queue_recurring_tasks_on_static; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_recurring_tasks_on_static ON public.solid_queue_recurring_tasks USING btree (static);


--
-- Name: index_solid_queue_scheduled_executions_on_job_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_scheduled_executions_on_job_id ON public.solid_queue_scheduled_executions USING btree (job_id);


--
-- Name: index_solid_queue_semaphores_on_expires_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_semaphores_on_expires_at ON public.solid_queue_semaphores USING btree (expires_at);


--
-- Name: index_solid_queue_semaphores_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_semaphores_on_key ON public.solid_queue_semaphores USING btree (key);


--
-- Name: index_solid_queue_semaphores_on_key_and_value; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_semaphores_on_key_and_value ON public.solid_queue_semaphores USING btree (key, value);


--
-- Name: index_users_on_email_address; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_email_address ON public.users USING btree (email_address);


--
-- Name: index_weather_forecasts_on_location; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_weather_forecasts_on_location ON public.weather_forecasts USING gist (location);


--
-- Name: index_weather_observations_on_location; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_weather_observations_on_location ON public.weather_observations USING gist (location);


--
-- Name: sensor_readings_2026_01_reading_type_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sensor_readings_2026_01_reading_type_idx ON public.sensor_readings_2026_01 USING btree (reading_type);


--
-- Name: sensor_readings_2026_01_sensor_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sensor_readings_2026_01_sensor_id_idx ON public.sensor_readings_2026_01 USING btree (sensor_id);


--
-- Name: sensor_readings_2026_01_sensor_id_recorded_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sensor_readings_2026_01_sensor_id_recorded_at_idx ON public.sensor_readings_2026_01 USING btree (sensor_id, recorded_at);


--
-- Name: sensor_readings_2026_02_reading_type_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sensor_readings_2026_02_reading_type_idx ON public.sensor_readings_2026_02 USING btree (reading_type);


--
-- Name: sensor_readings_2026_02_sensor_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sensor_readings_2026_02_sensor_id_idx ON public.sensor_readings_2026_02 USING btree (sensor_id);


--
-- Name: sensor_readings_2026_02_sensor_id_recorded_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sensor_readings_2026_02_sensor_id_recorded_at_idx ON public.sensor_readings_2026_02 USING btree (sensor_id, recorded_at);


--
-- Name: sensor_readings_2026_03_reading_type_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sensor_readings_2026_03_reading_type_idx ON public.sensor_readings_2026_03 USING btree (reading_type);


--
-- Name: sensor_readings_2026_03_sensor_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sensor_readings_2026_03_sensor_id_idx ON public.sensor_readings_2026_03 USING btree (sensor_id);


--
-- Name: sensor_readings_2026_03_sensor_id_recorded_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sensor_readings_2026_03_sensor_id_recorded_at_idx ON public.sensor_readings_2026_03 USING btree (sensor_id, recorded_at);


--
-- Name: sensor_readings_2026_04_reading_type_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sensor_readings_2026_04_reading_type_idx ON public.sensor_readings_2026_04 USING btree (reading_type);


--
-- Name: sensor_readings_2026_04_sensor_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sensor_readings_2026_04_sensor_id_idx ON public.sensor_readings_2026_04 USING btree (sensor_id);


--
-- Name: sensor_readings_2026_04_sensor_id_recorded_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sensor_readings_2026_04_sensor_id_recorded_at_idx ON public.sensor_readings_2026_04 USING btree (sensor_id, recorded_at);


--
-- Name: sensor_readings_2026_05_reading_type_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sensor_readings_2026_05_reading_type_idx ON public.sensor_readings_2026_05 USING btree (reading_type);


--
-- Name: sensor_readings_2026_05_sensor_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sensor_readings_2026_05_sensor_id_idx ON public.sensor_readings_2026_05 USING btree (sensor_id);


--
-- Name: sensor_readings_2026_05_sensor_id_recorded_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sensor_readings_2026_05_sensor_id_recorded_at_idx ON public.sensor_readings_2026_05 USING btree (sensor_id, recorded_at);


--
-- Name: sensor_readings_2026_06_reading_type_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sensor_readings_2026_06_reading_type_idx ON public.sensor_readings_2026_06 USING btree (reading_type);


--
-- Name: sensor_readings_2026_06_sensor_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sensor_readings_2026_06_sensor_id_idx ON public.sensor_readings_2026_06 USING btree (sensor_id);


--
-- Name: sensor_readings_2026_06_sensor_id_recorded_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sensor_readings_2026_06_sensor_id_recorded_at_idx ON public.sensor_readings_2026_06 USING btree (sensor_id, recorded_at);


--
-- Name: sensor_readings_2026_07_reading_type_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sensor_readings_2026_07_reading_type_idx ON public.sensor_readings_2026_07 USING btree (reading_type);


--
-- Name: sensor_readings_2026_07_sensor_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sensor_readings_2026_07_sensor_id_idx ON public.sensor_readings_2026_07 USING btree (sensor_id);


--
-- Name: sensor_readings_2026_07_sensor_id_recorded_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sensor_readings_2026_07_sensor_id_recorded_at_idx ON public.sensor_readings_2026_07 USING btree (sensor_id, recorded_at);


--
-- Name: sensor_readings_2026_08_reading_type_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sensor_readings_2026_08_reading_type_idx ON public.sensor_readings_2026_08 USING btree (reading_type);


--
-- Name: sensor_readings_2026_08_sensor_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sensor_readings_2026_08_sensor_id_idx ON public.sensor_readings_2026_08 USING btree (sensor_id);


--
-- Name: sensor_readings_2026_08_sensor_id_recorded_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sensor_readings_2026_08_sensor_id_recorded_at_idx ON public.sensor_readings_2026_08 USING btree (sensor_id, recorded_at);


--
-- Name: sensor_readings_2026_09_reading_type_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sensor_readings_2026_09_reading_type_idx ON public.sensor_readings_2026_09 USING btree (reading_type);


--
-- Name: sensor_readings_2026_09_sensor_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sensor_readings_2026_09_sensor_id_idx ON public.sensor_readings_2026_09 USING btree (sensor_id);


--
-- Name: sensor_readings_2026_09_sensor_id_recorded_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sensor_readings_2026_09_sensor_id_recorded_at_idx ON public.sensor_readings_2026_09 USING btree (sensor_id, recorded_at);


--
-- Name: sensor_readings_2026_10_reading_type_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sensor_readings_2026_10_reading_type_idx ON public.sensor_readings_2026_10 USING btree (reading_type);


--
-- Name: sensor_readings_2026_10_sensor_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sensor_readings_2026_10_sensor_id_idx ON public.sensor_readings_2026_10 USING btree (sensor_id);


--
-- Name: sensor_readings_2026_10_sensor_id_recorded_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sensor_readings_2026_10_sensor_id_recorded_at_idx ON public.sensor_readings_2026_10 USING btree (sensor_id, recorded_at);


--
-- Name: sensor_readings_2026_11_reading_type_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sensor_readings_2026_11_reading_type_idx ON public.sensor_readings_2026_11 USING btree (reading_type);


--
-- Name: sensor_readings_2026_11_sensor_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sensor_readings_2026_11_sensor_id_idx ON public.sensor_readings_2026_11 USING btree (sensor_id);


--
-- Name: sensor_readings_2026_11_sensor_id_recorded_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sensor_readings_2026_11_sensor_id_recorded_at_idx ON public.sensor_readings_2026_11 USING btree (sensor_id, recorded_at);


--
-- Name: sensor_readings_2026_12_reading_type_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sensor_readings_2026_12_reading_type_idx ON public.sensor_readings_2026_12 USING btree (reading_type);


--
-- Name: sensor_readings_2026_12_sensor_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sensor_readings_2026_12_sensor_id_idx ON public.sensor_readings_2026_12 USING btree (sensor_id);


--
-- Name: sensor_readings_2026_12_sensor_id_recorded_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sensor_readings_2026_12_sensor_id_recorded_at_idx ON public.sensor_readings_2026_12 USING btree (sensor_id, recorded_at);


--
-- Name: sensor_readings_2027_01_reading_type_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sensor_readings_2027_01_reading_type_idx ON public.sensor_readings_2027_01 USING btree (reading_type);


--
-- Name: sensor_readings_2027_01_sensor_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sensor_readings_2027_01_sensor_id_idx ON public.sensor_readings_2027_01 USING btree (sensor_id);


--
-- Name: sensor_readings_2027_01_sensor_id_recorded_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sensor_readings_2027_01_sensor_id_recorded_at_idx ON public.sensor_readings_2027_01 USING btree (sensor_id, recorded_at);


--
-- Name: sensor_readings_2027_02_reading_type_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sensor_readings_2027_02_reading_type_idx ON public.sensor_readings_2027_02 USING btree (reading_type);


--
-- Name: sensor_readings_2027_02_sensor_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sensor_readings_2027_02_sensor_id_idx ON public.sensor_readings_2027_02 USING btree (sensor_id);


--
-- Name: sensor_readings_2027_02_sensor_id_recorded_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sensor_readings_2027_02_sensor_id_recorded_at_idx ON public.sensor_readings_2027_02 USING btree (sensor_id, recorded_at);


--
-- Name: sensor_readings_2027_03_reading_type_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sensor_readings_2027_03_reading_type_idx ON public.sensor_readings_2027_03 USING btree (reading_type);


--
-- Name: sensor_readings_2027_03_sensor_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sensor_readings_2027_03_sensor_id_idx ON public.sensor_readings_2027_03 USING btree (sensor_id);


--
-- Name: sensor_readings_2027_03_sensor_id_recorded_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sensor_readings_2027_03_sensor_id_recorded_at_idx ON public.sensor_readings_2027_03 USING btree (sensor_id, recorded_at);


--
-- Name: sensor_readings_2027_04_reading_type_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sensor_readings_2027_04_reading_type_idx ON public.sensor_readings_2027_04 USING btree (reading_type);


--
-- Name: sensor_readings_2027_04_sensor_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sensor_readings_2027_04_sensor_id_idx ON public.sensor_readings_2027_04 USING btree (sensor_id);


--
-- Name: sensor_readings_2027_04_sensor_id_recorded_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sensor_readings_2027_04_sensor_id_recorded_at_idx ON public.sensor_readings_2027_04 USING btree (sensor_id, recorded_at);


--
-- Name: sensor_readings_2027_05_reading_type_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sensor_readings_2027_05_reading_type_idx ON public.sensor_readings_2027_05 USING btree (reading_type);


--
-- Name: sensor_readings_2027_05_sensor_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sensor_readings_2027_05_sensor_id_idx ON public.sensor_readings_2027_05 USING btree (sensor_id);


--
-- Name: sensor_readings_2027_05_sensor_id_recorded_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sensor_readings_2027_05_sensor_id_recorded_at_idx ON public.sensor_readings_2027_05 USING btree (sensor_id, recorded_at);


--
-- Name: sensor_readings_2027_06_reading_type_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sensor_readings_2027_06_reading_type_idx ON public.sensor_readings_2027_06 USING btree (reading_type);


--
-- Name: sensor_readings_2027_06_sensor_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sensor_readings_2027_06_sensor_id_idx ON public.sensor_readings_2027_06 USING btree (sensor_id);


--
-- Name: sensor_readings_2027_06_sensor_id_recorded_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sensor_readings_2027_06_sensor_id_recorded_at_idx ON public.sensor_readings_2027_06 USING btree (sensor_id, recorded_at);


--
-- Name: sensor_readings_2027_07_reading_type_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sensor_readings_2027_07_reading_type_idx ON public.sensor_readings_2027_07 USING btree (reading_type);


--
-- Name: sensor_readings_2027_07_sensor_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sensor_readings_2027_07_sensor_id_idx ON public.sensor_readings_2027_07 USING btree (sensor_id);


--
-- Name: sensor_readings_2027_07_sensor_id_recorded_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sensor_readings_2027_07_sensor_id_recorded_at_idx ON public.sensor_readings_2027_07 USING btree (sensor_id, recorded_at);


--
-- Name: sensor_readings_2027_08_reading_type_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sensor_readings_2027_08_reading_type_idx ON public.sensor_readings_2027_08 USING btree (reading_type);


--
-- Name: sensor_readings_2027_08_sensor_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sensor_readings_2027_08_sensor_id_idx ON public.sensor_readings_2027_08 USING btree (sensor_id);


--
-- Name: sensor_readings_2027_08_sensor_id_recorded_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sensor_readings_2027_08_sensor_id_recorded_at_idx ON public.sensor_readings_2027_08 USING btree (sensor_id, recorded_at);


--
-- Name: sensor_readings_2027_09_reading_type_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sensor_readings_2027_09_reading_type_idx ON public.sensor_readings_2027_09 USING btree (reading_type);


--
-- Name: sensor_readings_2027_09_sensor_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sensor_readings_2027_09_sensor_id_idx ON public.sensor_readings_2027_09 USING btree (sensor_id);


--
-- Name: sensor_readings_2027_09_sensor_id_recorded_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sensor_readings_2027_09_sensor_id_recorded_at_idx ON public.sensor_readings_2027_09 USING btree (sensor_id, recorded_at);


--
-- Name: sensor_readings_2027_10_reading_type_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sensor_readings_2027_10_reading_type_idx ON public.sensor_readings_2027_10 USING btree (reading_type);


--
-- Name: sensor_readings_2027_10_sensor_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sensor_readings_2027_10_sensor_id_idx ON public.sensor_readings_2027_10 USING btree (sensor_id);


--
-- Name: sensor_readings_2027_10_sensor_id_recorded_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sensor_readings_2027_10_sensor_id_recorded_at_idx ON public.sensor_readings_2027_10 USING btree (sensor_id, recorded_at);


--
-- Name: sensor_readings_2027_11_reading_type_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sensor_readings_2027_11_reading_type_idx ON public.sensor_readings_2027_11 USING btree (reading_type);


--
-- Name: sensor_readings_2027_11_sensor_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sensor_readings_2027_11_sensor_id_idx ON public.sensor_readings_2027_11 USING btree (sensor_id);


--
-- Name: sensor_readings_2027_11_sensor_id_recorded_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sensor_readings_2027_11_sensor_id_recorded_at_idx ON public.sensor_readings_2027_11 USING btree (sensor_id, recorded_at);


--
-- Name: sensor_readings_2027_12_reading_type_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sensor_readings_2027_12_reading_type_idx ON public.sensor_readings_2027_12 USING btree (reading_type);


--
-- Name: sensor_readings_2027_12_sensor_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sensor_readings_2027_12_sensor_id_idx ON public.sensor_readings_2027_12 USING btree (sensor_id);


--
-- Name: sensor_readings_2027_12_sensor_id_recorded_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sensor_readings_2027_12_sensor_id_recorded_at_idx ON public.sensor_readings_2027_12 USING btree (sensor_id, recorded_at);


--
-- Name: sensor_readings_2026_01_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.sensor_readings_pkey ATTACH PARTITION public.sensor_readings_2026_01_pkey;


--
-- Name: sensor_readings_2026_01_reading_type_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sensor_readings_on_reading_type ATTACH PARTITION public.sensor_readings_2026_01_reading_type_idx;


--
-- Name: sensor_readings_2026_01_sensor_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sensor_readings_on_sensor_id ATTACH PARTITION public.sensor_readings_2026_01_sensor_id_idx;


--
-- Name: sensor_readings_2026_01_sensor_id_recorded_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sensor_readings_on_sensor_id_and_recorded_at ATTACH PARTITION public.sensor_readings_2026_01_sensor_id_recorded_at_idx;


--
-- Name: sensor_readings_2026_02_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.sensor_readings_pkey ATTACH PARTITION public.sensor_readings_2026_02_pkey;


--
-- Name: sensor_readings_2026_02_reading_type_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sensor_readings_on_reading_type ATTACH PARTITION public.sensor_readings_2026_02_reading_type_idx;


--
-- Name: sensor_readings_2026_02_sensor_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sensor_readings_on_sensor_id ATTACH PARTITION public.sensor_readings_2026_02_sensor_id_idx;


--
-- Name: sensor_readings_2026_02_sensor_id_recorded_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sensor_readings_on_sensor_id_and_recorded_at ATTACH PARTITION public.sensor_readings_2026_02_sensor_id_recorded_at_idx;


--
-- Name: sensor_readings_2026_03_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.sensor_readings_pkey ATTACH PARTITION public.sensor_readings_2026_03_pkey;


--
-- Name: sensor_readings_2026_03_reading_type_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sensor_readings_on_reading_type ATTACH PARTITION public.sensor_readings_2026_03_reading_type_idx;


--
-- Name: sensor_readings_2026_03_sensor_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sensor_readings_on_sensor_id ATTACH PARTITION public.sensor_readings_2026_03_sensor_id_idx;


--
-- Name: sensor_readings_2026_03_sensor_id_recorded_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sensor_readings_on_sensor_id_and_recorded_at ATTACH PARTITION public.sensor_readings_2026_03_sensor_id_recorded_at_idx;


--
-- Name: sensor_readings_2026_04_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.sensor_readings_pkey ATTACH PARTITION public.sensor_readings_2026_04_pkey;


--
-- Name: sensor_readings_2026_04_reading_type_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sensor_readings_on_reading_type ATTACH PARTITION public.sensor_readings_2026_04_reading_type_idx;


--
-- Name: sensor_readings_2026_04_sensor_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sensor_readings_on_sensor_id ATTACH PARTITION public.sensor_readings_2026_04_sensor_id_idx;


--
-- Name: sensor_readings_2026_04_sensor_id_recorded_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sensor_readings_on_sensor_id_and_recorded_at ATTACH PARTITION public.sensor_readings_2026_04_sensor_id_recorded_at_idx;


--
-- Name: sensor_readings_2026_05_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.sensor_readings_pkey ATTACH PARTITION public.sensor_readings_2026_05_pkey;


--
-- Name: sensor_readings_2026_05_reading_type_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sensor_readings_on_reading_type ATTACH PARTITION public.sensor_readings_2026_05_reading_type_idx;


--
-- Name: sensor_readings_2026_05_sensor_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sensor_readings_on_sensor_id ATTACH PARTITION public.sensor_readings_2026_05_sensor_id_idx;


--
-- Name: sensor_readings_2026_05_sensor_id_recorded_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sensor_readings_on_sensor_id_and_recorded_at ATTACH PARTITION public.sensor_readings_2026_05_sensor_id_recorded_at_idx;


--
-- Name: sensor_readings_2026_06_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.sensor_readings_pkey ATTACH PARTITION public.sensor_readings_2026_06_pkey;


--
-- Name: sensor_readings_2026_06_reading_type_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sensor_readings_on_reading_type ATTACH PARTITION public.sensor_readings_2026_06_reading_type_idx;


--
-- Name: sensor_readings_2026_06_sensor_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sensor_readings_on_sensor_id ATTACH PARTITION public.sensor_readings_2026_06_sensor_id_idx;


--
-- Name: sensor_readings_2026_06_sensor_id_recorded_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sensor_readings_on_sensor_id_and_recorded_at ATTACH PARTITION public.sensor_readings_2026_06_sensor_id_recorded_at_idx;


--
-- Name: sensor_readings_2026_07_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.sensor_readings_pkey ATTACH PARTITION public.sensor_readings_2026_07_pkey;


--
-- Name: sensor_readings_2026_07_reading_type_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sensor_readings_on_reading_type ATTACH PARTITION public.sensor_readings_2026_07_reading_type_idx;


--
-- Name: sensor_readings_2026_07_sensor_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sensor_readings_on_sensor_id ATTACH PARTITION public.sensor_readings_2026_07_sensor_id_idx;


--
-- Name: sensor_readings_2026_07_sensor_id_recorded_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sensor_readings_on_sensor_id_and_recorded_at ATTACH PARTITION public.sensor_readings_2026_07_sensor_id_recorded_at_idx;


--
-- Name: sensor_readings_2026_08_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.sensor_readings_pkey ATTACH PARTITION public.sensor_readings_2026_08_pkey;


--
-- Name: sensor_readings_2026_08_reading_type_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sensor_readings_on_reading_type ATTACH PARTITION public.sensor_readings_2026_08_reading_type_idx;


--
-- Name: sensor_readings_2026_08_sensor_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sensor_readings_on_sensor_id ATTACH PARTITION public.sensor_readings_2026_08_sensor_id_idx;


--
-- Name: sensor_readings_2026_08_sensor_id_recorded_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sensor_readings_on_sensor_id_and_recorded_at ATTACH PARTITION public.sensor_readings_2026_08_sensor_id_recorded_at_idx;


--
-- Name: sensor_readings_2026_09_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.sensor_readings_pkey ATTACH PARTITION public.sensor_readings_2026_09_pkey;


--
-- Name: sensor_readings_2026_09_reading_type_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sensor_readings_on_reading_type ATTACH PARTITION public.sensor_readings_2026_09_reading_type_idx;


--
-- Name: sensor_readings_2026_09_sensor_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sensor_readings_on_sensor_id ATTACH PARTITION public.sensor_readings_2026_09_sensor_id_idx;


--
-- Name: sensor_readings_2026_09_sensor_id_recorded_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sensor_readings_on_sensor_id_and_recorded_at ATTACH PARTITION public.sensor_readings_2026_09_sensor_id_recorded_at_idx;


--
-- Name: sensor_readings_2026_10_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.sensor_readings_pkey ATTACH PARTITION public.sensor_readings_2026_10_pkey;


--
-- Name: sensor_readings_2026_10_reading_type_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sensor_readings_on_reading_type ATTACH PARTITION public.sensor_readings_2026_10_reading_type_idx;


--
-- Name: sensor_readings_2026_10_sensor_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sensor_readings_on_sensor_id ATTACH PARTITION public.sensor_readings_2026_10_sensor_id_idx;


--
-- Name: sensor_readings_2026_10_sensor_id_recorded_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sensor_readings_on_sensor_id_and_recorded_at ATTACH PARTITION public.sensor_readings_2026_10_sensor_id_recorded_at_idx;


--
-- Name: sensor_readings_2026_11_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.sensor_readings_pkey ATTACH PARTITION public.sensor_readings_2026_11_pkey;


--
-- Name: sensor_readings_2026_11_reading_type_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sensor_readings_on_reading_type ATTACH PARTITION public.sensor_readings_2026_11_reading_type_idx;


--
-- Name: sensor_readings_2026_11_sensor_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sensor_readings_on_sensor_id ATTACH PARTITION public.sensor_readings_2026_11_sensor_id_idx;


--
-- Name: sensor_readings_2026_11_sensor_id_recorded_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sensor_readings_on_sensor_id_and_recorded_at ATTACH PARTITION public.sensor_readings_2026_11_sensor_id_recorded_at_idx;


--
-- Name: sensor_readings_2026_12_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.sensor_readings_pkey ATTACH PARTITION public.sensor_readings_2026_12_pkey;


--
-- Name: sensor_readings_2026_12_reading_type_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sensor_readings_on_reading_type ATTACH PARTITION public.sensor_readings_2026_12_reading_type_idx;


--
-- Name: sensor_readings_2026_12_sensor_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sensor_readings_on_sensor_id ATTACH PARTITION public.sensor_readings_2026_12_sensor_id_idx;


--
-- Name: sensor_readings_2026_12_sensor_id_recorded_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sensor_readings_on_sensor_id_and_recorded_at ATTACH PARTITION public.sensor_readings_2026_12_sensor_id_recorded_at_idx;


--
-- Name: sensor_readings_2027_01_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.sensor_readings_pkey ATTACH PARTITION public.sensor_readings_2027_01_pkey;


--
-- Name: sensor_readings_2027_01_reading_type_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sensor_readings_on_reading_type ATTACH PARTITION public.sensor_readings_2027_01_reading_type_idx;


--
-- Name: sensor_readings_2027_01_sensor_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sensor_readings_on_sensor_id ATTACH PARTITION public.sensor_readings_2027_01_sensor_id_idx;


--
-- Name: sensor_readings_2027_01_sensor_id_recorded_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sensor_readings_on_sensor_id_and_recorded_at ATTACH PARTITION public.sensor_readings_2027_01_sensor_id_recorded_at_idx;


--
-- Name: sensor_readings_2027_02_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.sensor_readings_pkey ATTACH PARTITION public.sensor_readings_2027_02_pkey;


--
-- Name: sensor_readings_2027_02_reading_type_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sensor_readings_on_reading_type ATTACH PARTITION public.sensor_readings_2027_02_reading_type_idx;


--
-- Name: sensor_readings_2027_02_sensor_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sensor_readings_on_sensor_id ATTACH PARTITION public.sensor_readings_2027_02_sensor_id_idx;


--
-- Name: sensor_readings_2027_02_sensor_id_recorded_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sensor_readings_on_sensor_id_and_recorded_at ATTACH PARTITION public.sensor_readings_2027_02_sensor_id_recorded_at_idx;


--
-- Name: sensor_readings_2027_03_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.sensor_readings_pkey ATTACH PARTITION public.sensor_readings_2027_03_pkey;


--
-- Name: sensor_readings_2027_03_reading_type_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sensor_readings_on_reading_type ATTACH PARTITION public.sensor_readings_2027_03_reading_type_idx;


--
-- Name: sensor_readings_2027_03_sensor_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sensor_readings_on_sensor_id ATTACH PARTITION public.sensor_readings_2027_03_sensor_id_idx;


--
-- Name: sensor_readings_2027_03_sensor_id_recorded_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sensor_readings_on_sensor_id_and_recorded_at ATTACH PARTITION public.sensor_readings_2027_03_sensor_id_recorded_at_idx;


--
-- Name: sensor_readings_2027_04_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.sensor_readings_pkey ATTACH PARTITION public.sensor_readings_2027_04_pkey;


--
-- Name: sensor_readings_2027_04_reading_type_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sensor_readings_on_reading_type ATTACH PARTITION public.sensor_readings_2027_04_reading_type_idx;


--
-- Name: sensor_readings_2027_04_sensor_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sensor_readings_on_sensor_id ATTACH PARTITION public.sensor_readings_2027_04_sensor_id_idx;


--
-- Name: sensor_readings_2027_04_sensor_id_recorded_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sensor_readings_on_sensor_id_and_recorded_at ATTACH PARTITION public.sensor_readings_2027_04_sensor_id_recorded_at_idx;


--
-- Name: sensor_readings_2027_05_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.sensor_readings_pkey ATTACH PARTITION public.sensor_readings_2027_05_pkey;


--
-- Name: sensor_readings_2027_05_reading_type_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sensor_readings_on_reading_type ATTACH PARTITION public.sensor_readings_2027_05_reading_type_idx;


--
-- Name: sensor_readings_2027_05_sensor_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sensor_readings_on_sensor_id ATTACH PARTITION public.sensor_readings_2027_05_sensor_id_idx;


--
-- Name: sensor_readings_2027_05_sensor_id_recorded_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sensor_readings_on_sensor_id_and_recorded_at ATTACH PARTITION public.sensor_readings_2027_05_sensor_id_recorded_at_idx;


--
-- Name: sensor_readings_2027_06_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.sensor_readings_pkey ATTACH PARTITION public.sensor_readings_2027_06_pkey;


--
-- Name: sensor_readings_2027_06_reading_type_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sensor_readings_on_reading_type ATTACH PARTITION public.sensor_readings_2027_06_reading_type_idx;


--
-- Name: sensor_readings_2027_06_sensor_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sensor_readings_on_sensor_id ATTACH PARTITION public.sensor_readings_2027_06_sensor_id_idx;


--
-- Name: sensor_readings_2027_06_sensor_id_recorded_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sensor_readings_on_sensor_id_and_recorded_at ATTACH PARTITION public.sensor_readings_2027_06_sensor_id_recorded_at_idx;


--
-- Name: sensor_readings_2027_07_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.sensor_readings_pkey ATTACH PARTITION public.sensor_readings_2027_07_pkey;


--
-- Name: sensor_readings_2027_07_reading_type_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sensor_readings_on_reading_type ATTACH PARTITION public.sensor_readings_2027_07_reading_type_idx;


--
-- Name: sensor_readings_2027_07_sensor_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sensor_readings_on_sensor_id ATTACH PARTITION public.sensor_readings_2027_07_sensor_id_idx;


--
-- Name: sensor_readings_2027_07_sensor_id_recorded_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sensor_readings_on_sensor_id_and_recorded_at ATTACH PARTITION public.sensor_readings_2027_07_sensor_id_recorded_at_idx;


--
-- Name: sensor_readings_2027_08_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.sensor_readings_pkey ATTACH PARTITION public.sensor_readings_2027_08_pkey;


--
-- Name: sensor_readings_2027_08_reading_type_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sensor_readings_on_reading_type ATTACH PARTITION public.sensor_readings_2027_08_reading_type_idx;


--
-- Name: sensor_readings_2027_08_sensor_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sensor_readings_on_sensor_id ATTACH PARTITION public.sensor_readings_2027_08_sensor_id_idx;


--
-- Name: sensor_readings_2027_08_sensor_id_recorded_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sensor_readings_on_sensor_id_and_recorded_at ATTACH PARTITION public.sensor_readings_2027_08_sensor_id_recorded_at_idx;


--
-- Name: sensor_readings_2027_09_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.sensor_readings_pkey ATTACH PARTITION public.sensor_readings_2027_09_pkey;


--
-- Name: sensor_readings_2027_09_reading_type_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sensor_readings_on_reading_type ATTACH PARTITION public.sensor_readings_2027_09_reading_type_idx;


--
-- Name: sensor_readings_2027_09_sensor_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sensor_readings_on_sensor_id ATTACH PARTITION public.sensor_readings_2027_09_sensor_id_idx;


--
-- Name: sensor_readings_2027_09_sensor_id_recorded_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sensor_readings_on_sensor_id_and_recorded_at ATTACH PARTITION public.sensor_readings_2027_09_sensor_id_recorded_at_idx;


--
-- Name: sensor_readings_2027_10_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.sensor_readings_pkey ATTACH PARTITION public.sensor_readings_2027_10_pkey;


--
-- Name: sensor_readings_2027_10_reading_type_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sensor_readings_on_reading_type ATTACH PARTITION public.sensor_readings_2027_10_reading_type_idx;


--
-- Name: sensor_readings_2027_10_sensor_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sensor_readings_on_sensor_id ATTACH PARTITION public.sensor_readings_2027_10_sensor_id_idx;


--
-- Name: sensor_readings_2027_10_sensor_id_recorded_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sensor_readings_on_sensor_id_and_recorded_at ATTACH PARTITION public.sensor_readings_2027_10_sensor_id_recorded_at_idx;


--
-- Name: sensor_readings_2027_11_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.sensor_readings_pkey ATTACH PARTITION public.sensor_readings_2027_11_pkey;


--
-- Name: sensor_readings_2027_11_reading_type_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sensor_readings_on_reading_type ATTACH PARTITION public.sensor_readings_2027_11_reading_type_idx;


--
-- Name: sensor_readings_2027_11_sensor_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sensor_readings_on_sensor_id ATTACH PARTITION public.sensor_readings_2027_11_sensor_id_idx;


--
-- Name: sensor_readings_2027_11_sensor_id_recorded_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sensor_readings_on_sensor_id_and_recorded_at ATTACH PARTITION public.sensor_readings_2027_11_sensor_id_recorded_at_idx;


--
-- Name: sensor_readings_2027_12_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.sensor_readings_pkey ATTACH PARTITION public.sensor_readings_2027_12_pkey;


--
-- Name: sensor_readings_2027_12_reading_type_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sensor_readings_on_reading_type ATTACH PARTITION public.sensor_readings_2027_12_reading_type_idx;


--
-- Name: sensor_readings_2027_12_sensor_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sensor_readings_on_sensor_id ATTACH PARTITION public.sensor_readings_2027_12_sensor_id_idx;


--
-- Name: sensor_readings_2027_12_sensor_id_recorded_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sensor_readings_on_sensor_id_and_recorded_at ATTACH PARTITION public.sensor_readings_2027_12_sensor_id_recorded_at_idx;


--
-- Name: sensors fk_rails_0d0b7ffa32; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sensors
    ADD CONSTRAINT fk_rails_0d0b7ffa32 FOREIGN KEY (monitoring_station_id) REFERENCES public.monitoring_stations(id);


--
-- Name: monitoring_stations fk_rails_16c6dcc99e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.monitoring_stations
    ADD CONSTRAINT fk_rails_16c6dcc99e FOREIGN KEY (neighborhood_id) REFERENCES public.neighborhoods(id);


--
-- Name: alert_thresholds fk_rails_1c9cdd6425; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alert_thresholds
    ADD CONSTRAINT fk_rails_1c9cdd6425 FOREIGN KEY (river_id) REFERENCES public.rivers(id);


--
-- Name: solid_queue_recurring_executions fk_rails_318a5533ed; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_recurring_executions
    ADD CONSTRAINT fk_rails_318a5533ed FOREIGN KEY (job_id) REFERENCES public.solid_queue_jobs(id) ON DELETE CASCADE;


--
-- Name: solid_queue_failed_executions fk_rails_39bbc7a631; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_failed_executions
    ADD CONSTRAINT fk_rails_39bbc7a631 FOREIGN KEY (job_id) REFERENCES public.solid_queue_jobs(id) ON DELETE CASCADE;


--
-- Name: evacuation_routes fk_rails_40017d9618; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evacuation_routes
    ADD CONSTRAINT fk_rails_40017d9618 FOREIGN KEY (river_basin_id) REFERENCES public.river_basins(id);


--
-- Name: monitoring_stations fk_rails_43d6326617; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.monitoring_stations
    ADD CONSTRAINT fk_rails_43d6326617 FOREIGN KEY (river_id) REFERENCES public.rivers(id);


--
-- Name: solid_queue_blocked_executions fk_rails_4cd34e2228; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_blocked_executions
    ADD CONSTRAINT fk_rails_4cd34e2228 FOREIGN KEY (job_id) REFERENCES public.solid_queue_jobs(id) ON DELETE CASCADE;


--
-- Name: alert_thresholds fk_rails_4dd5cfd18f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alert_thresholds
    ADD CONSTRAINT fk_rails_4dd5cfd18f FOREIGN KEY (river_basin_id) REFERENCES public.river_basins(id);


--
-- Name: alerts fk_rails_5cf64a5041; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alerts
    ADD CONSTRAINT fk_rails_5cf64a5041 FOREIGN KEY (alert_threshold_id) REFERENCES public.alert_thresholds(id);


--
-- Name: sessions fk_rails_758836b4f0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT fk_rails_758836b4f0 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: solid_queue_ready_executions fk_rails_81fcbd66af; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_ready_executions
    ADD CONSTRAINT fk_rails_81fcbd66af FOREIGN KEY (job_id) REFERENCES public.solid_queue_jobs(id) ON DELETE CASCADE;


--
-- Name: monitoring_stations fk_rails_83953127ac; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.monitoring_stations
    ADD CONSTRAINT fk_rails_83953127ac FOREIGN KEY (river_basin_id) REFERENCES public.river_basins(id);


--
-- Name: alerts fk_rails_8426bfc331; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alerts
    ADD CONSTRAINT fk_rails_8426bfc331 FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: rivers fk_rails_86c7a5cf9d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rivers
    ADD CONSTRAINT fk_rails_86c7a5cf9d FOREIGN KEY (river_basin_id) REFERENCES public.river_basins(id);


--
-- Name: alerts fk_rails_955ec70dfc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alerts
    ADD CONSTRAINT fk_rails_955ec70dfc FOREIGN KEY (neighborhood_id) REFERENCES public.neighborhoods(id);


--
-- Name: alerts fk_rails_97d953eac8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alerts
    ADD CONSTRAINT fk_rails_97d953eac8 FOREIGN KEY (river_basin_id) REFERENCES public.river_basins(id);


--
-- Name: solid_queue_claimed_executions fk_rails_9cfe4d4944; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_claimed_executions
    ADD CONSTRAINT fk_rails_9cfe4d4944 FOREIGN KEY (job_id) REFERENCES public.solid_queue_jobs(id) ON DELETE CASCADE;


--
-- Name: alerts fk_rails_a373ae3498; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alerts
    ADD CONSTRAINT fk_rails_a373ae3498 FOREIGN KEY (river_id) REFERENCES public.rivers(id);


--
-- Name: solid_queue_scheduled_executions fk_rails_c4316f352d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_scheduled_executions
    ADD CONSTRAINT fk_rails_c4316f352d FOREIGN KEY (job_id) REFERENCES public.solid_queue_jobs(id) ON DELETE CASCADE;


--
-- Name: alerts fk_rails_d57155fb1b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alerts
    ADD CONSTRAINT fk_rails_d57155fb1b FOREIGN KEY (resolved_by_id) REFERENCES public.users(id);


--
-- Name: risk_assessments fk_rails_dfc4c4b3ee; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.risk_assessments
    ADD CONSTRAINT fk_rails_dfc4c4b3ee FOREIGN KEY (river_basin_id) REFERENCES public.river_basins(id);


--
-- Name: neighborhoods fk_rails_ed97da2abb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.neighborhoods
    ADD CONSTRAINT fk_rails_ed97da2abb FOREIGN KEY (region_id) REFERENCES public.regions(id);


--
-- Name: alert_notifications fk_rails_ee7a462e3e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alert_notifications
    ADD CONSTRAINT fk_rails_ee7a462e3e FOREIGN KEY (alert_id) REFERENCES public.alerts(id);


--
-- Name: sensor_readings fk_sensor_readings_sensors; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.sensor_readings
    ADD CONSTRAINT fk_sensor_readings_sensors FOREIGN KEY (sensor_id) REFERENCES public.sensors(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20260327163247'),
('20260326221300'),
('20260326221155'),
('20260326221041'),
('20260325234909'),
('20260324205844'),
('20260324000233'),
('20260321000024'),
('20260321000023'),
('20260321000022'),
('20260321000021'),
('20260321000020'),
('20260321000017'),
('20260321000016'),
('20260321000015'),
('20260321000014'),
('20260321000013'),
('20260321000012'),
('20260321000011'),
('20260321000010'),
('20260321000007'),
('20260321000006'),
('20260321000005'),
('20260321000004'),
('20260321000003'),
('20260321000002'),
('20260321000001'),
('1');

