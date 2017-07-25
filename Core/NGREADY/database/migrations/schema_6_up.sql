TRUNCATE TABLE public.router_peers;
ALTER TABLE public.router_peers DROP CONSTRAINT IF EXISTS router_peers_routers_router_id_fk;
ALTER TABLE public.router_peers DROP CONSTRAINT IF EXISTS router_peers_routers_router_id_fk2;
ALTER TABLE public.router_peers
  ADD CONSTRAINT router_peers_routers_router_id_fk
FOREIGN KEY (router_id) REFERENCES routers (router_id)  ON DELETE CASCADE;

ALTER TABLE public.router_peers
  ADD CONSTRAINT router_peers_routers_router_id_fk2
FOREIGN KEY (router_peer_id) REFERENCES routers (router_id)  ON DELETE CASCADE;

