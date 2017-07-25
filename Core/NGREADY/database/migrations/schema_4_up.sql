-- remove duplicate configs
ALTER TABLE router_configuration ADD checksum VARCHAR DEFAULT 32 NULL;
update router_configuration set checksum = md5(data);

DELETE FROM router_configuration
WHERE id IN (SELECT id
             FROM (SELECT id,
                     ROW_NUMBER() OVER (partition BY router_id, checksum ORDER BY id) AS rnum
                   FROM router_configuration) t
             WHERE t.rnum > 1);

--  CREATE UNIQUE INDEX router_configuration_checksum_uindex ON router_configuration (router_id,checksum);
