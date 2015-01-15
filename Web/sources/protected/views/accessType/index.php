<?php
/* @var $this AccessTypeController */
/* @var $dataProvider CActiveDataProvider */

$this->breadcrumbs=array(
	'Access Types',
);

$this->menu=array(
	array('label'=>'Create AccessType', 'url'=>array('create')),
	array('label'=>'Manage AccessType', 'url'=>array('admin')),
);
?>

<h1>Access Types</h1>

<?php $this->widget('zii.widgets.CListView', array(
	'dataProvider'=>$dataProvider,
	'itemView'=>'_view',
)); ?>
