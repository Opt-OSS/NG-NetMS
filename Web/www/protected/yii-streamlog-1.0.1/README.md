Yii 1 Streamlog
===============

Send Yii 1 logs to stdout/stderr - created to be used with the php-fpm/nginx Docker stack available at [http://github.com/neam/docker-stack]()

Thanks to Haensel for [this forum post](http://www.yiiframework.com/forum/index.php/topic/30484-yii-log-to-console-stdout/page__view__findpost__p__146923)!

Installation
------------

Install via composer:

    composer require neam/yii-streamlog:*

Or download the extension, copy the `src` folder to your project and make sure to require the file `LogRoute.php` at some stage of application initiation.

Usage
-----

Change all your existing routes that use CFileLogRoute to instead use \neam\yii_streamlog\LogRoute:

    'components' => array(
        'log' => array(
            'class' => 'CLogRouter',
            'routes' => array(
                array(
                    'class' => '\neam\yii_streamlog\LogRoute',
                    'levels' => 'error, warning',
                ),
            ),
        ),
    ),

Also, make sure to [set `catch_worker_output=yes` in your php-fpm pool config](https://github.com/neam/docker-stack/blob/b007920bcdf862570218e1fb0e855df44a6c51f7/stacks/php-nginx-memcache/boilerplate/stack/php/pool.d/www.conf#L17-L18).

Links
-----

- [Docker Stack Project](http://github.com/neam/docker-stack)
- [GitHub](https://github.com/neam/yii-streamlog)
