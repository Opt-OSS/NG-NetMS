<?php
/**
 * The default srbac controller
 */
class DefaultController extends CController {
  /**
   * The default action if no route is specified
   */
	public function actionIndex() {
		//$this->render('index');
		$baseUrl = Yii::app()->baseUrl;
		$cs = Yii::app()->getClientScript();
		$cs->registerCssFile($baseUrl.'/themes/bootstrap/css/bootstrap.min.css');
    $this->redirect(array('authitem/frontpage'));
	}
 }