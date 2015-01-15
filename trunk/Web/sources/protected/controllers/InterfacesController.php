<?php

class InterfacesController extends Controller
{

        public function actionIndex()
        {
            $this->render('index');
        }


        /**
         * Shows Ip map
         */
        public function actionIpmap()
        {
            $baseUrl = Yii::app()->baseUrl; 
            $cs = Yii::app()->clientScript;
//            $cs->registerScriptFile(Yii::app()->baseUrl . '/js/libs/jstree/dist/libs/jquery.js', CClientScript::POS_HEAD);
            $cs->registerScriptFile($baseUrl . '/js/libs/jstree/dist/jstree.js', CClientScript::POS_HEAD);
            $cs->registerScriptFile($baseUrl . '/js/libs/jstree/dist/jstreegrid.js', CClientScript::POS_HEAD);
            $cs->registerCssFile($baseUrl.'/js/libs/jstree/dist/themes/default/style.css');
            $cs->registerScriptFile($baseUrl . '/js/controller/ipmap.js', CClientScript::POS_HEAD);
            $arr_tree = Yii::app()->subnets->tree;
            $this->render('ipmap',array(
                        'arr_tree' => json_encode($arr_tree),
                    ));
        }
}