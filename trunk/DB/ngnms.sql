--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'SQL_ASCII';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


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

SET default_tablespace = '';

SET default_with_oids = false;

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
    ip_addr inet
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
-- Name: event_filter_history; Type: TABLE; Schema: public; Owner: ngnms; Tablespace: 
--

CREATE TABLE event_filter_history (
    id integer NOT NULL,
    filter character varying(1024),
    raiting integer
);


ALTER TABLE public.event_filter_history OWNER TO ngnms;

--
-- Name: event_filter_history_id_seq; Type: SEQUENCE; Schema: public; Owner: ngnms
--

CREATE SEQUENCE event_filter_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.event_filter_history_id_seq OWNER TO ngnms;

--
-- Name: event_filter_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ngnms
--

ALTER SEQUENCE event_filter_history_id_seq OWNED BY event_filter_history.id;


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
    created timestamp without time zone DEFAULT now() NOT NULL
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
    layer smallint DEFAULT 3
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


ALTER TABLE public.tbl_user_id_seq OWNER TO ngnms;

--
-- Name: tbl_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ngnms
--

ALTER SEQUENCE tbl_user_id_seq OWNED BY tbl_user.id;


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

ALTER TABLE ONLY event_filter_history ALTER COLUMN id SET DEFAULT nextval('event_filter_history_id_seq'::regclass);


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


--
-- Data for Name: access; Type: TABLE DATA; Schema: public; Owner: ngnms
--

COPY access (id, name, id_access_type) FROM stdin;
10	SERVERS	3
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
12h	7d	12h	1	archive	1	6	1	1
\.


--
-- Name: archive_conf_id_conf_seq; Type: SEQUENCE SET; Schema: public; Owner: ngnms
--

SELECT pg_catalog.setval('archive_conf_id_conf_seq', 1000, true);


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
28	16	10	KgaV0PIpmHk=
29	17	10	nYJK8LB9NNE=
30	18	10	vRIZOV4QuNQ=
31	14	10	nYJK8LB9NNE=
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
1	127.0.0.1	1426170469
\.


--
-- Name: bans_ips_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ngnms
--

SELECT pg_catalog.setval('bans_ips_id_seq', 1000, true);


--
-- Data for Name: bgp_links; Type: TABLE DATA; Schema: public; Owner: ngnms
--

COPY bgp_links (id, side_a, side_b, link_type) FROM stdin;
1	2	1	P
4	4	5	P
2	1	3	P
3	1	4	P
5	5	3	P
\.


--
-- Name: bgp_links_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ngnms
--

SELECT pg_catalog.setval('bgp_links_id_seq', 1000, true);


--
-- Data for Name: bgp_routers; Type: TABLE DATA; Schema: public; Owner: ngnms
--

COPY bgp_routers (id, bgp_type, status, autonomous_system, ip_addr) FROM stdin;
2	external	1		10.3.3.3
5	external	1	100	20.0.1.1
1	external	1	100	192.168.3.202
3	external	1	64512	192.168.3.200
4	external	1	500	20.0.1.2
\.


--
-- Name: bgp_routers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ngnms
--

SELECT pg_catalog.setval('bgp_routers_id_seq', 1000, true);


--
-- Data for Name: discovery_status; Type: TABLE DATA; Schema: public; Owner: ngnms
--

