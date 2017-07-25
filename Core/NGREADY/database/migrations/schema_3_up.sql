-- command line options for connectivity
insert into attr (id,name) values (7,'CmdOptions');
--Telnet
insert into attr_access(id_access_type,id_attr) values (1,7);
--SSH v1
insert into attr_access(id_access_type,id_attr) values (2,7);
--SSH v2
insert into attr_access(id_access_type,id_attr) values (3,7);