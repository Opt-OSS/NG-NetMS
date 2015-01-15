<?php
/**
 * add header into files from $dir which have extension from array($exts)
 * 
 * 
 */
  
function get_files($dir = ".",$exts){
	
     $files = array();  
     if ($handle = opendir($dir)) {     
          while (false !== ($item = readdir($handle))) {        
               if (is_file("$dir/$item")) {
				    $eext = getExtension($item);
				    if(isset($eext) && in_array($eext,$exts))
						$files[] = "$dir/$item";
               }        
               elseif (is_dir("$dir/$item") && ($item != ".") && ($item != "..") && ($item != 'Net')){
				   $new_part_arr = get_files("$dir/$item",$exts);
				   if(isset($new_part_arr) && is_array($new_part_arr))
                     $files = array_merge($files, $new_part_arr);
               }
          } 
          closedir($handle);
     }  
     return $files; 
}

function getExtension($filename) {
    return end(explode(".", $filename));
  }

$version_number = $argv[1];
if(isset($argv[2]))
{
$build_number = $argv[2];
	}
else
{
	$build_number = "N/A";
	}	

exec('cp -avr sources/. release');	
$dirs_array1= array('bin');
$exts1 = array('pl','sh'); 
$dir_pref = 'release/';
$files1 = array();
$files2 = array();

for($i = 0;$i<count($dirs_array1);$i++)
{
	$dir =  $dir_pref . $dirs_array1[$i]; 
	$files1 = array_merge($files1,get_files($dir,$exts1));
}

$dirs_array2 = array('lib');
$exts2 = array('pm'); 

for($i = 0;$i<count($dirs_array2);$i++)
{
	$dir =  $dir_pref . $dirs_array2[$i]; 
	$files2 = array_merge($files2,get_files($dir,$exts2));
}



 $add_str = '# NG-NetMS, a Next Generation Network Managment System
# 
# Version '. $version_number .' 
# Build number '. $build_number.'
# Copyright (C) 2014 Opt/Net
# 
# This file is part of NG-NetMS tool.
# 
# NG-NetMS is free software: you can redistribute it and/or modify it under the terms of the
# GNU General Public License v3.0 as published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# NG-NetMS is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# 
# See the GNU General Public License for more details. You should have received a copy of the GNU
# General Public License along with NG-NetMS. If not, see <http://www.gnu.org/licenses/gpl-3.0.html>.
# 
# Authors: T.Matselyukh, A. Jaropud, M.Golov
 ';
 
 for($i=0;$i<count($files1);$i++)
 {
	 echo $files1[$i]."\n";
	 $str_res ="";
	 $lines = file($files1[$i]);    
	    
	foreach ($lines as $line_num => $line) {
			if($line_num==0)
			{
				$str_res.=$line.$add_str."\n";
				}
			else
			{
				$str_res.=$line;
				}
		}
	file_put_contents($files1[$i],$str_res);
}

for($i=0;$i<count($files2);$i++)
 {
	 echo $files2[$i]."\n";
	file_put_contents($files2[$i],$add_str."\n".file_get_contents($files2[$i]));
}

?>
