# YiiExcel

Extensión para Yii framework que envuelve la autocarga de clases de [PHPExcel](https://github.com/PHPOffice/PHPExcel), perminiendo un uso transparente dentro de aplicaciones Yii.

## Installación

* Copie el directorio yiiexcel dentro de protected/extensions.
* Descargue [PHPExcel](http://phpexcel.codeplex.com/releases/view/96183).
* Cree un diectorio dentro de protected/vendors y llámelo phpexcel.
* Decomprima PHPExcel y copie el contenido del directorio Classes destro de del directorio phpexcel recién creado.
* Abra el archivo PHPExcel.php y comente la inlución del autocargador:

php


    :::php
    /** PHPExcel root directory */
    /*if (!defined('PHPEXCEL_ROOT')) {
        define('PHPEXCEL_ROOT', dirname(__FILE__) . '/');
        require(PHPEXCEL_ROOT . 'PHPExcel/Autoloader.php');
    }*/


* Edite el archivo index.php y registre el autocargador de YiiExcel:

php


    :::php
	require_once($yii);
    //Ne ejecutar la aplicación antes de registrar el autocargador
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
    
    //Ahora si se puede correr la aplicación
    $app->run();

* Edite el archivo de configuración main.php para agregar la clase PHPExcel:

php
    // autoloading model and component classes
    'import'=>array(
        ...
        'application.vendors.phpexcel.PHPExcel',
        ...
    ),


## Uso

Simplemente crea una instancia de PHPExcel

    :::php
    $objPHPExcel = new PHPExcel();


Consulta el archivo SiteController.php de ejemplo que está en el directorio example.
