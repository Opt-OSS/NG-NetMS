# YiiExcel

Yii extension wrapper for [PHPExcel](https://github.com/PHPOffice/PHPExcel) class autoload on Yii applications.

## Installation

* Copy yiiexcel directory to protected/extensions.
* Download [PHPExcel](http://phpexcel.codeplex.com/releases/view/96183).
*  Create a phpexcel directory on protected/vendors.
*  Unzip PHPExcel and copy Classes directory content to protected/extensions/phpexcel.
*  Edit PHPExcel.php file and comment the autoload inclusion:

php

    :::php
    /** PHPExcel root directory */
    /*if (!defined('PHPEXCEL_ROOT')) {
        define('PHPEXCEL_ROOT', dirname(__FILE__) . '/');
        require(PHPEXCEL_ROOT . 'PHPExcel/Autoloader.php');
    }*/


* Edit index.php file and register the YiiExcel autoloader:

php

    :::php
    require_once($yii);
    //do not run app before register YiiExcel autoload
    $app = Yii::createWebApplication($config);
    
    Yii::import('ext.yiiexcel.YiiExcel', true);
    Yii::registerAutoloader(array('YiiExcel', 'autoload'), true);
    
    // Optional:
    //	As we always try to run the autoloader before anything else, we can use it to do a few
    //		simple checks and initialisations
    PHPExcel_Shared_ZipStreamWrapper::register();
    
    if (ini_get('mbstring.func_overload') & 2) {
        throw new Exception('Multibyte function overloading in PHP must be disabled for string functions (2).');
    }
    PHPExcel_Shared_String::buildCharacterSets();
    
    //Now you can run application
    $app->run();

* Edit main.php config file to import PHPExcel main class:

php
    // autoloading model and component classes
    'import'=>array(
        ...
        'application.vendors.phpexcel.PHPExcel',
        ...
    ),



## Usage

Just create a PHPExcel instance:

    :::php
    $objPHPExcel = new PHPExcel();
    
Read the SiteController.php example file located inside example directory.
