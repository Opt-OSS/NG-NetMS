<?php
/* @var $this AccessTypeController */
/* @var $model AccessType */

$this->breadcrumbs=array(
	'Access Types'=>array('index'),
	$model->name,
);

$this->menu=array(
	array('label'=>'List AccessType', 'url'=>array('index')),
	array('label'=>'Create AccessType', 'url'=>array('create')),
	array('label'=>'Update AccessType', 'url'=>array('update', 'id'=>$model->id)),
	array('label'=>'Delete AccessType', 'url'=>'#', 'linkOptions'=>array('submit'=>array('delete','id'=>$model->id),'confirm'=>'Are you sure you want to delete this item?')),
	array('label'=>'Manage AccessType', 'url'=>array('admin')),
);
?>

<h1>View AccessType #<?php echo $model->id; ?></h1>

<?php $this->widget('zii.widgets.CDetailView', array(
	'data'=>$model,
	'attributes'=>array(
		'id',
		'name',
	),
)); ?>
