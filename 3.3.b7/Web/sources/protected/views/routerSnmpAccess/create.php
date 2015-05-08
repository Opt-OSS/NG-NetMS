<?php
$this->breadcrumbs=array(
	'Router Snmp Accesses'=>array('index'),
	'Create',
);

$this->menu=array(
array('label'=>'List RouterSnmpAccess','url'=>array('index')),
array('label'=>'Manage RouterSnmpAccess','url'=>array('admin')),
);
?>

<h1>Create RouterSnmpAccess</h1>

<?php echo $this->renderPartial('_form', array('model'=>$model)); ?>