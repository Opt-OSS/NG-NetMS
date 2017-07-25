<?php
/* @var $this AccessController */
/* @var $dataProvider CActiveDataProvider */

$this->breadcrumbs=array(
	'Accesses',
);

$this->menu=array(
	array('label'=>'Create Access', 'url'=>array('create')),
	array('label'=>'Manage Access', 'url'=>array('admin')),
);
?>

<h1>Accesses</h1>

<?php $this->widget('zii.widgets.CListView', array(
	'dataProvider'=>$dataProvider,
	'itemView'=>'_view',
)); ?>
