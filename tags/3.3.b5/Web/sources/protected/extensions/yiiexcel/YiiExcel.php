<?php
/**
 * 
 * Universidad Pedagógica Nacional Fracisco Morazán
 * Dirección de Tecnologías de Información
 * 
 * @author K'iin Balam <kbalam@upnfm.edu.hn>
 * 
 */

/**
 * YiiExcel class - wrapper for PHPExcel
 * 
 * This class provide a wrapper for PHPExcel Autoload. 
 * Please read the README file
 * 
 * This extension is an autoloader for PHPExcel on Yii framework 
 * 
 * @package YiiExcel
 * @author K'iin Balam <kbalam@upnfm.edu.hn>
 * @copyright Copyright (c) 2013 UPNFM
 * @license    http://www.gnu.org/licenses/old-licenses/lgpl-2.1.txt    LGPL
 * @version 1.0, 2013-01-18
 */
 
class YiiExcel {
    
    public static $_pathAlias = 'application.vendor.phpexcel';
    
    static function autoload($pClassName){
        if ((class_exists($pClassName, false)) || (strpos($pClassName, 'PHPExcel') !== 0)) {
            //  Either already loaded, or not a PHPExcel class request
            return false;
        }

        //get the path
        //$pClassFilePath = Yii::getPathOfAlias('application.vendors.phpexcel').'/'
        $pClassFilePath = Yii::getPathOfAlias(self::$_pathAlias).'/'
            .str_replace('_', DIRECTORY_SEPARATOR, $pClassName).'.php';

        if ((file_exists($pClassFilePath) === false) || (is_readable($pClassFilePath) === false)) {
            //  Can't load
            return false;
        }

        require($pClassFilePath);
    }//loadClass end
}//EPHPExcelAutoloader end