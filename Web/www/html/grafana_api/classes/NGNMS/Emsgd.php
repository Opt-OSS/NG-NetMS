<?php
/**
 * Created by PhpStorm.
 * User: VLZ
 * Date: 16.07.2015
 * Time: 19:24
 */

namespace NGNMS;

class Emsgd
{
    public static function p($f_message = null, $f_file = '', $f_line = '')
    {
        if (isset( $_GET['hidemsgd'] )) {
            return;
        }
        $dbg  = debug_backtrace();
        $type = gettype($f_message);
        if ($f_message === null) {
            $f_message = 'null';
        } elseif (( $f_message === false ) || ( $f_message === true )) {
            $f_message = $f_message === false ? 'false' : 'true';
        }
        $f_file = $f_file ? $f_file : $dbg[0]['file'];
        $f_line = $f_line ? $f_line : $dbg[0]['line'];
        $f_message = "\n$type:\n" . print_r($f_message, true);
        echo "\n<pre>\n" . $f_file . " " . $f_line . " " . $f_message . "\n</pre>\n";
    }

    public static function s($f_message, $f_file = '', $f_line = '')
    {
        if (isset( $_GET['hidemsgd'] )) {
            return '';
        }
        $dbg  = debug_backtrace();
        $f_file = $dbg[0]['file'];
        $f_line = $dbg[0]['line'];
        ob_start();
        self::p($f_message, $f_file , $f_line);

        return ob_get_clean();
    }

    /**
     * Pretty print
     *
     * @param null $f_message
     * @param string $f_file
     * @param string $f_line
     *
     */

    public static function pp($f_message = null, $f_file = '', $f_line = '')
    {
        if (isset( $_GET['hidemsgd'] )) {
            return;
        }
        $dbg  = debug_backtrace();
        $type = gettype($f_message);
        if ($f_message === null) {
            $f_message = 'null';
        } elseif (( $f_message === false ) || ( $f_message === true )) {
            $f_message = $f_message === false ? 'false' : 'true';
        }
        $f_file = $f_file ? $f_file : $dbg[0]['file'];
        $f_line = $f_line ? $f_line : $dbg[0]['line'];
        $f_message = "\n$type:\n" . print_r($f_message, true);
        echo "\n---------------\n" . $f_file . " " . $f_line . " " . $f_message . "\n";

    }

    public static function ss($f_message, $f_file = '', $f_line = '')
    {
        if (isset( $_GET['hidemsgd'] )) {
            return '';
        }
        $dbg  = debug_backtrace();
        $f_file = $dbg[0]['file'];
        $f_line = $dbg[0]['line'];
        ob_start();
        self::pp($f_message, $f_file, $f_line);

        return ob_get_clean();
    }

}
