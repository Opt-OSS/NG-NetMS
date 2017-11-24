INSERT INTO attr (id, name) VALUES (10, 'Timeout')  ON CONFLICT DO NOTHING;
--Telnet
insert into attr_access(id_access_type,id_attr) values (1,10) ON CONFLICT DO NOTHING;;
--SSH v1
insert into attr_access(id_access_type,id_attr) values (2,10) ON CONFLICT DO NOTHING;;
--SSH v2
insert into attr_access(id_access_type,id_attr) values (3,10) ON CONFLICT DO NOTHING;;
--Jump Host
insert into attr_access(id_access_type,id_attr) values (5,10) ON CONFLICT DO NOTHING;;