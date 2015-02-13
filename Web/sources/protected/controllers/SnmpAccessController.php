<?php

class SnmpAccessController extends Controller
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
                'actions' => array('index', 'view', 'routerjoin', 'move'),
                'users' => array('admin','ngnms'),
            ),
            array('allow', // allow authenticated user to perform 'create' and 'update' actions
                'actions' => array('create', 'update'),
                'users' => array('admin','ngnms'),
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
    public function actionView()
    {
        $model = new SnmpAccess('search');
        $model->unsetAttributes(); // clear any default values
        if (isset($_GET['SnmpAccess']))
            $model->attributes = $_GET['Access'];


        $this->render('view', array(
            'model' => $model,
        ));
    }

    /**
     * Creates a new model.
     * If creation is successful, the browser will be redirected to the 'view' page.
     */
    public function actionCreate()
    {
        $model = new SnmpAccess;

// Uncomment the following line if AJAX validation is needed
// $this->performAjaxValidation($model);

        if (isset($_POST['SnmpAccess'])) {
            $model->attributes = $_POST['SnmpAccess'];
            if ($model->save())
                $this->redirect(array('index'));
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

        if (isset($_POST['SnmpAccess'])) {
            if (preg_match("/\*\*\*/i",$_POST['SnmpAccess']['community_ro']))
            {
                 $_POST['SnmpAccess']['community_ro']= trim(Cripto::decrypt($model->attributes['community_ro'])) ;
            }
            if (preg_match("/\*\*\*/i",$_POST['SnmpAccess']['community_rw']))
            {
                $_POST['SnmpAccess']['community_rw'] = trim(Cripto::decrypt($model->attributes['community_rw'])) ;
            }
            $model->attributes = $_POST['SnmpAccess'];

            if ($model->save())
                $this->redirect(array('index'));
        }

        $model->community_ro = trim(Cripto::hidedata(Cripto::decrypt($model->community_ro)));
        $model->community_rw = trim(Cripto::hidedata(Cripto::decrypt($model->community_rw)));
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
                $this->redirect(isset($_POST['returnUrl']) ? $_POST['returnUrl'] : array('index'));
        } else
            throw new CHttpException(400, 'Invalid request. Please do not repeat this request again.');
    }

    /**
     * Lists all models.
     */
    public function actionIndex()
    {
        $dataProvider = new CActiveDataProvider('SnmpAccess');
        $this->render('index', array(
            'dataProvider' => $dataProvider,
        ));
    }

    /**
     * Manages all models.
     */
    public function actionAdmin()
    {
        $model = new SnmpAccess('search');
        $model->unsetAttributes(); // clear any default values
        if (isset($_GET['SnmpAccess']))
            $model->attributes = $_GET['SnmpAccess'];

        $this->render('admin', array(
            'model' => $model,
        ));
    }


    /**
     * Manages access to routers .
     */
    public function actionRouterjoin()
    {
        $acc_type_id = Yii::app()->getRequest()->getParam('id');
        $router_access_model = new RouterSnmpAccess('search');
        $router_access_model->unsetAttributes();
        $router_access_model->snmp_access_id = $acc_type_id;

        $attr_all = CHtml::listData(Routers::getAll(), 'router_id', 'name');
        $attr_curr = CHtml::listData($router_access_model->getRouterByAccess(), 'router_id', 'name');
        $arr_d = array_diff($attr_all, $attr_curr);


        $this->render('snmp_access_router', array(
            'model' => $router_access_model,
            'attr_nocurr' => $arr_d,
            'attr_curr' => $attr_curr
        ));
    }

    /**
     * Connect routers to SNMP access
     *
     */
    public function actionMove()
    {
        $acc_id = $_POST['id_access'];

        if (isset($_POST['Attr']) && count($_POST['Attr']) > 0) {
            foreach ($_POST['Attr'] as $currattr) {
                if (RouterSnmpAccess::checkAttr($acc_id, $currattr) < 1) {
                    if (RouterSnmpAccess::checkUniqueRouterId($currattr) < 1) {
                        $att_acc = new RouterSnmpAccess();
                        $att_acc->snmp_access_id = $acc_id;
                        $att_acc->router_id = $currattr;
                        $att_acc->save();
                    }
                }
            }
        }

        if (isset($_POST['Attrn']) && count($_POST['Attrn']) > 0) {
            foreach ($_POST['Attrn'] as $attrn) {
                if (RouterSnmpAccess::checkAttr($acc_id, $attrn) > 0) {
                    RouterSnmpAccess::model()->deleteAll("snmp_access_id='" . $acc_id . "' AND router_id='" . $attrn . "'");
                }
            }
        }

        $this->actionView();
    }

    /**
     * Returns the data model based on the primary key given in the GET variable.
     * If the data model is not found, an HTTP exception will be raised.
     * @param integer the ID of the model to be loaded
     */
    public function loadModel($id)
    {
        $model = SnmpAccess::model()->findByPk($id);
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
        if (isset($_POST['ajax']) && $_POST['ajax'] === 'snmp-access-form') {
            echo CActiveForm::validate($model);
            Yii::app()->end();
        }
    }
}
