<?php
$this->breadcrumbs=array(
	'Router Snmp Accesses'=>array('index'),
	$model->id=>array('view','id'=>$model->id),
	'Update',
);

	$this->menu=array(
	array('label'=>'List RouterSnmpAccess','url'=>array('index')),
	array('label'=>'Create RouterSnmpAccess','url'=>array('create')),
	array('label'=>'View RouterSnmpAccess','url'=>array('view','id'=>$model->id)),
	array('label'=>'Manage RouterSnmpAccess','url'=>array('admin')),
	);
	?>

	<h1>Update RouterSnmpAccess <?php echo $model->id; ?></h1>

<?php echo $this->renderPartial('_form',array('model'=>$model)); ?>