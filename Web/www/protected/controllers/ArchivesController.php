<?php

class ArchivesController extends Controller
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
                'actions' => array('create', 'update'),
                'users' => array('@'),
            ),
            array('allow', // allow admin user to perform 'admin' and 'delete' actions
                'actions' => array('admin', 'delete'),
                'users' => array('ngnms'),
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
        $model = new Archives;

// Uncomment the following line if AJAX validation is needed
// $this->performAjaxValidation($model);

        if (isset($_POST['Archives'])) {
            $model->attributes = $_POST['Archives'];
            if ($model->save())
                $this->redirect(array('view', 'id' => $model->archive_id));
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

// Uncomment the following line if AJAX validation is needed
// $this->performAjaxValidation($model);

        if (isset($_POST['Archives'])) {
            $model->attributes = $_POST['Archives'];
            if ($model->save())
                $this->redirect(array('view', 'id' => $model->archive_id));
        }

        $this->render('update', array(
            'model' => $model,
        ));
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
    public function actionIndex()
    {
        if (!Yii::app()->user->isGuest) {
            if (Yii::app()->user->checkAccess('editAssets')) {
                $baseUrl = Yii::app()->baseUrl;
                $cs = Yii::app()->clientScript;
                $cs->registerCssFile($baseUrl . '/css/bootstrap-switch.css');
                $cs->registerScriptFile(Yii::app()->baseUrl . '/js/libs/bootstrap-switch.js', CClientScript::POS_HEAD);
                $dataProvider = new CActiveDataProvider('Archives');
                $count = ArchiveConf::model()->count();

                if ($count > 0) {
                    $id_conf = 1;
                    $model1 = ArchiveConf::model()->findByPk($id_conf);
                } else {
                    $model1 = new ArchiveConf;
                }
                $this->render('index', array(
                    'model1' => $model1,
                    'dataProvider' => $dataProvider,
                ));
            } else {
                throw new CHttpException(403, 'Forbidden');
            }
        } else {
            $this->redirect('index.php?r=site/login');
        }
    }

    /**
     * Manages all models.
     */
    public function actionAdmin()
    {
        if (isset($_GET['act']) && isset($_GET['archive_id'])) {
            $cur_arc = $this->loadModel($_GET['archive_id']);
            chdir('/home/ngnms/NGREADY/archive/');
            #TODO Move archive restore to worker
            throw new \Exception("Web/www/protected/controllers/ArchivesController.php: Unimplemented");
            if ($_GET['act'] > 0) {
                $arr_attr = array();
                $str_1 = substr(Yii::app()->db->connectionString, 6);
                $arr1 = explode(";", $str_1);

                foreach ($arr1 as $key => $val) {
                    $arr2 = explode("=", $val);
                    $arr_attr[$arr2[0]] = $arr2[1];
                }
                $filename = $cur_arc->file_name;
                //check file is gzipped
                $gzipped = false;
                if (file_exists($filename.'.gz') ){
                    $filename .= '.gz';
                    $gzipped = true;
                }elseif(substr($filename,-3) === '.gz' && file_exists($filename)) {
                    $gzipped = true;
                }
                $filename = escapeshellarg($filename);
                if ($gzipped) {
                    $command1 = 'gunzip -c '. $filename .' 2>&1 | psql ' . $arr_attr['dbname']. ' 2>&1' ;
                }else{
                    $command1 = 'psql ' . $arr_attr['dbname'] . " -f " . $filename . ' 2>&1' ;
                }
                /**
                 * We use | to unzip, so escape will break command line.
                 * BTW we use only filenem as parameter, so its safe not to escape whole command
                 * and filename is already escaped
                 */
                //$escaped_command1 = escapeshellcmd($command1);
                $escaped_command1 = $command1;
                exec($escaped_command1,$output,$result);
                if ($result || count($output)){
                    Yii::app()->user->setFlash('error', "Command executin failed<br> ".$escaped_command1."<br> Result code: ".$result."<br>".join('<br>',$output));
                }else{
                    Yii::app()->user->setFlash('success', "File successfully loaded");
                    Yii::app()->db->createCommand()
                                  ->update('archives',
                                      array(
                                          'in_db' => 1,
                                      ),
                                      'archive_id=:archive_id',
                                      array(':archive_id' => $_GET['archive_id'])
                                  );
                }
            } else {
                Events::model()->deleteAll(
                    "receiver_ts >= :start_time AND  receiver_ts <= :end_time",
                    array(':start_time' => $cur_arc->start_time, ':end_time' => $cur_arc->end_time)
                );
                Yii::app()->db->createCommand()
                              ->update('archives',
                                  array(
                                      'in_db' => 0,
                                  ),
                                  'archive_id=:archive_id',
                                  array(':archive_id' => $_GET['archive_id'])
                              );
            }



        }

        $model = new Archives('search');
        $model->unsetAttributes(); // clear any default values

        if (isset($_GET['Archives']))
            $model->attributes = $_GET['Archives'];

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
        $model = Archives::model()->findByPk($id);
        if ($model === null)
            throw new CHttpException(404, 'The requested page does not exist.');
        return $model;
    }

    /**
     * Performs the AJAX validation.
     * @param CModel the model to be validated
     */
    protected function performAjaxValidation($model)
    {
        if (isset($_POST['ajax']) && $_POST['ajax'] === 'archives-form') {
            echo CActiveForm::validate($model);
            Yii::app()->end();
        }
    }
}
