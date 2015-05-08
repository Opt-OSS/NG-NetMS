<?php
/* @var $this AttrValueController */
/* @var $model AttrValue */

$this->breadcrumbs=array(
	'Attr Values'=>array('index'),
	'Create',
);

$this->menu=array(
	array('label'=>'List AttrValue', 'url'=>array('index')),
	array('label'=>'Manage AttrValue', 'url'=>array('admin')),
);
?>

<h1>Create AttrValue</h1>

<?php $this->renderPartial('_form', array('model'=>$model)); ?>