CREATE UNIQUE INDEX IF NOT EXISTS router_vendors_name_uindex ON router_vendors (name);
ALTER TABLE routers ALTER COLUMN eq_type TYPE VARCHAR(50) USING eq_type::VARCHAR(50);
ALTER TABLE routers ALTER COLUMN eq_vendor TYPE VARCHAR(50) USING eq_type::VARCHAR(50);
INSERT INTO router_vendors ( name,rgb) VALUES ( 'Juniper', '0000FF')  ON CONFLICT DO NOTHING;
INSERT INTO router_vendors ( name,rgb) VALUES ( 'Cisco', '449970')  ON CONFLICT DO NOTHING;
INSERT INTO router_vendors ( name,rgb) VALUES ( 'Extreme', '00FF00')  ON CONFLICT DO NOTHING;
INSERT INTO router_vendors ( name,rgb) VALUES ( 'Linux', '00FF00')  ON CONFLICT DO NOTHING;
INSERT INTO router_vendors ( name,rgb) VALUES ( 'Netscreen', '00FF00')  ON CONFLICT DO NOTHING;
INSERT INTO router_vendors ( name,rgb) VALUES ( 'HP_ProCurve', '00FF00')  ON CONFLICT DO NOTHING;
INSERT INTO router_vendors ( name,rgb) VALUES ( 'HP_iLO', '00FF00')  ON CONFLICT DO NOTHING;


