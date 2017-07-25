<?php

namespace neam\yii_streamlog;

use CLogRoute;

class LogRoute extends CLogRoute
{
    public function processLogs($logs)
    {
        $STDOUT = fopen("php://stdout", "w");
        foreach ($logs as $log) {
            fwrite($STDOUT, $log[0] . "\n"); //write the message [1] = level, [2]=category
        }
        fclose($STDOUT);
    }
}
