<?php
$this->breadcrumbs=array(
	'General Settings'=>array('admin'),
	$model->name,
);

$this->menu=array(
array('label'=>'Create General Settings','url'=>array('create')),
array('label'=>'Update General Settings','url'=>array('update','id'=>$model->id)),
array('label'=>'Delete GeneralSettings','url'=>'#','linkOptions'=>array('submit'=>array('delete','id'=>$model->id),'confirm'=>'Are you sure you want to delete this item?')),
array('label'=>'Manage GeneralSettings','url'=>array('admin')),
);
?>

<h1>View GeneralSettings #<?php echo $model->id; ?></h1>

<?php $this->widget('bootstrap.widgets.TbDetailView',array(
'data'=>$model,
'attributes'=>array(
		'id',
		'name',
		'value',
),
)); ?>
