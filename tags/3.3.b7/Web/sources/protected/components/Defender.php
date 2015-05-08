<?php
/**
 * Class to protect a login form
 * User: andrew
 * Date: 3/12/15
 * Time: 11:28 AM
 */

class Defender extends CComponent
{

    /**
     * User Host IP Address.
     * @var string
     */
    public $ip;

    /**
     * Allowed failed logins during the 'failedLoginsTestDuration' period.
     * @var int Failed login attempts.
     */
    public $failedLoginsAllowed = 3; // 3 failed logins in $failedLoginsTestDuration seconds

    /**
     * Max number of failed logins allowed before showing a Captcha test.
     */
    public $maxLoginsBeforeCaptcha = 3;

    /**
     * Test period for login errors count, from now backwards.
     * @var int Time in seconds.
     */
    public $failedLoginsTestDuration = 3600; // 60 minutes

    /**
     * Duration of the lock.
     * @var int Time in seconds.
     */
    public $lockDuration = 1800; // 30 minutes

    /**
     * Number of locks tolerated before definitive ban of the ip.
     * @var int Number of locks: 0 to disable ban.
     */
    public $locksBeforeBan = 5;

    /**
     * Number of bans tolerated before eternal ban of the ip.
     * @var int Number of locks: 0 to disable ban.
     */
    public $bansBeforeEternalBan = 2;

    /**
     * Test period for ban errors count, from now backwards.
     * @var int Time in seconds.
     */
    public $bansTestDuration = 86400; // 24 hours

    /**
    * Duration of the ban.
    * @var int Time in seconds.
    */
    public $banDuration = 86400; // 24 hours

    /**
     * Db tables with records about failed logins, locked ips and banned ips.
     * @var string The db table name.
     */
    public $failedLoginsTable = "failed_logins";

    public $locksTable = "locked_ips";

    public $bansTable = 'bans_ips';

    /**
     * The total number of failed logins in the test period. READ ONLY.
     * @var int
     */
    public $failedLogins;

    /**
     * The total number of times an Ip has been locked during $bansTestDuration, from now backward. READ ONLY.
     * @var int
     */
    public $timesLocked;

    /**
     * The total number of times an Ip has been baned , from now backward. READ ONLY.
     * @var int
     */
    public $timesBaned;

    /**
     * The result of a query on the ip_locks table. List of lock records for the current ip.
     * @var array
     */
    private $locks;

    /**
     * The result of a query on the bans_locks table. List of ban records for the current ip.
     * @var array
     */
    private $bans;


    /**
     * Whether the ip is locked or banned. READ ONLY.
     * @var int
     */
    public $isLocked;

    public $isBanned;

    /**
     * Create an instance of the defender based on the ip provided.
     * @param string $ip User Host IP Address.
     */
    public function __construct()
    {
//        $this->ip = Yii::app()->request()->getUserHostAddress();
        $this->ip = Yii::app()->request->getUserHostAddress();

        // Get lock record for the current ip.
        $this->locks = $this->getLocks();

        // Stores data about the current ip.
        $this->timesLocked = $this->locks->rowCount;

        // Get ban record for the current ip.
        $this->bans = $this->getBans();

        // Stores data about the current ip.
        $this->timesBaned = $this->bans->rowCount;

        $this->isLocked = (boolean) $this->isLocked();

        $this->isBanned = (boolean) $this->isBanned();

        // Store the number of failed logins for the currenti ip.
        if (!$this->isLocked && !$this->isBanned)
        {
            $this->failedLogins = $this->countLoginErrors();
        }
        else
        {
            // If locked or banned, the number of failed login is always 1000 more than allowed.
            $this->failedLogins = $this->failedLoginsAllowed + 1000;
        }
    }

    /**
     * Check the session to get login failures: returns false if the user has
     * too many failures in a small time span.
     * @param array $session User's session.
     * @param int $ip User's ip.
     * @return boolean Wheter the user has the right to continue logging in.
     */
    public function isSafeIp()
    {
        if ($this->isLocked || $this->isBanned)
        {
            return false;
        }
        return true;
    }

    /**
     * Lock ip. This ip will be locked for the time defined in $this->lockDuration
     * @param string $ip
     */
    public function lockIp()
    {
        if (!$this->isLocked)
        {
            Yii::log('Now locked: ' . $this->ip, 'warning');
            return Yii::app()->db->createCommand()
                ->insert($this->locksTable, array(
                        'ip' => $this->ip,
                        'time' => time(),
                    )
                );
        }
        Yii::log('Already locked: ' . $this->ip, 'warning');
    }

