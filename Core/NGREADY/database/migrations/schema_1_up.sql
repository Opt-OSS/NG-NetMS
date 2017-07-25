
CREATE SEQUENCE public.archive_tables_id_seq
  INCREMENT 1 MINVALUE 1
  MAXVALUE 9223372036854775807 START 1
  CACHE 1;

  ALTER SEQUENCE public.archive_tables_id_seq RESTART WITH 1000;


CREATE TABLE IF NOT EXISTS public.archive_tables (
  id            INTEGER DEFAULT nextval('"archive_tables_id_seq"' :: TEXT :: REGCLASS) NOT NULL,
  table_name    VARCHAR(50)                                                            NOT NULL,
  start_time    TIMESTAMP WITH TIME ZONE                                               NOT NULL,
  end_time      TIMESTAMP WITH TIME ZONE                                               NOT NULL,
  archive_id    INTEGER                                                                NOT NULL,
  records_count INTEGER,
  microsecounds REAL,
  CONSTRAINT archive_tables_pkey PRIMARY KEY (id),
  CONSTRAINT archive_tables_fk FOREIGN KEY (archive_id)
  REFERENCES public.archives (archive_id)
  ON DELETE CASCADE
  ON UPDATE CASCADE
  NOT DEFERRABLE
)
WITH (OIDS = FALSE
);
;;

ALTER TABLE public.archive_tables
  ALTER COLUMN id SET STATISTICS 0;
;;