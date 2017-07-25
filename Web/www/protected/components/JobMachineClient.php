<?php
use NGNMS\Emsgd;

/**
 * Created by IntelliJ IDEA.
 * User: Home
 * Date: 09.06.2017
 * Time: 16:58
 */
class JobMachineClient {

    /** @var  CDbConnection */
    public $db;
    private $queue;
    const database_schema = 'jobmachine';
    const task_table = 'task';
    const QUEUE_PREFIX = 'jm:';
    const RESPONSE_PREFIX = 'jmr:';
    private $prevent_duplicates;

    public function __construct($queue = null, $prevent_duplicates = false) {
        $this->db = Yii::app()->db;
        $this->queue = $queue;
        $this->prevent_duplicates = $prevent_duplicates;
    }

    public function send($data, $queue = null) {
        $queue = $this->queue or $queue;
        if (!$queue) {
            throw new \Exception('job queue name is required');
        }
        if ($this->prevent_duplicates) {
            $frozen = json_encode($data);
            $class = $this->fetch_class($queue);
            $cnt =
                $this->db->createCommand("SELECT 
                      count(*) FROM jobmachine.task
                       WHERE class_id = :queue_id AND parameters = :payload
                       AND status <> 200
                      ")->queryScalar(['queue_id' => $class['class_id'], 'payload' => $frozen]);
            if ($cnt > 0) {
                return;
            }

        }

        $id = $this->insert_task($data, $queue);
        $this->notify($queue);

    }


    private function insert_task($data, $queue) {
        $t = self::database_schema . '.' . self::task_table;
        $class = $this->fetch_class($queue);
        $frozen = json_encode($data);
        $id = $this->db->createCommand("
        		INSERT INTO jobmachine.task
                    (class_id,parameters,status)
                VALUES (:class,:params,:status)
                RETURNING task_id
        ")->queryScalar(['class' => $class['class_id'], 'params' => $frozen, 'status' => 0]);
        Emsgd::p($id);
        return $id;
    }

    private function notify($queue, $payload = null, $reply = false) {
        if (empty($queue)) {
            return;
        }

        $prefix = $reply ? self::RESPONSE_PREFIX : self::QUEUE_PREFIX;
        $queue = $prefix . $queue;
        Emsgd::p($queue);
        $task = $this->db->createCommand("
        		SELECT pg_notify(:queue,:payload)
        ")->queryRow(true, ['queue' => $queue, 'payload' => $payload]);
    }

    private function fetch_class($queue) {
        $class = $this->db->createCommand("
            SELECT class_id
            FROM  jobmachine.class
		WHERE name=:queue
	      "
        )->queryRow(true, ['queue' => $queue]);
        if (empty($class['class_id'])) {
            $class = $this->db->createCommand("
        	INSERT INTO jobmachine.class
                    (name)
                VALUES (:queue)
                RETURNING class_id        
		"
            )->queryRow(true, ['queue' => $queue]);
        }
        return $class;
    }

}