<?php
/* @var $this AttrValueController */
/* @var $dataProvider CActiveDataProvider */

$this->breadcrumbs=array(
	'Attr Values',
);

$this->menu=array(
	array('label'=>'Create AttrValue', 'url'=>array('create')),
	array('label'=>'Manage AttrValue', 'url'=>array('admin')),
);
?>

<h1>Attr Values</h1>

<?php $this->widget('zii.widgets.CListView', array(
	'dataProvider'=>$dataProvider,
	'itemView'=>'_view',
)); ?>
