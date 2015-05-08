<?php
/* @var $this AttrController */
/* @var $model Attr */

$this->breadcrumbs=array(
	'Attrs'=>array('index'),
	$model->name=>array('view','id'=>$model->id),
	'Update',
);

$this->menu=array(
	array('label'=>'List Attr', 'url'=>array('index')),
	array('label'=>'Create Attr', 'url'=>array('create')),
	array('label'=>'View Attr', 'url'=>array('view', 'id'=>$model->id)),
	array('label'=>'Manage Attr', 'url'=>array('admin')),
);
?>

<h1>Update Attr <?php echo $model->id; ?></h1>

<?php $this->renderPartial('_form', array('model'=>$model)); ?>