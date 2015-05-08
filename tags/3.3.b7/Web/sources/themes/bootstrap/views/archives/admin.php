<?php
$this->breadcrumbs=array(
	'Archive Manager'=>array('index'),
	'Manage Archives',
);

?>

<h1>Manage Archives</h1>


<?php $this->widget('bootstrap.widgets.TbGridView',array(
'id'=>'archives-grid',
'dataProvider'=>$model->search(),
'filter'=>$model,
'columns'=>array(
		'archive_id',
		'start_time',
		'end_time',
		'file_name',
		'in_db',
array(
'class'=>'bootstrap.widgets.TbButtonColumn',
),
),
)); ?>
