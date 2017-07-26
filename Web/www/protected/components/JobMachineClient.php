<?php
use NGNMS\Emsgd;

/**
 * Created by IntelliJ IDEA.
 * User: Home
 * Date: 09.06.2017
 * Time: 16:58
 */
class JobMachineClient
{

    /** @var  CDbConnection */
    public $db;
    private $queue;
    const database_schema = 'jobmachine';
    const task_table = 'task';
    const QUEUE_PREFIX = 'jm:';
    const RESPONSE_PREFIX = 'jmr:';
    private $prevent_duplicates;
    private $class_id;

    public function __construct($queue , $prevent_duplicates = false)
    {
        $this->db = Yii::app()->db;
        $this->queue = $queue;
        $this->class_id = $this->fetch_class($this->queue);
        $this->prevent_duplicates = $prevent_duplicates;
    }

    public function send($data )
    {
        if (!$this->queue ) {
            throw new \Exception('job queue name is required');
        }
        if ($this->prevent_duplicates) {
            $frozen = json_encode($data);
            $cnt =
                $this->db->createCommand("SELECT 
                      count(*) FROM jobmachine.task
                       WHERE class_id = :queue_id AND parameters = :payload
                       AND status <> 200
                      ")->queryScalar(['queue_id' =>  $this->class_id, 'payload' => $frozen]);
            if ($cnt > 0) {
                return 0;
            }

        }

        $id = $this->insert_task($data);
        $this->notify();
        return $id;

    }


    private function insert_task($data)
    {
        $frozen = json_encode($data);

        $id = $this->db->createCommand("
        		INSERT INTO jobmachine.task
                    (class_id,parameters,status)
                VALUES (:class_id,:params,:status)
                RETURNING task_id
        ")->queryScalar(['class_id' => $this->class_id, 'params' => $frozen, 'status' => 0]);

        return $id;
    }

    private function notify($payload = null, $reply = false)
    {

        $prefix = $reply ? self::RESPONSE_PREFIX : self::QUEUE_PREFIX;
        $queue = $prefix . $this->queue;

        $task = $this->db->createCommand("
        		SELECT pg_notify(:queue,:payload)
        ")->queryRow(true, ['queue' => $queue, 'payload' => $payload]);
    }

    private function fetch_class($queue)
    {
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
        return $class['class_id'];
    }

    public function get_running_tasks()
    {
        return $this->db->createCommand("SELECT 
                      task_id,parameters FROM jobmachine.task
                       WHERE class_id = :class_id 
                       AND (status = 100 or status =0)
                      ")->queryAll(true,['class_id' =>$this->class_id] );
    }

}