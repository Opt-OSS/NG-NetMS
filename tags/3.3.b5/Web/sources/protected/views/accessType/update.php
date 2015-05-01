<?php
/* @var $this AccessTypeController */
/* @var $model AccessType */

$this->breadcrumbs=array(
	'Access Types'=>array('index'),
	$model->name=>array('view','id'=>$model->id),
	'Update',
);

$this->menu=array(
	array('label'=>'List AccessType', 'url'=>array('index')),
	array('label'=>'Create AccessType', 'url'=>array('create')),
	array('label'=>'View AccessType', 'url'=>array('view', 'id'=>$model->id)),
	array('label'=>'Manage AccessType', 'url'=>array('admin')),
);
?>

<h1>Update AccessType <?php echo $model->id; ?></h1>

<?php $this->renderPartial('_form', array('model'=>$model)); ?>