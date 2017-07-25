delete from menuitem
  where name = 'IP Connectivity Map';
insert into
  menuitem (name,parentid,label,ordervalue, route,accesslevel,depthlevel,menutypeid,adminnotes,active,icon)
values('IP Connectivity Map',12,'IP Connectivity Map',3,'/routers/ipmap/','viewMap',1,'map','',1,'icon-map-marker');
CREATE TABLE public.router_peers (
  id SERIAL,
  router_id INTEGER NOT NULL,
  router_peer_id INTEGER NOT NULL,
  peer_type VARCHAR(20) NOT NULL,
  peer_info VARCHAR(20) NOT NULL,
  description VARCHAR(200),
  CONSTRAINT router_peers_idx UNIQUE(router_id, router_peer_id, peer_type, peer_info),
  CONSTRAINT router_peers_pkey PRIMARY KEY(id)
)
WITH (oids = false);