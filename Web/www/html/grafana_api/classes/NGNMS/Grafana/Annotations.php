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

class Annotations extends Grafana
{


    public function print_annotations($router_id, $facilities,$from, $to){
        $cnt=0;
        foreach($facilities as $facility){
            $f = ':f'.$cnt++;
            $fnames[$f]=$facility;
        }
        $sSQL= /** @lang SQL */ "
          select 
              extract(EPOCH FROM receiver_ts)*1000 AS ts,
              sum(coalesce(t.severity,0)) as severity,
              string_agg(distinct case WHEN t.facility = '' THEN 'NO facility' ELSE t.facility END,'\n' ) AS tags,
              string_agg(concat(t.facility,': ', descr ),'<hr>') AS descr
                          
              FROM events t
              WHERE receiver_ts BETWEEN :from AND :to
                  AND t.origin_id IN (:rtid)
                  and t.facility in (".implode(',',array_keys($fnames)).")
                  group by 1
              ORDER BY 1
              LIMIT 1000
                ";
//        Emsgd::pp($sSQL);
        $stmt = $this->conn->prepare($sSQL);
        $stmt->bindValue('from', $from, PDO::PARAM_STR);
        $stmt->bindValue('to', $to, PDO::PARAM_STR);
        $stmt->bindValue('rtid', $router_id, PDO::PARAM_STR);
        foreach ($fnames as $bind=>$facility){
            $val = $facility == Events::NO_FACILITY ?  '' : $facility;
//            Emsgd::pp("$bind=>'$val' for $facility");
            $stmt->bindValue($bind,$val , PDO::PARAM_STR);
        }
        $stmt->execute();
        $comma = false;

        while ($r = $stmt->fetch(PDO::FETCH_ASSOC)) {
            if ($comma) {
                echo ',';
            } else {
                $comma = true;
            }
            echo json_encode([
                'time' => (int)$r['ts'],
                'title' => "Severity sum ".$r['severity'],
                'text' => $r['descr'],
                'tags'=>preg_split('/\n/',$r['tags'])
            ]);
        }
    }

}