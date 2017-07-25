<?php
$this->breadcrumbs=array(
	'General Settings',
);

$this->menu=array(
array('label'=>'Create General Settings','url'=>array('create')),
array('label'=>'Manage General Settings','url'=>array('admin')),
);
?>

<h1>General Settings</h1>

<?php $this->widget('bootstrap.widgets.TbListView',array(
'dataProvider'=>$dataProvider,
'itemView'=>'_view',
)); ?>
