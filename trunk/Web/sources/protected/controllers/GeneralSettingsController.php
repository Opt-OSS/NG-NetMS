<?php

class GeneralSettingsController extends Controller
{
    /**
     * @var string the default layout for the views. Defaults to '//layouts/column2', meaning
     * using two-column layout. See 'protected/views/layouts/column2.php'.
     */
    public $layout = '//layouts/column2';

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
            array('allow', // allow all users to perform 'index' and 'view' actions
                'actions' => array('index', 'view'),
                'users' => array('*'),
            ),
            array('allow', // allow authenticated user to perform 'create' and 'update' actions
                'actions' => array('create', 'update','setperiod','getperiod'),
                'users' => array('@'),
            ),
            array('allow', // allow admin user to perform 'admin' and 'delete' actions
                'actions' => array('admin', 'delete'),
                'users' => array('admin','ngnms'),
            ),
            array('deny', // deny all users
                'users' => array('*'),
            ),
        );
    }

    /**
     * Displays a particular model.
     * @param integer $id the ID of the model to be displayed
     */
    public function actionView($id)
    {
        $this->render('view', array(
            'model' => $this->loadModel($id),
        ));
    }

    /**
     * Creates a new model.
     * If creation is successful, the browser will be redirected to the 'view' page.
     */
    public function actionCreate()
    {
        $model = new GeneralSettings;

// Uncomment the following line if AJAX validation is needed
// $this->performAjaxValidation($model);

        if (isset($_POST['GeneralSettings'])) {
            $model->attributes = $_POST['GeneralSettings'];
            if ($model->save())
                $this->redirect(array('admin', 'id' => $model->id));
        }

        $this->render('create', array(
            'model' => $model,
        ));
    }

    /**
     * Updates a particular model.
     * If update is successful, the browser will be redirected to the 'view' page.
     * @param integer $id the ID of the model to be updated
     */
    public function actionUpdate($id)
    {
        $model = $this->loadModel($id);

        if (isset($_POST['GeneralSettings'])) {
            $model = $this->loadModelUp($id);
            if (preg_match("/\*\*\*/i",$_POST['GeneralSettings']['value']))
            {
                $_POST['GeneralSettings']['value']= trim($model->attributes['value']) ;
            }
            $model->attributes = $_POST['GeneralSettings'];

            if ($model->save())
                $this->redirect(array('admin', 'id' => $model->id));
        }

        $this->render('update', array(
            'model' => $model,
        ));
    }

    public function actionSetperiod()
    {
        if (!Yii::app()->user->isGuest)
        {
            if (Yii::app()->request->isAjaxRequest && isset($_POST['label']))
            {
                $model = GeneralSettings::model()->findByAttributes(array('name'=>'perioddiscovery'));
                $arr_crontab = Yii::app()->params['cronperiods'];
                $ind = trim($_POST['label']);
                $scan = $_POST['scanner_t'];
                $model->value = $arr_crontab[$ind];
                if($model->save())
                {
                    $arr_attr=array();
                    $str_1 = substr(Yii::app()->db->connectionString,6);
                    $arr1 = explode(";",$str_1);

                    foreach($arr1 as $key=>$val)
                    {
                        $arr2 = explode("=",$val);
                        $arr_attr[$arr2[0]] = $arr2[1];
                    }

  chdir('/home/ngnms/NGREADY/bin/');
                    putenv("NGNMS_HOME=/home/ngnms/NGREADY");
                    putenv('NGNMS_CONFIGS=/home/ngnms/NGREADY/configs');
                    putenv('PATH=/home/ngnms/NGREADY/bin:/usr/bin');
                    putenv('PERL5LIB=/usr/local/share/perl/5.18.2:/home/ngnms/NGREADY/bin:/home/ngnms/NGREADY/lib:/home/ngnms/NGREADY/lib/Net');
                    putenv('MIBDIRS=/home/ngnms/NGREADY/mibs');


                    $arr_attr['username'] = Yii::app()->db->username;
                    $arr_attr['password'] = Yii::app()->db->password;



                    $command1 = '/usr/bin/perl scheduler.pl';
                    if($scan > 0)
                    {
                        $command1 .= ' -s ';
                    }

                    if(isset($arr_attr['host']) )
                    {
                        $command1 .= " -L ".$arr_attr['host'];
                    }

                    if(isset($arr_attr['dbname']) )
                    {
                        $command1 .= " -D ".$arr_attr['dbname'];
                    }

                    if(isset($arr_attr['username']))
                    {
                        $command1 .= " -U ".$arr_attr['username'];
                    }

                    if(isset($arr_attr['password']))
                    {
                        $command1 .= " -W ".$arr_attr['password'];
                    }

                    if(isset($arr_attr['port']))
                    {
                        $command1 .= " -P ".$arr_attr['port'];
                    }

                    $escaped_command1 = escapeshellcmd($command1);
                    $sss=system($escaped_command1);
                    $model0 = GeneralSettings::model()->findByAttributes(array('name'=>'scanner'));
                    $model0->value = $scan;
                    $model0->save();

                    $data = array("ok"=>1);
                }
                else
                {
                    $data = array("ok"=>0);
                }
                echo json_encode($data);
            }
        }
        else
        {
            $this->redirect('index.php?r=site/login');
        }
    }

    public function actionGetperiod()
    {
        if (!Yii::app()->user->isGuest)
        {
            if (Yii::app()->request->isAjaxRequest )
            {
                $model = GeneralSettings::model()->findByAttributes(array('name'=>'perioddiscovery'));
                $cur_disc = array_search($model->value, Yii::app()->params['cronperiods']);
                $data = array('label' => $cur_disc);
                echo json_encode($data);
            }
        }
        else
        {
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
        if (Yii::app()->request->isPostRequest) {
// we only allow deletion via POST request
            $this->loadModel($id)->delete();

// if AJAX request (triggered by deletion via admin grid view), we should not redirect the browser
            if (!isset($_GET['ajax']))
                $this->redirect(isset($_POST['returnUrl']) ? $_POST['returnUrl'] : array('admin'));
        } else
            throw new CHttpException(400, 'Invalid request. Please do not repeat this request again.');
    }

    /**
     * Lists all models.
     */
 /*   public function actionIndex()
    {
        $dataProvider = new CActiveDataProvider('GeneralSettings');
        $this->render('index', array(
            'dataProvider' => $dataProvider,
        ));
    }*/

    /**
     * Manages all models.
     */
    public function actionAdmin()
    {
        $model = new GeneralSettings('search');
        $model->unsetAttributes(); // clear any default values
        if (isset($_GET['GeneralSettings']))
            $model->attributes = $_GET['GeneralSettings'];


        $this->render('admin', array(
            'model' => $model,
        ));
    }

    /**
     * Returns the data model based on the primary key given in the GET variable.
     * If the data model is not found, an HTTP exception will be raised.
     * @param integer the ID of the model to be loaded
     */
    public function loadModel($id)
    {
        $model = GeneralSettings::model()->findByPk($id);
        if ($model === null)
            throw new CHttpException(404, 'The requested page does not exist.');
        if($model->name !='chiave' && $model->name !='perioddiscovery' &&  $model->name !='scanner')
        {
            if (preg_match("/password/i",$model->name) || preg_match("/community/i",$model->name))
            {
                $model->value = trim(Cripto::hidedata($model->value));
            }
            else
            {
                $model->value = trim(Cripto::decrypt($model->value));
            }
        }
        return $model;
    }

    public function loadModelUp($id)
    {
        $model = GeneralSettings::model()->findByPk($id);
        if ($model === null)
            throw new CHttpException(404, 'The requested page does not exist.');
        if($model->name !='chiave' && $model->name !='perioddiscovery' &&  $model->name !='scanner')
        {
                $model->value = trim(Cripto::decrypt($model->value));
        }
        return $model;
    }

    /**
     * Performs the AJAX validation.
     * @param CModel the model to be validated
     */
    protected function performAjaxValidation($model)
    {
        if (isset($_POST['ajax']) && $_POST['ajax'] === 'general-settings-form') {
            echo CActiveForm::validate($model);
            Yii::app()->end();
        }
    }
}
