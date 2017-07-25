<?php
/* @var $this RoutersController */
/* @var $model Routers */

$this->breadcrumbs=array(
	'Routers'=>array('index'),
	'Create',
);

$this->menu=array(
	array('label'=>'List Routers', 'url'=>array('index')),
	array('label'=>'Manage Routers', 'url'=>array('admin')),
);
?>

<h1>Create Routers</h1>

<?php $this->renderPartial('_form', array('model'=>$model)); ?>