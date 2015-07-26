<?php
/**
 * Created by PhpStorm.
 * User: VLZ
 * Date: 09.12.2014
 * Time: 21:38
 */
	if (!function_exists('emsgd')) {


		function emsgd($f_message = null, $f_file = '', $f_line = '')
		{
			if (isset($_GET['hidemsgd'])) return;
			$dbg = debug_backtrace();
			$type = gettype ($f_message);
			if ($f_message === null) {
				$f_message = 'null';
			} elseif (($f_message === false) || ($f_message === true)) {
				$f_message = $f_message === false ? 'false' : 'true';
			}
			$f_file = $dbg[0]['file'];
			$f_line = $dbg[0]['line'];
			$f_message = "<pre style='white-space: pre-line;word-wrap: break-word'>$type:\n" . print_r($f_message, TRUE) . '</pre>';
			echo '<div style="text-align:left;background-color:yellow;color:black;">' . $f_file . " " . $f_line . " " . $f_message . '</div>';
		}

		function emsgds($f_message, $f_file = '', $f_line = '')
		{
			if (isset($_GET['hidemsgd'])) return;
			$dbg = debug_backtrace();
			$type = gettype ($f_message);
			if ($f_message === null) {
				$f_message = 'null';
			} elseif (($f_message === false) || ($f_message === true)) {
				$f_message = $f_message === false ? 'false' : 'true';
			}
			$f_file = $dbg[0]['file'];
			$f_line = $dbg[0]['line'];
			$f_message = "<pre style='white-space: pre-line;word-wrap: break-word'>$type:\n" . print_r($f_message, TRUE) . '</pre>';
			return '<div style="text-align:left;background-color:yellow;color:black;">' . $f_file . " " . $f_line . " " . $f_message . '</div>';
		}

	}