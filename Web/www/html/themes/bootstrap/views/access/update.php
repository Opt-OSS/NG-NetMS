<?php
/* @var $this AccessController */
/* @var $model Access */

$this->breadcrumbs=array(
	'Access methods'=>array('index'),
	$model->name=>array('view','id'=>$model->id),
	'Update',
);

$this->menu=array(
	array('label'=>'List Access', 'url'=>array('index')),
	array('label'=>'Create Access', 'url'=>array('create')),
	array('label'=>'View Access', 'url'=>array('view', 'id'=>$model->id)),
	array('label'=>'Manage Access', 'url'=>array('admin')),
);
?>

<h1>Update Access <?php echo $model->id; ?></h1>

<?php $this->renderPartial('_form', array('model'=>$model)); ?>
