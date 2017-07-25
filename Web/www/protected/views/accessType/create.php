<?php
/* @var $this AccessTypeController */
/* @var $model AccessType */

$this->breadcrumbs=array(
	'Access Types'=>array('index'),
	'Create',
);

$this->menu=array(
	array('label'=>'List AccessType', 'url'=>array('index')),
	array('label'=>'Manage AccessType', 'url'=>array('admin')),
);
?>

<h1>Create AccessType</h1>

<?php $this->renderPartial('_form', array('model'=>$model)); ?>