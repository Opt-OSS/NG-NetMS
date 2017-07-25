<?php

// uncomment the following to define a path alias
// Yii::setPathOfAlias('local','path/to/local-folder');

// This is the main Web application configuration. Any writable
// CWebApplication properties can be configured here.
//Yii::setPathOfAlias('chartjs', dirname(__FILE__).'/../extensions/yii-chartjs');
return array(
	'basePath'=>dirname(__FILE__).DIRECTORY_SEPARATOR.'..',
	'name'=>'OptOSS',
    'id' => 'ngnms',
    'aliases' => array(
//    'bootstrap' => realpath(__DIR__.'/../extensions/bootstrap'),
        'bootstrap' => realpath(__DIR__.'/../yiibooster'),
        'chartjs' => realpath(__DIR__.'/../extensions/yii-chartjs'),
    ),
    'theme'=>'bootstrap', // requires you to copy the theme under your themes directory
    'modules'=>array(
        'gii'=>array(
            'class'=>'system.gii.GiiModule',
	    'password'=>'medusa',
            'generatorPaths'=>array(
                'bootstrap.gii',
            ),            
        ),
        'srbac'  => array(
            // model for table User
            'userclass' => 'User',
            // Unique id of user
            'userid'    => 'id',
            // Username
            'username'  => 'username',
            // Debug mode
            'debug'    => false,
            // Count of records on page
            'pageSize'  => 20,
            // Rolename of superuser
            'superUser' => 'admin',
            // Style of modul
            'css'      => 'srbac.css',
            //  Message to not authorized users who tried to access the private area of ??this site for them
            'notAuthorizedView' => 'srbac.views.authitem.unauthorized',
            // User operations permitted
            'userActions'          => array('Show','View','List','Index'),
            //
            'listBoxNumberOfLines' => 15,
            // Path to images
            'imagesPath'          => 'srbac.images',
            //
            'imagesPack'          => 'noia',
            //
            'iconText'            => true,
        ),
    ),
	// preloading 'log' component
	'preload'=>array('log','chartjs'),

	// autoloading model and component classes
	'import'=>array(
		'application.models.*',
		'application.components.*',
                'application.modules.srbac.controllers.SBaseController',
                'application.yiibooster.components.*',
		'application.vendor.phpexcel.*',
	),

/*	'modules'=>array(
		// uncomment the following to enable the Gii tool
		
		'gii'=>array(
			'class'=>'system.gii.GiiModule',
			'password'=>'Enter Your Password Here',
			// If removed, Gii defaults to localhost only. Edit carefully to taste.
			'ipFilters'=>array('127.0.0.1','::1'),
		),
		
	),*/

	// application components
	'components'=>array(
		'user'=>array(
			// enable cookie-based authentication
			'allowAutoLogin'=>true,
                        'loginUrl'=>array('site/login')
		),
        'bootstrap'=>array(
            'class'=>'application.yiibooster.components.Bootstrap',
        ),
        'graph' => array(
            'class'=>'RoutersGraphData',
        ),
        'subnets' => array(
            'class'=>'Subnet',
        ),
        'difftools' => array(
            'class'=>'DiffConf',
        ),
        'chartjs' => array('class' => 'chartjs.components.ChartJs'),
		// uncomment the following to enable URLs in path-format
        /*
		'urlManager'=>array(
			'urlFormat'=>'path',
			'rules'=>array(
				'<controller:\w+>/<id:\d+>'=>'<controller>/view',
				'<controller:\w+>/<action:\w+>/<id:\d+>'=>'<controller>/<action>',
				'<controller:\w+>/<action:\w+>'=>'<controller>/<action>',
			),
		),
        */
        'db'=>array(
			'connectionString' => 'pgsql:host=localhost;port=5432;dbname=ngnms',
//			'emulatePrepare' => true,
			'username' => 'ngnms',
			'password' => 'ngnms',
			'charset' => 'utf8',
		),
        'authManager'   =>array(
                        'class'=>'application.modules.srbac.components.SDbAuthManager',
                        'connectionID'    => 'db',
                        'itemTable'          => 'authitem',
                        'itemChildTable'    => 'authitemchild',
                        'assignmentTable' => 'authassignment',
                        'defaultRoles'      =>  array('Guest'),
        ),
		'errorHandler'=>array(
			// use 'site/error' action to display errors
			'errorAction'=>'site/error',
		),
		'log'=>array(
			'class'=>'CLogRouter',
			'routes'=>array(
				array(
					'class'=>'CFileLogRoute',
					'levels'=>'error, warning',
				),
				// uncomment the following to show log messages on web pages
				/*
				array(
					'class'=>'CWebLogRoute',
				),
				*/
			),
		),
	),

	// application-level parameters that can be accessed
	// using Yii::app()->params['paramName']
	'params'=>array(
		// this is used in contact page
		'adminEmail' => 'sales@opt-net.eu',
                'colorsVendor' => array(
                    'Cisco' => '#2E8B57',
                    'Juniper' => '#4682B4',
                    'default' => 'white'
                ),
                'imagesVendor' => array(
                    'Cisco' => '/router_green.png',
                    'Juniper' => '/router_blue.png',
                    'down' => '/router_grey.png',
                    'default' => '/router_white.png'
                ),
                'colorsEdge' => array(
                    'P' => 'green',
                    'B' => '#0000CD',
                    'D' => 'black' //default
                ),
                'colorsStatus'=>array(
                    'up' =>  '#2E8B57',
                    'down' => '#DC143C',
                    'enabled' => '#2E8B57',
                    'disabled' =>'#DC143C',
                    'UNKNOWN' =>'#DDD',
                    'unknown' =>'#DDD',

                ),
        'cronperiods'=>array(
            '15 min' => 15,
            '30 min' => 30,
            'hour' => 60,
            '6 hours' => 360,
            '12 hours' => 720,
            'day' => 1440,
            'week' => 10080
        ),
        'vendors' => array(
                'Cisco' => 'Cisco',
                'Extreme'=>'Extreme',
                'Juniper'=>'Juniper',
                'Linux'=>'Linux',
                'Netscreen'=>'Netscreen',
                'HP_ProCurve'=>'HP ProCurve',
                'HP_iLO'=>'HP iLO',
        ),
                'color_na' => '#808080',
                'point_on_chart'=>200,
                'prev_of_chart'=>25,
                'next_of_chart'=>175,
	    ),
);
