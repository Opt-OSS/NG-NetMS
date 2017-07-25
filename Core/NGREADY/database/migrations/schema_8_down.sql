ALTER TABLE public.archive_conf ALTER COLUMN arc_period TYPE VARCHAR(4) USING arc_period::VARCHAR(4);
UPDATE public.archive_conf set  log_level = 6;
update general_settings set value='1d' where id = 9;
update archive_conf set arc_period='1d';