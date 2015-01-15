<?php
/* @var $this RoutersController */
/* @var $model Routers */

$this->breadcrumbs=array(
	'Routers'=>array('index'),
	'Create',
);


?>

<h1>Create Router Manually</h1>

<?php $this->renderPartial('_form', array('model'=>$model)); ?>