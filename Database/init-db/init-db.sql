--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;


CREATE DATABASE ngnms WITH TEMPLATE = template0 ENCODING = 'UTF8' LC_COLLATE = 'en_US.UTF-8' LC_CTYPE = 'en_US.UTF-8';


ALTER DATABASE ngnms OWNER TO ngnms;

\connect ngnms

--
-- Name: jobmachine; Type: SCHEMA; Schema: -; Owner: ngnms
--

CREATE SCHEMA jobmachine;


ALTER SCHEMA jobmachine OWNER TO ngnms;



SET search_path = jobmachine, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: class; Type: TABLE; Schema: jobmachine; Owner: ngnms; Tablespace:
--

CREATE TABLE class (
    class_id integer NOT NULL,
    name text,
    created timestamp without time zone DEFAULT now() NOT NULL,
    modified timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE jobmachine.class OWNER TO ngnms;

--
-- Name: TABLE class; Type: COMMENT; Schema: jobmachine; Owner: ngnms
--

COMMENT ON TABLE class IS 'Task class';


--
-- Name: COLUMN class.class_id; Type: COMMENT; Schema: jobmachine; Owner: ngnms
--

COMMENT ON COLUMN class.class_id IS 'Unique identification';


--
-- Name: COLUMN class.name; Type: COMMENT; Schema: jobmachine; Owner: ngnms
--

COMMENT ON COLUMN class.name IS 'Job class name';


--
-- Name: COLUMN class.created; Type: COMMENT; Schema: jobmachine; Owner: ngnms
--

COMMENT ON COLUMN class.created IS 'Timestamp for row creation';


--
-- Name: COLUMN class.modified; Type: COMMENT; Schema: jobmachine; Owner: ngnms
--

COMMENT ON COLUMN class.modified IS 'Timestamp for latest update of this row';


--
-- Name: class_class_id_seq; Type: SEQUENCE; Schema: jobmachine; Owner: ngnms
--

CREATE SEQUENCE class_class_id_seq
START WITH 1
INCREMENT BY 1
NO MINVALUE
NO MAXVALUE
CACHE 1;


ALTER TABLE jobmachine.class_class_id_seq OWNER TO ngnms;

--
-- Name: class_class_id_seq; Type: SEQUENCE OWNED BY; Schema: jobmachine; Owner: ngnms
--

ALTER SEQUENCE class_class_id_seq OWNED BY class.class_id;


--
-- Name: result; Type: TABLE; Schema: jobmachine; Owner: ngnms; Tablespace:
--

CREATE TABLE result (
    result_id integer NOT NULL,
    task_id integer,
    result text,
    resulttype text,
    created timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE jobmachine.result OWNER TO ngnms;

--
-- Name: TABLE result; Type: COMMENT; Schema: jobmachine; Owner: ngnms
--

COMMENT ON TABLE result IS 'Results';


--
-- Name: COLUMN result.result_id; Type: COMMENT; Schema: jobmachine; Owner: ngnms
--

COMMENT ON COLUMN result.result_id IS 'Unique identification';


--
-- Name: COLUMN result.task_id; Type: COMMENT; Schema: jobmachine; Owner: ngnms
--

COMMENT ON COLUMN result.task_id IS 'Task of the result';


--
-- Name: COLUMN result.result; Type: COMMENT; Schema: jobmachine; Owner: ngnms
--

COMMENT ON COLUMN result.result IS 'Result of the job';


--
-- Name: COLUMN result.resulttype; Type: COMMENT; Schema: jobmachine; Owner: ngnms
--

COMMENT ON COLUMN result.resulttype IS 'Type of result: xml, html, etc';


--
-- Name: COLUMN result.created; Type: COMMENT; Schema: jobmachine; Owner: ngnms
--

COMMENT ON COLUMN result.created IS 'Timestamp for row creation';


--
-- Name: task; Type: TABLE; Schema: jobmachine; Owner: ngnms; Tablespace:
--

CREATE TABLE task (
    task_id integer NOT NULL,
    transaction_id integer,
    class_id integer,
    grouping text,
    title text,
    parameters text,
    status integer NOT NULL,
    run_after timestamp without time zone,
    remove_after timestamp without time zone,
    created timestamp without time zone DEFAULT now() NOT NULL,
    modified timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE jobmachine.task OWNER TO ngnms;

--
-- Name: TABLE task; Type: COMMENT; Schema: jobmachine; Owner: ngnms
--

COMMENT ON TABLE task IS 'Tasks';


--
-- Name: COLUMN task.task_id; Type: COMMENT; Schema: jobmachine; Owner: ngnms
--

COMMENT ON COLUMN task.task_id IS 'Unique identification';


--
-- Name: COLUMN task.transaction_id; Type: COMMENT; Schema: jobmachine; Owner: ngnms
--

COMMENT ON COLUMN task.transaction_id IS 'If several tasks need to be executed in sequence';


--
-- Name: COLUMN task.class_id; Type: COMMENT; Schema: jobmachine; Owner: ngnms
--

COMMENT ON COLUMN task.class_id IS 'Job class to be executed';


--
-- Name: COLUMN task.grouping; Type: COMMENT; Schema: jobmachine; Owner: ngnms
--

COMMENT ON COLUMN task.grouping IS 'Optional job group. Jobs will be retrieved by group if defined';


--
-- Name: COLUMN task.title; Type: COMMENT; Schema: jobmachine; Owner: ngnms
--

COMMENT ON COLUMN task.title IS 'Optional job title';


--
-- Name: COLUMN task.parameters; Type: COMMENT; Schema: jobmachine; Owner: ngnms
--

COMMENT ON COLUMN task.parameters IS 'from client to the scheduled task. Serialized as JSON';


--
-- Name: COLUMN task.status; Type: COMMENT; Schema: jobmachine; Owner: ngnms
--

COMMENT ON COLUMN task.status IS '0 - entered, 100 - processing started, 200 - processing finished, - 900 - processing finished w/ error';


--
-- Name: COLUMN task.run_after; Type: COMMENT; Schema: jobmachine; Owner: ngnms
--

COMMENT ON COLUMN task.run_after IS 'Wait until this time to run the task';


--
-- Name: COLUMN task.remove_after; Type: COMMENT; Schema: jobmachine; Owner: ngnms
--

COMMENT ON COLUMN task.remove_after IS 'Wait until this time to delete the task';


--
-- Name: COLUMN task.created; Type: COMMENT; Schema: jobmachine; Owner: ngnms
--

COMMENT ON COLUMN task.created IS 'Timestamp for row creation';


--
-- Name: COLUMN task.modified; Type: COMMENT; Schema: jobmachine; Owner: ngnms
--

COMMENT ON COLUMN task.modified IS 'Timestamp for latest update of this row';


--
-- Name: fulltask; Type: VIEW; Schema: jobmachine; Owner: ngnms
--

CREATE VIEW fulltask AS
    SELECT task.task_id,
        task.status,
        task.parameters,
        class.name,
        result.result_id,
        result.result
    FROM ((task
        JOIN class USING (class_id))
        LEFT JOIN result USING (task_id));


ALTER TABLE jobmachine.fulltask OWNER TO ngnms;

--
-- Name: result_result_id_seq; Type: SEQUENCE; Schema: jobmachine; Owner: ngnms
--

CREATE SEQUENCE result_result_id_seq
START WITH 1
INCREMENT BY 1
NO MINVALUE
NO MAXVALUE
CACHE 1;


ALTER TABLE jobmachine.result_result_id_seq OWNER TO ngnms;

--
-- Name: result_result_id_seq; Type: SEQUENCE OWNED BY; Schema: jobmachine; Owner: ngnms
--

ALTER SEQUENCE result_result_id_seq OWNED BY result.result_id;


--
-- Name: task_task_id_seq; Type: SEQUENCE; Schema: jobmachine; Owner: ngnms
--

CREATE SEQUENCE task_task_id_seq
START WITH 1
INCREMENT BY 1
NO MINVALUE
NO MAXVALUE
CACHE 1;


ALTER TABLE jobmachine.task_task_id_seq OWNER TO ngnms;

--
-- Name: task_task_id_seq; Type: SEQUENCE OWNED BY; Schema: jobmachine; Owner: ngnms
--

ALTER SEQUENCE task_task_id_seq OWNED BY task.task_id;


SET search_path = public, pg_catalog;

--
-- Name: access; Type: TABLE; Schema: public; Owner: ngnms; Tablespace:
--

CREATE TABLE access (
    id integer NOT NULL,
    name character varying(150),
    id_access_type integer
);


ALTER TABLE public.access OWNER TO ngnms;

--
-- Name: access_id_seq; Type: SEQUENCE; Schema: public; Owner: ngnms
--

CREATE SEQUENCE access_id_seq
START WITH 1
INCREMENT BY 1
NO MINVALUE
NO MAXVALUE
CACHE 1;


ALTER TABLE public.access_id_seq OWNER TO ngnms;

--
-- Name: access_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ngnms
--

ALTER SEQUENCE access_id_seq OWNED BY access.id;


--
-- Name: access_type; Type: TABLE; Schema: public; Owner: ngnms; Tablespace:
--

CREATE TABLE access_type (
    id integer NOT NULL,
    name character varying(40)
);


ALTER TABLE public.access_type OWNER TO ngnms;

--
-- Name: TABLE access_type; Type: COMMENT; Schema: public; Owner: ngnms
--

COMMENT ON TABLE access_type IS 'type of access to routers';


--
-- Name: access_type_id_seq; Type: SEQUENCE; Schema: public; Owner: ngnms
--

CREATE SEQUENCE access_type_id_seq
START WITH 1
INCREMENT BY 1
NO MINVALUE
NO MAXVALUE
CACHE 1;


ALTER TABLE public.access_type_id_seq OWNER TO ngnms;

--
-- Name: access_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ngnms
--

ALTER SEQUENCE access_type_id_seq OWNED BY access_type.id;


--
-- Name: admrecords; Type: TABLE; Schema: public; Owner: ngnms; Tablespace:
--

CREATE TABLE admrecords (
    rec_id integer DEFAULT nextval(('"admrecords_RecID_seq"'::text)::regclass) NOT NULL,
    date_time timestamp without time zone NOT NULL,
    who character varying(20) NOT NULL,
    action character varying(20) NOT NULL,
    obj_type integer DEFAULT (-1),
    obj_id integer DEFAULT (-1)
);


ALTER TABLE public.admrecords OWNER TO ngnms;

--
-- Name: admrecords_RecID_seq; Type: SEQUENCE; Schema: public; Owner: ngnms
--

CREATE SEQUENCE "admrecords_RecID_seq"
START WITH 1
INCREMENT BY 1
NO MINVALUE
NO MAXVALUE
CACHE 1;


ALTER TABLE public."admrecords_RecID_seq" OWNER TO ngnms;

--
-- Name: archive_conf; Type: TABLE; Schema: public; Owner: ngnms; Tablespace:
--

CREATE TABLE archive_conf (
    arc_expire character varying(10),
    arc_delete character varying(10),
    arc_period character varying(4),
    arc_enable smallint DEFAULT 0,
    arc_path character varying(100),
    log_syslog smallint DEFAULT 1,
    log_level smallint DEFAULT 6,
    arc_gzip smallint DEFAULT 0,
    id_conf integer NOT NULL
);


ALTER TABLE public.archive_conf OWNER TO ngnms;

--
-- Name: COLUMN archive_conf.arc_expire; Type: COMMENT; Schema: public; Owner: ngnms
--

COMMENT ON COLUMN archive_conf.arc_expire IS 'ArcTimeout';


--
-- Name: COLUMN archive_conf.arc_delete; Type: COMMENT; Schema: public; Owner: ngnms
--

COMMENT ON COLUMN archive_conf.arc_delete IS 'ArcDelTimeout';


--
-- Name: COLUMN archive_conf.arc_period; Type: COMMENT; Schema: public; Owner: ngnms
--

COMMENT ON COLUMN archive_conf.arc_period IS 'period for cron';


--
-- Name: archive_conf_id_conf_seq; Type: SEQUENCE; Schema: public; Owner: ngnms
--

CREATE SEQUENCE archive_conf_id_conf_seq
START WITH 1
INCREMENT BY 1
NO MINVALUE
NO MAXVALUE
CACHE 1;


ALTER TABLE public.archive_conf_id_conf_seq OWNER TO ngnms;

--
-- Name: archive_conf_id_conf_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ngnms
--

ALTER SEQUENCE archive_conf_id_conf_seq OWNED BY archive_conf.id_conf;


--
-- Name: archive_tables; Type: TABLE; Schema: public; Owner: ngnms; Tablespace:
--

CREATE TABLE archive_tables (
    id integer DEFAULT nextval(('"archive_tables_id_seq"'::text)::regclass) NOT NULL,
    table_name character varying(50) NOT NULL,
    start_time timestamp with time zone NOT NULL,
    end_time timestamp with time zone NOT NULL,
    archive_id integer NOT NULL,
    records_count integer,
    microsecounds real
);
ALTER TABLE ONLY archive_tables ALTER COLUMN id SET STATISTICS 0;


ALTER TABLE public.archive_tables OWNER TO ngnms;

--
-- Name: archive_tables_id_seq; Type: SEQUENCE; Schema: public; Owner: ngnms
--

CREATE SEQUENCE archive_tables_id_seq
START WITH 1
INCREMENT BY 1
NO MINVALUE
NO MAXVALUE
CACHE 1;


ALTER TABLE public.archive_tables_id_seq OWNER TO ngnms;

--
-- Name: archives; Type: TABLE; Schema: public; Owner: ngnms; Tablespace:
--

CREATE TABLE archives (
    archive_id integer DEFAULT nextval(('"archives_archive_id_seq"'::text)::regclass) NOT NULL,
    start_time timestamp with time zone NOT NULL,
    end_time timestamp with time zone NOT NULL,
    file_name character varying(64) NOT NULL,
    in_db boolean DEFAULT false NOT NULL
);


ALTER TABLE public.archives OWNER TO ngnms;

--
-- Name: archives_archive_id_seq; Type: SEQUENCE; Schema: public; Owner: ngnms
--

CREATE SEQUENCE archives_archive_id_seq
START WITH 1
INCREMENT BY 1
NO MINVALUE
NO MAXVALUE
CACHE 1;


ALTER TABLE public.archives_archive_id_seq OWNER TO ngnms;

--
-- Name: attr; Type: TABLE; Schema: public; Owner: ngnms; Tablespace:
--

CREATE TABLE attr (
    id integer NOT NULL,
    name character varying(100)
);


ALTER TABLE public.attr OWNER TO ngnms;

--
-- Name: attr_access; Type: TABLE; Schema: public; Owner: ngnms; Tablespace:
--

CREATE TABLE attr_access (
    id integer NOT NULL,
    id_access_type integer,
    id_attr integer
);


ALTER TABLE public.attr_access OWNER TO ngnms;

--
-- Name: attr_access_id_seq; Type: SEQUENCE; Schema: public; Owner: ngnms
--

CREATE SEQUENCE attr_access_id_seq
START WITH 1
INCREMENT BY 1
NO MINVALUE
NO MAXVALUE
CACHE 1;


ALTER TABLE public.attr_access_id_seq OWNER TO ngnms;

--
-- Name: attr_access_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ngnms
--

ALTER SEQUENCE attr_access_id_seq OWNED BY attr_access.id;


--
-- Name: attr_id_seq; Type: SEQUENCE; Schema: public; Owner: ngnms
--

CREATE SEQUENCE attr_id_seq
START WITH 1
INCREMENT BY 1
NO MINVALUE
NO MAXVALUE
CACHE 1;


ALTER TABLE public.attr_id_seq OWNER TO ngnms;

--
-- Name: attr_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ngnms
--

ALTER SEQUENCE attr_id_seq OWNED BY attr.id;


--
-- Name: attr_value; Type: TABLE; Schema: public; Owner: ngnms; Tablespace:
--

CREATE TABLE attr_value (
    id integer NOT NULL,
    id_attr_access integer,
    id_access integer,
    value text
);


ALTER TABLE public.attr_value OWNER TO ngnms;

--
-- Name: attr_value_id_seq; Type: SEQUENCE; Schema: public; Owner: ngnms
--

CREATE SEQUENCE attr_value_id_seq
START WITH 1
INCREMENT BY 1
NO MINVALUE
NO MAXVALUE
CACHE 1;


ALTER TABLE public.attr_value_id_seq OWNER TO ngnms;

--
-- Name: attr_value_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ngnms
--

ALTER SEQUENCE attr_value_id_seq OWNED BY attr_value.id;


--
-- Name: authassignment; Type: TABLE; Schema: public; Owner: ngnms; Tablespace:
--

CREATE TABLE authassignment (
    itemname character varying(64) NOT NULL,
    userid character varying(64) NOT NULL,
    bizrule text,
    data text
);


ALTER TABLE public.authassignment OWNER TO ngnms;

--
-- Name: authitem; Type: TABLE; Schema: public; Owner: ngnms; Tablespace:
--

CREATE TABLE authitem (
    name character varying(64) NOT NULL,
    type integer NOT NULL,
    description text,
    bizrule text,
    data text
);


ALTER TABLE public.authitem OWNER TO ngnms;

--
-- Name: authitemchild; Type: TABLE; Schema: public; Owner: ngnms; Tablespace:
--

CREATE TABLE authitemchild (
    parent character varying(64) NOT NULL,
    child character varying(64) NOT NULL
);


ALTER TABLE public.authitemchild OWNER TO ngnms;

--
-- Name: bans_ips; Type: TABLE; Schema: public; Owner: ngnms; Tablespace:
--

CREATE TABLE bans_ips (
    id integer NOT NULL,
    ip inet,
    finish_time integer
);


ALTER TABLE public.bans_ips OWNER TO ngnms;

--
-- Name: bans_ips_id_seq; Type: SEQUENCE; Schema: public; Owner: ngnms
--

CREATE SEQUENCE bans_ips_id_seq
START WITH 1
INCREMENT BY 1
NO MINVALUE
NO MAXVALUE
CACHE 1;


ALTER TABLE public.bans_ips_id_seq OWNER TO ngnms;

--
-- Name: bans_ips_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ngnms
--

ALTER SEQUENCE bans_ips_id_seq OWNED BY bans_ips.id;


--
-- Name: bgp_links; Type: TABLE; Schema: public; Owner: ngnms; Tablespace:
--

CREATE TABLE bgp_links (
    id integer NOT NULL,
    side_a integer,
    side_b integer,
    link_type character varying(30)
);


ALTER TABLE public.bgp_links OWNER TO ngnms;

--
-- Name: bgp_links_id_seq; Type: SEQUENCE; Schema: public; Owner: ngnms
--

CREATE SEQUENCE bgp_links_id_seq
START WITH 1
INCREMENT BY 1
NO MINVALUE
NO MAXVALUE
CACHE 1;


ALTER TABLE public.bgp_links_id_seq OWNER TO ngnms;

--
-- Name: bgp_links_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ngnms
--

ALTER SEQUENCE bgp_links_id_seq OWNED BY bgp_links.id;


--
-- Name: bgp_routers; Type: TABLE; Schema: public; Owner: ngnms; Tablespace:
--

CREATE TABLE bgp_routers (
    id integer NOT NULL,
    bgp_type character varying(30),
    status integer,
    autonomous_system character varying(10),
    ip_addr inet,
    bgp_router_identifier inet
);


ALTER TABLE public.bgp_routers OWNER TO ngnms;

--
-- Name: bgp_routers_id_seq; Type: SEQUENCE; Schema: public; Owner: ngnms
--

CREATE SEQUENCE bgp_routers_id_seq
START WITH 1
INCREMENT BY 1
NO MINVALUE
NO MAXVALUE
CACHE 1;


ALTER TABLE public.bgp_routers_id_seq OWNER TO ngnms;

--
-- Name: bgp_routers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ngnms
--

ALTER SEQUENCE bgp_routers_id_seq OWNED BY bgp_routers.id;


--
-- Name: dbix_migration; Type: TABLE; Schema: public; Owner: ngnms; Tablespace:
--

CREATE TABLE dbix_migration (
    name character(64) NOT NULL,
    value character(64)
);


ALTER TABLE public.dbix_migration OWNER TO ngnms;

--
-- Name: discovery_status; Type: TABLE; Schema: public; Owner: ngnms; Tablespace:
--

CREATE TABLE discovery_status (
    username character varying,
    percent integer,
    lastchange timestamp with time zone,
    finish timestamp with time zone,
    start timestamp with time zone NOT NULL,
    ended integer,
    interactive integer DEFAULT 0
);


ALTER TABLE public.discovery_status OWNER TO ngnms;

--
-- Name: events; Type: TABLE; Schema: public; Owner: ngnms; Tablespace:
--

CREATE TABLE events (
    event_id integer DEFAULT nextval(('"events_event_id_seq"'::text)::regclass) NOT NULL,
    origin_ts timestamp with time zone,
    receiver_ts timestamp with time zone,
    origin character varying(64),
    origin_id integer,
    facility character varying(64),
    code character varying(64),
    descr character varying(10000),
    priority character varying(10),
    severity integer,
    raw_event character varying
);


ALTER TABLE public.events OWNER TO ngnms;

--
-- Name: events_event_id_seq; Type: SEQUENCE; Schema: public; Owner: ngnms
--

CREATE SEQUENCE events_event_id_seq
START WITH 1
INCREMENT BY 1
NO MINVALUE
NO MAXVALUE
CACHE 1;


ALTER TABLE public.events_event_id_seq OWNER TO ngnms;

--
-- Name: failed_logins; Type: TABLE; Schema: public; Owner: ngnms; Tablespace:
--

CREATE TABLE failed_logins (
    id integer NOT NULL,
    ip inet,
    "time" integer
);


ALTER TABLE public.failed_logins OWNER TO ngnms;

--
-- Name: failed_logins_id_seq; Type: SEQUENCE; Schema: public; Owner: ngnms
--

CREATE SEQUENCE failed_logins_id_seq
START WITH 1
INCREMENT BY 1
NO MINVALUE
NO MAXVALUE
CACHE 1;


ALTER TABLE public.failed_logins_id_seq OWNER TO ngnms;

--
-- Name: failed_logins_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ngnms
--

ALTER SEQUENCE failed_logins_id_seq OWNED BY failed_logins.id;


--
-- Name: general_settings; Type: TABLE; Schema: public; Owner: ngnms; Tablespace:
--

CREATE TABLE general_settings (
    id integer NOT NULL,
    name character varying(50),
    value character varying(255),
    label character varying(100),
    order_view smallint
);


ALTER TABLE public.general_settings OWNER TO ngnms;

--
-- Name: general_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: ngnms
--

CREATE SEQUENCE general_settings_id_seq
START WITH 1
INCREMENT BY 1
NO MINVALUE
NO MAXVALUE
CACHE 1;


ALTER TABLE public.general_settings_id_seq OWNER TO ngnms;

--
-- Name: general_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ngnms
--

ALTER SEQUENCE general_settings_id_seq OWNED BY general_settings.id;


--
-- Name: interfaces; Type: TABLE; Schema: public; Owner: ngnms; Tablespace:
--

CREATE TABLE interfaces (
    router_id integer NOT NULL,
    ph_int_id integer NOT NULL,
    ifc_id integer DEFAULT nextval(('"interfaces_ifc_id_seq"'::text)::regclass) NOT NULL,
    name character varying(32) NOT NULL,
    ip_addr inet,
    mask inet,
    descr character varying(100)
);


ALTER TABLE public.interfaces OWNER TO ngnms;

--
-- Name: interfaces_ifc_id_seq; Type: SEQUENCE; Schema: public; Owner: ngnms
--

CREATE SEQUENCE interfaces_ifc_id_seq
START WITH 1
INCREMENT BY 1
NO MINVALUE
NO MAXVALUE
CACHE 1;


ALTER TABLE public.interfaces_ifc_id_seq OWNER TO ngnms;

--
-- Name: inv_hw; Type: TABLE; Schema: public; Owner: ngnms; Tablespace:
--

CREATE TABLE inv_hw (
    router_id integer NOT NULL,
    hw_item character(50) NOT NULL,
    hw_name character(100),
    hw_version character(100),
    hw_amount character(30)
);


ALTER TABLE public.inv_hw OWNER TO ngnms;

--
-- Name: inv_sw; Type: TABLE; Schema: public; Owner: ngnms; Tablespace:
--

CREATE TABLE inv_sw (
    router_id integer NOT NULL,
    sw_item character(50) NOT NULL,
    sw_name character(100),
    sw_version character(100)
);


ALTER TABLE public.inv_sw OWNER TO ngnms;

--
-- Name: locked_ips; Type: TABLE; Schema: public; Owner: ngnms; Tablespace:
--

CREATE TABLE locked_ips (
    id integer NOT NULL,
    ip inet,
    "time" integer
);


ALTER TABLE public.locked_ips OWNER TO ngnms;

--
-- Name: locked_ips_id_seq; Type: SEQUENCE; Schema: public; Owner: ngnms
--

CREATE SEQUENCE locked_ips_id_seq
START WITH 1
INCREMENT BY 1
NO MINVALUE
NO MAXVALUE
CACHE 1;


ALTER TABLE public.locked_ips_id_seq OWNER TO ngnms;

--
-- Name: locked_ips_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ngnms
--

ALTER SEQUENCE locked_ips_id_seq OWNED BY locked_ips.id;


--
-- Name: menu; Type: TABLE; Schema: public; Owner: ngnms; Tablespace:
--

CREATE TABLE menu (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    label character varying(50) NOT NULL
);


ALTER TABLE public.menu OWNER TO ngnms;

--
-- Name: menu_id_seq; Type: SEQUENCE; Schema: public; Owner: ngnms
--

CREATE SEQUENCE menu_id_seq
START WITH 1
INCREMENT BY 1
NO MINVALUE
NO MAXVALUE
CACHE 1;


ALTER TABLE public.menu_id_seq OWNER TO ngnms;

--
-- Name: menu_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ngnms
--

ALTER SEQUENCE menu_id_seq OWNED BY menu.id;


--
-- Name: menuitem; Type: TABLE; Schema: public; Owner: ngnms; Tablespace:
--

CREATE TABLE menuitem (
    id integer NOT NULL,
    name character varying(255) DEFAULT NULL::character varying,
    parentid integer,
    label character varying(50) DEFAULT NULL::character varying,
    ordervalue integer,
    route character varying(255) DEFAULT NULL::character varying,
    accesslevel character varying(255) DEFAULT NULL::character varying,
    depthlevel integer,
    menutypeid character varying(100) DEFAULT NULL::character varying,
    adminnotes text,
    active smallint,
    created timestamp without time zone DEFAULT now(),
    modified timestamp without time zone DEFAULT now() NOT NULL,
    deleted timestamp without time zone,
    icon character varying(255) DEFAULT NULL::character varying
);


ALTER TABLE public.menuitem OWNER TO ngnms;

--
-- Name: menuitem_id_seq; Type: SEQUENCE; Schema: public; Owner: ngnms
--

CREATE SEQUENCE menuitem_id_seq
START WITH 1
INCREMENT BY 1
NO MINVALUE
NO MAXVALUE
CACHE 1;


ALTER TABLE public.menuitem_id_seq OWNER TO ngnms;

--
-- Name: menuitem_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ngnms
--

ALTER SEQUENCE menuitem_id_seq OWNED BY menuitem.id;


--
-- Name: network; Type: TABLE; Schema: public; Owner: ngnms; Tablespace:
--

CREATE TABLE network (
    link_id integer DEFAULT nextval(('"network_link_id_seq"'::text)::regclass) NOT NULL,
    router_id_a integer NOT NULL,
    ifc_id_a integer,
    router_id_b integer NOT NULL,
    ifc_id_b integer,
    link_type character varying(4)
);


ALTER TABLE public.network OWNER TO ngnms;

--
-- Name: network_link_id_seq; Type: SEQUENCE; Schema: public; Owner: ngnms
--

CREATE SEQUENCE network_link_id_seq
START WITH 1
INCREMENT BY 1
NO MINVALUE
NO MAXVALUE
CACHE 1;


ALTER TABLE public.network_link_id_seq OWNER TO ngnms;

--
-- Name: ph_int; Type: TABLE; Schema: public; Owner: ngnms; Tablespace:
--

CREATE TABLE ph_int (
    router_id integer NOT NULL,
    ph_int_id integer DEFAULT nextval(('"ph_int_ph_int_id_seq"'::text)::regclass) NOT NULL,
    name character varying(128) NOT NULL,
    state character varying(8),
    condition character varying(8),
    descr character varying(256),
    speed character varying(20)
);


ALTER TABLE public.ph_int OWNER TO ngnms;

--
-- Name: ph_int_ph_int_id_seq; Type: SEQUENCE; Schema: public; Owner: ngnms
--

CREATE SEQUENCE ph_int_ph_int_id_seq
START WITH 1
INCREMENT BY 1
NO MINVALUE
NO MAXVALUE
CACHE 1;


ALTER TABLE public.ph_int_ph_int_id_seq OWNER TO ngnms;

--
-- Name: router_access; Type: TABLE; Schema: public; Owner: ngnms; Tablespace:
--

CREATE TABLE router_access (
    id integer NOT NULL,
    id_access integer,
    id_router integer
);


ALTER TABLE public.router_access OWNER TO ngnms;

--
-- Name: router_access_id_seq; Type: SEQUENCE; Schema: public; Owner: ngnms
--

CREATE SEQUENCE router_access_id_seq
START WITH 1
INCREMENT BY 1
NO MINVALUE
NO MAXVALUE
CACHE 1;


ALTER TABLE public.router_access_id_seq OWNER TO ngnms;

--
-- Name: router_access_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ngnms
--

ALTER SEQUENCE router_access_id_seq OWNED BY router_access.id;


--
-- Name: router_configuration; Type: TABLE; Schema: public; Owner: ngnms; Tablespace:
--

CREATE TABLE router_configuration (
    id integer NOT NULL,
    router_id integer NOT NULL,
    data bytea NOT NULL,
    created timestamp without time zone DEFAULT now() NOT NULL,
    checksum character varying DEFAULT 32
);


ALTER TABLE public.router_configuration OWNER TO ngnms;

--
-- Name: router_configuration_id_seq; Type: SEQUENCE; Schema: public; Owner: ngnms
--

CREATE SEQUENCE router_configuration_id_seq
START WITH 1
INCREMENT BY 1
NO MINVALUE
NO MAXVALUE
CACHE 1;


ALTER TABLE public.router_configuration_id_seq OWNER TO ngnms;

--
-- Name: router_configuration_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ngnms
--

ALTER SEQUENCE router_configuration_id_seq OWNED BY router_configuration.id;


--
-- Name: router_graph; Type: TABLE; Schema: public; Owner: ngnms; Tablespace:
--

CREATE TABLE router_graph (
    router_id integer NOT NULL,
    x real NOT NULL,
    y real NOT NULL
);


ALTER TABLE public.router_graph OWNER TO ngnms;

--
-- Name: router_icons; Type: TABLE; Schema: public; Owner: ngnms; Tablespace:
--

CREATE TABLE router_icons (
    id integer NOT NULL,
    vendor_name character varying(40),
    router_state integer,
    img_path character varying(255),
    size_w smallint,
    size_h smallint,
    layer smallint
);


ALTER TABLE public.router_icons OWNER TO ngnms;

--
-- Name: router_icons_id_seq; Type: SEQUENCE; Schema: public; Owner: ngnms
--

CREATE SEQUENCE router_icons_id_seq
START WITH 1
INCREMENT BY 1
NO MINVALUE
NO MAXVALUE
CACHE 1;


ALTER TABLE public.router_icons_id_seq OWNER TO ngnms;

--
-- Name: router_icons_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ngnms
--

ALTER SEQUENCE router_icons_id_seq OWNED BY router_icons.id;


--
-- Name: router_peers; Type: TABLE; Schema: public; Owner: ngnms; Tablespace:
--

CREATE TABLE router_peers (
    id integer NOT NULL,
    router_id integer NOT NULL,
    router_peer_id integer NOT NULL,
    peer_type character varying(20) NOT NULL,
    peer_info character varying(20) NOT NULL,
    description character varying(200)
);


ALTER TABLE public.router_peers OWNER TO ngnms;

--
-- Name: router_peers_id_seq; Type: SEQUENCE; Schema: public; Owner: ngnms
--

CREATE SEQUENCE router_peers_id_seq
START WITH 1
INCREMENT BY 1
NO MINVALUE
NO MAXVALUE
CACHE 1;


ALTER TABLE public.router_peers_id_seq OWNER TO ngnms;

--
-- Name: router_peers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ngnms
--

ALTER SEQUENCE router_peers_id_seq OWNED BY router_peers.id;


--
-- Name: router_snmp_access; Type: TABLE; Schema: public; Owner: ngnms; Tablespace:
--

CREATE TABLE router_snmp_access (
    id integer NOT NULL,
    router_id integer,
    snmp_access_id integer
);


ALTER TABLE public.router_snmp_access OWNER TO ngnms;

--
-- Name: router_snmp_access_id_seq; Type: SEQUENCE; Schema: public; Owner: ngnms
--

CREATE SEQUENCE router_snmp_access_id_seq
START WITH 1
INCREMENT BY 1
NO MINVALUE
NO MAXVALUE
CACHE 1;


ALTER TABLE public.router_snmp_access_id_seq OWNER TO ngnms;

--
-- Name: router_snmp_access_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ngnms
--

ALTER SEQUENCE router_snmp_access_id_seq OWNED BY router_snmp_access.id;


--
-- Name: router_states; Type: TABLE; Schema: public; Owner: ngnms; Tablespace:
--

CREATE TABLE router_states (
    id integer NOT NULL,
    name character varying(30)
);


ALTER TABLE public.router_states OWNER TO ngnms;

--
-- Name: router_states_id_seq; Type: SEQUENCE; Schema: public; Owner: ngnms
--

CREATE SEQUENCE router_states_id_seq
START WITH 1
INCREMENT BY 1
NO MINVALUE
NO MAXVALUE
CACHE 1;


ALTER TABLE public.router_states_id_seq OWNER TO ngnms;

--
-- Name: router_states_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ngnms
--

ALTER SEQUENCE router_states_id_seq OWNED BY router_states.id;


--
-- Name: router_vendors; Type: TABLE; Schema: public; Owner: ngnms; Tablespace:
--

CREATE TABLE router_vendors (
    id integer DEFAULT nextval(('"router_vendors_id_seq"'::text)::regclass) NOT NULL,
    name character varying(50) NOT NULL,
    rgb character(6) NOT NULL
);


ALTER TABLE public.router_vendors OWNER TO ngnms;

--
-- Name: router_vendors_id_seq; Type: SEQUENCE; Schema: public; Owner: ngnms
--

CREATE SEQUENCE router_vendors_id_seq
START WITH 1
INCREMENT BY 1
NO MINVALUE
NO MAXVALUE
CACHE 1;


ALTER TABLE public.router_vendors_id_seq OWNER TO ngnms;

--
-- Name: routers; Type: TABLE; Schema: public; Owner: ngnms; Tablespace:
--

CREATE TABLE routers (
    router_id integer DEFAULT nextval(('"routers_router_id_seq"'::text)::regclass) NOT NULL,
    name character varying(255) NOT NULL,
    ip_addr inet,
    eq_type character(50),
    eq_vendor character(50),
    location character(255),
    status character(20),
    icon_color character(20) DEFAULT NULL::bpchar,
    layer smallint DEFAULT 3,
    is_router_identifier INTEGER
);


ALTER TABLE public.routers OWNER TO ngnms;

--
-- Name: routers_router_id_seq; Type: SEQUENCE; Schema: public; Owner: ngnms
--

CREATE SEQUENCE routers_router_id_seq
START WITH 1
INCREMENT BY 1
NO MINVALUE
NO MAXVALUE
CACHE 1;


ALTER TABLE public.routers_router_id_seq OWNER TO ngnms;

--
-- Name: scan_exception; Type: TABLE; Schema: public; Owner: ngnms; Tablespace:
--

CREATE TABLE scan_exception (
    id integer NOT NULL,
    addr cidr,
    name character varying(100)
);


ALTER TABLE public.scan_exception OWNER TO ngnms;

--
-- Name: scan_exception_id_seq; Type: SEQUENCE; Schema: public; Owner: ngnms
--

CREATE SEQUENCE scan_exception_id_seq
START WITH 1
INCREMENT BY 1
NO MINVALUE
NO MAXVALUE
CACHE 1;


ALTER TABLE public.scan_exception_id_seq OWNER TO ngnms;

--
-- Name: scan_exception_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ngnms
--

ALTER SEQUENCE scan_exception_id_seq OWNED BY scan_exception.id;


--
-- Name: snmp_access; Type: TABLE; Schema: public; Owner: ngnms; Tablespace:
--

CREATE TABLE snmp_access (
    id integer NOT NULL,
    community_ro text,
    community_rw text,
    name character varying(40)
);


ALTER TABLE public.snmp_access OWNER TO ngnms;

--
-- Name: snmp_access_id_seq; Type: SEQUENCE; Schema: public; Owner: ngnms
--

CREATE SEQUENCE snmp_access_id_seq
START WITH 1
INCREMENT BY 1
NO MINVALUE
NO MAXVALUE
CACHE 1;


ALTER TABLE public.snmp_access_id_seq OWNER TO ngnms;

--
-- Name: snmp_access_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ngnms
--

ALTER SEQUENCE snmp_access_id_seq OWNED BY snmp_access.id;


--
-- Name: tbl_user; Type: TABLE; Schema: public; Owner: ngnms; Tablespace:
--

CREATE TABLE tbl_user (
    id integer NOT NULL,
    username character varying(128) NOT NULL,
    password character varying(128) NOT NULL,
    email character varying(128) NOT NULL,
    fname character varying(128) NOT NULL,
    lname character varying(128) NOT NULL,
    company character varying(128) NOT NULL
);


ALTER TABLE public.tbl_user OWNER TO ngnms;

--
-- Name: tbl_user_id_seq; Type: SEQUENCE; Schema: public; Owner: ngnms
--

CREATE SEQUENCE tbl_user_id_seq
START WITH 1
INCREMENT BY 1
NO MINVALUE
NO MAXVALUE
CACHE 1;



SET search_path = public, pg_catalog;

--
-- Name: getalarms(timestamp with time zone, interval, interval, integer); Type: FUNCTION; Schema: public; Owner: ngnms
--

CREATE FUNCTION getalarms(timestamp with time zone, interval, interval, integer) RETURNS bigint
LANGUAGE sql
AS $_$select sum(severity) from events
where origin_id = $4 and
      origin_ts > $1 + $2 and
      origin_ts <= $1 + $3$_$;


ALTER FUNCTION public.getalarms(timestamp with time zone, interval, interval, integer) OWNER TO ngnms;

--
-- Name: trigger_router_after_insert_update(); Type: FUNCTION; Schema: public; Owner: ngnms
--

CREATE FUNCTION trigger_router_after_insert_update() RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    if (select eq_vendor from routers where routers.router_id=NEW.router_id)='Linux'
    then UPDATE routers set layer = 5 where router_id=NEW.router_id AND layer!=5;
    end if;
    return NEW;
END;
$$;


ALTER FUNCTION public.trigger_router_after_insert_update() OWNER TO ngnms;

--
-- Name: trigger_router_after_insert_update1(); Type: FUNCTION; Schema: public; Owner: ngnms
--

CREATE FUNCTION trigger_router_after_insert_update1() RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    if (select eq_vendor from routers where routers.router_id=NEW.router_id)!='Linux' AND  (select eq_vendor from routers where routers.router_id=NEW.router_id) NOT LIKE '%buntu%'
    then UPDATE routers set layer = 3 where router_id=NEW.router_id and layer=5;
    end if;
    return NEW;
END;
$$;


ALTER FUNCTION public.trigger_router_after_insert_update1() OWNER TO ngnms;

--
-- Name: trigger_router_after_insert_update2(); Type: FUNCTION; Schema: public; Owner: ngnms
--

CREATE FUNCTION trigger_router_after_insert_update2() RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    if (select eq_vendor from routers where routers.router_id=NEW.router_id) like '%buntu%'
    then UPDATE routers set layer = 5 where router_id=NEW.router_id AND layer!=5;
    end if;
    return NEW;
END;
$$;


ALTER FUNCTION public.trigger_router_after_insert_update2() OWNER TO ngnms;




ALTER TABLE public.tbl_user_id_seq OWNER TO ngnms;

--
-- Name: tbl_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ngnms
--

ALTER SEQUENCE tbl_user_id_seq OWNED BY tbl_user.id;


SET search_path = jobmachine, pg_catalog;

--
-- Name: class_id; Type: DEFAULT; Schema: jobmachine; Owner: ngnms
--

ALTER TABLE ONLY class ALTER COLUMN class_id SET DEFAULT nextval('class_class_id_seq'::regclass);


--
-- Name: result_id; Type: DEFAULT; Schema: jobmachine; Owner: ngnms
--

ALTER TABLE ONLY result ALTER COLUMN result_id SET DEFAULT nextval('result_result_id_seq'::regclass);


--
-- Name: task_id; Type: DEFAULT; Schema: jobmachine; Owner: ngnms
--

ALTER TABLE ONLY task ALTER COLUMN task_id SET DEFAULT nextval('task_task_id_seq'::regclass);


SET search_path = public, pg_catalog;

--
-- Name: id; Type: DEFAULT; Schema: public; Owner: ngnms
--

ALTER TABLE ONLY access ALTER COLUMN id SET DEFAULT nextval('access_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: ngnms
--

ALTER TABLE ONLY access_type ALTER COLUMN id SET DEFAULT nextval('access_type_id_seq'::regclass);


--
-- Name: id_conf; Type: DEFAULT; Schema: public; Owner: ngnms
--

ALTER TABLE ONLY archive_conf ALTER COLUMN id_conf SET DEFAULT nextval('archive_conf_id_conf_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: ngnms
--

ALTER TABLE ONLY attr ALTER COLUMN id SET DEFAULT nextval('attr_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: ngnms
--

ALTER TABLE ONLY attr_access ALTER COLUMN id SET DEFAULT nextval('attr_access_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: ngnms
--

ALTER TABLE ONLY attr_value ALTER COLUMN id SET DEFAULT nextval('attr_value_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: ngnms
--

ALTER TABLE ONLY bans_ips ALTER COLUMN id SET DEFAULT nextval('bans_ips_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: ngnms
--

ALTER TABLE ONLY bgp_links ALTER COLUMN id SET DEFAULT nextval('bgp_links_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: ngnms
--

ALTER TABLE ONLY bgp_routers ALTER COLUMN id SET DEFAULT nextval('bgp_routers_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: ngnms
--

ALTER TABLE ONLY failed_logins ALTER COLUMN id SET DEFAULT nextval('failed_logins_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: ngnms
--

ALTER TABLE ONLY general_settings ALTER COLUMN id SET DEFAULT nextval('general_settings_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: ngnms
--

ALTER TABLE ONLY locked_ips ALTER COLUMN id SET DEFAULT nextval('locked_ips_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: ngnms
--

ALTER TABLE ONLY menu ALTER COLUMN id SET DEFAULT nextval('menu_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: ngnms
--

ALTER TABLE ONLY menuitem ALTER COLUMN id SET DEFAULT nextval('menuitem_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: ngnms
--

ALTER TABLE ONLY router_access ALTER COLUMN id SET DEFAULT nextval('router_access_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: ngnms
--

ALTER TABLE ONLY router_configuration ALTER COLUMN id SET DEFAULT nextval('router_configuration_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: ngnms
--

ALTER TABLE ONLY router_icons ALTER COLUMN id SET DEFAULT nextval('router_icons_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: ngnms
--

ALTER TABLE ONLY router_peers ALTER COLUMN id SET DEFAULT nextval('router_peers_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: ngnms
--

ALTER TABLE ONLY router_snmp_access ALTER COLUMN id SET DEFAULT nextval('router_snmp_access_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: ngnms
--

ALTER TABLE ONLY router_states ALTER COLUMN id SET DEFAULT nextval('router_states_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: ngnms
--

ALTER TABLE ONLY scan_exception ALTER COLUMN id SET DEFAULT nextval('scan_exception_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: ngnms
--

ALTER TABLE ONLY snmp_access ALTER COLUMN id SET DEFAULT nextval('snmp_access_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: ngnms
--

ALTER TABLE ONLY tbl_user ALTER COLUMN id SET DEFAULT nextval('tbl_user_id_seq'::regclass);


SET search_path = jobmachine, pg_catalog;

--
-- Data for Name: class; Type: TABLE DATA; Schema: jobmachine; Owner: ngnms
--

COPY class (class_id, name, created, modified) FROM stdin;
\.


--
-- Name: class_class_id_seq; Type: SEQUENCE SET; Schema: jobmachine; Owner: ngnms
--

SELECT pg_catalog.setval('class_class_id_seq', 1, false);


--
-- Data for Name: result; Type: TABLE DATA; Schema: jobmachine; Owner: ngnms
--

COPY result (result_id, task_id, result, resulttype, created) FROM stdin;
\.


--
-- Name: result_result_id_seq; Type: SEQUENCE SET; Schema: jobmachine; Owner: ngnms
--

SELECT pg_catalog.setval('result_result_id_seq', 1, false);


--
-- Data for Name: task; Type: TABLE DATA; Schema: jobmachine; Owner: ngnms
--

COPY task (task_id, transaction_id, class_id, grouping, title, parameters, status, run_after, remove_after, created, modified) FROM stdin;
\.


--
-- Name: task_task_id_seq; Type: SEQUENCE SET; Schema: jobmachine; Owner: ngnms
--

SELECT pg_catalog.setval('task_task_id_seq', 1, false);


SET search_path = public, pg_catalog;

--
-- Data for Name: access; Type: TABLE DATA; Schema: public; Owner: ngnms
--

COPY access (id, name, id_access_type) FROM stdin;
\.


--
-- Name: access_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ngnms
--

SELECT pg_catalog.setval('access_id_seq', 1000, true);


--
-- Data for Name: access_type; Type: TABLE DATA; Schema: public; Owner: ngnms
--

COPY access_type (id, name) FROM stdin;
1	Telnet
2	SSHv1
3	SSHv2
\.


--
-- Name: access_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ngnms
--

SELECT pg_catalog.setval('access_type_id_seq', 1000, true);


--
-- Data for Name: admrecords; Type: TABLE DATA; Schema: public; Owner: ngnms
--

COPY admrecords (rec_id, date_time, who, action, obj_type, obj_id) FROM stdin;
\.


--
-- Name: admrecords_RecID_seq; Type: SEQUENCE SET; Schema: public; Owner: ngnms
--

SELECT pg_catalog.setval('"admrecords_RecID_seq"', 1000, false);


--
-- Data for Name: archive_conf; Type: TABLE DATA; Schema: public; Owner: ngnms
--

COPY archive_conf (arc_expire, arc_delete, arc_period, arc_enable, arc_path, log_syslog, log_level, arc_gzip, id_conf) FROM stdin;
6h	7d	6h	1	archive	1	6	1	1
\.


--
-- Name: archive_conf_id_conf_seq; Type: SEQUENCE SET; Schema: public; Owner: ngnms
--

SELECT pg_catalog.setval('archive_conf_id_conf_seq', 1000, true);


--
-- Data for Name: archive_tables; Type: TABLE DATA; Schema: public; Owner: ngnms
--

COPY archive_tables (id, table_name, start_time, end_time, archive_id, records_count, microsecounds) FROM stdin;
\.


--
-- Name: archive_tables_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ngnms
--

SELECT pg_catalog.setval('archive_tables_id_seq', 1000, false);


--
-- Data for Name: archives; Type: TABLE DATA; Schema: public; Owner: ngnms
--

COPY archives (archive_id, start_time, end_time, file_name, in_db) FROM stdin;
\.


--
-- Name: archives_archive_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ngnms
--

SELECT pg_catalog.setval('archives_archive_id_seq', 1000, true);


--
-- Data for Name: attr; Type: TABLE DATA; Schema: public; Owner: ngnms
--

COPY attr (id, name) FROM stdin;
2	Password
3	Port
1	Login
6	Enpassword
7	CmdOptions
\.


--
-- Data for Name: attr_access; Type: TABLE DATA; Schema: public; Owner: ngnms
--

COPY attr_access (id, id_access_type, id_attr) FROM stdin;
1	1	1
2	1	2
3	1	3
4	2	1
5	2	2
6	2	3
9	5	1
10	5	2
11	5	3
12	1	6
13	2	6
14	3	6
16	3	1
17	3	2
18	3	3
19	1	7
20	2	7
21	3	7
\.


--
-- Name: attr_access_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ngnms
--

SELECT pg_catalog.setval('attr_access_id_seq', 1000, true);


--
-- Name: attr_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ngnms
--

SELECT pg_catalog.setval('attr_id_seq', 1000, true);


--
-- Data for Name: attr_value; Type: TABLE DATA; Schema: public; Owner: ngnms
--

COPY attr_value (id, id_attr_access, id_access, value) FROM stdin;
\.


--
-- Name: attr_value_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ngnms
--

SELECT pg_catalog.setval('attr_value_id_seq', 1000, true);


--
-- Data for Name: authassignment; Type: TABLE DATA; Schema: public; Owner: ngnms
--

COPY authassignment (itemname, userid, bizrule, data) FROM stdin;
admin	1		s:0:"";
SRBAC access	1		s:0:"";
\.


--
-- Data for Name: authitem; Type: TABLE DATA; Schema: public; Owner: ngnms
--

COPY authitem (name, type, description, bizrule, data) FROM stdin;
SRBAC access	2	Allow SRBAC access		s:0:"";
changeRole	0	change Role		s:0:"";
createUser	0	create user		s:0:"";
deleteUser	0	delete  user		s:0:"";
Editor	2	it is possible update data of users		s:0:"";
editUser	1			s:0:"";
manage	1	manage users		s:0:"";
read	1			s:0:"";
readUser	0	read data of User		s:0:"";
updateOwnData	1	edit own record	return Yii::app()->user->id==$params["user"]->id;	s:0:"";
updateUser	0	update user		s:0:"";
User	2	User		s:0:"";
viewAssets	0			s:0:"";
viewEvents	0			s:0:"";
viewUsers	0	view users		s:0:"";
viewMap	0			s:0:"";
admin	2	Administrator		s:0:"";
viewAccess	0			s:0:"";
editAccess	0			s:0:"";
accessManagement	1			s:0:"";
editAssets	0			s:0:"";
editMap	0			s:0:"";
\.


--
-- Data for Name: authitemchild; Type: TABLE DATA; Schema: public; Owner: ngnms
--

COPY authitemchild (parent, child) FROM stdin;
manage	changeRole
manage	createUser
manage	deleteUser
Editor	editUser
admin	manage
User	read
editUser	readUser
manage	readUser
User	updateOwnData
editUser	updateUser
manage	updateUser
updateOwnData	updateUser
manage	viewAssets
read	viewAssets
manage	viewEvents
read	viewEvents
editUser	viewUsers
manage	viewUsers
read	viewUsers
read	viewMap
admin	read
accessManagement	editAccess
admin	accessManagement
accessManagement	viewAssets
accessManagement	editAssets
\.


--
-- Data for Name: bans_ips; Type: TABLE DATA; Schema: public; Owner: ngnms
--

COPY bans_ips (id, ip, finish_time) FROM stdin;
\.


--
-- Name: bans_ips_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ngnms
--

SELECT pg_catalog.setval('bans_ips_id_seq', 1000, true);


--
-- Data for Name: bgp_links; Type: TABLE DATA; Schema: public; Owner: ngnms
--

COPY bgp_links (id, side_a, side_b, link_type) FROM stdin;
\.


--
-- Name: bgp_links_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ngnms
--

SELECT pg_catalog.setval('bgp_links_id_seq', 1000, true);


--
-- Data for Name: bgp_routers; Type: TABLE DATA; Schema: public; Owner: ngnms
--

COPY bgp_routers (id, bgp_type, status, autonomous_system, ip_addr, bgp_router_identifier) FROM stdin;
\.


--
-- Name: bgp_routers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ngnms
--

SELECT pg_catalog.setval('bgp_routers_id_seq', 1000, true);


--
-- Data for Name: dbix_migration; Type: TABLE DATA; Schema: public; Owner: ngnms
--

COPY dbix_migration (name, value) FROM stdin;
version                                                         	6
\.


--
-- Data for Name: discovery_status; Type: TABLE DATA; Schema: public; Owner: ngnms
--

COPY discovery_status (username, percent, lastchange, finish, start, ended, interactive) FROM stdin;
\.


--
-- Data for Name: events; Type: TABLE DATA; Schema: public; Owner: ngnms
--

COPY events (event_id, origin_ts, receiver_ts, origin, origin_id, facility, code, descr, priority, severity, raw_event) FROM stdin;
\.


--
-- Name: events_event_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ngnms
--

SELECT pg_catalog.setval('events_event_id_seq', 1000, true);


--
-- Data for Name: failed_logins; Type: TABLE DATA; Schema: public; Owner: ngnms
--

COPY failed_logins (id, ip, "time") FROM stdin;
\.


--
-- Name: failed_logins_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ngnms
--

SELECT pg_catalog.setval('failed_logins_id_seq', 1000, true);


--
-- Data for Name: general_settings; Type: TABLE DATA; Schema: public; Owner: ngnms
--

COPY general_settings (id, name, value, label, order_view) FROM stdin;
1	chiave	123412341234123412341234	key	0
7	hostType		Host Type	2
8	community	r4RtB3qc69s=	SNMP Community	3
5	type access	wta1Fku6x9s=	Access Type	4
2	username	lUxJzFwE4Yg=	User Name	5
3	password	YEe5NW4OZxQ=	Password	6
4	enpassword	mo8Rm+PV3fY=	Enable Password	7
9	perioddiscovery	360	Period of discovery	8
10	scanner	1	Subnets scanner	9
6	seedHost	56Oz57cqXxPVS2Xw8RzY0w==	Seed Host	1
\.


--
-- Name: general_settings_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ngnms
--

SELECT pg_catalog.setval('general_settings_id_seq', 1000, true);


--
-- Data for Name: interfaces; Type: TABLE DATA; Schema: public; Owner: ngnms
--

COPY interfaces (router_id, ph_int_id, ifc_id, name, ip_addr, mask, descr) FROM stdin;
\.


--
-- Name: interfaces_ifc_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ngnms
--

SELECT pg_catalog.setval('interfaces_ifc_id_seq', 1000, true);


--
-- Data for Name: inv_hw; Type: TABLE DATA; Schema: public; Owner: ngnms
--

COPY inv_hw (router_id, hw_item, hw_name, hw_version, hw_amount) FROM stdin;
\.


--
-- Data for Name: inv_sw; Type: TABLE DATA; Schema: public; Owner: ngnms
--

COPY inv_sw (router_id, sw_item, sw_name, sw_version) FROM stdin;
\.


--
-- Data for Name: locked_ips; Type: TABLE DATA; Schema: public; Owner: ngnms
--

COPY locked_ips (id, ip, "time") FROM stdin;
\.


--
-- Name: locked_ips_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ngnms
--

SELECT pg_catalog.setval('locked_ips_id_seq', 1000, true);


--
-- Data for Name: menu; Type: TABLE DATA; Schema: public; Owner: ngnms
--

COPY menu (id, name, label) FROM stdin;
1	assets	Assets
2	events	Events
3	help	Help
5	management	Management
4	map	Map
\.


--
-- Name: menu_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ngnms
--

SELECT pg_catalog.setval('menu_id_seq', 1, false);


--
-- Data for Name: menuitem; Type: TABLE DATA; Schema: public; Owner: ngnms
--

COPY menuitem (id, name, parentid, label, ordervalue, route, accesslevel, depthlevel, menutypeid, adminnotes, active, created, modified, deleted, icon) FROM stdin;
2	Events	\N	Events	2	/site/events	viewEvents	0	events		1	2014-07-25 14:57:28.66074	2014-07-25 14:57:28.66074	\N	icon-list
18	Summary of activity by origin	2	Summary of activity by origin	1	/events/summarybyorigin	viewEvents	1	events		1	2014-09-16 11:25:21.306061	2014-09-16 11:25:21.306061	\N	\N
4	Help	0	Help	4	/site/help	viewHelp	0	help		1	2014-07-25 15:05:09.687362	2014-07-25 15:05:09.687362	\N	icon-book
19	Summary of activity by facility	2	Summary of activity by facility	2	/events/summarybyfacility	viewEvents	1	events		1	2014-09-16 11:27:59.278911	2014-09-16 11:27:59.278911	\N	\N
1	Assets	\N	Assets	1	/routers/index	viewAssets	0	assets		1	2014-07-25 14:53:49.09895	2014-07-25 14:53:49.09895	\N	icon-folder-open
7	HW Inventory	1	HW Inventory	2	/routers/hwinventory	viewAssets	1	assets		1	2014-08-11 10:46:24.584662	2014-08-11 10:46:24.584662	\N	icon-hdd
8	SW Inventory	1	SW Inventory	3	/routers/swinventory	viewAssets	1	assets		1	2014-08-11 10:48:59.239971	2014-08-11 10:48:59.239971	\N	icon-qrcode
10	Report HW	1	Report HW by part number	5	/routers/hwbypartnumber	viewAssets	1	assets		1	2014-08-18 12:12:46.276378	2014-08-18 12:12:46.276378	\N	icon-truck
11	Report SW	1	Report SW by revision	6	/routers/swbyrevision/	viewAssets	1	assets		1	2014-08-18 12:14:46.536875	2014-08-18 12:14:46.536875	\N	icon-computer-service
3	Management	\N	Management	4	/site/management	SRBAC access	0	management		1	2014-07-25 15:03:21.682224	2014-07-25 15:03:21.682224	\N	icon-user
9	Routers Map	12	Dynamic Map	2	/routers/routermap/	viewMap	1	map		1	2014-08-18 11:01:46.674012	2014-08-18 11:01:46.674012	\N	icon-map-marker
14	IP Map	12	IP Map	3	interfaces/ipmap	viewMap	1	map	\N	1	2014-08-29 16:03:14.187256	2014-08-29 16:03:14.187256	\N	\N
17	New user	3	New user	2	/user/adduser	createUser	2	management		1	2014-09-11 15:41:02.48011	2014-09-11 15:41:02.48011	\N	NULL::character varying
16	Edit Users	3	Edit Users	3	/user/editusers	updateUser	1	management		1	2014-09-11 15:38:26.156082	2014-09-11 15:38:26.156082	\N	icon-user
21	Attributes	3	Attributes	5	attr/index	viewAccess	2	management		1	2014-10-15 15:43:32.774161	2014-10-15 15:43:32.774161	\N	\N
22	Access Attributes	3	Access Attributes	6	accessType/admin	viewAccess	2	management		1	2014-10-15 17:40:07.344578	2014-10-15 17:40:07.344578	\N	\N
5	SRBAC	3	RBAC	1	/srbac	SRBAC access	1	management		1	2014-08-06 17:17:25.063425	2014-08-06 17:17:25.063425	\N	icon-tasks
28	Clean DB	3	Clean DB	12	/routers/cleandb	editAssets	2	management	\N	1	2014-11-25 14:26:20.90684	2014-11-25 14:26:20.90684	\N	\N
29	Run Audit	3	Run Audit	13	/routers/runaudit	editAssets	2	management	\N	1	2014-11-25 14:26:40.385833	2014-11-25 14:26:40.385833	\N	\N
30	General Settings	3	General Settings	14	/generalSettings/admin	editAccess	2	management	\N	1	2014-11-25 14:27:19.881901	2014-11-25 14:27:19.881901	\N	\N
12	map	\N	Map	3	/routers/routermap	viewMap	0	map		1	2014-08-19 15:30:04.371204	2014-08-19 15:30:04.371204	\N	\N
13	Topology Map	12	Topology Map	1	/routers/topologymap	editMap	1	map		1	2014-08-19 15:39:22.687852	2014-08-19 15:39:22.687852	\N	\N
23	Accesses	3	Access methods	8	access/index	editAccess	2	management		1	2014-10-16 12:57:50.51618	2014-10-16 12:57:50.51618	\N	\N
25	Accesses to routers	3	Access to devices	10	access/view	editAccess	2	management		1	2014-10-17 12:41:26.600358	2014-10-17 12:41:26.600358	\N	\N
27	Routers SNMP Access	3	SNMP Access to devices	11	snmpAccess/view	editAccess	2	management		1	2014-10-31 10:43:16.430257	2014-10-31 10:43:16.430257	\N	\N
26	Snmp Accesses	3	SNMP Access methods	7	snmpAccess/index	editAccess	2	management		1	2014-10-31 09:39:41.714009	2014-10-31 09:39:41.714009	\N	\N
31	List of networks Not to be scanned	3	List of networks NOT to be scanned	15	/scanException/index	editAssets	2	management	\N	1	2015-01-22 15:31:35.929486	2015-01-22 15:31:35.929486	\N	\N
20	Access Type	3	Access Type	4	accessType/index	viewAccess	2	management		1	2014-10-15 11:45:06.226073	2014-10-15 11:45:06.226073	\N	\N
6	Routers	1	Devices	1	/routers/index	viewAssets	1	assets		1	2014-08-06 17:39:44.593037	2014-08-06 17:39:44.593037	\N	icon-road
24	Routers manual control	3	Devices manual control	9	routers/admin	editAccess	2	management		1	2014-10-17 12:21:23.980129	2014-10-17 12:21:23.980129	\N	\N
15	Router Configuration	1	Device Configuration	7	/routers/viewconf/	viewAssets	1	assets		1	2014-09-02 16:58:12.453124	2014-09-02 16:58:12.453124	\N	\N
32	Archives	3	Archive Manager	16	/archives/index	editAccess	2	management	\N	1	2015-05-05 12:11:07.090979	2015-05-05 12:11:07.090979	\N	\N
33	IP Connectivity Map	12	IP Connectivity Map	3	/routers/ipmap/	viewMap	1	map		1	2017-02-21 11:49:52.747633	2017-02-21 11:49:52.747633	\N	icon-map-marker
\.


--
-- Name: menuitem_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ngnms
--

SELECT pg_catalog.setval('menuitem_id_seq', 33, true);


--
-- Data for Name: network; Type: TABLE DATA; Schema: public; Owner: ngnms
--

COPY network (link_id, router_id_a, ifc_id_a, router_id_b, ifc_id_b, link_type) FROM stdin;
\.


--
-- Name: network_link_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ngnms
--

SELECT pg_catalog.setval('network_link_id_seq', 1000, true);


--
-- Data for Name: ph_int; Type: TABLE DATA; Schema: public; Owner: ngnms
--

COPY ph_int (router_id, ph_int_id, name, state, condition, descr, speed) FROM stdin;
\.


--
-- Name: ph_int_ph_int_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ngnms
--

SELECT pg_catalog.setval('ph_int_ph_int_id_seq', 1000, true);


--
-- Data for Name: router_access; Type: TABLE DATA; Schema: public; Owner: ngnms
--

COPY router_access (id, id_access, id_router) FROM stdin;
\.


--
-- Name: router_access_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ngnms
--

SELECT pg_catalog.setval('router_access_id_seq', 1000, true);


--
-- Data for Name: router_configuration; Type: TABLE DATA; Schema: public; Owner: ngnms
--

COPY router_configuration (id, router_id, data, created, checksum) FROM stdin;
\.


--
-- Name: router_configuration_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ngnms
--

SELECT pg_catalog.setval('router_configuration_id_seq', 1000, true);


--
-- Data for Name: router_graph; Type: TABLE DATA; Schema: public; Owner: ngnms
--

COPY router_graph (router_id, x, y) FROM stdin;
\.


--
-- Data for Name: router_icons; Type: TABLE DATA; Schema: public; Owner: ngnms
--

COPY router_icons (id, vendor_name, router_state, img_path, size_w, size_h, layer) FROM stdin;
1	Juniper	1	/router_white.png	24	24	3
2	Juniper	2	/router_blue.png	24	24	3
3	Juniper	3	/router_black.png	24	24	3
4	Cisco	1	/router_white.png	24	24	3
5	Cisco	2	/router_green.png	24	24	3
6	Cisco	3	/router_black.png	24	24	3
7	DEFAULT	1	/router_white.png	24	24	3
8	DEFAULT	2	/router_white.png	24	24	3
9	DEFAULT	3	/router_white.png	24	24	3
17	HP	1	/router_white.png	24	24	3
18	HP	2	/router_grey.png	24	24	3
19	HP	3	/router_black.png	24	24	3
20	Juniper	1	/switch_white.png	24	24	2
21	Juniper	2	/switch_blue.png	24	24	2
22	Juniper	3	/switch_black.png	24	24	2
23	Cisco	1	/switch_white.png	24	24	2
24	Cisco	2	/switch_green.png	24	24	2
25	Cisco	3	/switch_black.png	24	24	2
26	HP	1	/switch_white.png	24	24	2
27	HP	3	/switch_black.png	24	24	2
28	HP	2	/switch_grey.png	24	24	2
15	Linux	2	/VM_in_cloud_96x96.png	24	24	5
16	Linux	3	/VM_dn-96x96.png	24	24	5
10	OCX	2	/OCX_96x96.png	96	96	5
11	CloudProvider	2	/Cloud_provider_96x96.png	96	96	5
12	ocxStorage	2	/OCXclient_storage_up_96x96.png	48	48	5
13	ocxStorage	3	/OCXclient_storage_dn_96x96.png	48	48	5
29	Netscreen	1	/hero_icon_white.png	24	24	3
30	Netscreen	2	/hero_icon_blue.png	24	24	3
31	Netscreen	3	/hero_icon_grey.png	24	24	3
32	Extreme	1	/router_white.png	24	24	3
33	Extreme	2	/router_purple.png	24	24	3
34	Extreme	3	/router_black.png	24	24	3
35	Extreme	1	/switch_white.png	24	24	2
36	Extreme	2	/switch_purple.png	24	24	2
37	Extreme	3	/switch_black.png	24	24	2
14	Linux	1	/VM_dn-96x96.png	24	24	5
39	Juniper	10	/router_white.png	24	24	3
40	Cisco	10	/router_white.png	24	24	3
41	DEFAULT	10	/router_white.png	24	24	3
42	HP	10	/router_white.png	24	24	3
43	Juniper	10	/switch_white.png	24	24	2
44	Cisco	10	/switch_white.png	24	24	2
45	HP	10	/switch_white.png	24	24	2
46	Extreme	10	/switch_white.png	24	24	2
47	Extreme	10	/router_white.png	24	24	3
48	Netscreen	10	/hero_icon_white.png	24	24	3
49	Linux	10	/VM_dn-96x96.png	24	24	5
\.


--
-- Name: router_icons_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ngnms
--

SELECT pg_catalog.setval('router_icons_id_seq', 1000, true);


--
-- Data for Name: router_peers; Type: TABLE DATA; Schema: public; Owner: ngnms
--

COPY router_peers (id, router_id, router_peer_id, peer_type, peer_info, description) FROM stdin;
\.


--
-- Name: router_peers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ngnms
--

SELECT pg_catalog.setval('router_peers_id_seq', 1000, true);


--
-- Data for Name: router_snmp_access; Type: TABLE DATA; Schema: public; Owner: ngnms
--

COPY router_snmp_access (id, router_id, snmp_access_id) FROM stdin;
\.


--
-- Name: router_snmp_access_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ngnms
--

SELECT pg_catalog.setval('router_snmp_access_id_seq', 1000, true);


--
-- Data for Name: router_states; Type: TABLE DATA; Schema: public; Owner: ngnms
--

COPY router_states (id, name) FROM stdin;
1	UNKNOWN
2	UP
3	DOWN
4	RED ALARM
5	YELLOW ALARM
6	RUNNING
7	STARTING
8	FINISHING
9	STOPPED
10	UNMANAGED
\.


--
-- Name: router_states_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ngnms
--

SELECT pg_catalog.setval('router_states_id_seq', 1000, true);


--
-- Data for Name: router_vendors; Type: TABLE DATA; Schema: public; Owner: ngnms
--

COPY router_vendors (id, name, rgb) FROM stdin;
2	Juniper	0000FF
1	Cisco	449970
\.


--
-- Name: router_vendors_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ngnms
--

SELECT pg_catalog.setval('router_vendors_id_seq', 1000, true);


--
-- Data for Name: routers; Type: TABLE DATA; Schema: public; Owner: ngnms
--

COPY routers (router_id, name, ip_addr, eq_type, eq_vendor, location, status, icon_color, layer) FROM stdin;
\.


--
-- Name: routers_router_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ngnms
--

SELECT pg_catalog.setval('routers_router_id_seq', 1000, true);


--
-- Data for Name: scan_exception; Type: TABLE DATA; Schema: public; Owner: ngnms
--

COPY scan_exception (id, addr, name) FROM stdin;
2	127.0.0.0/8	Loopback
3	169.254.0.0/16	Local link
4	224.0.0.0/4	Multicast
5	255.255.255.255/32	Limited broadcast
1	0.0.0.0/8	This network
\.


--
-- Name: scan_exception_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ngnms
--

SELECT pg_catalog.setval('scan_exception_id_seq', 1000, true);


--
-- Data for Name: snmp_access; Type: TABLE DATA; Schema: public; Owner: ngnms
--

COPY snmp_access (id, community_ro, community_rw, name) FROM stdin;
\.


--
-- Name: snmp_access_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ngnms
--

SELECT pg_catalog.setval('snmp_access_id_seq', 1000, true);


--
-- Data for Name: tbl_user; Type: TABLE DATA; Schema: public; Owner: ngnms
--

COPY tbl_user (id, username, password, email, fname, lname, company) FROM stdin;
1	ngnms	923c64e5887b61064207a09d7e1a752b	info@opt-net.eu	Admin	Admin	Opt Net
\.


--
-- Name: tbl_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ngnms
--

SELECT pg_catalog.setval('tbl_user_id_seq', 1000, true);


SET search_path = jobmachine, pg_catalog;

--
-- Name: class_pkey; Type: CONSTRAINT; Schema: jobmachine; Owner: ngnms; Tablespace:
--

ALTER TABLE ONLY class
    ADD CONSTRAINT class_pkey PRIMARY KEY (class_id);


--
-- Name: result_pkey; Type: CONSTRAINT; Schema: jobmachine; Owner: ngnms; Tablespace:
--

ALTER TABLE ONLY result
    ADD CONSTRAINT result_pkey PRIMARY KEY (result_id);


--
-- Name: task_pkey; Type: CONSTRAINT; Schema: jobmachine; Owner: ngnms; Tablespace:
--

ALTER TABLE ONLY task
    ADD CONSTRAINT task_pkey PRIMARY KEY (task_id);


SET search_path = public, pg_catalog;

--
-- Name: access_pkey; Type: CONSTRAINT; Schema: public; Owner: ngnms; Tablespace:
--

ALTER TABLE ONLY access
    ADD CONSTRAINT access_pkey PRIMARY KEY (id);


--
-- Name: access_type_pkey; Type: CONSTRAINT; Schema: public; Owner: ngnms; Tablespace:
--

ALTER TABLE ONLY access_type
    ADD CONSTRAINT access_type_pkey PRIMARY KEY (id);


--
-- Name: admrecords_pkey; Type: CONSTRAINT; Schema: public; Owner: ngnms; Tablespace:
--

ALTER TABLE ONLY admrecords
    ADD CONSTRAINT admrecords_pkey PRIMARY KEY (rec_id);


--
-- Name: archive_tables_pkey; Type: CONSTRAINT; Schema: public; Owner: ngnms; Tablespace:
--

ALTER TABLE ONLY archive_tables
    ADD CONSTRAINT archive_tables_pkey PRIMARY KEY (id);


--
-- Name: archives_pkey; Type: CONSTRAINT; Schema: public; Owner: ngnms; Tablespace:
--

ALTER TABLE ONLY archives
    ADD CONSTRAINT archives_pkey PRIMARY KEY (archive_id);


--
-- Name: attr_access_id_access_type_id_attr_key; Type: CONSTRAINT; Schema: public; Owner: ngnms; Tablespace:
--

ALTER TABLE ONLY attr_access
    ADD CONSTRAINT attr_access_id_access_type_id_attr_key UNIQUE (id_access_type, id_attr);


--
-- Name: attr_pkey; Type: CONSTRAINT; Schema: public; Owner: ngnms; Tablespace:
--

ALTER TABLE ONLY attr
    ADD CONSTRAINT attr_pkey PRIMARY KEY (id);


--
-- Name: attr_value_id_attr_access_id_access_key; Type: CONSTRAINT; Schema: public; Owner: ngnms; Tablespace:
--

ALTER TABLE ONLY attr_value
    ADD CONSTRAINT attr_value_id_attr_access_id_access_key UNIQUE (id_attr_access, id_access);


--
-- Name: attr_value_pkey; Type: CONSTRAINT; Schema: public; Owner: ngnms; Tablespace:
--

ALTER TABLE ONLY attr_value
    ADD CONSTRAINT attr_value_pkey PRIMARY KEY (id);


--
-- Name: authassignment_pkey; Type: CONSTRAINT; Schema: public; Owner: ngnms; Tablespace:
--

ALTER TABLE ONLY authassignment
    ADD CONSTRAINT authassignment_pkey PRIMARY KEY (itemname, userid);


--
-- Name: authitem_pkey; Type: CONSTRAINT; Schema: public; Owner: ngnms; Tablespace:
--

ALTER TABLE ONLY authitem
    ADD CONSTRAINT authitem_pkey PRIMARY KEY (name);


--
-- Name: authitemchild_pkey; Type: CONSTRAINT; Schema: public; Owner: ngnms; Tablespace:
--

ALTER TABLE ONLY authitemchild
    ADD CONSTRAINT authitemchild_pkey PRIMARY KEY (parent, child);


--
-- Name: bans_ips_pkey; Type: CONSTRAINT; Schema: public; Owner: ngnms; Tablespace:
--

ALTER TABLE ONLY bans_ips
    ADD CONSTRAINT bans_ips_pkey PRIMARY KEY (id);


--
-- Name: dbix_migration_pkey; Type: CONSTRAINT; Schema: public; Owner: ngnms; Tablespace:
--

ALTER TABLE ONLY dbix_migration
    ADD CONSTRAINT dbix_migration_pkey PRIMARY KEY (name);


--
-- Name: event_id_pkey; Type: CONSTRAINT; Schema: public; Owner: ngnms; Tablespace:
--

ALTER TABLE ONLY events
    ADD CONSTRAINT event_id_pkey PRIMARY KEY (event_id);


--
-- Name: failed_logins_pkey; Type: CONSTRAINT; Schema: public; Owner: ngnms; Tablespace:
--

ALTER TABLE ONLY failed_logins
    ADD CONSTRAINT failed_logins_pkey PRIMARY KEY (id);


--
-- Name: interfaces_pkey; Type: CONSTRAINT; Schema: public; Owner: ngnms; Tablespace:
--

ALTER TABLE ONLY interfaces
    ADD CONSTRAINT interfaces_pkey PRIMARY KEY (ifc_id);


--
-- Name: locked_ips_pkey; Type: CONSTRAINT; Schema: public; Owner: ngnms; Tablespace:
--

ALTER TABLE ONLY locked_ips
    ADD CONSTRAINT locked_ips_pkey PRIMARY KEY (id);


--
-- Name: menu_pkey; Type: CONSTRAINT; Schema: public; Owner: ngnms; Tablespace:
--

ALTER TABLE ONLY menu
    ADD CONSTRAINT menu_pkey PRIMARY KEY (id);


--
-- Name: menuitem_pkey; Type: CONSTRAINT; Schema: public; Owner: ngnms; Tablespace:
--

ALTER TABLE ONLY menuitem
    ADD CONSTRAINT menuitem_pkey PRIMARY KEY (id);


--
-- Name: network_pkey; Type: CONSTRAINT; Schema: public; Owner: ngnms; Tablespace:
--

ALTER TABLE ONLY network
    ADD CONSTRAINT network_pkey PRIMARY KEY (link_id);


--
-- Name: ph_int_pkey; Type: CONSTRAINT; Schema: public; Owner: ngnms; Tablespace:
--

ALTER TABLE ONLY ph_int
    ADD CONSTRAINT ph_int_pkey PRIMARY KEY (ph_int_id);


--
-- Name: pk_arch_conf; Type: CONSTRAINT; Schema: public; Owner: ngnms; Tablespace:
--

ALTER TABLE ONLY archive_conf
    ADD CONSTRAINT pk_arch_conf PRIMARY KEY (id_conf);


--
-- Name: pk_bgp_id; Type: CONSTRAINT; Schema: public; Owner: ngnms; Tablespace:
--

ALTER TABLE ONLY bgp_routers
    ADD CONSTRAINT pk_bgp_id PRIMARY KEY (id);


--
-- Name: pk_bgp_link; Type: CONSTRAINT; Schema: public; Owner: ngnms; Tablespace:
--

ALTER TABLE ONLY bgp_links
    ADD CONSTRAINT pk_bgp_link PRIMARY KEY (id);


--
-- Name: pk_discovery; Type: CONSTRAINT; Schema: public; Owner: ngnms; Tablespace:
--

ALTER TABLE ONLY discovery_status
    ADD CONSTRAINT pk_discovery PRIMARY KEY (start);


--
-- Name: pk_router_config; Type: CONSTRAINT; Schema: public; Owner: ngnms; Tablespace:
--

ALTER TABLE ONLY router_configuration
    ADD CONSTRAINT pk_router_config PRIMARY KEY (id);


--
-- Name: pk_router_icons; Type: CONSTRAINT; Schema: public; Owner: ngnms; Tablespace:
--

ALTER TABLE ONLY router_icons
    ADD CONSTRAINT pk_router_icons PRIMARY KEY (id);


--
-- Name: pk_router_states; Type: CONSTRAINT; Schema: public; Owner: ngnms; Tablespace:
--

ALTER TABLE ONLY router_states
    ADD CONSTRAINT pk_router_states PRIMARY KEY (id);


--
-- Name: pk_rsa; Type: CONSTRAINT; Schema: public; Owner: ngnms; Tablespace:
--

ALTER TABLE ONLY router_snmp_access
    ADD CONSTRAINT pk_rsa PRIMARY KEY (id);


--
-- Name: pk_scan_exception; Type: CONSTRAINT; Schema: public; Owner: ngnms; Tablespace:
--

ALTER TABLE ONLY scan_exception
    ADD CONSTRAINT pk_scan_exception PRIMARY KEY (id);


--
-- Name: pk_settings; Type: CONSTRAINT; Schema: public; Owner: ngnms; Tablespace:
--

ALTER TABLE ONLY general_settings
    ADD CONSTRAINT pk_settings PRIMARY KEY (id);


--
-- Name: pk_snmp_access; Type: CONSTRAINT; Schema: public; Owner: ngnms; Tablespace:
--

ALTER TABLE ONLY snmp_access
    ADD CONSTRAINT pk_snmp_access PRIMARY KEY (id);


--
-- Name: router_access_id_access_id_router_key; Type: CONSTRAINT; Schema: public; Owner: ngnms; Tablespace:
--

ALTER TABLE ONLY router_access
    ADD CONSTRAINT router_access_id_access_id_router_key UNIQUE (id_access, id_router);


--
-- Name: router_access_pkey; Type: CONSTRAINT; Schema: public; Owner: ngnms; Tablespace:
--

ALTER TABLE ONLY router_access
    ADD CONSTRAINT router_access_pkey PRIMARY KEY (id);


--
-- Name: router_configuration_id_key; Type: CONSTRAINT; Schema: public; Owner: ngnms; Tablespace:
--

ALTER TABLE ONLY router_configuration
    ADD CONSTRAINT router_configuration_id_key UNIQUE (id);


--
-- Name: router_peers_idx; Type: CONSTRAINT; Schema: public; Owner: ngnms; Tablespace:
--

ALTER TABLE ONLY router_peers
    ADD CONSTRAINT router_peers_idx UNIQUE (router_id, router_peer_id, peer_type, peer_info);


--
-- Name: router_peers_pkey; Type: CONSTRAINT; Schema: public; Owner: ngnms; Tablespace:
--

ALTER TABLE ONLY router_peers
    ADD CONSTRAINT router_peers_pkey PRIMARY KEY (id);


--
-- Name: router_vendors_pkey; Type: CONSTRAINT; Schema: public; Owner: ngnms; Tablespace:
--

ALTER TABLE ONLY router_vendors
    ADD CONSTRAINT router_vendors_pkey PRIMARY KEY (id);


--
-- Name: routers_pkey; Type: CONSTRAINT; Schema: public; Owner: ngnms; Tablespace:
--

ALTER TABLE ONLY routers
    ADD CONSTRAINT routers_pkey PRIMARY KEY (router_id);


--
-- Name: tbl_user_pkey; Type: CONSTRAINT; Schema: public; Owner: ngnms; Tablespace:
--

ALTER TABLE ONLY tbl_user
    ADD CONSTRAINT tbl_user_pkey PRIMARY KEY (id);


--
-- Name: uni_rsa_router; Type: CONSTRAINT; Schema: public; Owner: ngnms; Tablespace:
--

ALTER TABLE ONLY router_snmp_access
    ADD CONSTRAINT uni_rsa_router UNIQUE (router_id);


--
-- Name: uni_settings; Type: CONSTRAINT; Schema: public; Owner: ngnms; Tablespace:
--

ALTER TABLE ONLY general_settings
    ADD CONSTRAINT uni_settings UNIQUE (name);


--
-- Name: aattr_acc_a; Type: INDEX; Schema: public; Owner: ngnms; Tablespace:
--

CREATE INDEX aattr_acc_a ON attr_access USING hash (id_attr);


--
-- Name: access_id_access_type_idx; Type: INDEX; Schema: public; Owner: ngnms; Tablespace:
--

CREATE INDEX access_id_access_type_idx ON access USING btree (id_access_type);


--
-- Name: attr_acc_a_t; Type: INDEX; Schema: public; Owner: ngnms; Tablespace:
--

CREATE INDEX attr_acc_a_t ON attr_access USING hash (id_access_type);


--
-- Name: attr_value_id_access_idx; Type: INDEX; Schema: public; Owner: ngnms; Tablespace:
--

CREATE INDEX attr_value_id_access_idx ON attr_value USING btree (id_access);


--
-- Name: attr_value_id_attr_access_idx; Type: INDEX; Schema: public; Owner: ngnms; Tablespace:
--

CREATE INDEX attr_value_id_attr_access_idx ON attr_value USING btree (id_attr_access);


--
-- Name: child; Type: INDEX; Schema: public; Owner: ngnms; Tablespace:
--

CREATE INDEX child ON authitemchild USING btree (child);


--
-- Name: event_origin_idx; Type: INDEX; Schema: public; Owner: ngnms; Tablespace:
--

CREATE INDEX event_origin_idx ON events USING btree (origin_ts);


--
-- Name: event_receiver_idx; Type: INDEX; Schema: public; Owner: ngnms; Tablespace:
--

CREATE INDEX event_receiver_idx ON events USING btree (receiver_ts);


--
-- Name: events_event_id_key; Type: INDEX; Schema: public; Owner: ngnms; Tablespace:
--

CREATE UNIQUE INDEX events_event_id_key ON events USING btree (event_id);


--
-- Name: fki_fk1_bgp_link; Type: INDEX; Schema: public; Owner: ngnms; Tablespace:
--

CREATE INDEX fki_fk1_bgp_link ON bgp_links USING btree (side_a);


--
-- Name: fki_fk2_bgp_link; Type: INDEX; Schema: public; Owner: ngnms; Tablespace:
--

CREATE INDEX fki_fk2_bgp_link ON bgp_links USING btree (side_b);


--
-- Name: idx_scan_exc; Type: INDEX; Schema: public; Owner: ngnms; Tablespace:
--

CREATE INDEX idx_scan_exc ON scan_exception USING btree (id);


--
-- Name: r_s_a_router_id; Type: INDEX; Schema: public; Owner: ngnms; Tablespace:
--

CREATE INDEX r_s_a_router_id ON router_snmp_access USING btree (router_id);


--
-- Name: r_s_a_snmp_access_id; Type: INDEX; Schema: public; Owner: ngnms; Tablespace:
--

CREATE INDEX r_s_a_snmp_access_id ON router_snmp_access USING btree (snmp_access_id);


--
-- Name: router_access_id_router_idx; Type: INDEX; Schema: public; Owner: ngnms; Tablespace:
--

CREATE INDEX router_access_id_router_idx ON router_access USING btree (id_router);


--
-- Name: snmp_access_id_idx; Type: INDEX; Schema: public; Owner: ngnms; Tablespace:
--

CREATE INDEX snmp_access_id_idx ON snmp_access USING btree (id);


--
-- Name: router_tr; Type: TRIGGER; Schema: public; Owner: ngnms
--

CREATE TRIGGER router_tr AFTER INSERT OR UPDATE ON routers FOR EACH ROW EXECUTE PROCEDURE trigger_router_after_insert_update();


--
-- Name: router_tr1; Type: TRIGGER; Schema: public; Owner: ngnms
--

CREATE TRIGGER router_tr1 AFTER INSERT OR UPDATE ON routers FOR EACH ROW EXECUTE PROCEDURE trigger_router_after_insert_update1();


--
-- Name: router_tr2; Type: TRIGGER; Schema: public; Owner: ngnms
--

CREATE TRIGGER router_tr2 AFTER INSERT OR UPDATE ON routers FOR EACH ROW EXECUTE PROCEDURE trigger_router_after_insert_update2();


SET search_path = jobmachine, pg_catalog;

--
-- Name: result_task_id_fkey; Type: FK CONSTRAINT; Schema: jobmachine; Owner: ngnms
--

ALTER TABLE ONLY result
    ADD CONSTRAINT result_task_id_fkey FOREIGN KEY (task_id) REFERENCES task(task_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: task_class_id_fkey; Type: FK CONSTRAINT; Schema: jobmachine; Owner: ngnms
--

ALTER TABLE ONLY task
    ADD CONSTRAINT task_class_id_fkey FOREIGN KEY (class_id) REFERENCES class(class_id);


SET search_path = public, pg_catalog;

--
-- Name: access_id_access_type_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ngnms
--

ALTER TABLE ONLY access
    ADD CONSTRAINT access_id_access_type_fkey FOREIGN KEY (id_access_type) REFERENCES access_type(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: archive_tables_fk; Type: FK CONSTRAINT; Schema: public; Owner: ngnms
--

ALTER TABLE ONLY archive_tables
    ADD CONSTRAINT archive_tables_fk FOREIGN KEY (archive_id) REFERENCES archives(archive_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: attr_value_id_access_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ngnms
--

ALTER TABLE ONLY attr_value
    ADD CONSTRAINT attr_value_id_access_fkey FOREIGN KEY (id_access) REFERENCES access(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: authassignment_ibfk_1; Type: FK CONSTRAINT; Schema: public; Owner: ngnms
--

ALTER TABLE ONLY authassignment
    ADD CONSTRAINT authassignment_ibfk_1 FOREIGN KEY (itemname) REFERENCES authitem(name) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: authitemchild_ibfk_1; Type: FK CONSTRAINT; Schema: public; Owner: ngnms
--

ALTER TABLE ONLY authitemchild
    ADD CONSTRAINT authitemchild_ibfk_1 FOREIGN KEY (parent) REFERENCES authitem(name) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: authitemchild_ibfk_2; Type: FK CONSTRAINT; Schema: public; Owner: ngnms
--

ALTER TABLE ONLY authitemchild
    ADD CONSTRAINT authitemchild_ibfk_2 FOREIGN KEY (child) REFERENCES authitem(name) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk1_bgp_link; Type: FK CONSTRAINT; Schema: public; Owner: ngnms
--

ALTER TABLE ONLY bgp_links
    ADD CONSTRAINT fk1_bgp_link FOREIGN KEY (side_a) REFERENCES bgp_routers(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk2_bgp_link; Type: FK CONSTRAINT; Schema: public; Owner: ngnms
--

ALTER TABLE ONLY bgp_links
    ADD CONSTRAINT fk2_bgp_link FOREIGN KEY (side_b) REFERENCES bgp_routers(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_id_snmp_access_router; Type: FK CONSTRAINT; Schema: public; Owner: ngnms
--

ALTER TABLE ONLY router_snmp_access
    ADD CONSTRAINT fk_id_snmp_access_router FOREIGN KEY (snmp_access_id) REFERENCES snmp_access(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_router_icons_router_state; Type: FK CONSTRAINT; Schema: public; Owner: ngnms
--

ALTER TABLE ONLY router_icons
    ADD CONSTRAINT fk_router_icons_router_state FOREIGN KEY (router_state) REFERENCES router_states(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_router_id; Type: FK CONSTRAINT; Schema: public; Owner: ngnms
--

ALTER TABLE ONLY router_graph
    ADD CONSTRAINT fk_router_id FOREIGN KEY (router_id) REFERENCES routers(router_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_router_id_conf; Type: FK CONSTRAINT; Schema: public; Owner: ngnms
--

ALTER TABLE ONLY router_configuration
    ADD CONSTRAINT fk_router_id_conf FOREIGN KEY (router_id) REFERENCES routers(router_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_router_id_snmp_access; Type: FK CONSTRAINT; Schema: public; Owner: ngnms
--

ALTER TABLE ONLY router_snmp_access
    ADD CONSTRAINT fk_router_id_snmp_access FOREIGN KEY (router_id) REFERENCES routers(router_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: interfaces_router_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ngnms
--

ALTER TABLE ONLY interfaces
    ADD CONSTRAINT interfaces_router_id_fkey FOREIGN KEY (router_id) REFERENCES routers(router_id) ON DELETE CASCADE;


--
-- Name: inv_hw_router_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ngnms
--

ALTER TABLE ONLY inv_hw
    ADD CONSTRAINT inv_hw_router_id_fkey FOREIGN KEY (router_id) REFERENCES routers(router_id) ON DELETE CASCADE;


--
-- Name: inv_sw_router_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ngnms
--

ALTER TABLE ONLY inv_sw
    ADD CONSTRAINT inv_sw_router_id_fkey FOREIGN KEY (router_id) REFERENCES routers(router_id) ON DELETE CASCADE;


--
-- Name: network_router_id_a_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ngnms
--

ALTER TABLE ONLY network
    ADD CONSTRAINT network_router_id_a_fkey FOREIGN KEY (router_id_a) REFERENCES routers(router_id) ON DELETE CASCADE;


--
-- Name: network_router_id_b_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ngnms
--

ALTER TABLE ONLY network
    ADD CONSTRAINT network_router_id_b_fkey FOREIGN KEY (router_id_b) REFERENCES routers(router_id) ON DELETE CASCADE;


--
-- Name: ph_int_router_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ngnms
--

ALTER TABLE ONLY ph_int
    ADD CONSTRAINT ph_int_router_id_fkey FOREIGN KEY (router_id) REFERENCES routers(router_id) ON DELETE CASCADE;


--
-- Name: router_access_id_access_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ngnms
--

ALTER TABLE ONLY router_access
    ADD CONSTRAINT router_access_id_access_fkey FOREIGN KEY (id_access) REFERENCES access(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: router_access_id_router_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ngnms
--

ALTER TABLE ONLY router_access
    ADD CONSTRAINT router_access_id_router_fkey FOREIGN KEY (id_router) REFERENCES routers(router_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: router_peers_routers_router_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: ngnms
--

ALTER TABLE ONLY router_peers
    ADD CONSTRAINT router_peers_routers_router_id_fk FOREIGN KEY (router_id) REFERENCES routers(router_id) ON DELETE CASCADE;


--
-- Name: router_peers_routers_router_id_fk2; Type: FK CONSTRAINT; Schema: public; Owner: ngnms
--

ALTER TABLE ONLY router_peers
    ADD CONSTRAINT router_peers_routers_router_id_fk2 FOREIGN KEY (router_peer_id) REFERENCES routers(router_id) ON DELETE CASCADE;


--
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- Name: admrecords; Type: ACL; Schema: public; Owner: ngnms
--

REVOKE ALL ON TABLE admrecords FROM PUBLIC;
REVOKE ALL ON TABLE admrecords FROM ngnms;
GRANT ALL ON TABLE admrecords TO ngnms;


--
-- Name: admrecords_RecID_seq; Type: ACL; Schema: public; Owner: ngnms
--

REVOKE ALL ON SEQUENCE "admrecords_RecID_seq" FROM PUBLIC;
REVOKE ALL ON SEQUENCE "admrecords_RecID_seq" FROM ngnms;
GRANT ALL ON SEQUENCE "admrecords_RecID_seq" TO ngnms;


--
-- Name: archives; Type: ACL; Schema: public; Owner: ngnms
--

REVOKE ALL ON TABLE archives FROM PUBLIC;
REVOKE ALL ON TABLE archives FROM ngnms;
GRANT ALL ON TABLE archives TO ngnms;


--
-- Name: archives_archive_id_seq; Type: ACL; Schema: public; Owner: ngnms
--

REVOKE ALL ON SEQUENCE archives_archive_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE archives_archive_id_seq FROM ngnms;
GRANT ALL ON SEQUENCE archives_archive_id_seq TO ngnms;


--
-- Name: events; Type: ACL; Schema: public; Owner: ngnms
--

REVOKE ALL ON TABLE events FROM PUBLIC;
REVOKE ALL ON TABLE events FROM ngnms;
GRANT ALL ON TABLE events TO ngnms;


--
-- Name: events_event_id_seq; Type: ACL; Schema: public; Owner: ngnms
--

REVOKE ALL ON SEQUENCE events_event_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE events_event_id_seq FROM ngnms;
GRANT ALL ON SEQUENCE events_event_id_seq TO ngnms;


--
-- Name: interfaces; Type: ACL; Schema: public; Owner: ngnms
--

REVOKE ALL ON TABLE interfaces FROM PUBLIC;
REVOKE ALL ON TABLE interfaces FROM ngnms;
GRANT ALL ON TABLE interfaces TO ngnms;


--
-- Name: interfaces_ifc_id_seq; Type: ACL; Schema: public; Owner: ngnms
--

REVOKE ALL ON SEQUENCE interfaces_ifc_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE interfaces_ifc_id_seq FROM ngnms;
GRANT ALL ON SEQUENCE interfaces_ifc_id_seq TO ngnms;


--
-- Name: inv_hw; Type: ACL; Schema: public; Owner: ngnms
--

REVOKE ALL ON TABLE inv_hw FROM PUBLIC;
REVOKE ALL ON TABLE inv_hw FROM ngnms;
GRANT ALL ON TABLE inv_hw TO ngnms;


--
-- Name: inv_sw; Type: ACL; Schema: public; Owner: ngnms
--

REVOKE ALL ON TABLE inv_sw FROM PUBLIC;
REVOKE ALL ON TABLE inv_sw FROM ngnms;
GRANT ALL ON TABLE inv_sw TO ngnms;


--
-- Name: network; Type: ACL; Schema: public; Owner: ngnms
--

REVOKE ALL ON TABLE network FROM PUBLIC;
REVOKE ALL ON TABLE network FROM ngnms;
GRANT ALL ON TABLE network TO ngnms;


--
-- Name: network_link_id_seq; Type: ACL; Schema: public; Owner: ngnms
--

REVOKE ALL ON SEQUENCE network_link_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE network_link_id_seq FROM ngnms;
GRANT ALL ON SEQUENCE network_link_id_seq TO ngnms;


--
-- Name: ph_int; Type: ACL; Schema: public; Owner: ngnms
--

REVOKE ALL ON TABLE ph_int FROM PUBLIC;
REVOKE ALL ON TABLE ph_int FROM ngnms;
GRANT ALL ON TABLE ph_int TO ngnms;


--
-- Name: ph_int_ph_int_id_seq; Type: ACL; Schema: public; Owner: ngnms
--

REVOKE ALL ON SEQUENCE ph_int_ph_int_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE ph_int_ph_int_id_seq FROM ngnms;
GRANT ALL ON SEQUENCE ph_int_ph_int_id_seq TO ngnms;


--
-- Name: router_graph; Type: ACL; Schema: public; Owner: ngnms
--

REVOKE ALL ON TABLE router_graph FROM PUBLIC;
REVOKE ALL ON TABLE router_graph FROM ngnms;
GRANT ALL ON TABLE router_graph TO ngnms;


--
-- Name: router_vendors; Type: ACL; Schema: public; Owner: ngnms
--

REVOKE ALL ON TABLE router_vendors FROM PUBLIC;
REVOKE ALL ON TABLE router_vendors FROM ngnms;
GRANT ALL ON TABLE router_vendors TO ngnms;


--
-- Name: router_vendors_id_seq; Type: ACL; Schema: public; Owner: ngnms
--

REVOKE ALL ON SEQUENCE router_vendors_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE router_vendors_id_seq FROM ngnms;
GRANT ALL ON SEQUENCE router_vendors_id_seq TO ngnms;


--
-- Name: routers; Type: ACL; Schema: public; Owner: ngnms
--

REVOKE ALL ON TABLE routers FROM PUBLIC;
REVOKE ALL ON TABLE routers FROM ngnms;
GRANT ALL ON TABLE routers TO ngnms;


--
-- Name: routers_router_id_seq; Type: ACL; Schema: public; Owner: ngnms
--

REVOKE ALL ON SEQUENCE routers_router_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE routers_router_id_seq FROM ngnms;
GRANT ALL ON SEQUENCE routers_router_id_seq TO ngnms;


--
-- PostgreSQL database dump complete
--

