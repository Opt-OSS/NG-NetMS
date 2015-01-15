<?php
$this->breadcrumbs=array(
	'Router Snmp Accesses',
);

$this->menu=array(
array('label'=>'Create RouterSnmpAccess','url'=>array('create')),
array('label'=>'Manage RouterSnmpAccess','url'=>array('admin')),
);
?>

<h1>Router Snmp Accesses</h1>

<?php $this->widget('bootstrap.widgets.TbListView',array(
'dataProvider'=>$dataProvider,
'itemView'=>'_view',
)); ?>
