--
-- File generated with SQLiteStudio v3.0.6 on �� ��� 24 02:00:39 2015
--
-- Text encoding used: windows-1251
--
PRAGMA foreign_keys = off;
BEGIN TRANSACTION;

-- Table: interfaces
CREATE TABLE interfaces (
    router_id INTEGER,
    ph_int_id INTEGER,
    ifc_id    INTEGER PRIMARY KEY AUTOINCREMENT,
    name      VARCHAR,
    ip_addr   VARCHAR,
    mask      VARCHAR,
    descr     VARCHAR
);


-- Table: network
CREATE TABLE network (
    link_id     INTEGER PRIMARY KEY,
    router_id_a INTEGER,
    ifc_id_a    INTEGER,
    router_id_b INTEGER,
    ifc_id_b    INTEGER,
    link_type   VARCHAR
);


-- Table: routers
CREATE TABLE routers (
    router_id  INTEGER PRIMARY KEY,
    name       VARCHAR,
    ip_addr    VARCHAR,
    eq_type    VARCHAR,
    eq_vendor  VARCHAR,
    location   VARCHAR,
    status     VARCHAR,
    icon_color VARCHAR,
    layer      INTEGER
);


COMMIT TRANSACTION;
PRAGMA foreign_keys = on;
