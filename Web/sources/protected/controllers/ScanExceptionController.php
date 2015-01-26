<?php

class ScanExceptionController extends Controller
{
/**
* @var string the default layout for the views. Defaults to '//layouts/column2', meaning
* using two-column layout. See 'protected/views/layouts/column2.php'.
*/
public $layout='//layouts/column2';

/**
* @return array action filters
*/
public function filters()
{
return array(
'accessControl', // perform access control for CRUD operations
);
}

/**
* Specifies the access control rules.
* This method is used by the 'accessControl' filter.
* @return array access control rules
*/
public function accessRules()
{
return array(
array('allow',  // allow all users to perform 'index' and 'view' actions
'actions'=>array('index'),
'users'=>array('ngnms'),
),
array('allow', // allow authenticated user to perform 'create' and 'update' actions
'actions'=>array('create','update','delete'),
'users'=>array('ngnms'),
),

array('deny',  // deny all users
'users'=>array('*'),
),
);
}


/**
* Creates a new model.
* If creation is successful, the browser will be redirected to the 'view' page.
*/
    public function actionCreate()
    {
        if (!Yii::app()->user->isGuest) {
            if (Yii::app()->user->checkAccess('editAssets')) {
                $model = new ScanException;
                if (isset($_POST['ScanException'])) {
                    $arr_1 = $this->checkCIDR($_POST['ScanException']['addr']);
                    $rmode = $arr_1['rmode'];
                    $phrase = $arr_1['phrase'];

                    if ($rmode > 0) {
                        $model->attributes = $_POST['ScanException'];
                        if ($model->save())
                            $this->redirect(array('index'));
                    } else {
                        Yii::app()->user->setFlash('exceptupdate', $phrase);
                        $this->refresh();
                    }
                }

                $this->render('create', array(
                    'model' => $model,
                ));
            } else {
                throw new CHttpException(403, 'Forbidden');
            }
        } else {
            $this->redirect('index.php?r=site/login');
        }
    }

/**
* Updates a particular model.
* If update is successful, the browser will be redirected to the 'view' page.
* @param integer $id the ID of the model to be updated
*/
public function actionUpdate($id)
{
    if (!Yii::app()->user->isGuest) {
        if (Yii::app()->user->checkAccess('editAssets')) {
            $model=$this->loadModel($id);

            if(isset($_POST['ScanException']))
            {
                $arr_1 = $this->checkCIDR($_POST['ScanException']['addr']);
                $rmode = $arr_1['rmode'];
                $phrase = $arr_1['phrase'];

                if($rmode > 0)
                {
                    $model->attributes=$_POST['ScanException'];
                    if($model->save())
                    $this->redirect(array('index'));
                }
                else
                {
                    Yii::app()->user->setFlash('exceptupdate', $phrase);
                    $this->refresh();
                }
            }

            $this->render('update',array(
            'model'=>$model,
            ));
        }
        else {
            throw new CHttpException(403, 'Forbidden');
        }
    } else {
        $this->redirect('index.php?r=site/login');
    }
}

/**
* Deletes a particular model.
* If deletion is successful, the browser will be redirected to the 'admin' page.
* @param integer $id the ID of the model to be deleted
*/
    public function actionDelete($id)
    {
        if (!Yii::app()->user->isGuest) {
            if (Yii::app()->user->checkAccess('editAssets')) {
                if (Yii::app()->request->isPostRequest) {
// we only allow deletion via POST request
                    $this->loadModel($id)->delete();

// if AJAX request (triggered by deletion via admin grid view), we should not redirect the browser
                    if (!isset($_GET['ajax']))
                        $this->redirect(isset($_POST['returnUrl']) ? $_POST['returnUrl'] : array('index'));
                } else
                    throw new CHttpException(400, 'Invalid request. Please do not repeat this request again.');
            } else {
                throw new CHttpException(403, 'Forbidden');
            }
        } else {
            $this->redirect('index.php?r=site/login');
        }
    }

    /**
* Lists all models.
*/

    public function actionIndex()
    {
        if (!Yii::app()->user->isGuest) {
            if (Yii::app()->user->checkAccess('editAssets')) {
                $model = new ScanException('search');
                $model->unsetAttributes(); // clear any default values
                if (isset($_GET['ScanException']))
                    $model->attributes = $_GET['ScanException'];

                $this->render('index', array(
                    'model' => $model,
                ));
            } else {
                throw new CHttpException(403, 'Forbidden');
            }
        } else {
            $this->redirect('index.php?r=site/login');
        }
    }


    /**
* Returns the data model based on the primary key given in the GET variable.
* If the data model is not found, an HTTP exception will be raised.
* @param integer the ID of the model to be loaded
*/
public function loadModel($id)
{
$model=ScanException::model()->findByPk($id);
if($model===null)
throw new CHttpException(404,'The requested page does not exist.');
return $model;
}

/**
* Performs the AJAX validation.
* @param CModel the model to be validated
*/
protected function performAjaxValidation($model)
{
if(isset($_POST['ajax']) && $_POST['ajax']==='scan-exception-form')
{
echo CActiveForm::validate($model);
Yii::app()->end();
}
}
    protected function checkCIDR($ip)
    {
        $phrase = '';
        $rmode = 1;

        if(empty($ip)  )
        {
            $rmode = 0;
            $phrase = 'Subnet is empty!';
        }
        else
        {
            $arr_subn = array();
            $arr_subn = explode('/',$ip);

            if(count($arr_subn) < 2)
            {
                $rmode = 0;
                $phrase = 'Subnet is not valid!';
            }
            else
            {

                $valid0 = preg_match('/^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\z/', $arr_subn[0]);
                if(!$valid0)
                {
                    $phrase .= 'Subnet is not valid!<br>';
                }

                if(is_numeric($arr_subn[1]) && $arr_subn[1]>0 && $arr_subn[1]<=32 )
                {
                    $ipLong = ip2long($arr_subn[0]);
                    $numIp = pow(2, 32 - $arr_subn[1]); // Number of IP addresses in range
                    $netmask = (~ ($numIp - 1)); // Network mask
                    $ipLongF = $ipLong & $netmask; // First IP address (even if given IP was not the first in the CIDR range)
                    if($ipLong != $ipLongF)
                    {
                        $valid1 = 0;
                        $phrase .= 'Value has bits set to right of mask!';
                    }
                    else
                    {
                        $valid1 = 1;
                    }
                }
                else
                {
                    $valid1 = 0;
                    $phrase .= 'Specified CIDR  is invalid (should be between 1 and 32)';
                }

                if(!$valid0 || !$valid1)
                {
                    $rmode = 0;
                }
            }

        }

        $arr_ret = array('rmode'=>$rmode,'phrase'=>$phrase);

        return $arr_ret;
    }
}