COPY discovery_status (username, percent, lastchange, finish, start, ended, interactive) FROM stdin;
ngnms	100	2015-03-03 10:29:52.497039+00	\N	2015-03-03 10:29:22.384744+00	1	0
ngnms	100	2015-03-03 12:56:04.993837+00	\N	2015-03-03 12:55:34.845552+00	1	0
ngnms	100	2015-03-03 10:40:13.304092+00	\N	2015-03-03 10:39:43.181516+00	1	0
ngnms	100	2015-03-03 10:30:48.047236+00	\N	2015-03-03 10:30:17.908725+00	1	0
ngnms	100	2015-02-24 16:00:01.503887+00	\N	2015-02-24 15:59:31.370127+00	1	0
ngnms	100	2015-03-03 12:57:13.243858+00	\N	2015-03-03 12:56:43.0572+00	1	0
ngnms	100	2015-03-03 10:41:49.878958+00	\N	2015-03-03 10:41:19.766715+00	1	0
ngnms	100	2015-03-03 13:18:10.849946+00	\N	2015-03-03 13:17:40.731248+00	1	0
ngnms	100	2015-03-03 10:33:21.455153+00	\N	2015-03-03 10:32:51.10649+00	1	0
ngnms	100	2015-03-03 10:17:43.765512+00	\N	2015-03-03 10:17:13.648684+00	1	0
ngnms	100	2015-03-03 10:46:01.769713+00	\N	2015-03-03 10:45:31.621452+00	1	0
ngnms	100	2015-03-03 10:26:48.272398+00	\N	2015-03-03 10:26:18.108398+00	1	0
ngnms	100	2015-03-03 10:34:20.496469+00	\N	2015-03-03 10:33:50.360414+00	1	0
ngnms	100	2015-03-03 13:02:37.601804+00	\N	2015-03-03 13:02:07.440992+00	1	0
ngnms	100	2015-03-03 13:44:04.868191+00	2015-03-03 13:44:05.758243+00	2015-03-03 13:43:34.697723+00	1	0
ngnms	100	2015-03-03 10:29:01.138711+00	\N	2015-03-03 10:28:30.982191+00	1	0
ngnms	100	2015-03-03 10:37:34.220884+00	\N	2015-03-03 10:37:04.082837+00	1	0
ngnms	100	2015-03-03 13:03:20.935261+00	\N	2015-03-03 13:02:50.764631+00	1	0
ngnms	100	2015-03-03 12:19:02.24033+00	\N	2015-03-03 12:18:32.131449+00	1	0
ngnms	100	2015-03-03 13:09:38.125904+00	\N	2015-03-03 13:09:07.958669+00	1	0
ngnms	100	2015-03-03 13:16:24.141746+00	\N	2015-03-03 13:15:54.002467+00	1	0
ngnms	100	2015-03-06 13:18:39.765998+00	2015-03-06 13:18:40.026084+00	2015-03-06 13:18:02.720962+00	1	0
ngnms	100	2015-03-06 10:58:10.49898+00	2015-03-06 10:58:11.461391+00	2015-03-06 10:57:40.366546+00	1	0
ngnms	100	2015-03-06 13:18:39.765998+00	2015-03-06 13:18:40.026084+00	2015-03-06 13:18:09.67638+00	1	0
ngnms	100	2015-03-06 09:46:39.131466+00	2015-03-06 09:46:40.046925+00	2015-03-06 09:46:08.991493+00	1	0
ngnms	100	2015-03-03 14:00:03.247435+00	2015-03-03 14:32:39.503413+00	2015-03-03 13:59:33.073579+00	1	1
ngnms	100	2015-03-06 10:59:23.33231+00	2015-03-06 10:59:24.291443+00	2015-03-06 10:58:53.19514+00	1	0
ngnms	100	2015-03-06 10:29:09.351831+00	2015-03-06 10:29:10.138571+00	2015-03-06 10:28:39.175759+00	1	0
ngnms	100	2015-03-03 14:59:20.339959+00	2015-03-03 14:59:21.495144+00	2015-03-03 14:58:49.837442+00	1	1
ngnms	100	2015-03-06 09:44:31.406754+00	2015-03-06 09:44:31.804079+00	2015-03-06 09:44:01.164886+00	1	0
ngnms	100	2015-03-06 10:34:14.184516+00	2015-03-06 10:34:14.913427+00	2015-03-06 10:33:44.008533+00	1	0
ngnms	100	2015-03-06 13:15:44.375041+00	2015-03-06 13:15:45.236594+00	2015-03-06 13:15:14.187837+00	1	0
ngnms	100	2015-03-06 10:51:37.307709+00	2015-03-06 10:51:38.102501+00	2015-03-06 10:51:07.196879+00	1	0
ngnms	100	2015-03-06 10:53:34.165673+00	2015-03-06 10:53:34.964499+00	2015-03-06 10:53:04.051568+00	1	0
	100	2015-11-18 00:03:03.388393+00	2015-11-18 00:03:15.453689+00	2015-11-18 00:00:02.648532+00	1	0
	100	2015-11-18 13:49:03.912022+00	2015-11-18 13:49:16.112454+00	2015-11-18 13:46:43.027758+00	1	0
	100	2015-11-15 00:08:26.683163+00	2015-11-15 00:08:35.111576+00	2015-11-15 00:00:02.918622+00	1	0
	100	2015-11-09 00:07:33.134921+00	2015-11-09 00:08:23.358555+00	2015-11-09 00:00:02.699954+00	1	0
	100	2015-11-17 00:03:04.108707+00	2015-11-17 00:03:10.635768+00	2015-11-17 00:00:05.433698+00	1	0
	100	2015-11-19 09:25:29.787099+00	2015-11-19 09:25:31.577085+00	2015-11-19 09:23:46.2181+00	1	0
	100	2015-11-08 00:07:35.236899+00	2015-11-08 00:07:39.44586+00	2015-11-08 00:00:02.444793+00	1	0
	100	2015-11-17 11:23:29.493448+00	2015-11-17 11:23:31.407089+00	2015-11-17 11:21:41.560518+00	1	0
	100	2015-11-19 13:19:53.610085+00	2015-11-19 13:19:59.682169+00	2015-11-19 13:17:38.847484+00	1	0
	100	2015-11-19 11:12:09.772588+00	2015-11-19 11:12:10.640067+00	2015-11-19 11:10:15.165834+00	1	0
	100	2015-11-14 00:07:35.479001+00	2015-11-14 00:07:37.044282+00	2015-11-14 00:00:02.94313+00	1	0
	100	2015-11-07 00:07:33.451685+00	2015-11-07 00:07:34.091137+00	2015-11-07 00:00:02.308058+00	1	0
	100	2015-11-19 00:03:15.583199+00	2015-11-19 00:03:19.159378+00	2015-11-19 00:00:02.969518+00	1	0
	100	2015-11-16 11:05:11.387673+00	2015-11-16 11:05:12.205783+00	2015-11-16 11:03:11.091886+00	1	0
	100	2015-11-19 13:59:49.849099+00	2015-11-19 13:59:50.452239+00	2015-11-19 13:58:11.062841+00	1	0
	100	2015-11-13 00:07:45.059932+00	2015-11-13 00:07:46.131919+00	2015-11-13 00:00:02.631219+00	1	0
	100	2015-11-19 11:08:08.04694+00	2015-11-19 11:08:11.320223+00	2015-11-19 11:05:51.06144+00	1	0
	100	2015-11-06 00:07:24.558487+00	2015-11-06 00:07:25.899677+00	2015-11-06 00:00:02.425376+00	1	0
	100	2015-11-18 12:02:18.327281+00	2015-11-18 12:02:22.339976+00	2015-11-18 12:00:02.846257+00	1	0
	100	2015-11-19 11:03:22.588335+00	2015-11-19 11:03:24.161278+00	2015-11-19 11:01:45.148515+00	1	0
	100	2015-11-05 00:07:00.386612+00	2015-11-05 00:08:27.107238+00	2015-11-05 00:00:04.809172+00	1	0
	100	2015-11-17 18:03:01.757022+00	2015-11-17 18:03:11.891025+00	2015-11-17 18:00:02.622636+00	1	0
	100	2015-11-19 08:53:12.473693+00	2015-11-19 08:53:13.352182+00	2015-11-19 08:50:43.805228+00	1	0
	100	2015-11-16 18:02:15.201679+00	2015-11-16 18:02:15.739699+00	2015-11-16 18:00:02.462754+00	1	0
	100	2015-11-12 00:08:33.148897+00	2015-11-12 00:08:44.83707+00	2015-11-12 00:00:02.925799+00	1	0
	100	2015-11-18 18:02:16.788282+00	2015-11-18 18:02:17.140539+00	2015-11-18 18:00:02.879233+00	1	0
	100	2015-11-18 13:34:09.327206+00	2015-11-18 13:34:12.603106+00	2015-11-18 13:31:37.000002+00	1	0
	100	2015-11-19 13:53:40.555894+00	2015-11-19 13:53:41.154686+00	2015-11-19 13:51:19.06566+00	1	0
	100	2015-11-11 00:07:20.629707+00	2015-11-11 00:07:24.560218+00	2015-11-11 00:00:02.717153+00	1	0
	100	2015-11-19 12:28:21.130581+00	2015-11-19 12:29:13.563015+00	2015-11-19 12:25:43.824007+00	1	0
	100	2015-11-19 13:28:00.453147+00	2015-11-19 13:28:02.13285+00	2015-11-19 13:25:37.475985+00	1	0
	100	2015-11-17 06:03:32.418732+00	2015-11-17 06:04:06.157877+00	2015-11-17 06:00:02.626745+00	1	0
	100	2015-11-10 00:06:50.665484+00	2015-11-10 00:06:51.026293+00	2015-11-10 00:00:03.200873+00	1	0
	100	2015-11-18 14:06:09.081232+00	2015-11-18 14:06:16.51122+00	2015-11-18 14:03:51.826525+00	1	0
	100	2015-11-18 06:02:07.781112+00	2015-11-18 06:02:08.869001+00	2015-11-18 06:00:03.083693+00	1	0
	100	2015-11-19 10:55:49.081435+00	2015-11-19 10:55:54.274016+00	2015-11-19 10:53:41.587066+00	1	0
	100	2015-11-16 00:07:42.609617+00	2015-11-16 00:07:45.212764+00	2015-11-16 00:00:02.955996+00	1	0
	100	2015-11-17 12:01:55.538149+00	2015-11-17 12:01:56.033583+00	2015-11-17 12:00:02.813598+00	1	0
	100	2015-11-16 12:02:58.380374+00	2015-11-16 12:03:19.841225+00	2015-11-16 12:00:02.623498+00	1	0
	100	2015-11-19 14:12:46.996089+00	2015-11-19 14:12:48.86159+00	2015-11-19 14:10:42.87006+00	1	0
	100	2015-11-19 13:37:12.123903+00	2015-11-19 13:37:12.761462+00	2015-11-19 13:35:11.27065+00	1	0
	100	2015-11-19 08:42:05.198083+00	2015-11-19 08:42:05.69827+00	2015-11-19 08:40:13.122765+00	1	0
	100	2015-11-19 13:34:31.476793+00	2015-11-19 13:34:31.981061+00	2015-11-19 13:31:32.461213+00	1	0
	100	2015-11-18 14:12:52.00499+00	2015-11-18 14:12:52.335378+00	2015-11-18 14:12:09.130894+00	1	0
	100	2015-11-18 13:29:53.554396+00	2015-11-18 13:29:54.004258+00	2015-11-18 13:28:09.11213+00	1	0
	100	2015-11-19 12:33:08.184786+00	2015-11-19 12:33:08.711556+00	2015-11-19 12:31:10.733877+00	1	0
	100	2015-11-19 09:44:35.681113+00	2015-11-19 09:44:37.696585+00	2015-11-19 09:42:55.310013+00	1	0
	100	2015-11-19 13:22:40.222215+00	2015-11-19 13:22:41.046701+00	2015-11-19 13:20:46.668785+00	1	0
	100	2015-11-19 13:31:25.001829+00	2015-11-19 13:31:26.735901+00	2015-11-19 13:29:17.399393+00	1	0
	100	2015-11-19 11:55:34.087866+00	2015-11-19 11:55:44.497818+00	2015-11-19 11:53:07.042499+00	1	0
	100	2015-11-19 11:27:11.443451+00	2015-11-19 11:27:14.368742+00	2015-11-19 11:25:17.738085+00	1	0
	100	2015-11-19 06:02:23.586944+00	2015-11-19 06:02:24.527524+00	2015-11-19 06:00:03.212276+00	1	0
	100	2015-11-19 13:14:05.49447+00	2015-11-19 13:14:05.954693+00	2015-11-19 13:12:07.419296+00	1	0
	100	2015-11-19 11:22:21.998173+00	2015-11-19 11:22:25.491489+00	2015-11-19 11:20:19.654232+00	1	0
	100	2015-11-19 13:44:38.143766+00	2015-11-19 13:44:59.219038+00	2015-11-19 13:42:01.277859+00	1	0
	100	2015-11-19 12:24:20.931115+00	2015-11-19 12:24:23.526867+00	2015-11-19 12:22:43.862128+00	1	0
	100	2015-11-19 12:02:28.206212+00	2015-11-19 12:02:32.428343+00	2015-11-19 12:00:02.566731+00	1	0
	100	2015-11-19 15:00:02.55256+00	2015-11-19 15:00:03.034486+00	2015-11-19 14:57:39.733276+00	1	0
	100	2015-11-20 08:09:19.718531+00	2015-11-20 08:09:20.163739+00	2015-11-20 08:07:16.05218+00	1	0
	100	2015-11-19 14:27:05.144324+00	2015-11-19 14:27:05.779335+00	2015-11-19 14:25:22.494279+00	1	0
	100	2015-11-19 14:54:37.838803+00	2015-11-19 14:54:38.372223+00	2015-11-19 14:52:43.891771+00	1	0
	100	2015-11-19 14:50:33.192614+00	2015-11-19 14:50:33.844592+00	2015-11-19 14:48:40.823057+00	1	0
	100	2015-11-19 18:02:19.134994+00	2015-11-19 18:02:21.47171+00	2015-11-19 18:00:02.664915+00	1	0
	100	2015-11-19 14:34:27.935714+00	2015-11-19 14:34:28.958938+00	2015-11-19 14:32:25.583206+00	1	0
	100	2015-11-20 07:48:15.730513+00	2015-11-20 07:49:14.759804+00	2015-11-20 07:44:37.496804+00	1	0
	100	2015-11-20 00:02:38.996432+00	2015-11-20 00:02:50.593734+00	2015-11-20 00:00:02.848285+00	1	0
	100	2015-11-20 06:02:54.910911+00	2015-11-20 06:02:58.822018+00	2015-11-20 06:00:03.067447+00	1	0
	100	2015-11-20 08:11:30.186267+00	2015-11-20 08:11:30.741393+00	2015-11-20 08:09:57.666116+00	1	0
	100	2015-11-20 08:17:04.679878+00	2015-11-20 08:17:05.260928+00	2015-11-20 08:14:50.0324+00	1	0
	100	2015-11-20 08:19:36.579913+00	2015-11-20 08:19:41.224452+00	2015-11-20 08:17:43.102693+00	1	0
	100	2015-11-20 08:25:33.679056+00	2015-11-20 08:25:34.218403+00	2015-11-20 08:24:00.701499+00	1	0
	100	2015-11-20 08:28:11.151547+00	2015-11-20 08:28:13.60334+00	2015-11-20 08:26:23.250817+00	1	0
	100	2015-11-20 08:33:35.881468+00	2015-11-20 08:33:38.366123+00	2015-11-20 08:31:46.952705+00	1	0
	100	2015-11-20 08:36:40.445746+00	2015-11-20 08:36:41.098407+00	2015-11-20 08:34:45.883528+00	1	0
	100	2015-11-20 12:02:35.094825+00	2015-11-20 12:02:41.388529+00	2015-11-20 12:00:03.101432+00	1	0
	100	2015-11-20 12:05:58.770723+00	2015-11-20 12:05:59.336278+00	2015-11-20 12:04:13.874058+00	1	0
	100	2015-11-20 12:15:37.62146+00	2015-11-20 12:15:38.207747+00	2015-11-20 12:13:53.00723+00	1	0
	100	2015-11-20 12:19:55.670257+00	2015-11-20 12:19:56.260459+00	2015-11-20 12:18:05.29681+00	1	0
	100	2015-11-20 12:24:47.256037+00	2015-11-20 12:24:47.757299+00	2015-11-20 12:23:10.501498+00	1	0
	100	2015-11-22 10:01:22.515915+00	2015-11-22 10:01:24.254117+00	2015-11-22 10:00:02.787977+00	1	0
	100	2015-11-20 13:44:55.119518+00	2015-11-20 13:44:55.678864+00	2015-11-20 13:42:44.788929+00	1	0
	100	2015-12-02 09:28:58.324326+00	2015-12-02 09:28:59.466145+00	2015-12-02 09:27:42.357972+00	1	0
	100	2015-11-20 13:24:17.594609+00	2015-11-20 13:24:20.253589+00	2015-11-20 13:21:38.606714+00	1	0
	100	2015-11-20 13:29:59.823254+00	2015-11-20 13:30:03.9721+00	2015-11-20 13:27:41.672492+00	1	0
	100	2015-11-30 12:02:34.904288+00	2015-11-30 12:02:36.593467+00	2015-11-30 12:00:05.720013+00	1	0
	100	2015-11-25 00:02:28.95498+00	2015-11-25 00:02:29.110219+00	2015-11-25 00:00:05.152138+00	1	0
	100	2015-11-20 14:01:30.22619+00	2015-11-20 14:01:31.294491+00	2015-11-20 14:00:15.496625+00	1	0
	100	2015-11-22 18:01:37.686679+00	2015-11-22 18:01:39.632576+00	2015-11-22 18:00:02.936258+00	1	0
	100	2015-11-20 14:22:26.977518+00	2015-11-20 14:22:28.0496+00	2015-11-20 14:21:04.70048+00	1	0
	100	2015-11-26 18:01:46.123581+00	2015-11-26 18:01:46.364903+00	2015-11-26 18:00:06.202586+00	1	0
	100	2015-11-21 12:02:07.292282+00	2015-11-21 12:02:08.368081+00	2015-11-21 12:00:02.936604+00	1	0
	100	2015-11-20 12:43:51.484139+00	2015-11-20 12:43:51.964264+00	2015-11-20 12:41:33.050464+00	1	0
	100	2015-11-22 15:01:25.327521+00	2015-11-22 15:01:27.080252+00	2015-11-22 15:00:02.864924+00	1	0
	100	2015-11-21 20:01:24.946996+00	2015-11-21 20:01:26.644956+00	2015-11-21 20:00:02.816167+00	1	0
	100	2015-11-22 01:01:20.68079+00	2015-11-22 01:01:22.386511+00	2015-11-22 01:00:02.913194+00	1	0
	100	2015-11-20 14:05:08.311658+00	2015-11-20 14:05:09.381859+00	2015-11-20 14:03:36.708071+00	1	0
	100	2015-11-22 06:01:48.870547+00	2015-11-22 06:01:50.585541+00	2015-11-22 06:00:02.632484+00	1	0
	100	2015-12-01 12:02:28.003352+00	2015-12-01 12:02:29.235136+00	2015-12-01 12:00:06.684197+00	1	0
	100	2015-11-20 13:36:27.773831+00	2015-11-20 13:36:29.55151+00	2015-11-20 13:34:46.313789+00	1	0
	100	2015-11-20 13:49:00.598573+00	2015-11-20 13:49:01.148867+00	2015-11-20 13:47:13.07664+00	1	0
	100	2015-11-30 18:01:49.338535+00	2015-11-30 18:01:50.50585+00	2015-11-30 18:00:03.377871+00	1	0
	100	2015-11-20 14:43:42.800282+00	2015-11-20 14:43:43.873957+00	2015-11-20 14:42:14.487939+00	1	0
	100	2015-11-26 06:01:44.660913+00	2015-11-26 06:01:44.888785+00	2015-11-26 06:00:06.801002+00	1	0
	100	2015-11-22 11:01:44.845692+00	2015-11-22 11:01:46.85596+00	2015-11-22 11:00:02.656649+00	1	0
	100	2015-11-21 15:45:59.509095+00	2015-11-21 15:46:01.448242+00	2015-11-21 15:45:07.964431+00	1	0
	100	2015-11-20 14:08:13.929654+00	2015-11-20 14:08:15.000612+00	2015-11-20 14:06:43.623466+00	1	0
	100	2015-11-23 18:01:52.749311+00	2015-11-23 18:01:52.945889+00	2015-11-23 18:00:05.56708+00	1	0
	100	2015-11-20 13:52:24.054967+00	2015-11-20 13:52:25.128713+00	2015-11-20 13:51:03.100155+00	1	0
	100	2015-11-21 21:01:23.702567+00	2015-11-21 21:01:25.417271+00	2015-11-21 21:00:02.933129+00	1	0
	50	2015-11-22 22:01:40.001363+00	2015-11-23 00:00:03.321984+00	2015-11-22 21:58:02.255578+00	1	0
	100	2015-11-20 13:16:52.653834+00	2015-11-20 13:16:53.333884+00	2015-11-20 13:14:57.22736+00	1	0
	15	2015-11-27 00:00:51.457814+00	2015-11-27 06:00:06.060396+00	2015-11-27 00:00:07.298363+00	1	0
	100	2015-11-22 02:01:21.703279+00	2015-11-22 02:01:23.425304+00	2015-11-22 02:00:02.789243+00	1	0
	100	2015-11-20 18:01:42.913173+00	2015-11-20 18:01:44.011598+00	2015-11-20 18:00:03.170497+00	1	0
	100	2015-11-20 13:41:00.725924+00	2015-11-20 13:41:13.764354+00	2015-11-20 13:38:36.713452+00	1	0
	100	2015-11-20 14:13:38.107239+00	2015-11-20 14:13:39.184801+00	2015-11-20 14:12:10.110053+00	1	0
	100	2015-11-20 13:56:26.719911+00	2015-11-20 13:56:27.784329+00	2015-11-20 13:55:07.241372+00	1	0
	100	2015-11-24 12:02:08.094072+00	2015-11-24 12:02:08.340861+00	2015-11-24 12:00:03.525521+00	1	0
	100	2015-11-21 17:01:57.999832+00	2015-11-21 17:01:59.776142+00	2015-11-21 17:00:05.33025+00	1	0
	100	2015-11-22 07:01:22.777824+00	2015-11-22 07:01:24.567915+00	2015-11-22 07:00:03.137467+00	1	0
	100	2015-11-22 19:12:28.10592+00	2015-11-22 19:12:29.876605+00	2015-11-22 19:09:05.533531+00	1	0
	100	2015-11-22 16:01:33.842991+00	2015-11-22 16:01:35.588809+00	2015-11-22 16:00:02.469701+00	1	0
	100	2015-11-21 22:01:32.219866+00	2015-11-21 22:01:33.981385+00	2015-11-21 22:00:02.756221+00	1	0
	100	2015-11-21 00:02:06.415694+00	2015-11-21 00:02:07.491876+00	2015-11-21 00:00:02.839434+00	1	0
	100	2015-11-20 13:58:17.504428+00	2015-11-20 13:58:18.562582+00	2015-11-20 13:56:46.302456+00	1	0
	100	2015-11-22 12:01:51.980505+00	2015-11-22 12:01:54.093732+00	2015-11-22 12:00:02.367904+00	1	0
	100	2015-11-27 18:02:01.395993+00	2015-11-27 18:02:01.673558+00	2015-11-27 18:00:06.462716+00	1	0
	100	2015-11-25 18:01:34.598338+00	2015-11-25 18:01:34.750607+00	2015-11-25 18:00:03.625863+00	1	0
	100	2015-11-22 03:01:31.473674+00	2015-11-22 03:01:33.256368+00	2015-11-22 03:00:02.80359+00	1	0
	100	2015-11-21 18:02:43.806239+00	2015-11-21 18:02:45.724671+00	2015-11-21 18:00:02.252692+00	1	0
	100	2015-11-28 06:02:26.750205+00	2015-11-28 06:02:26.967337+00	2015-11-28 06:00:06.845519+00	1	0
	100	2015-11-21 06:02:18.678498+00	2015-11-21 06:02:19.786215+00	2015-11-21 06:00:02.405439+00	1	0
	100	2015-11-22 08:01:16.786475+00	2015-11-22 08:01:18.581654+00	2015-11-22 08:00:03.216441+00	1	0
	100	2015-11-21 23:01:57.912283+00	2015-11-21 23:01:59.657052+00	2015-11-21 23:00:02.381168+00	1	0
	100	2015-11-25 06:01:34.076912+00	2015-11-25 06:01:34.286799+00	2015-11-25 06:00:02.535885+00	1	0
	100	2015-11-20 14:19:20.338281+00	2015-11-20 14:19:20.709957+00	2015-11-20 14:17:01.968082+00	1	0
	100	2015-12-02 09:53:04.815002+00	2015-12-02 09:53:05.988893+00	2015-12-02 09:51:59.730433+00	1	0
	100	2015-11-21 19:01:34.043792+00	2015-11-21 19:01:35.786918+00	2015-11-21 19:00:03.201467+00	1	0
	100	2015-11-22 16:30:01.64039+00	2015-11-22 16:30:03.415616+00	2015-11-22 16:29:11.217151+00	1	0
	100	2015-11-23 06:01:38.961728+00	2015-11-23 06:01:39.196193+00	2015-11-23 06:00:02.898608+00	1	0
	100	2015-11-22 04:01:32.527031+00	2015-11-22 04:01:34.308588+00	2015-11-22 04:00:02.724842+00	1	0
	100	2015-11-22 13:01:33.376768+00	2015-11-22 13:01:35.078418+00	2015-11-22 13:00:02.775595+00	1	0
	5	2015-11-28 12:02:17.865882+00	2015-11-30 06:00:06.199992+00	2015-11-28 12:02:01.136165+00	1	0
	100	2015-11-24 00:02:25.818773+00	2015-11-24 00:02:26.309641+00	2015-11-24 00:00:03.391858+00	1	0
	100	2015-11-22 00:02:03.332416+00	2015-11-22 00:02:05.184137+00	2015-11-22 00:00:03.141774+00	1	0
	100	2015-11-22 19:28:33.83794+00	2015-11-22 19:28:34.044339+00	2015-11-22 19:21:29.720126+00	1	0
	100	2015-11-22 09:01:25.695472+00	2015-11-22 09:01:27.415647+00	2015-11-22 09:00:02.852178+00	1	0
	100	2015-12-02 10:38:39.802568+00	2015-12-02 10:38:40.914059+00	2015-12-02 10:37:31.036975+00	1	0
	100	2015-11-22 05:01:51.819907+00	2015-11-22 05:01:53.639738+00	2015-11-22 05:00:02.71992+00	1	0
	100	2015-12-02 09:50:33.093233+00	2015-12-02 09:50:34.201515+00	2015-12-02 09:49:22.196202+00	1	0
	100	2015-11-24 18:01:52.200537+00	2015-11-24 18:01:52.573506+00	2015-11-24 18:00:03.102273+00	1	0
	100	2015-11-22 17:01:52.535772+00	2015-11-22 17:01:54.365716+00	2015-11-22 17:00:03.108579+00	1	0
	100	2015-11-22 14:01:20.659208+00	2015-11-22 14:01:22.416521+00	2015-11-22 14:00:02.440746+00	1	0
	100	2015-12-01 06:01:48.972745+00	2015-12-01 06:01:50.132275+00	2015-12-01 06:00:03.682574+00	1	0
	100	2015-11-26 12:02:12.709517+00	2015-11-26 12:02:13.257268+00	2015-11-26 12:00:07.329341+00	1	0
	100	2015-11-30 09:15:45.176302+00	2015-11-30 09:15:46.294543+00	2015-11-30 09:14:12.138281+00	1	0
	100	2015-11-26 00:02:14.214766+00	2015-11-26 00:02:14.815676+00	2015-11-26 00:00:04.265049+00	1	0
	100	2015-11-23 12:02:30.830004+00	2015-11-23 12:02:31.055968+00	2015-11-23 12:00:03.571897+00	1	0
	100	2015-11-22 19:32:50.959657+00	2015-11-22 19:32:51.317142+00	2015-11-22 19:29:11.769218+00	1	0
	100	2015-11-27 12:02:13.605262+00	2015-11-27 12:02:13.877908+00	2015-11-27 12:00:05.824525+00	1	0
	100	2015-11-25 12:02:34.978455+00	2015-11-25 12:02:35.141114+00	2015-11-25 12:00:02.955896+00	1	0
	100	2015-11-24 06:01:47.040539+00	2015-11-24 06:01:47.384672+00	2015-11-24 06:00:03.341908+00	1	0
	100	2015-12-02 06:01:38.379166+00	2015-12-02 06:01:39.578852+00	2015-12-02 06:00:03.002716+00	1	0
	100	2015-11-28 00:01:41.702965+00	2015-11-28 00:01:42.20114+00	2015-11-28 00:00:07.600231+00	1	0
	100	2015-12-02 09:18:23.634159+00	2015-12-02 09:18:24.852913+00	2015-12-02 09:17:07.708118+00	1	0
	100	2015-12-02 00:02:36.384206+00	2015-12-02 00:02:37.54829+00	2015-12-02 00:00:07.457611+00	1	0
	100	2015-12-01 00:02:47.382682+00	2015-12-01 00:02:55.005139+00	2015-12-01 00:00:02.513718+00	1	0
	100	2015-11-30 09:14:01.110403+00	2015-11-30 09:14:01.35185+00	2015-11-30 09:11:52.353956+00	1	0
	100	2015-12-01 18:01:47.385599+00	2015-12-01 18:01:48.52544+00	2015-12-01 18:00:02.475195+00	1	0
	100	2015-12-02 09:49:13.890009+00	2015-12-02 09:49:15.13114+00	2015-12-02 09:48:02.954732+00	1	0
	100	2015-12-02 11:11:04.994808+00	2015-12-02 11:11:06.114329+00	2015-12-02 11:09:54.239726+00	1	0
	100	2015-12-02 09:14:40.924736+00	2015-12-02 09:14:42.078491+00	2015-12-02 09:13:25.731965+00	1	0
	100	2015-12-02 10:32:33.114012+00	2015-12-02 10:32:34.216383+00	2015-12-02 10:31:22.964463+00	1	0
	100	2015-12-02 09:55:16.30572+00	2015-12-02 09:55:17.422672+00	2015-12-02 09:54:15.832671+00	1	0
	100	2015-12-02 10:37:00.821337+00	2015-12-02 10:37:01.92871+00	2015-12-02 10:35:49.816877+00	1	0
	100	2015-12-02 12:01:17.789864+00	2015-12-02 12:01:18.918707+00	2015-12-02 12:00:02.573191+00	1	0
	100	2015-12-02 11:43:08.519679+00	2015-12-02 11:43:09.713+00	2015-12-02 11:41:58.760275+00	1	0
	100	2015-12-02 11:57:04.772912+00	2015-12-02 11:57:05.890914+00	2015-12-02 11:55:55.565511+00	1	0
	100	2015-12-02 11:40:48.741162+00	2015-12-02 11:40:49.889757+00	2015-12-02 11:39:40.667937+00	1	0
	100	2015-12-02 12:03:32.012108+00	2015-12-02 12:03:33.122333+00	2015-12-02 12:02:33.831448+00	1	0
	100	2015-12-02 12:11:27.525684+00	2015-12-02 12:11:28.627823+00	2015-12-02 12:10:19.281116+00	1	0
	100	2015-12-02 12:15:05.08216+00	2015-12-02 12:15:06.203066+00	2015-12-02 12:13:55.425873+00	1	0
	100	2015-12-02 12:16:49.674932+00	2015-12-02 12:16:50.777554+00	2015-12-02 12:15:48.028393+00	1	0
	100	2015-12-02 12:20:13.739782+00	2015-12-02 12:20:14.905868+00	2015-12-02 12:19:10.319322+00	1	0
	100	2015-12-02 12:23:11.852615+00	2015-12-02 12:23:12.975632+00	2015-12-02 12:21:59.511206+00	1	0
	100	2015-12-02 12:24:21.822747+00	2015-12-02 12:24:22.937483+00	2015-12-02 12:23:26.582804+00	1	0
	100	2015-12-02 12:26:35.000476+00	2015-12-02 12:26:36.128107+00	2015-12-02 12:25:36.220729+00	1	0
	100	2015-12-02 12:29:18.118368+00	2015-12-02 12:29:19.227306+00	2015-12-02 12:28:09.770751+00	1	0
	100	2015-12-02 12:30:49.817678+00	2015-12-02 12:30:50.937893+00	2015-12-02 12:29:40.892478+00	1	0
	100	2015-12-02 12:39:27.781298+00	2015-12-02 12:39:28.907564+00	2015-12-02 12:38:18.000566+00	1	0
	100	2015-12-03 13:14:54.221919+00	2015-12-03 13:14:55.351283+00	2015-12-03 13:13:43.209046+00	1	0
	100	2015-12-03 14:26:59.669388+00	2015-12-03 14:27:00.815203+00	2015-12-03 14:25:46.557319+00	1	0
	100	2015-12-02 12:52:58.347205+00	2015-12-02 12:52:59.465198+00	2015-12-02 12:51:48.855622+00	1	0
	100	2015-12-04 08:00:59.863558+00	2015-12-04 08:01:01.036244+00	2015-12-04 07:59:50.998821+00	1	0
	100	2015-12-03 08:29:06.852037+00	2015-12-03 08:29:07.95347+00	2015-12-03 08:27:54.676813+00	1	0
	100	2015-12-06 06:01:19.408589+00	2015-12-06 06:01:20.529485+00	2015-12-06 06:00:02.897043+00	1	0
	100	2015-12-03 11:59:37.993817+00	2015-12-03 11:59:39.125217+00	2015-12-03 11:58:29.65346+00	1	0
	100	2015-12-06 00:01:14.8016+00	2015-12-06 00:01:15.920471+00	2015-12-06 00:00:02.379939+00	1	0
	100	2015-12-02 13:01:57.174066+00	2015-12-02 13:01:58.370523+00	2015-12-02 13:00:54.114266+00	1	0
	100	2015-12-04 09:00:20.926031+00	2015-12-04 09:00:22.046328+00	2015-12-04 08:59:19.125972+00	1	0
	100	2015-12-03 13:17:20.190202+00	2015-12-03 13:17:21.30857+00	2015-12-03 13:16:16.993428+00	1	0
	100	2015-12-03 08:37:24.704528+00	2015-12-03 08:37:25.884006+00	2015-12-03 08:36:15.045639+00	1	0
	100	2015-12-04 07:20:57.136961+00	2015-12-04 07:20:58.261206+00	2015-12-04 07:19:51.955622+00	1	0
	100	2015-12-02 13:06:34.472396+00	2015-12-02 13:06:35.577819+00	2015-12-02 13:05:33.920866+00	1	0
	100	2015-12-03 12:01:11.683245+00	2015-12-03 12:01:12.815949+00	2015-12-03 12:00:02.766156+00	1	0
	100	2015-12-03 14:32:15.229799+00	2015-12-03 14:32:16.369546+00	2015-12-03 14:31:03.721768+00	1	0
	100	2015-12-03 08:53:06.963226+00	2015-12-03 08:53:08.111384+00	2015-12-03 08:51:58.45945+00	1	0
	100	2015-12-04 09:41:43.950929+00	2015-12-04 09:41:45.090339+00	2015-12-04 09:40:33.571033+00	1	0
	100	2015-12-02 13:09:46.050614+00	2015-12-02 13:09:47.161108+00	2015-12-02 13:08:38.766502+00	1	0
	100	2015-12-03 13:30:13.907508+00	2015-12-03 13:30:15.016343+00	2015-12-03 13:29:12.074598+00	1	0
	100	2015-12-03 12:24:52.270335+00	2015-12-03 12:24:53.463404+00	2015-12-03 12:23:53.004243+00	1	0
	100	2015-12-03 09:18:23.845462+00	2015-12-03 09:18:25.02033+00	2015-12-03 09:17:09.632739+00	1	0
	100	2015-12-04 14:50:23.409616+00	2015-12-04 14:50:24.585537+00	2015-12-04 14:49:11.853574+00	1	0
	100	2015-12-02 13:16:35.820128+00	2015-12-02 13:16:36.95907+00	2015-12-02 13:15:23.820475+00	1	0
	100	2015-12-04 08:06:19.955123+00	2015-12-04 08:06:21.093761+00	2015-12-04 08:05:09.35089+00	1	0
	100	2015-12-04 14:03:57.125136+00	2015-12-04 14:03:58.271135+00	2015-12-04 14:02:46.696241+00	1	0
	100	2015-12-04 07:24:57.435162+00	2015-12-04 07:24:58.568878+00	2015-12-04 07:23:44.304228+00	1	0
	100	2015-12-03 14:35:24.907842+00	2015-12-03 14:35:26.049593+00	2015-12-03 14:34:11.801392+00	1	0
	100	2015-12-03 13:32:34.47625+00	2015-12-03 13:32:35.594681+00	2015-12-03 13:31:22.055718+00	1	0
	100	2015-12-03 09:32:46.114997+00	2015-12-03 09:32:47.230199+00	2015-12-03 09:31:32.279167+00	1	0
	100	2015-12-02 13:20:14.224357+00	2015-12-02 13:20:15.343353+00	2015-12-02 13:19:06.185108+00	1	0
	100	2015-12-03 12:27:17.669195+00	2015-12-03 12:27:18.801239+00	2015-12-03 12:26:05.849581+00	1	0
	100	2015-12-04 14:15:41.606475+00	2015-12-04 14:15:42.800036+00	2015-12-04 14:14:38.950157+00	1	0
	100	2015-12-03 09:36:43.756234+00	2015-12-03 09:36:44.901408+00	2015-12-03 09:35:34.124687+00	1	0
	100	2015-12-02 18:01:35.700829+00	2015-12-02 18:01:36.802082+00	2015-12-02 18:00:05.050775+00	1	0
	100	2015-12-04 09:57:51.453441+00	2015-12-04 09:57:52.658827+00	2015-12-04 09:56:38.14619+00	1	0
	100	2015-12-04 09:04:27.616532+00	2015-12-04 09:04:28.743173+00	2015-12-04 09:03:23.136223+00	1	0
	100	2015-12-03 12:30:16.13315+00	2015-12-03 12:30:17.261133+00	2015-12-03 12:29:08.761277+00	1	0
	100	2015-12-03 13:43:53.093057+00	2015-12-03 13:43:54.224973+00	2015-12-03 13:42:43.116535+00	1	0
	100	2015-12-03 00:01:44.895769+00	2015-12-03 00:01:46.025083+00	2015-12-03 00:00:02.746307+00	1	0
	100	2015-12-03 09:38:58.923143+00	2015-12-03 09:39:00.037878+00	2015-12-03 09:37:48.036712+00	1	0
	100	2015-12-03 14:53:29.720341+00	2015-12-03 14:53:30.855281+00	2015-12-03 14:52:20.445317+00	1	0
	100	2015-12-03 12:34:16.729543+00	2015-12-03 12:34:17.883424+00	2015-12-03 12:33:04.298871+00	1	0
	100	2015-12-03 06:01:33.215697+00	2015-12-03 06:01:34.352073+00	2015-12-03 06:00:02.965254+00	1	0
	100	2015-12-04 08:23:13.430005+00	2015-12-04 08:23:14.580241+00	2015-12-04 08:22:02.324415+00	1	0
	100	2015-12-03 09:44:37.962518+00	2015-12-03 09:44:39.110791+00	2015-12-03 09:43:27.958763+00	1	0
	100	2015-12-04 07:31:02.589637+00	2015-12-04 07:31:03.773606+00	2015-12-04 07:29:51.955142+00	1	0
	100	2015-12-03 13:49:34.173006+00	2015-12-03 13:49:35.322791+00	2015-12-03 13:48:30.268196+00	1	0
	100	2015-12-04 09:43:27.728198+00	2015-12-04 09:43:28.865397+00	2015-12-04 09:42:16.002676+00	1	0
	100	2015-12-03 12:47:33.002354+00	2015-12-03 12:47:34.130179+00	2015-12-03 12:46:21.035852+00	1	0
	100	2015-12-03 11:39:52.802334+00	2015-12-03 11:39:53.927051+00	2015-12-03 11:38:52.707844+00	1	0
	100	2015-12-04 13:24:40.068735+00	2015-12-04 13:24:41.185454+00	2015-12-04 13:23:35.10176+00	1	0
	100	2015-12-03 14:55:38.079841+00	2015-12-03 14:55:39.2063+00	2015-12-03 14:54:29.018858+00	1	0
	100	2015-12-04 14:42:28.228302+00	2015-12-04 14:42:29.351249+00	2015-12-04 14:41:27.840409+00	1	0
	100	2015-12-03 11:50:09.206124+00	2015-12-03 11:50:10.320967+00	2015-12-03 11:49:06.980578+00	1	0
	100	2015-12-03 14:03:49.771752+00	2015-12-03 14:03:50.979861+00	2015-12-03 14:02:47.173724+00	1	0
	100	2015-12-03 13:04:10.235134+00	2015-12-03 13:04:11.354092+00	2015-12-03 13:02:59.414656+00	1	0
	100	2015-12-04 09:21:26.93992+00	2015-12-04 09:21:28.081526+00	2015-12-04 09:20:25.30198+00	1	0
	100	2015-12-04 07:36:36.426342+00	2015-12-04 07:36:37.560928+00	2015-12-04 07:35:29.372123+00	1	0
	100	2015-12-03 11:57:46.759+00	2015-12-03 11:57:47.945763+00	2015-12-03 11:56:33.296459+00	1	0
	100	2015-12-04 08:27:32.915736+00	2015-12-04 08:27:34.022197+00	2015-12-04 08:26:37.602491+00	1	0
	100	2015-12-03 13:06:18.900911+00	2015-12-03 13:06:20.046362+00	2015-12-03 13:05:18.21239+00	1	0
	100	2015-12-03 18:01:19.577434+00	2015-12-03 18:01:20.772201+00	2015-12-03 18:00:02.925889+00	1	0
	100	2015-12-03 14:10:26.746915+00	2015-12-03 14:10:27.965079+00	2015-12-03 14:09:23.237979+00	1	0
	100	2015-12-04 14:32:10.854405+00	2015-12-04 14:32:12.027573+00	2015-12-04 14:30:59.791091+00	1	0
	100	2015-12-03 13:10:44.010595+00	2015-12-03 13:10:45.148948+00	2015-12-03 13:09:40.040394+00	1	0
	100	2015-12-04 11:58:36.294253+00	2015-12-04 11:58:37.395766+00	2015-12-04 11:57:23.343541+00	1	0
	100	2015-12-04 09:45:24.90097+00	2015-12-04 09:45:26.019549+00	2015-12-04 09:44:13.334171+00	1	0
	100	2015-12-04 07:50:06.118872+00	2015-12-04 07:50:07.260613+00	2015-12-04 07:49:01.95522+00	1	0
	100	2015-12-03 14:16:06.419312+00	2015-12-03 14:16:07.526532+00	2015-12-03 14:15:01.066666+00	1	0
	100	2015-12-04 00:01:39.032342+00	2015-12-04 00:01:40.131894+00	2015-12-04 00:00:03.07983+00	1	0
	100	2015-12-04 08:29:12.89514+00	2015-12-04 08:29:14.034074+00	2015-12-04 08:28:03.20863+00	1	0
	100	2015-12-04 09:32:11.857754+00	2015-12-04 09:32:12.983561+00	2015-12-04 09:31:01.065579+00	1	0
	100	2015-12-04 14:05:45.65363+00	2015-12-04 14:05:46.795562+00	2015-12-04 14:04:37.274967+00	1	0
	100	2015-12-04 07:56:20.940633+00	2015-12-04 07:56:22.045072+00	2015-12-04 07:55:17.905056+00	1	0
	100	2015-12-04 06:01:35.458553+00	2015-12-04 06:01:36.998004+00	2015-12-04 06:00:02.379276+00	1	0
	100	2015-12-04 13:54:59.278722+00	2015-12-04 13:55:00.418353+00	2015-12-04 13:53:59.19443+00	1	0
	100	2015-12-05 00:01:26.097446+00	2015-12-05 00:01:27.234273+00	2015-12-05 00:00:02.854214+00	1	0
	100	2015-12-04 08:42:43.740719+00	2015-12-04 08:42:44.891724+00	2015-12-04 08:41:44.388981+00	1	0
	100	2015-12-04 09:47:15.50711+00	2015-12-04 09:47:16.667653+00	2015-12-04 09:46:11.768245+00	1	0
	100	2015-12-04 09:36:01.118017+00	2015-12-04 09:36:02.261063+00	2015-12-04 09:34:50.540569+00	1	0
	100	2015-12-04 14:19:29.859093+00	2015-12-04 14:19:31.025458+00	2015-12-04 14:18:18.160226+00	1	0
	100	2015-12-04 12:01:48.316234+00	2015-12-04 12:01:49.501319+00	2015-12-04 12:00:00.778845+00	1	0
	100	2015-12-05 18:01:32.360393+00	2015-12-05 18:01:33.467029+00	2015-12-05 18:00:02.674379+00	1	0
	100	2015-12-06 12:01:19.579598+00	2015-12-06 12:01:20.699086+00	2015-12-06 12:00:02.433041+00	1	0
	100	2015-12-04 13:58:35.164112+00	2015-12-04 13:58:36.376178+00	2015-12-04 13:57:23.520214+00	1	0
	100	2015-12-04 09:55:10.47061+00	2015-12-04 09:55:11.603767+00	2015-12-04 09:54:06.98259+00	1	0
	100	2015-12-04 14:13:01.77768+00	2015-12-04 14:13:02.948069+00	2015-12-04 14:12:00.339816+00	1	0
	100	2015-12-04 12:06:10.528106+00	2015-12-04 12:06:11.707156+00	2015-12-04 12:04:57.208332+00	1	0
	100	2015-12-04 14:46:09.76532+00	2015-12-04 14:46:10.927011+00	2015-12-04 14:45:06.316805+00	1	0
	100	2015-12-04 14:34:11.623207+00	2015-12-04 14:34:12.759+00	2015-12-04 14:33:01.92824+00	1	0
	100	2015-12-04 14:27:38.49694+00	2015-12-04 14:27:39.630132+00	2015-12-04 14:26:23.881117+00	1	0
	100	2015-12-05 12:01:23.897959+00	2015-12-05 12:01:25.002821+00	2015-12-05 12:00:03.061387+00	1	0
	100	2015-12-04 18:01:20.055638+00	2015-12-04 18:01:21.1632+00	2015-12-04 18:00:02.807236+00	1	0
	100	2015-12-06 18:01:17.529285+00	2015-12-06 18:01:18.637929+00	2015-12-06 18:00:02.394971+00	1	0
	100	2015-12-05 06:01:25.021663+00	2015-12-05 06:01:26.126083+00	2015-12-05 06:00:02.892532+00	1	0
	100	2015-12-07 06:01:31.211575+00	2015-12-07 06:01:32.324699+00	2015-12-07 06:00:03.087256+00	1	0
	100	2015-12-07 00:01:10.311526+00	2015-12-07 00:01:11.425169+00	2015-12-07 00:00:02.446994+00	1	0
	100	2015-12-08 00:01:23.801027+00	2015-12-08 00:01:24.955305+00	2015-12-08 00:00:02.773126+00	1	0
	100	2015-12-07 12:01:27.839176+00	2015-12-07 12:01:28.953786+00	2015-12-07 12:00:02.987128+00	1	0
	100	2015-12-07 18:01:21.893637+00	2015-12-07 18:01:22.999485+00	2015-12-07 18:00:02.395188+00	1	0
	100	2015-12-08 06:01:31.462149+00	2015-12-08 06:01:32.587139+00	2015-12-08 06:00:02.489112+00	1	0
	100	2015-12-08 08:20:29.955657+00	2015-12-08 08:20:31.070809+00	2015-12-08 08:19:20.972243+00	1	0
	100	2015-12-08 12:01:19.242091+00	2015-12-08 12:01:20.469539+00	2015-12-08 12:00:02.65101+00	1	0
	100	2015-12-08 18:01:21.415342+00	2015-12-08 18:01:22.558806+00	2015-12-08 18:00:03.764375+00	1	0
	100	2015-12-09 00:02:02.234863+00	2015-12-09 00:02:03.396235+00	2015-12-09 00:00:03.32631+00	1	0
	100	2015-12-09 06:01:30.574643+00	2015-12-09 06:01:31.704544+00	2015-12-09 06:00:02.805789+00	1	0
	100	2015-12-09 18:01:27.779741+00	2015-12-09 18:01:29.162906+00	2015-12-09 18:00:03.800021+00	1	0
	100	2015-12-12 06:01:29.948203+00	2015-12-12 06:01:31.081239+00	2015-12-12 06:00:03.889375+00	1	0
	100	2015-12-09 12:02:23.40369+00	2015-12-09 12:02:26.276692+00	2015-12-09 12:00:02.999285+00	1	0
	100	2015-12-10 00:01:51.224487+00	2015-12-10 00:01:53.151961+00	2015-12-10 00:00:02.902206+00	1	0
	100	2015-12-15 18:01:22.133084+00	2015-12-15 18:01:23.297956+00	2015-12-15 18:00:03.039137+00	1	0
	100	2015-12-12 12:01:59.341994+00	2015-12-12 12:02:00.487042+00	2015-12-12 12:00:03.206903+00	1	0
	100	2015-12-17 10:05:32.456313+00	2015-12-17 10:05:33.582656+00	2015-12-17 10:04:30.36602+00	1	0
	100	2015-12-14 08:59:30.291947+00	2015-12-14 08:59:31.485805+00	2015-12-14 08:58:28.727703+00	1	0
	100	2015-12-10 06:01:22.343552+00	2015-12-10 06:01:23.493251+00	2015-12-10 06:00:03.558255+00	1	0
	100	2015-12-17 08:45:08.410654+00	2015-12-17 08:45:09.544483+00	2015-12-17 08:44:04.35981+00	1	0
	100	2015-12-12 18:01:32.032611+00	2015-12-12 18:01:33.161412+00	2015-12-12 18:00:03.701126+00	1	0
	100	2015-12-16 14:33:17.823547+00	2015-12-16 14:33:18.95367+00	2015-12-16 14:32:15.391108+00	1	0
	100	2015-12-10 12:02:25.289934+00	2015-12-10 12:02:28.947993+00	2015-12-10 12:00:03.254242+00	1	0
	100	2015-12-16 00:02:21.641845+00	2015-12-16 00:02:23.091589+00	2015-12-16 00:00:03.480824+00	1	0
	100	2015-12-14 12:02:22.310723+00	2015-12-14 12:02:23.422458+00	2015-12-14 12:00:07.025399+00	1	0
	100	2015-12-13 00:01:43.784178+00	2015-12-13 00:01:45.071687+00	2015-12-13 00:00:02.971009+00	1	0
	100	2015-12-10 18:01:19.832622+00	2015-12-10 18:01:20.966986+00	2015-12-10 18:00:03.728896+00	1	0
	100	2015-12-17 10:23:54.807209+00	2015-12-17 10:23:55.927396+00	2015-12-17 10:22:45.426743+00	1	0
	100	2015-12-14 12:51:57.529714+00	2015-12-14 12:51:58.703997+00	2015-12-14 12:50:47.199998+00	1	0
	100	2015-12-11 00:01:44.860737+00	2015-12-11 00:01:46.059497+00	2015-12-11 00:00:02.976973+00	1	0
	100	2015-12-13 06:01:34.814728+00	2015-12-13 06:01:36.028713+00	2015-12-13 06:00:04.673453+00	1	0
	100	2015-12-16 06:01:22.075417+00	2015-12-16 06:01:23.405439+00	2015-12-16 06:00:03.046965+00	1	0
	100	2015-12-17 09:01:46.864435+00	2015-12-17 09:01:47.991944+00	2015-12-17 09:00:46.127804+00	1	0
	100	2015-12-16 14:38:34.376445+00	2015-12-16 14:38:35.518067+00	2015-12-16 14:37:24.317037+00	1	0
	100	2015-12-11 06:01:31.082793+00	2015-12-11 06:01:32.407421+00	2015-12-11 06:00:03.507841+00	1	0
	100	2015-12-13 12:01:52.284234+00	2015-12-13 12:01:53.48906+00	2015-12-13 12:00:03.801468+00	1	0
	100	2015-12-14 12:56:08.366052+00	2015-12-14 12:56:09.536533+00	2015-12-14 12:55:06.048616+00	1	0
	100	2015-12-11 09:42:00.889707+00	2015-12-11 09:42:02.019219+00	2015-12-11 09:40:42.02292+00	1	0
	100	2015-12-16 08:18:29.672659+00	2015-12-16 08:18:30.774726+00	2015-12-16 08:17:20.051797+00	1	0
	100	2015-12-13 18:01:25.343881+00	2015-12-13 18:01:26.514542+00	2015-12-13 18:00:05.562044+00	1	0
	100	2015-12-16 18:01:22.12367+00	2015-12-16 18:01:23.257633+00	2015-12-16 18:00:05.295091+00	1	0
	100	2015-12-11 12:01:28.096107+00	2015-12-11 12:01:29.212874+00	2015-12-11 12:00:03.766+00	1	0
	100	2015-12-14 12:59:28.234614+00	2015-12-14 12:59:29.363715+00	2015-12-14 12:58:22.516647+00	1	0
	100	2015-12-17 09:07:53.830956+00	2015-12-17 09:07:55.017111+00	2015-12-17 09:06:44.978597+00	1	0
	100	2015-12-14 00:01:38.161672+00	2015-12-14 00:01:39.344273+00	2015-12-14 00:00:04.474339+00	1	0
	100	2015-12-11 12:27:05.04676+00	2015-12-11 12:27:06.174203+00	2015-12-11 12:26:03.583946+00	1	0
	100	2015-12-16 08:27:47.324762+00	2015-12-16 08:27:48.461206+00	2015-12-16 08:26:50.838382+00	1	0
	100	2015-12-17 10:32:18.981462+00	2015-12-17 10:32:20.105473+00	2015-12-17 10:31:20.409772+00	1	0
	100	2015-12-14 18:01:24.786286+00	2015-12-14 18:01:25.915736+00	2015-12-14 18:00:02.946231+00	1	0
	100	2015-12-11 14:43:54.79477+00	2015-12-11 14:43:55.922618+00	2015-12-11 14:42:55.85845+00	1	0
	100	2015-12-14 06:01:24.145839+00	2015-12-14 06:01:25.586644+00	2015-12-14 06:00:06.474776+00	1	0
	100	2015-12-17 00:01:27.995474+00	2015-12-17 00:01:29.097718+00	2015-12-17 00:00:04.556806+00	1	0
	100	2015-12-16 08:31:10.474577+00	2015-12-16 08:31:11.608108+00	2015-12-16 08:29:57.784716+00	1	0
	100	2015-12-11 18:01:28.561376+00	2015-12-11 18:01:29.706507+00	2015-12-11 18:00:02.67736+00	1	0
	100	2015-12-15 00:01:36.785797+00	2015-12-15 00:01:37.910599+00	2015-12-15 00:00:03.362757+00	1	0
	100	2015-12-14 08:55:54.953183+00	2015-12-14 08:55:56.086414+00	2015-12-14 08:54:49.359188+00	1	0
	100	2015-12-17 09:44:57.861495+00	2015-12-17 09:44:58.987631+00	2015-12-17 09:43:48.292741+00	1	0
	100	2015-12-12 00:01:45.869676+00	2015-12-12 00:01:47.352254+00	2015-12-12 00:00:11.565192+00	1	0
	100	2015-12-17 12:01:18.072733+00	2015-12-17 12:01:19.273822+00	2015-12-17 12:00:02.575816+00	1	0
	100	2015-12-17 06:01:16.955426+00	2015-12-17 06:01:18.061299+00	2015-12-17 06:00:02.516723+00	1	0
	100	2015-12-14 08:57:09.92342+00	2015-12-14 08:57:11.072499+00	2015-12-14 08:56:09.645742+00	1	0
	100	2015-12-15 06:01:19.699818+00	2015-12-15 06:01:20.82027+00	2015-12-15 06:00:02.442729+00	1	0
	100	2015-12-16 09:06:01.225317+00	2015-12-16 09:06:02.380158+00	2015-12-16 09:04:50.213054+00	1	0
	100	2015-12-14 08:58:20.572502+00	2015-12-14 08:58:21.737741+00	2015-12-14 08:57:19.714588+00	1	0
	100	2015-12-15 12:02:03.852108+00	2015-12-15 12:02:05.718626+00	2015-12-15 12:00:03.941441+00	1	0
	100	2015-12-17 09:52:55.044467+00	2015-12-17 09:52:56.149382+00	2015-12-17 09:51:42.349552+00	1	0
	100	2015-12-16 09:24:50.564212+00	2015-12-16 09:24:51.681566+00	2015-12-16 09:23:39.389427+00	1	0
	100	2015-12-17 07:18:59.52934+00	2015-12-17 07:19:00.646721+00	2015-12-17 07:17:59.464417+00	1	0
	100	2015-12-16 12:01:20.244519+00	2015-12-16 12:01:21.414741+00	2015-12-16 12:00:03.164549+00	1	0
	100	2015-12-17 09:56:04.948949+00	2015-12-17 09:56:06.063814+00	2015-12-17 09:55:03.706032+00	1	0
	100	2015-12-17 08:34:30.033451+00	2015-12-17 08:34:31.203648+00	2015-12-17 08:33:18.051756+00	1	0
