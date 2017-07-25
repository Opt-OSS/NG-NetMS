<?php
/**
 * Created by PhpStorm.
 * User: Home
 * Date: 02.03.2017
 * Time: 20:41
 */

namespace NGNMS\Grafana;


use PDO;

abstract class Grafana
{
    public static function sanitize_int_list($string){
        return array_unique(array_map(function ($e) {return intval($e);},preg_split('/[,\|]/',$string)));
    }
    protected $conn;
    public function __construct(PDO $pdo)
    {
        $this->conn = $pdo;
    }

    public function get_db_table($interval,$table='auto'){
        if ($table == 'auto') {
            if ($interval <= 15) {
                $table = '1s';
            } elseif ($interval <= 60) {
                $table = '15s';
            } elseif ($interval <= 15 * 60) { //15m
                $table = '1m';
            } elseif ($interval <= 60 * 60) { //1hr
                $table = '15m';
            } else {
                $table = '1h';
            }
        }
        switch ($table) {
            case '1s':
                $db_table = "observer_history_t1";
                break;
            case '15s':
                $db_table = "observer_history_t1_15sec";
                break;
            case '1m':
                $db_table = "observer_history_t1_1min";
                break;
            case '15m':
                $db_table = "observer_history_t1_15min";
                break;
            case '1h':
                $db_table = "observer_history_t1_1hr";
                break;
            default:
                $db_table = "observer_history_t1_1min";
        }
        return $db_table;
    }

    /**
     * @param $stmt \PDOStatement
     * @param $tname string
     */
    protected function __print_serie($stmt, $tname, $ads = ""){
        $rustart = getrusage();
        $stmt->execute();
        echo '
                    {
                    '.$ads.'
                    "target":"' . $tname . '", 
                    "datapoints":[                
                ';
        $comma = false;
        $cnt = 0;
        $ss = "";
        while ($r = $stmt->fetch(PDO::FETCH_ASSOC)) {
            if ($comma) {
                echo ',';
            } else {
                $comma = true;
            }
            $s =  '[' . ($r['value'] === null ? 'null' : $r['value']) . ',' . $r['time_msec']. ']';
            echo $s;
            $cnt++;
        }
        $ru = getrusage();
        echo '
                    ],
                    "count":' . $cnt . ',
                    "computation":"' . rutime($ru, $rustart, "utime") . '",
                    "system_call":"' . rutime($ru, $rustart, "stime") . '"
                    }
                ';
    }
}