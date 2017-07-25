<?php
/**
 *
 * Postgress timeseries guides:
 *  --  http://no0p.github.io/postgresql/2014/05/08/timeseries-tips-pg.html
 *  -- blog series - use next/prev on the bottom
 *          https://blog.svedr.in/posts/nifty-queries-over-time-series-data-using-postgresql.html
 *
 */
session_start();
require_once __DIR__ . '/classes/Psr4ClassLoader.php';
$loader = new Psr4ClassLoader();
$loader->addPrefix('NGNMS\\', __DIR__ . '/classes/NGNMS');
$loader->register();

use \NGNMS\Emsgd;
use NGNMS\Grafana\Annotations;
use NGNMS\Grafana\Grafana;
use NGNMS\Grafana\Events;
use NGNMS\Grafana\Auth;
use NGNMS\Grafana\AuthException;

$database_host = getenv('NGNMS_DB_HOST') ?: 'localhost';
$database_port = getenv('NGNMS_DB_PORT') ?: '5432';
$database_name = getenv('NGNMS_DB') ?: 'ngnms';
$database_user = getenv('NGNMS_DB_USER') ?: 'ngnms';
$database_pass = getenv('NGNMS_DB_PASSWORD') ?: 'ngnms';

ini_set('display_errors', 1);


const ROOT_REGEXP = '#^/grafana_api/?$#';
const SEARCH_REGEXP = '#^/grafana_api/search/?$#';
const QUERY_REGEXP = '#^/grafana_api/query/?$#';
const ANNOTATIONS_REGEXP = '#^/grafana_api/annotations/?$#';


class RegexRouter
{

    private $routes = array();

    public function route($pattern, $callback)
    {
        $this->routes[$pattern] = $callback;
    }

    public function execute($uri)
    {
        foreach ($this->routes as $pattern => $callback) {
            if (preg_match($pattern, $uri, $params) === 1) {
                array_shift($params);
                return call_user_func_array($callback, array_values($params));
            }
        }
        return false;
    }

}



try {
    $conn = new PDO("pgsql:host=$database_host;port=$database_port;dbname=$database_name", $database_user, $database_pass);
    // set the PDO error mode to exception
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
//    echo "Connected successfully";
} catch (PDOException $e) {
    die("Connection failed: " . $e->getMessage());
}



function rutime($ru, $rus, $index)
{
    return ($ru["ru_$index.tv_sec"] * 1000 + intval($ru["ru_$index.tv_usec"] / 1000))
        - ($rus["ru_$index.tv_sec"] * 1000 + intval($rus["ru_$index.tv_usec"] / 1000));
}

function setCORSHeaders()
{
    header("Content-Type: application/json");
    header("Access-Control-Allow-Origin: *");
    header("Access-Control-Allow-Methods: *");
    header("Access-Control-Allow-Headers: accept, content-type");
}

header("X-SGM-DATE: " . date("Ymd H:i:s"));
$request_url = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$router = new RegexRouter();


/**
 * / should return 200 ok. Used for "Test connection" on the datasource config page.
 */
$router->route(ROOT_REGEXP, function () {
    http_response_code(200);
    echo "OK";
    exit(0);

});
/**
 * /search used by the find metric options on the query tab in panels.
 */
