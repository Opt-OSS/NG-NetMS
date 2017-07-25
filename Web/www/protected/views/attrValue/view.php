<?php
/* @var $this AttrValueController */
/* @var $model AttrValue */

$this->breadcrumbs=array(
	'Attr Values'=>array('index'),
	$model->id,
);

$this->menu=array(
	array('label'=>'List AttrValue', 'url'=>array('index')),
	array('label'=>'Create AttrValue', 'url'=>array('create')),
	array('label'=>'Update AttrValue', 'url'=>array('update', 'id'=>$model->id)),
	array('label'=>'Delete AttrValue', 'url'=>'#', 'linkOptions'=>array('submit'=>array('delete','id'=>$model->id),'confirm'=>'Are you sure you want to delete this item?')),
	array('label'=>'Manage AttrValue', 'url'=>array('admin')),
);
?>

<h1>View AttrValue #<?php echo $model->id; ?></h1>

<?php $this->widget('zii.widgets.CDetailView', array(
	'data'=>$model,
	'attributes'=>array(
		'id',
		'id_attr_access',
		'id_access',
		'value',
	),
)); ?>
