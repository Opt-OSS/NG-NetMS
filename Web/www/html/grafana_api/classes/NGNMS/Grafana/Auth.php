<?php

/**
 * Created by PhpStorm.
 * User: Home
 * Date: 04.03.2017
 * Time: 17:21
 */

namespace NGNMS\Grafana;

use NGNMS\Emsgd;
use NGNMS\Grafana\AuthException;
use PDO;

class Auth {
    protected $conn;
    private $user_id_key;
    private $status = false;
    private $error = "Unauthorized";
    private $ngnms_user_id;
    private $access = [];

    public function __construct(PDO $pdo) {

//        $this->status = true;
//        Emsgd::p($_SESSION);
//        Emsgd::p($_COOKIE);
//        $raw_post = file_get_contents("php://input");
//        Emsgd::p($raw_post);
//        return;
        if (false !== $proxy = getenv('GRAFANA_PROXY_ALLOWED')) {
            if ($_SERVER['REMOTE_ADDR'] == gethostbyname($proxy)) {
                //todo make some caching
                $this->status = true;
                return;
            }

        }

        $this->conn = $pdo;

        $pgversion = $this->conn->query('SHOW server_version_num')->fetchColumn();
        if ($pgversion < 90500) {
            $this->error = "Postgresql >= 9.5 required";
            return;
        }
        $this->user_id_key = md5('Yii.' . 'CWebUser' . '.' . 'ngnms') . '__id';

        if (session_status() == PHP_SESSION_NONE) {
            $this->error = "Session not exists";
            return;
        }

        if (empty($_SESSION[$this->user_id_key])) {
            $this->error = "NGNMS: not logged in";
            return;
        }
        $this->ngnms_user_id = intval($_SESSION[$this->user_id_key]);
        if (!$this->ngnms_user_id) {
            $this->error = "NGNMS: wrong user";
            return;
        }

        $this->status = true;
        return;

        $stmt = $this->conn->prepare("
            SELECT DISTINCT ac2.child
            FROM authassignment aa
              JOIN authitem  ai1 ON (aa.itemname = ai1.name)
              LEFT OUTER JOIN authitemchild ac1 ON ac1.parent = ai1.name
              LEFT JOIN authitemchild ac2 ON ac1.child = ac2.parent
            WHERE userid = ? AND ac1.child LIKE 'Grafana%'
            ");
        $stmt->execute([$this->ngnms_user_id]);
        $this->access = $stmt->fetchAll(PDO::FETCH_COLUMN);

        if (count($this->access)) {
            $this->status = true;
        }
    }

    public function can($operation) {
        return true;
        if (!$this->status) return false;
        if (!in_array($operation, $this->access)) {
            $this->error = "Operation not allowed";
            return false;
        };
        return true;
    }

    public function can_or_die($operation) {
        return true;
        if (!$this->can($operation)) {
            throw new AuthException();
        };
        return true;
    }

    /**
     * @return mixed
     */
    public function getStatus() {
        return $this->status;
    }


    /**
     * @return mixed
     */
    public function getNgnmsUserId() {
        return $this->ngnms_user_id;
    }

    /**
     * @return string
     */
    public function getError() {
        return '[{"message":"' . $this->error . '","error":"Permission denided"}]';
    }
}