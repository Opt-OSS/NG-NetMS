<?php

class AttrValueController extends Controller
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
				'users'=>array('*'),
			),
			array('allow', // allow authenticated user to perform 'create' and 'update' actions
				'actions'=>array('create','update'),
				'users'=>array('@'),
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


		// Uncomment the following line if AJAX validation is needed
		// $this->performAjaxValidation($model);

		if(isset($_POST['AttrValue']))
		{
            $ammount = count($_POST['AttrValue']);

            for($i=0;$i<$ammount;$i++)
            {
                $model=new AttrValue;
                $model->unsetAttributes();
                $model->id_access= $_POST['AttrValue'][$i]['id_access'];
                $model->id_attr_access = $_POST['id_attr_access'][$i];
                $model->value= Cripto::encrypt($_POST['AttrValue'][$i]['value']);
                $model->save();
            }
                $this->redirect(Yii::app()->controller->createUrl("access/index"));
		}
        else
        {
            $model=new AttrValue;
            $id_acc =(int) Yii::app()->getRequest()->getParam('id');
            $id_acc_type = (int)Yii::app()->getRequest()->getParam('id_access_type');
            $model->id_access = $id_acc;
            $arr_attrs = AttrAccess::model()->getListAttrByAccType($id_acc_type);
            $amount = count($arr_attrs);
            for($i = 0;$i < $amount;$i++)
            {
                if(isset($arr_attrs[$i]['value']))
                {
                    $arr_attrs[$i]['value'] = trim(Cripto::decrypt($arr_attrs[$i]['value']));
                }
            }
            $this->render('update',array(
                'model'=>$model,
                'arr_attrs'=>$arr_attrs,
                'id_acc'=>$id_acc,
                'id_acc_type'=>$id_acc_type
            ));
        }

	}

	/**
	 * Updates a particular model.
	 * If update is successful, the browser will be redirected to the 'view' page.
	 * @param integer $id the ID of the model to be updated
	 */
	public function actionUpdate($id)
	{
	/*	$model=$this->loadModel($id);

		// Uncomment the following line if AJAX validation is needed
		// $this->performAjaxValidation($model);

		if(isset($_POST['AttrValue']))
		{
			$model->attributes=$_POST['AttrValue'];
			if($model->save())
				$this->redirect(array('view','id'=>$model->id));
		}

		$this->render('update',array(
			'model'=>$model,
		));*/
        if(isset($_POST['AttrValue']))
        {
            $ammount = count($_POST['AttrValue']);

            for($i=0;$i<$ammount;$i++)
            {
                $model=new AttrValue;
                $model->unsetAttributes();
                $model->id_access= $_POST['AttrValue'][$i]['id_access'];
                $model->id_attr_access = $_POST['id_attr_access'][$i];
//                $model->value= $_POST['AttrValue'][$i]['value'];
                $pks = $model->checkValueAttr();

                if($pks>0)
                {
                    if (preg_match("/\*\*\*/i",$_POST['AttrValue'][$i]['value']))
                    {
                        $model_av = $this->loadModel($pks);
                        $_POST['AttrValue'][$i]['value'] = trim(Cripto::decrypt($model_av->attributes['value'])) ;
                    }
                    AttrValue::model()->updateByPk($pks,  array('value'=>Cripto::encrypt($_POST['AttrValue'][$i]['value'])));
                }
                else
                {
                    $model->value=Cripto::encrypt($_POST['AttrValue'][$i]['value']);
                    $model->save();
                }
            }
            $this->redirect(Yii::app()->controller->createUrl("access/index"));
        }
        else
        {
            $model=new AttrValue;
            $id_acc =(int) Yii::app()->getRequest()->getParam('id');
            $id_acc_type =(int) Yii::app()->getRequest()->getParam('id_access_type');
            $model->id_access = $id_acc;
            $arr_attrs = AttrAccess::model()->getListAttrValByAccType($id_acc_type,$id_acc);
            $amount = count($arr_attrs);

            for($i = 0;$i < $amount;$i++)
            {
                if(empty($arr_attrs[$i]['value']))
                {
                    $arr_attrs[$i]['value'] ='';
                }
                else
                {
                    $arr_attrs[$i]['value'] = trim(Cripto::decrypt($arr_attrs[$i]['value']));

                   if (preg_match("/password/i",$arr_attrs[$i]['name']))
                    {
                        $arr_attrs[$i]['value'] = Cripto::hidedata($arr_attrs[$i]['value']);
                    }
                }
            }

            $model->search();
            $this->render('update',array(
                'model'=>$model,
                'arr_attrs'=>$arr_attrs,
                'id_acc'=>$id_acc,
                'id_acc_type'=>$id_acc_type
            ));
        }
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
	 * Lists all models for definded access.
	 */
    public function actionIndex()
    {
        $acc_id = (int) Yii::app()->getRequest()->getParam('id');
        $acc_id = (int)$acc_id;
        $attr_val = new AttrValue('search');
        $attr_val->unsetAttributes();
        $attr_val->id_access = $acc_id;
        $arr_r = $attr_val->getAttrValByAccId();
        $amount1 = count($arr_r);
        $arr_ing = array();


        for ($k1 = 0; $k1 < $amount1; $k1++) {
            if($arr_r[$k1]['id']  || empty($arr_r[$k1]['value']))
            {
                $arr_ing[$k1]['id'] = $k1+1;
                $arr_ing[$k1]['name'] = $arr_r[$k1]['name'];
                $arr_ing[$k1]['value'] = Cripto::decrypt($arr_r[$k1]['value']);
                if (preg_match("/password/i",$arr_r[$k1]['name']))
                {
                    $arr_ing[$k1]['value'] = Cripto::hidedata($arr_ing[$k1]['value']);
                }
            }
        }

        $this->renderPartial('_relational', array(
            'id' => $acc_id,
            'gridDataProvider' => new CArrayDataProvider($arr_ing),
            'gridColumns' => array(array('name' => 'id', 'header' => '#','value' => '$data["id"]','htmlOptions'=>array('width'=>'10%'),),
                array('name' => 'name', 'header' => 'Name', 'type' => 'raw', 'value' => '$data["name"]','htmlOptions'=>array('width'=>'25%'),),
                array('name' => 'value', 'header' => 'Value', 'type' => 'raw', 'value' => '$data["value"]','htmlOptions'=>array('width'=>'65%'),),
            )
        ));
    }

	/**
	 * Manages all models.
	 */
	public function actionAdmin()
	{
		$model=new AttrValue('search');
		$model->unsetAttributes();  // clear any default values
		if(isset($_GET['AttrValue']))
			$model->attributes=$_GET['AttrValue'];

		$this->render('admin',array(
			'model'=>$model,
		));
	}

	/**
	 * Returns the data model based on the primary key given in the GET variable.
	 * If the data model is not found, an HTTP exception will be raised.
	 * @param integer $id the ID of the model to be loaded
	 * @return AttrValue the loaded model
	 * @throws CHttpException
	 */
	public function loadModel($id)
	{
		$model=AttrValue::model()->findByPk($id);
		if($model===null)
			throw new CHttpException(404,'The requested page does not exist.');
		return $model;
	}

	/**
	 * Performs the AJAX validation.
	 * @param AttrValue $model the model to be validated
	 */
	protected function performAjaxValidation($model)
	{
		if(isset($_POST['ajax']) && $_POST['ajax']==='attr-value-form')
		{
			echo CActiveForm::validate($model);
			Yii::app()->end();
		}
	}
}
