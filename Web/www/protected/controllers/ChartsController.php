<?php

/**
 * Created by PhpStorm.
 * User: VLZ
 * Date: 26.11.2015
 * Time: 0:06
 */
class ChartsController extends Controller
{
    public function actionIndex()
    {
        if (Yii::app()->user->checkAccess('user')) {
            echo "here";
        } else {
            echo  Yii::getVersion();;
        }
    }


}