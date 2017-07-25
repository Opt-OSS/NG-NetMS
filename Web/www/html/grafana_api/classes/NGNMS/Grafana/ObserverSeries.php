<?php
/**
 * Created by PhpStorm.
 * User: Home
 * Date: 02.03.2017
 * Time: 20:00
 */

namespace NGNMS\Grafana;


use NGNMS\Emsgd;
use PDO;

class ObserverSeries extends Grafana
{
    private $interval;
    private $db_table;

    private function _resolve_observation_query_names($oop_id)
    {
        $sSQL = "
       SELECT concat(r.name,' ',om.name) AS name
        FROM observer_options oo
          JOIN routers r ON r.router_id = oo.routers_id
          LEFT JOIN origin_model_options om  ON om.id = oo.origin_model_options_id
        WHERE oo.id = :oop_id
    ";
        $stmt = $this->conn->prepare($sSQL);
        $stmt->bindValue('oop_id', $oop_id, PDO::PARAM_INT);
        $stmt->execute();
        return $stmt->fetchColumn();

    }

    private function _get_observation_query($oop_id)
    {
        $interval = $this->interval;
        $db_table = $this->db_table;
        $sSQL = /** @lang SQL */
            "
                        WITH filled_dates AS (
                          SELECT ts,round(extract(EPOCH FROM ts)/$interval )*" . ($interval * 1000) . " AS time_msec, 0 AS value FROM
                            generate_series(:from::TIMESTAMPTZ, :to::TIMESTAMPTZ, '" . ($interval * 1000) . " msec')
                              AS ts
                        ),
                        observation AS (
                            SELECT round(extract(EPOCH FROM ts)/$interval )*" . ($interval * 1000) . " AS time_msec ,avg(value) AS value
                                FROM $db_table t
                                WHERE t.ts BETWEEN :from AND :to
                                AND t.observer_options_id = :oop_id
                                GROUP BY round(extract(EPOCH FROM ts)/$interval )*" . ($interval * 1000) . "
                        )
                        SELECT  filled_dates.time_msec,observation.value AS value
                            FROM filled_dates LEFT OUTER JOIN observation ON (filled_dates.time_msec = observation.time_msec)
                            ORDER BY filled_dates.time_msec
                        ";

        //Emsgd::pp($sSQL);
        $stmt = $this->conn->prepare($sSQL);
        $stmt->bindParam('oop_id', $oop_id, PDO::PARAM_INT);


//                    $stmt->bindValue('oop_id', 13, PDO::PARAM_INT);
        return $stmt;
    }


    public function print_time_series($target, $from, $to, $interval)
    {

        $router_id = (int)$target['router_id'];
        $oop_id = (int)$target['oop_id'];
        $this->interval = $interval;
        $this->db_table = $this->get_db_table($this->interval, $target['table']);

        $stmt = $this->_get_observation_query($oop_id);
        $tname = $this->_resolve_observation_query_names($oop_id);
        $stmt->bindValue('from', $from, PDO::PARAM_STR);
        $stmt->bindValue('to', $to, PDO::PARAM_STR);
        $ads = '"interval":' . $this->interval . ',"table":"' . $this->db_table . '",';

        $this->__print_serie($stmt, $tname, $ads);

    }
}