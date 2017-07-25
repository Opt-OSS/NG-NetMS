ALTER TABLE public.archive_conf ALTER COLUMN arc_period TYPE VARCHAR(255) USING arc_period::VARCHAR(255);
UPDATE public.archive_conf set  log_level = 1;
update general_settings set value='5 0 * * *' where id = 9;
update archive_conf set arc_period='30 2 * * *';

