CREATE schema jobmachine;
-- SET search_path TO jobmachine;

CREATE TABLE jobmachine.class (
  class_id            serial PRIMARY KEY,
  name                text,
  created             timestamp NOT NULL DEFAULT now(),
  modified            timestamp NOT NULL DEFAULT now()
);

COMMENT ON TABLE jobmachine.class IS 'Task class';
COMMENT ON COLUMN jobmachine.class.class_id IS 'Unique identification';
COMMENT ON COLUMN jobmachine.class.name IS 'Job class name';
COMMENT ON COLUMN jobmachine.class.created IS 'Timestamp for row creation';
COMMENT ON COLUMN jobmachine.class.modified IS 'Timestamp for latest update of this row';

CREATE TABLE jobmachine.task (
  task_id             serial PRIMARY KEY,
  transaction_id      integer,
  class_id            integer REFERENCES jobmachine.class (class_id),
  grouping            text,
  title               text,
  parameters          text,
  status              integer NOT NULL,
  run_after           timestamp DEFAULT NULL,
  remove_after        timestamp DEFAULT NULL,
  created             timestamp NOT NULL DEFAULT now(),
  modified            timestamp NOT NULL DEFAULT now()
);

COMMENT ON TABLE jobmachine.task IS 'Tasks';
COMMENT ON COLUMN jobmachine.task.task_id IS 'Unique identification';
COMMENT ON COLUMN jobmachine.task.transaction_id IS 'If several tasks need to be executed in sequence';
COMMENT ON COLUMN jobmachine.task.class_id IS 'Job class to be executed';
COMMENT ON COLUMN jobmachine.task.grouping IS 'Optional job group. Jobs will be retrieved by group if defined';
COMMENT ON COLUMN jobmachine.task.title IS 'Optional job title';
COMMENT ON COLUMN jobmachine.task.parameters IS 'from client to the scheduled task. Serialized as JSON';
COMMENT ON COLUMN jobmachine.task.status IS '0 - entered, 100 - processing started, 200 - processing finished, - 900 - processing finished w/ error';
COMMENT ON COLUMN jobmachine.task.run_after IS 'Wait until this time to run the task';
COMMENT ON COLUMN jobmachine.task.remove_after IS 'Wait until this time to delete the task';
COMMENT ON COLUMN jobmachine.task.created IS 'Timestamp for row creation';
COMMENT ON COLUMN jobmachine.task.modified IS 'Timestamp for latest update of this row';

CREATE TABLE jobmachine.result (
  result_id           serial PRIMARY KEY,
  task_id             integer REFERENCES jobmachine.task (task_id)
  ON DELETE CASCADE
  ON UPDATE CASCADE,
  result              text,
  resulttype          text,
  created             timestamp NOT NULL DEFAULT now()
);

COMMENT ON TABLE jobmachine.result IS 'Results';
COMMENT ON COLUMN jobmachine.result.result_id IS 'Unique identification';
COMMENT ON COLUMN jobmachine.result.task_id IS 'Task of the result';
COMMENT ON COLUMN jobmachine.result.result IS 'Result of the job';
COMMENT ON COLUMN jobmachine.result.resulttype IS 'Type of result: xml, html, etc';
COMMENT ON COLUMN jobmachine.result.created IS 'Timestamp for row creation';

-- Views

CREATE OR REPLACE VIEW jobmachine.fulltask AS
  SELECT
    jobmachine.task.task_id,jobmachine.task.status,jobmachine.task.parameters,
    jobmachine.class.name,
    jobmachine.result.result_id,jobmachine.result.result
  FROM
    jobmachine.task
    JOIN
    jobmachine.class
    USING
      (class_id)
    LEFT JOIN
      jobmachine.result
    USING
      (task_id)
;
