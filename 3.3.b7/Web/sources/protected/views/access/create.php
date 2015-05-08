<?php
/* @var $this AccessController */
/* @var $model Access */

$this->breadcrumbs=array(
	'Accesses'=>array('index'),
	'Create',
);

$this->menu=array(
	array('label'=>'List Access', 'url'=>array('index')),
	array('label'=>'Manage Access', 'url'=>array('admin')),
);
?>

<h1>Create Access</h1>

<?php $this->renderPartial('_form', array('model'=>$model)); ?>