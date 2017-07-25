<?php
/* @var $this AccessController */
/* @var $model Access */

$this->breadcrumbs=array(
	'Accesses'=>array('index'),
	$model->name,
);

$this->menu=array(
	array('label'=>'List Access', 'url'=>array('index')),
	array('label'=>'Create Access', 'url'=>array('create')),
	array('label'=>'Update Access', 'url'=>array('update', 'id'=>$model->id)),
	array('label'=>'Delete Access', 'url'=>'#', 'linkOptions'=>array('submit'=>array('delete','id'=>$model->id),'confirm'=>'Are you sure you want to delete this item?')),
	array('label'=>'Manage Access', 'url'=>array('admin')),
);
?>

<h1>View Access #<?php echo $model->id; ?></h1>

<?php $this->widget('zii.widgets.CDetailView', array(
	'data'=>$model,
	'attributes'=>array(
		'id',
		'name',
		'id_access_type',
	),
)); ?>