    /**
     * Check wether the ip is currently locked.
     * @return boolean
     */
    public function isLocked()
    {
        foreach ($this->locks as $lock)
        {
            if ($lock['time'] > time() - $this->lockDuration)
            {
                Yii::log('Ip locked? YES', 'warning');
                Yii::log('Time locked? ' . $lock['time'], 'warning');
                return true;
            }
        }
        Yii::log('Ip locked? NO', 'warning');
        return false;
    }

    /**
     *Ban ip. This ip will be banned for the time defined in $this->banDuration
     * if
     * @param string $ip
     */
    public function banIp($f_time)
    {
        if (!$this->isLocked)
        {
            Yii::log('Now locked: ' . $this->ip, 'warning');
            return Yii::app()->db->createCommand()
                ->insert($this->bansTable, array(
                        'ip' => $this->ip,
                        'finish_time' => $f_time,
                    )
                );
        }
        Yii::log('Already locked: ' . $this->ip, 'warning');
    }

    /**
     * Check wether the ip is banned.
     * @return int
     */
    public function isBanned()
    {
        foreach ($this->bans as $ban)
        {
            if ($ban['finish_time'] > time())
            {
                Yii::log('Ip baned? YES', 'warning');
                Yii::log('Time baned? ' . $ban['finish_time'], 'warning');
                return true;
            }
        }
        Yii::log('Ip baned? NO', 'warning');
        return false;
    }

    /**
     * Get bans records for the current ip.
     * @return array Array with ip
     */
    public function getBans()
    {
        return Yii::app()->db->createCommand()
            ->select('finish_time')
            ->from($this->bansTable)
            ->where('ip=:ip ',array(':ip' => $this->ip))
            ->query();
    }

    /**
     * Get lock records for the current ip.
     * @return array Array with ip
     */
    public function getLocks()
    {
        return Yii::app()->db->createCommand()
            ->select('time')
            ->from($this->locksTable)
            ->where('ip=:ip and time>:time',
                    array(':ip' => $this->ip,
                    ':time' => time() - $this->bansTestDuration
                    ))
            ->query();
    }

    /**
     * Get the number of failed logins for the current ip.
     * @param type $ip The ip of the current user.
     * @return int
     */
    public function countLoginErrors()
    {
        $errors = Yii::app()->db->createCommand()
            ->select('count(*) as num')
            ->from($this->failedLoginsTable)
            ->where('ip=:ip and time>:time', array(
                    ':ip' => $this->ip,
                    ':time' => time() - $this->failedLoginsTestDuration
                )
            )
            ->queryScalar();
        return $errors;
    }

    /**
     * Save ip and time of a failed login attempt in the db and delete old records.
     * @param array $session User's session.
     * @param int $ip User's ip.
     */
    public function recordFailedLogin()
    {
//      @TODO Move the deletion of old record to a CRON JOB when deploying the application.
//      $deleted = Yii::app()->db->createCommand()->delete($this->failedLoginsTable, 'time<:time', array(
//          ':time' => (time() - $this->failedLoginsTestDuration)
//              )
//      );
//      Yii::log('Rows deleted: ' . $deleted, 'warning');
        $inserted = Yii::app()->db->createCommand()
            ->insert($this->failedLoginsTable, array(
                    'ip' => $this->ip,
                    'time' => time(),
                )
            );
        if ($this->failedLogins + 1 > $this->failedLoginsAllowed)
        {
            $this->lockIp();
            if ($this->timesLocked +1 > $this->locksBeforeBan)
            {
                if($this->timesBaned+1 > $this->bansBeforeEternalBan)
                {
                    $finish_time = time()+86400*365*5; // ban for 5 years
                }
                else
                {
                    $finish_time = time() + $this->banDuration;
                }

                $this->banIp($finish_time);
            }

        }


        Yii::log('Rows inserted: ' . $inserted, 'warning');


    }


    /**
     * Remove every failed login record about the current ip
     * @return integer number of rows deleted
     */
    public function removeFailedLogins()
    {
        return Yii::app()->db->createCommand()->delete($this->failedLoginsTable, 'ip=:ip', array(
                ':ip' => $this->ip
            )
        );
    }

}