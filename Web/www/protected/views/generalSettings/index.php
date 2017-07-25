<?php
$this->breadcrumbs=array(
	'General Settings',
);

$this->menu=array(
array('label'=>'Create GeneralSettings','url'=>array('create')),
array('label'=>'Manage GeneralSettings','url'=>array('admin')),
);
?>

<h1>General Settings</h1>

<?php $this->widget('bootstrap.widgets.TbListView',array(
'dataProvider'=>$dataProvider,
'itemView'=>'_view',
)); ?>
