<?php
/* @var $this AttrController */
/* @var $dataProvider CActiveDataProvider */

$this->breadcrumbs=array(
	'Attrs',
);

$this->menu=array(
	array('label'=>'Create Attr', 'url'=>array('create')),
	array('label'=>'Manage Attr', 'url'=>array('admin')),
);
?>

<h1>Attrs</h1>

<?php $this->widget('zii.widgets.CListView', array(
	'dataProvider'=>$dataProvider,
	'itemView'=>'_view',
)); ?>
