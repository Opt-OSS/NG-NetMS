<?php

/**
 * User controller.
 *
 * Need to user signup actions & user account support.
 *
 * @author     Andrey Jaropud <ajaropud@opt-net.eu>
 * @package    application.controllers
 * @since      1.0.0
 */
class UserController extends Controller
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
		);
	}

	/**
	 * Displays a particular model.
	 * @param integer $id the ID of the model to be displayed
	 */
	public function actionView($id)
	{
		if (!Yii::app()->user->checkAccess('viewUsers')) {
			throw new CHttpException(403,'Forbidden');
		}
		$this->render('view',array(
			'model'=>$this->loadModel($id),
		));
	}

        public function actionEditusers()
        {
            if (!Yii::app()->user->isGuest) {
		if (!Yii::app()->user->checkAccess('viewUsers')) {
			throw new CHttpException(403,'Forbidden');
		}
                $model = new User('search');
                $model->unsetAttributes();
                if (isset($_GET['User']))
                    $model->attributes = $_GET['User'];
		$this->render('list',array(
			'model'=>$model,
		));
            }
            else 
            {
                $this->redirect('index.php?r=site/login');
            }
        }
	/**
	 * Creates a new model.
	 * If creation is successful, the browser will be redirected to the 'view' page.
	 */
	public function actionCreate()
	{
		if (!Yii::app()->user->checkAccess('createUser')) {
			throw new CHttpException(403,'Forbidden');
		}
		$model=new User;

		// Uncomment the following line if AJAX validation is needed
		// $this->performAjaxValidation($model);

		if(isset($_POST['User']))
		{

			$model->attributes=$_POST['User'];
			$pass = md5($model->password);
			$model->password = $pass;
			if($model->save())
				$this->redirect(array('view','id'=>$model->id));
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
		//check whether the user can edit this entry

		$model=$this->loadModel($id);
		$checkpass = $model->password;
                
		if (!Yii::app()->user->checkAccess('updateUser')
			&& !Yii::app()->user->checkAccess('updateOwnData', array('user'=>$model))) {
			throw new CHttpException(403,'Forbidden');
		}
		// Uncomment the following line if AJAX validation is needed
		// $this->performAjaxValidation($model);

		if(isset($_POST['User']))
		{
			$model->attributes=$_POST['User'];
                        
			if (empty($model->password)) {
                                $model->password  =  $checkpass;
                                $model->password_repeat = $checkpass;
			} else {
                            if($_POST['User']['old_password'] == $checkpass)
                            {
                                    $pass = md5($model->password);
                                    $model->password = $pass;
                                    $model->password_repeat = $pass;
                            }
                            else 
                            {                              
                                $model->password =  $checkpass;
                                $model->password_repeat = $checkpass;
                            }
			}
                        
			if($model->save())
                        {
                           $this->redirect(array('user/editusers'));
                        }
                        else{    
                            $debug = '<br/>ERROR :: couldnt add to DB Mark :<br />'.CHtml::errorSummary($model); 
                            echo $debug;
                        }
				
		}
                else
                {
                    $model->password = '';
                    $model->old_password = $checkpass;
                    $this->render('view',array(
                            'model'=>$model,
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
		if (!Yii::app()->user->checkAccess('deleteUser')) {
			throw new CHttpException(403,'Forbidden');
		}
		if(Yii::app()->request->isPostRequest)
		{
			// we only allow deletion via POST request
			$this->loadModel($id)->delete();

			// if AJAX request (triggered by deletion via admin grid view), we should not redirect the browser
			if(!isset($_GET['ajax']))
                        {
                            $model = new User('search');
                            $model->unsetAttributes();
                            $this->render('list',array(
			    'model'=>$model,
                                ));
                        }
		}
		else
			throw new CHttpException(400,'Invalid request. Please do not repeat this request again.');
	}

	/**
	 * Lists all models.
	 */
	public function actionIndex()
	{

		if (!Yii::app()->user->checkAccess('viewUsers')) {
			throw new CHttpException(403,'Forbidden');
		}

		$dataProvider=new CActiveDataProvider('User');
		$this->render('index',array(
			'dataProvider'=>$dataProvider,
		));
	}

	/**
	 * Manages all models.
	 */
	public function actionAdmin()
	{
		if (!Yii::app()->user->checkAccess('admin')) {
			throw new CHttpException(403,'Forbidden');
		}

		$model=new User('search');
		$model->unsetAttributes();  // clear any default values
		if(isset($_GET['User']))
			$model->attributes=$_GET['User'];

		$this->render('admin',array(
			'model'=>$model,
		));
	}

	/**
	 * Returns the data model based on the primary key given in the GET variable.
	 * If the data model is not found, an HTTP exception will be raised.
	 * @param integer the ID of the model to be loaded
	 */
	public function loadModel($id)
	{
		$model=User::model()->findByPk($id);
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
		if(isset($_POST['ajax']) && $_POST['ajax']==='user-form')
		{
			echo CActiveForm::validate($model);
			Yii::app()->end();
		}
	}
	public function actionAdduser()
	{
            if (!Yii::app()->user->checkAccess('createUser')) {
			throw new CHttpException(403,'Forbidden');
		}
		// Create new model with sign up scenario
		$user = new User(User::SCENARIO_SIGNUP);

		// There is data to save
		if(isset($_POST['User']))
		{
			// Safety define attributes
			$user->attributes = $_POST['User'];
			$decrypt_pass = $user->password;
			// Validation
			if($user->validate())
			{
				$pass = md5($decrypt_pass);
				$user->password = $pass;
				// Save data
				// need to repeate validation
				$user->save(false);

				// Redirect to login page
//				$this->redirect($this->createUrl('site/login'));
                                $this->redirect($this->createUrl('user/adduser'));
			}
			else
			{
				$user->password = $decrypt_pass;
			}
		}

		// Signup form
		$this->render('form_signup', array('model'=>$user));
	}
}
