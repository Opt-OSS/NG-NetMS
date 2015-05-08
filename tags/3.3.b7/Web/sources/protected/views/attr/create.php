<?php
/* @var $this AttrController */
/* @var $model Attr */

$this->breadcrumbs=array(
	'Attrs'=>array('index'),
	'Create',
);

$this->menu=array(
	array('label'=>'List Attr', 'url'=>array('index')),
	array('label'=>'Manage Attr', 'url'=>array('admin')),
);
?>

<h1>Create Attr</h1>

<?php $this->renderPartial('_form', array('model'=>$model)); ?>