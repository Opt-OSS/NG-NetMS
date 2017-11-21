INSERT INTO access_type (id, name) VALUES (5, 'JumpHost')  ON CONFLICT DO NOTHING;
INSERT INTO attr (id, name) VALUES (8, 'JumpHost')  ON CONFLICT DO NOTHING;
INSERT INTO attr (id, name) VALUES (9, 'WrappedAccess')  ON CONFLICT DO NOTHING;
INSERT INTO attr_access (id, id_access_type, id_attr) VALUES (9, 5, 1)  ON CONFLICT DO NOTHING;
INSERT INTO attr_access (id, id_access_type, id_attr) VALUES (10, 5, 2)  ON CONFLICT DO NOTHING;
INSERT INTO attr_access (id, id_access_type, id_attr) VALUES (11, 5, 3)  ON CONFLICT DO NOTHING;
INSERT INTO attr_access (id, id_access_type, id_attr) VALUES (12, 5, 7)  ON CONFLICT DO NOTHING;
INSERT INTO attr_access (id, id_access_type, id_attr) VALUES (13, 5, 8)  ON CONFLICT DO NOTHING;
INSERT INTO attr_access (id, id_access_type, id_attr) VALUES (14, 5, 9) ON CONFLICT DO NOTHING;
INSERT INTO general_settings(id,name,value,label,order_view) VALUES (11,'default_access_method','','Default access method',10)  ON CONFLICT DO NOTHING;;

update general_settings
    set label = concat(name,' @DEPRICATED'),
      order_view = 100
where name in ('type access','username','password','enpassword')