\.


--
-- Data for Name: event_filter_history; Type: TABLE DATA; Schema: public; Owner: ngnms
--

COPY event_filter_history (id, filter, raiting) FROM stdin;
132	RegExp-All Severity: >1; 	1
133	RegExp-All Severity: >1; Description: ^((?!snmp).)*$; 	1
134	RegExp-Any Code: ^((?!257).)*$; 	1
135	RegExp-Any Description: ^((?!snmp).)*$; 	2
136	RegExp-Any Facility: <> traffic; 	2
137	RegExp-Any Facility: == traffic; 	1
138	RegExp-Any Severity: >10; 	2
139	RegExp-Any Severity: >1; 	3
140	RegExp-Any Severity: >1; Description: ^((?!snmp).)*$; 	1
141	Text-Any Code: ^((?!257).)*$; 	1
142	Text-Any Facility: <> traffic; 	2
143	Text-Any Facility: <>traffic; 	1
144	Text-Any Severity: >10; 	1
145	Text-Any Severity: >1; 	1
\.


--
-- Name: event_filter_history_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ngnms
--

SELECT pg_catalog.setval('event_filter_history_id_seq', 145, true);


--
-- Data for Name: events; Type: TABLE DATA; Schema: public; Owner: ngnms
--

COPY events (event_id, origin_ts, receiver_ts, origin, origin_id, facility, code, descr, priority, severity, raw_event) FROM stdin;
\.


