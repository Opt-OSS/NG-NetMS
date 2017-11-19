<?php

class AccessController extends Controller
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
			'postOnly + delete', // we only allow deletion via POST request
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
				'actions'=>array('index','view'),
				'users'=>array('@'),
			),
			array('allow', // allow authenticated user to perform 'create' and 'update' actions
				'actions'=>array('create','update','routerjoin','move'),
				'users'=>array('admin','ngnms'),
			),
			array('allow', // allow admin user to perform 'admin' and 'delete' actions
				'actions'=>array('admin','delete'),
				'users'=>array('admin','ngnms'),
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
		$model=new Access;

		// Uncomment the following line if AJAX validation is needed
		// $this->performAjaxValidation($model);

		if(isset($_POST['Access']))
		{
			$model->attributes=$_POST['Access'];
			if($model->save())
                $this->redirect(Yii::app()->controller->createUrl("attrValue/create", array("id"=>$model->id,"id_access_type"=>$model->id_access_type)));
		}

		$this->render('create',array(
			'model'=>$model,
		));
	}

	/**
	 * Updates a particular model.
	 * If update is successful, the browser will be redirected to the 'view' page.
	 * @param integer $id the ID of the model to be updated
	 */
	public function actionUpdate($id)
	{
		$model=$this->loadModel($id);

		// Uncomment the following line if AJAX validation is needed
		// $this->performAjaxValidation($model);

		if(isset($_POST['Access']))
		{
			$model->attributes=$_POST['Access'];
			if($model->save())
				$this->redirect(array('view','id'=>$model->id));
		}

		$this->render('update',array(
			'model'=>$model,
		));
	}

	/**
	 * Deletes a particular model.
	 * If deletion is successful, the browser will be redirected to the 'admin' page.
	 * @param integer $id the ID of the model to be deleted
	 */
	public function actionDelete($id)
	{
		$this->loadModel($id)->delete();

		// if AJAX request (triggered by deletion via admin grid view), we should not redirect the browser
		if(!isset($_GET['ajax']))
			$this->redirect(isset($_POST['returnUrl']) ? $_POST['returnUrl'] : array('admin'));
	}

	/**
	 * Lists all models.
	 */
	public function actionIndex()
	{
        $model=new Access('search');
        $model->unsetAttributes();  // clear any default values
        if(isset($_GET['Access']))
            $model->attributes=$_GET['Access'];


        $this->render('index',array(
            'model'=>$model,
        ));
	}


    /**
     * Lists all models.
     */
    public function actionView()
    {
        $model=new Access('search');
        $model->unsetAttributes();  // clear any default values
        if(isset($_GET['Access']))
            $model->attributes=$_GET['Access'];


        $this->render('view',array(
            'model'=>$model,
        ));
    }

    /**
	 * Manages all models.
	 */
	public function actionAdmin()
	{
		$model=new Access('search');
		$model->unsetAttributes();  // clear any default values
		if(isset($_GET['Access']))
			$model->attributes=$_GET['Access'];


		$this->render('admin',array(
			'model'=>$model,
		));
	}

    /**
     * Manages access to routers .
     */
    public function actionRouterjoin()
    {
        $acc_type_id = (int)Yii::app()->getRequest()->getParam('id');


        //standard devices
        $router_access_model = new RouterAccess('search');
        $router_access_model->unsetAttributes();
        $router_access_model->id_access = $acc_type_id;
        $attr_all = CHtml::listData(Routers::getAll(),'router_id','name');
        $attr_curr = CHtml::listData($router_access_model->getRouterByAccess(),'router_id','name');
        natsort($attr_curr);
        $arr_d = array_diff($attr_all,$attr_curr);
        natsort($arr_d);
        //BGP neighbors
//        $bgp_router_access_model = new BgpRouterAccess('search');
//        $bgp_router_access_model->unsetAttributes();
//        $bgp_router_access_model->id_access = $acc_type_id;
//        $bgp_attr_all = CHtml::listData(BgpRouters::getAll(),'id','ip_addr');
//        $bgp_attr_curr = CHtml::listData($bgp_router_access_model->getRouterByAccess(),'id','ip_addr');
//        natsort($bgp_attr_curr);
//        $bgp_arr_d = array_diff($bgp_attr_all,$bgp_attr_curr);
//        natsort($bgp_arr_d);

        $this->render('access_router',array(
            'model'=>$router_access_model,
            'attr_nocurr'=>$arr_d,
            'attr_curr'=>$attr_curr,

//            'bgp_model'=>$bgp_router_access_model,
//            'bgp_attr_nocurr'=>$bgp_arr_d,
//            'bgp_attr_curr'=>$bgp_attr_curr
        ));
    }

    /**
     * Connect and reconnect  routers  to access
     */
    public function actionMove()
    {
        $acc_id = $_POST['id_access'];
        //standard devices
        if(isset($_POST['Attr']) && count($_POST['Attr']) >0 )
        {
            foreach($_POST['Attr'] as $currattr)
            {
                if(RouterAccess::checkAttr($acc_id,$currattr) < 1)
                {
                    $att_acc = new RouterAccess();
                    $att_acc->id_access = $acc_id;
                    $att_acc->id_router = $currattr;
                    $att_acc->save();
                }
            }
        }

        if(isset($_POST['Attrn']) && count($_POST['Attrn']) >0 )
        {
            foreach($_POST['Attrn'] as $attrn)
            {
                if(RouterAccess::checkAttr($acc_id,$attrn) > 0)
                {
                    RouterAccess::model()->deleteAll("id_access='" . $acc_id . "' AND id_router='".$attrn."'");
                }
            }
        }
        //BGP neighbors
        if(!empty($_POST['bgp_Attr']) )
        {
            foreach($_POST['bgp_Attr'] as $currattr)
            {
                if(BgpRouterAccess::checkAttr($acc_id,$currattr) < 1)
                {
                    $att_acc = new BgpRouterAccess();
                    $att_acc->id_access = $acc_id;
                    $att_acc->id_router = $currattr;
                    $att_acc->save();
                }
            }
        }

        if(!empty($_POST['bgp_Attrn']))
        {
            foreach($_POST['bgp_Attrn'] as $attrn)
            {
                if(BgpRouterAccess::checkAttr($acc_id,$attrn) > 0)
                {
                    BgpRouterAccess::model()->deleteAll("id_access='" . $acc_id . "' AND id_router='".$attrn."'");
                }
            }
        }
        $this->actionView();
    }

	/**
	 * Returns the data model based on the primary key given in the GET variable.
	 * If the data model is not found, an HTTP exception will be raised.
	 * @param integer $id the ID of the model to be loaded
	 * @return Access the loaded model
	 * @throws CHttpException
	 */
	public function loadModel($id)
	{
		$model=Access::model()->findByPk($id);
		if($model===null)
			throw new CHttpException(404,'The requested page does not exist.');
		return $model;
	}

	/**
	 * Performs the AJAX validation.
	 * @param Access $model the model to be validated
	 */
	protected function performAjaxValidation($model)
	{
		if(isset($_POST['ajax']) && $_POST['ajax']==='access-form')
		{
			echo CActiveForm::validate($model);
			Yii::app()->end();
		}
	}
}
