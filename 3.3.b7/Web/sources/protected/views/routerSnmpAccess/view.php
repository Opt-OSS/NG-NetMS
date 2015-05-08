<?php
$this->breadcrumbs=array(
	'Router Snmp Accesses'=>array('index'),
	$model->id,
);

$this->menu=array(
array('label'=>'List RouterSnmpAccess','url'=>array('index')),
array('label'=>'Create RouterSnmpAccess','url'=>array('create')),
array('label'=>'Update RouterSnmpAccess','url'=>array('update','id'=>$model->id)),
array('label'=>'Delete RouterSnmpAccess','url'=>'#','linkOptions'=>array('submit'=>array('delete','id'=>$model->id),'confirm'=>'Are you sure you want to delete this item?')),
array('label'=>'Manage RouterSnmpAccess','url'=>array('admin')),
);
?>

<h1>View RouterSnmpAccess #<?php echo $model->id; ?></h1>

<?php $this->widget('bootstrap.widgets.TbDetailView',array(
'data'=>$model,
'attributes'=>array(
		'id',
		'router_id',
		'snmp_access_id',
),
)); ?>
