<?php
/**
 * Created by PhpStorm.
 * User: Home
 * Date: 02.03.2017
 * Time: 22:16
 */

namespace NGNMS\Grafana;


use InvalidArgumentException;
use NGNMS\Emsgd;
use PDO;

class Events extends Grafana
{
    const NO_FACILITY = 'NO FACILITY';
    private $interval;
    private $db_table;
    private $router_names = null;

    public function print_events($router_id, $facilities, $from, $to)
    {
        $fnames = [];
        $cnt = 0;
        foreach ($facilities as $facility) {
            $f = ':f' . $cnt++;
            $fnames[$f] = $facility;
        }
        $rnames = [];
        foreach ($router_id as $rid) {
            $f = ':r' . $cnt++;
            $rnames[$f] = $rid;
        }

        $sSQL = "
                SELECT  extract(EPOCH FROM t.receiver_ts)*1000 AS time_msec ,facility,t.severity,t.descr AS value
                                FROM events t
                                WHERE t.receiver_ts BETWEEN :from AND :to
                                 AND t.origin_id IN (" . implode(',', array_keys($rnames)) . ")
                                 AND t.facility IN (" . implode(',', array_keys($fnames)) . ")
                                 LIMIT 5000
                ";
//        Emsgd::pp($sSQL);
        $stmt = $this->conn->prepare($sSQL);


        $stmt->bindValue('from', $from, PDO::PARAM_STR);
        $stmt->bindValue('to', $to, PDO::PARAM_STR);
        foreach ($fnames as $bind => $facility) {
            //            Emsgd::pp("$bind=>'$val' for $facility");

            $val = $facility == self::NO_FACILITY ? '' : $facility;
            $stmt->bindValue($bind, $val, PDO::PARAM_STR);
        }
        foreach ($rnames as $bind => $rid) {
//            Emsgd::pp("$bind=>'$rid' for $rid");
            $stmt->bindValue($bind, $rid, PDO::PARAM_STR);
        }
        $columns = [
            ['text' => 'Time', 'type' => 'time'],
            ['text' => 'Facility', 'type' => 'string'],
            ['text' => 'Severity', 'type' => 'number'],
            ['text' => "Text", 'type' => "string"],
        ];

        $start = microtime(true);
        $stmt->execute();
//                Emsgd::pp($stmt->debugDumpParams());
        echo '
              {
              "type": "table",
              "query": '.(microtime(true)-$start).',
              "columns":' . json_encode($columns) . ',
               "rows":[';
        $comma = false;

        while ($r = $stmt->fetch(PDO::FETCH_NUM)) {
            if ($comma) {
                echo ',';
            } else {
                $comma = true;
            }
            echo json_encode($r, JSON_NUMERIC_CHECK);
        }
        echo '
                    ]}';

    }

    private function _resolve_query_names($router_id, $facility)
    {
        if (!$router_id){
            return trim($facility);
        }
        if (null === $this->router_names) {

            $rs = $this->conn->query(
                "
                SELECT r.router_id, r.name FROM routers r 
                "
            )->fetchAll();
            foreach ($rs as $r) {
                $this->router_names[$r['router_id']] = $r['name'];
            }
        }
        $name = empty($this->router_names[$router_id]) ? 'UNKNOWN ' . $router_id : $this->router_names[$router_id];
        return trim($name . ' ' . $facility);

    }

