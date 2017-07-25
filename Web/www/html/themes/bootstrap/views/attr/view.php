<?php
/* @var $this AttrController */
/* @var $model Attr */

$this->breadcrumbs=array(
	'Attrs'=>array('index'),
	$model->name,
);

$this->menu=array(
	array('label'=>'List Attr', 'url'=>array('index')),
	array('label'=>'Create Attr', 'url'=>array('create')),
	array('label'=>'Update Attr', 'url'=>array('update', 'id'=>$model->id)),
	array('label'=>'Delete Attr', 'url'=>'#', 'linkOptions'=>array('submit'=>array('delete','id'=>$model->id),'confirm'=>'Are you sure you want to delete this item?')),
	array('label'=>'Manage Attr', 'url'=>array('admin')),
);
?>

<h1>View Attr #<?php echo $model->id; ?></h1>

<?php $this->widget('zii.widgets.CDetailView', array(
	'data'=>$model,
	'attributes'=>array(
		'id',
		'name',
	),
)); ?>