--
-- Name: events_event_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ngnms
--

SELECT pg_catalog.setval('events_event_id_seq', 173679, true);


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
9	perioddiscovery	360	Period of discovery	8
10	scanner	0	Subnets scanner	9
6	seedHost	J1InBNwVIYGihE9NAry6uw==\n	Seed Host	1
2	username	lUxJzFwE4Yg=\n	User Name	5
3	password	YEe5NW4OZxQ=\n	Password	6
4	enpassword	mo8Rm+PV3fY=\n	Enable Password	7
8	community	r4RtB3qc69s=\n	SNMP Community	3
7	hostType	ooRPTQK8urs=\n	Host Type	2
5	type access	4mfGqba4MA4=\n	Access Type	4
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

SELECT pg_catalog.setval('interfaces_ifc_id_seq', 1084, true);


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
1	127.0.0.1	1426155098
2	127.0.0.1	1426165216
3	127.0.0.1	1426166085
4	127.0.0.1	1426166700
5	127.0.0.1	1426167031
6	127.0.0.1	1426167733
7	127.0.0.1	1426168333
8	127.0.0.1	1426168742
9	127.0.0.1	1426169342
10	127.0.0.1	1426169869
11	127.0.0.1	1426170504
12	127.0.0.1	1426171637
13	127.0.0.1	1426859792
14	127.0.0.1	1426861787
15	127.0.0.1	1426863879
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
\.


