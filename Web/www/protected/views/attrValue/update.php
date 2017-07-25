<?php
/* @var $this AttrValueController */
/* @var $model AttrValue */

$this->breadcrumbs=array(
	'Attr Values'=>array('index'),
	$model->id=>array('view','id'=>$model->id),
	'Update',
);

$this->menu=array(
	array('label'=>'List AttrValue', 'url'=>array('index')),
	array('label'=>'Create AttrValue', 'url'=>array('create')),
	array('label'=>'View AttrValue', 'url'=>array('view', 'id'=>$model->id)),
	array('label'=>'Manage AttrValue', 'url'=>array('admin')),
);
?>

<h1>Update AttrValue <?php echo $model->id; ?></h1>

<?php $this->renderPartial('_form', array('model'=>$model)); ?>