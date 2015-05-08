<?php
/* @var $this RoutersController */
/* @var $model Routers */

$this->breadcrumbs=array(
	'Devices'=>array('index'),
	'Create',
);


?>

<h1>Create Device Manually</h1>

<?php $this->renderPartial('_form', array('model'=>$model)); ?>