    private function _get_severity_query($fnames,$router_id = null, $field='facility',$min_severity = 0)
    {
        $interval = $this->interval;
        $aggr = [];
        $cnt = 0;
        foreach (array_keys($fnames) as $f) {
            $aggr[] = "sum(t.severity) FILTER (WHERE target=:$f) AS $f\n";
        }
        $and_router = $router_id ? '  t.origin_id = :router_id ' : '1=1';
        $sSQL = /** @lang SQL */
            "
                        WITH filled_dates AS (
                          SELECT round(extract(EPOCH FROM ts)/$interval )* $interval AS time_msec FROM
                            generate_series(:from::TIMESTAMPTZ, :to::TIMESTAMPTZ, '" . ($interval * 1000) . " msec')
                              AS ts
                        ),
                        data as (
                            SELECT
                                     t.severity,$field as target,
                              round(extract(EPOCH FROM t.receiver_ts)/$interval )* $interval AS time_msec
                                  FROM events t
                                  WHERE t.receiver_ts BETWEEN :from AND :to
                                  and severity >= $min_severity
                                 AND $and_router
                            ),
                        observation AS (
                            SELECT 
                            time_msec ,
                            " . join(',', $aggr) . "
                                FROM data t
                                GROUP BY time_msec
                        )
                        SELECT  filled_dates.time_msec * 1000 as time_msec, " . join(',', array_keys($fnames)) . " 
                            FROM filled_dates LEFT OUTER JOIN observation ON (filled_dates.time_msec = observation.time_msec)
                            ORDER BY filled_dates.time_msec
                        ";
//        Emsgd::pp($sSQL);
        $stmt = $this->conn->prepare($sSQL);
        if ($router_id) {
            $stmt->bindValue('router_id', $router_id, PDO::PARAM_INT);
        }
        foreach ($fnames as $bind => $facility) {
            $val = $facility == self::NO_FACILITY ? '' : $facility;
//            Emsgd::pp("$bind=>'$val' for $facility");
            $stmt->bindValue($bind, $val, PDO::PARAM_STR);
        }


        return $stmt;
    }

    private function _get_datapoints($stmt, $fnames)
    {

        $stmt->execute();
        //init all series arrays
        $datapoints = array_fill_keys(array_keys($fnames), '');
        $comma = '';
        while ($r = $stmt->fetch(PDO::FETCH_ASSOC)) {
            foreach ($fnames as $bind => $facility) {
//                Emsgd::pp($r);die;
                $datapoints[$bind] .= $comma . '[' . ($r[$bind] ?: 'null') . ',' . $r['time_msec'] . ']';
            }
            $comma = ',';
        }
        return $datapoints;
    }

    private function _get_query_overview($by_field)
    {
        $interval = $this->interval;

        $filled_datapoints =
        $sSQL = /** @lang SQL */
            "
            WITH 
                filled_dates AS (
                    SELECT 
                      round(extract(EPOCH FROM ts)/$interval )*" . ($interval * 1000) . " AS time_msec
                    FROM
                         generate_series(:from::TIMESTAMPTZ, :to::TIMESTAMPTZ, '" . ($interval * 1000) . " msec') AS ts
                ),
                observation AS (
                     
                    SELECT 

                    round(extract(EPOCH FROM t.receiver_ts)/$interval )*" . ($interval * 1000) . " AS time_msec ,
                    sum(severity) AS value
                        FROM events t
                        WHERE t.receiver_ts BETWEEN :from AND :to
                        GROUP BY 1,2
                ),
                filled_datapoints AS (
                      SELECT DISTINCT
                        target,
                        filled_dates.time_msec,
                        0 AS value
                      FROM observation, filled_dates
                )                        
            SELECT
              filled_datapoints.target,
              filled_datapoints.time_msec,
              observation.value
            FROM filled_datapoints
              LEFT OUTER JOIN observation
                ON (filled_datapoints.time_msec = observation.time_msec AND filled_datapoints.target = observation.target)
            ORDER BY 1, 2
                        ";

        $sSQL = /** @lang SQL */
            "

                    SELECT 
                    $by_field AS target,
                    round(extract(EPOCH FROM t.receiver_ts)/$interval )*" . ($interval * 1000) . " AS time_msec ,
                    sum(severity) AS value
                        FROM events t
                        WHERE t.receiver_ts BETWEEN :from AND :to
                        GROUP BY 1,2
                        ORDER BY 1,2
                
                        ";
//        Emsgd::pp($sSQL);
        $stmt = $this->conn->prepare($sSQL);
        return $stmt;
    }

