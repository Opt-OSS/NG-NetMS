<?php

class AccessTypeController extends Controller
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
				'actions'=>array('create','update','edit','move'),
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
	 * Displays a particular model.
	 * @param integer $id the ID of the model to be displayed
	 */
	public function actionView($id)
	{
		$this->render('view',array(
			'model'=>$this->loadModel($id),
		));
	}

	/**
	 * Creates a new model.
	 * If creation is successful, the browser will be redirected to the 'view' page.
	 */
	public function actionCreate()
	{
		$model=new AccessType;

		// Uncomment the following line if AJAX validation is needed
		// $this->performAjaxValidation($model);

		if(isset($_POST['AccessType']))
		{
			$model->attributes=$_POST['AccessType'];
			if($model->save())
				$this->redirect(array('index'));
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

		if(isset($_POST['AccessType']))
		{
			$model->attributes=$_POST['AccessType'];
			if($model->save())
				$this->redirect(array('index'));
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
		$dataProvider=new CActiveDataProvider('AccessType');
		$this->render('index',array(
			'dataProvider'=>$dataProvider,
		));
	}

	/**
	 * Manages all models.
	 */
	public function actionAdmin()
	{
		$model=new AccessType('search');
		$model->unsetAttributes();  // clear any default values
		if(isset($_GET['AccessType']))
			$model->attributes=$_GET['AccessType'];

		$this->render('admin',array(
			'model'=>$model,
		));
	}

    /**
     * Manages attributes of access type .
     */
    public function actionEdit()
    {
        $acc_type_id =(int) Yii::app()->getRequest()->getParam('id');
        $model=new AccessType('search');
        $model->unsetAttributes();  // clear any default values

/*        if(isset($_GET['AccessType']))
            $model->attributes=$_GET['AccessType'];*/
        $model->id = $acc_type_id;

        $attr_access_model = new AttrAccess('search');
        $attr_access_model->unsetAttributes();
        $attr_access_model->id_access_type = $acc_type_id;

        $attr_all = CHtml::listData(Attr::getAll(),'id','name');
        $attr_curr = CHtml::listData($attr_access_model->getAttrByAccType(),'id','name');
        $arr_d = array_diff($attr_all,$attr_curr);


        $this->render('access_attr',array(
            'model'=>$model,
            'attr_nocurr'=>$arr_d,
            'attr_curr'=>$attr_curr
        ));
    }

    /**
     * Connect and reconnect attributes to access type
     */
    public function actionMove()
    {
        $acc_t = $_POST['id'];

        if(isset($_POST['Attr']) && count($_POST['Attr']) >0 )
        {
            foreach($_POST['Attr'] as $currattr)
            {
                if(AttrAccess::checkAttr($acc_t,$currattr) < 1)
                {
                    $att_acc = new AttrAccess();
                    $att_acc->id_access_type = $acc_t;
                    $att_acc->id_attr = $currattr;
                    $att_acc->save();
                }
            }
        }

        if(isset($_POST['Attrn']) && count($_POST['Attrn']) >0 )
        {
            foreach($_POST['Attrn'] as $attrn)
            {
                if(AttrAccess::checkAttr($acc_t,$attrn) > 0)
                {
                    AttrAccess::model()->deleteAll("id_access_type='" . $acc_t . "' AND id_attr='".$attrn."'");
                }
            }
        }

        $this->actionAdmin();
    }

	/**
	 * Returns the data model based on the primary key given in the GET variable.
	 * If the data model is not found, an HTTP exception will be raised.
	 * @param integer $id the ID of the model to be loaded
	 * @return AccessType the loaded model
	 * @throws CHttpException
	 */
	public function loadModel($id)
	{
		$model=AccessType::model()->findByPk($id);
		if($model===null)
			throw new CHttpException(404,'The requested page does not exist.');
		return $model;
	}

	/**
	 * Performs the AJAX validation.
	 * @param AccessType $model the model to be validated
	 */
	protected function performAjaxValidation($model)
	{
		if(isset($_POST['ajax']) && $_POST['ajax']==='access-type-form')
		{
			echo CActiveForm::validate($model);
			Yii::app()->end();
		}
	}
}