$router->route(SEARCH_REGEXP, function () {
    //TODO move searches to corespond clases
    global $conn;
    http_response_code(200);
    $entityBody = file_get_contents('php://input');
    error_log(print_r($entityBody, 1));
    $qry = json_decode($entityBody);
//    print_r($qry);
//    Emsgd::pp($qry);
    if (isset($qry->target)) {
        $r = [];
        if (false && $qry->target == 'select metric') {
            $r = $conn->query("
            SELECT DISTINCT concat('ngnms2.observer.',r.router_id,'.',oop.id) AS value,concat(r.name,' (',r.ip_addr,' #',r.router_id,').',oop.id) AS text
                FROM routers r
                JOIN observer_options  oop ON (r.router_id = oop.routers_id)
            ")->fetchAll(PDO::FETCH_ASSOC);

        } elseif (preg_match('/ngnms2\.observer\.routers/', $qry->target)) {
            $r = $conn->query("
            SELECT DISTINCT r.router_id AS value,concat(r.name,' (',r.ip_addr,' #',r.router_id,')') AS text
                FROM routers r
                -- join observer_options  oop on (r.router_id = oop.routers_id)
            ")->fetchAll(PDO::FETCH_ASSOC);
        } elseif (preg_match('/ngnms2\.observer\.\(*([\d\|]+)\)*\.metrics/', $qry->target, $matches)) {
            $rids = join(',',Grafana::sanitize_int_list($matches[1])); //This is SQL-injection safe - only digits and commas
            $r = $conn->query("
            select  oop.id as value,concat(om.name,',',om.unit) as text
                FROM routers r
                  JOIN observer_options oop on (oop.routers_id = r.router_id)
                  JOIN origin_model_options om on (om.id = oop.origin_model_options_id)
                where r.router_id in ($rids)
            ")->fetchAll(PDO::FETCH_ASSOC);
        }elseif((preg_match('/ngnms2\.events\.\(*([\d\|]+)\)*\.facility/', $qry->target, $matches)) ){
            $routers=join(',',Grafana::sanitize_int_list($matches[1]));
            $empty_facility = Events::NO_FACILITY;
//            Emsgd::pp($routers);
            $r = $conn->query("
              select distinct
               case when facility = '' then '$empty_facility' else facility end as text,
              case when facility = '' then '$empty_facility' else facility end as value
                from events
                where 1=1
                   and origin_id in ($routers)
                ORDER BY 1
            ")->fetchAll(PDO::FETCH_ASSOC);


        }
        echo json_encode($r);
        return true;
    }


    exit(0);

});

/**
 * /query should return metrics based on input.
 */
$router->route(QUERY_REGEXP, function () {
    global $conn,$auth;

    http_response_code(200);
    $entityBody = file_get_contents('php://input');
    $jsn = json_decode($entityBody);

    $target_comma = '';

    echo "[" ;
    $interval = intval($jsn->intervalMs / 1000) ?: 1;
    foreach ($jsn->targets as $tq) {

        if ($tq->type == 'table') {
            if (preg_match('/ngnms2\.(?<system>events)\.{*(?<routers>[\d,]+)}*\.{*(?<facilities>.*?)}*$/', $tq->target, $matches)) {
                /**
                 * Data table with events
                 */
                $auth->can_or_die('GrafanaEvent');
                $router_id =  Grafana::sanitize_int_list($matches['routers']);
                $facilities = preg_split('/,/',$matches['facilities']);
                $t = new \NGNMS\Grafana\Events($conn);
                echo $target_comma ;
                $t->print_events($router_id, $facilities, $jsn->range->from, $jsn->range->to);
                $target_comma = ',';
            }
        } else {
            if (preg_match('/ngnms2\.(?<system>observer)\.{*(?<routers>[\d,]+)}*\.{*(?<oop_id>[\d,]+)}*\.(?<smoothness>.*?)$/', $tq->target, $matches)) {
                $auth->can_or_die('GrafanaRouter');
                $routers = Grafana::sanitize_int_list($matches['routers']);
                $ooids = Grafana::sanitize_int_list($matches['oop_id']);
                foreach ($routers as $router_id) {
                    foreach ($ooids as $oop_id) {
                        $target = [
                            "router_id" => $router_id,
                            "oop_id" => $oop_id,
                            "table" => $matches['smoothness'],
                            "target_name" => $tq->target,
                        ];
                            $s = new \NGNMS\Grafana\ObserverSeries($conn);
                        echo $target_comma ;
                        $s->print_time_series($target, $jsn->range->from, $jsn->range->to, $interval);
                        $target_comma = ',';
                    }
                }


            }elseif (preg_match('/ngnms2\.(?<system>events)\.{*(?<routers>[\d,]+)}*\.{*(?<facilities>.*?)}*\.(?<min_severity>\d+)\.(?<smoothness>.*?)$/', $tq->target, $matches)) {
                /**
                 * Router events
                 */
                $auth->can_or_die('GrafanaRouter');
                $routers = Grafana::sanitize_int_list($matches['routers']);
                $facilities =  preg_split('/,/',$matches['facilities']);
                foreach ($routers as $router_id) {
                        $target = [
                            "router_id" => $router_id,
                            "facilities" => $facilities,
                            "table" => $matches['smoothness'],
                            "target_name" => $tq->target,
                            "min_severity"=>intval($matches['min_severity'])
                        ];
                            $s = new \NGNMS\Grafana\Events($conn);

                        echo $target_comma ;
                        $s->print_time_series($target, $jsn->range->from, $jsn->range->to, $interval);
                        $target_comma = ',';
                }


            }
            elseif(preg_match('/ngnms2\.events\.overview\.(?<min_severity>\d+)\.(?<by>by_facility|by_router)$/', $tq->target, $matches)){
                /**
                 * Data events overviews
                 */
                $auth->can_or_die('GrafanaOverview');
                $s = new \NGNMS\Grafana\Events($conn);
                echo $target_comma ;
                $s->print_overview($matches['by'], $jsn->range->from, $jsn->range->to, $interval,intval($matches['min_severity']));
                $target_comma = ',';
            }
        }
    }
    echo  "]";
    exit(0);

});

/**
 * /annotations used by the find metric options on the query tab in panels.
 */
$router->route(ANNOTATIONS_REGEXP, function () {
    global $conn;
    http_response_code(200);
    $entityBody = file_get_contents('php://input');
    $jsn = json_decode($entityBody);

    if (preg_match('/ngnms2\.(?<system>events)\.{*(?<routers>[\d,]+)}*\.{*(?<facilities>.*?)}*$/', $jsn->annotation->query, $matches)) {
        $rtid = $matches['routers'];
        $facilities = preg_split('/,/',$matches['facilities']);
//        Emsgd::pp($rtid);
        $a = new Annotations($conn);
        echo '[ ';
        $a->print_annotations($rtid, $facilities, $jsn->range->from, $jsn->range->to);
        echo ' ] ';
    } else {
        return '[]';
    }
    return true;

});

/**
 * Run app
 */
$auth = new Auth($conn);
try {
    setCORSHeaders();


    if (!$auth->getStatus()){
        echo "[";
        throw new AuthException();
    }

    $success = $router->execute($request_url);
    if (!$success) {
        throw new \ErrorException("Route '$request_url' not found");
    }
} catch (AuthException  $e){
    http_response_code(401);
    echo $auth->getError()."]";
}
catch (Exception $e) {
    echo("UNHANLED  Exception " . $e->getCode() . ": " . $e->getMessage());
}