    public function print_overview($by, $from, $to, $interval,$min_severity=0)
    {
        $rustart = getrusage();
        $this->interval = $interval;
        $ads = '"interval":' . $this->interval . ',';
        $field = $by == 'by_facility' ? 'facility' : 'origin_id';

        $stmt = $this->conn->prepare("
        SELECT        
          DISTINCT $field AS val 
          FROM events 
          WHERE receiver_ts BETWEEN ? AND ? 
          and severity >= ?
        ");
        $stmt->execute([$from, $to, $min_severity]);
        $fnames = [];$cnt = 0;
        while ($r = $stmt->fetch(PDO::FETCH_ASSOC)) {
            $f = 'f' . $cnt++;
            $fnames[$f] = $r['val'];
        }
        if (!count($fnames)){
            echo '{
                
                    "target":"No events found for severity > '.$min_severity.'", 
                    "datapoints":[],
                    "computation":0,
                    "system_call":0,
                    "query_time": 0
                    }';
            return;
        }
        $stmt = $this->_get_severity_query($fnames, null,$field,$min_severity);
        $stmt->bindValue('from', $from, PDO::PARAM_STR);
        $stmt->bindValue('to', $to, PDO::PARAM_STR);
        $ads = '"interval":' . $this->interval . ',';
        $started = microtime(true);
        $dps = $this->_get_datapoints($stmt, $fnames);
        $execution_time = microtime(true) - $started;
        $ru = getrusage();
        $targets = [];
//        Emsgd::pp($fnames);
        foreach ($fnames as $bind => $facility) {
            if( $field == 'origin_id'){
                $tname = $facility > 0 ? $this->_resolve_query_names($facility, '') : 'UNKNOWN';
            }else{
                $tname = $facility ?:Events::NO_FACILITY;
            }
            $targets[] = '
                    {
                    ' . $ads . '
                    "target":"' . $tname . '", 
                    "datapoints":[' . $dps[$bind] . '],
                    "computation":"' . rutime($ru, $rustart, "utime") . '",
                    "system_call":"' . rutime($ru, $rustart, "stime") . '",
                    "query_time": '.$execution_time.'
                    }
                ';
        }
        echo join(',', $targets);


    }

    public function print_time_series($target, $from, $to, $interval)
    {
        $rustart = getrusage();
        $router_id = (int)$target['router_id'];
        $facilities = $target['facilities'];
        $min_severity = intval($target['min_severity']);
        $cnt = 0;
        $fnames = [];
        foreach ($facilities as $facility) {
            $f = 'f' . $cnt++;
            $fnames[$f] = $facility;
        }

        $this->interval = $interval;
        $this->db_table = $this->get_db_table($this->interval, $target['table']);
        $stmt = $this->_get_severity_query($fnames, $router_id,'facility',$min_severity);
//        $tname = $this->_resolve_query_names($router_id,$facilities) ;
        $stmt->bindValue('from', $from, PDO::PARAM_STR);
        $stmt->bindValue('to', $to, PDO::PARAM_STR);
        $ads = '"interval":' . $this->interval . ',"table":"' . $this->db_table . '",';

        $dps = $this->_get_datapoints($stmt, $fnames);
        $ru = getrusage();
        $targets = [];
        foreach ($fnames as $bind => $facility) {
            $targets[] = '
                    {
                    ' . $ads . '
                    "target":"' . $this->_resolve_query_names($router_id, $facility) . '", 
                    "datapoints":[' . $dps[$bind] . '],
                    "computation":"' . rutime($ru, $rustart, "utime") . '",
                    "system_call":"' . rutime($ru, $rustart, "stime") . '"
                    }
                ';
        }
        echo join(',', $targets);


    }
}