--
-- Name: menuitem_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ngnms
--

SELECT pg_catalog.setval('menuitem_id_seq', 31, true);


--
-- Data for Name: network; Type: TABLE DATA; Schema: public; Owner: ngnms
--

COPY network (link_id, router_id_a, ifc_id_a, router_id_b, ifc_id_b, link_type) FROM stdin;
\.


--
-- Name: network_link_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ngnms
--

SELECT pg_catalog.setval('network_link_id_seq', 1094, true);


--
-- Data for Name: ph_int; Type: TABLE DATA; Schema: public; Owner: ngnms
--

COPY ph_int (router_id, ph_int_id, name, state, condition, descr, speed) FROM stdin;
\.


--
-- Name: ph_int_ph_int_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ngnms
--

SELECT pg_catalog.setval('ph_int_ph_int_id_seq', 1276, true);


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

COPY router_configuration (id, router_id, data, created) FROM stdin;
\.


--
-- Name: router_configuration_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ngnms
--

SELECT pg_catalog.setval('router_configuration_id_seq', 1020, true);


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

SELECT pg_catalog.setval('routers_router_id_seq', 1015, true);


--
-- Data for Name: scan_exception; Type: TABLE DATA; Schema: public; Owner: ngnms
--

COPY scan_exception (id, addr, name) FROM stdin;
2	127.0.0.0/8	Loopback
3	169.254.0.0/16	Local link
4	224.0.0.0/4	Multicast
5	255.255.255.255/32	Limited broadcast
1	0.0.0.0/8	This network
7	128.0.0.0/2	Custom subnet
12	213.34.86.0/27	Ziggo ISP
\.


--
-- Name: scan_exception_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ngnms
--

SELECT pg_catalog.setval('scan_exception_id_seq', 1000, true);


--
-- Data for Name: snmp_access; Type: TABLE DATA; Schema: public; Owner: ngnms
--

COPY snmp_access (id, community_ro, community_rw, name) FROM stdin;
2	VPT+xqOp7Sc=		test2
1	r4RtB3qc69s=		test12
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
-- Name: event_filter_history_pkey; Type: CONSTRAINT; Schema: public; Owner: ngnms; Tablespace: 
--

ALTER TABLE ONLY event_filter_history
    ADD CONSTRAINT event_filter_history_pkey PRIMARY KEY (id);


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


--
-- Name: access_id_access_type_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ngnms
--

ALTER TABLE ONLY access
    ADD CONSTRAINT access_id_access_type_fkey FOREIGN KEY (id_access_type) REFERENCES access_type(id) ON UPDATE CASCADE ON DELETE CASCADE;


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

