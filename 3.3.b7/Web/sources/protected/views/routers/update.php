<?php
/* @var $this RoutersController */
/* @var $model Routers */

$this->breadcrumbs=array(
	'Routers'=>array('index'),
	$model->name=>array('view','id'=>$model->router_id),
	'Update',
);

$this->menu=array(
	array('label'=>'List Routers', 'url'=>array('index')),
	array('label'=>'Create Routers', 'url'=>array('create')),
	array('label'=>'View Routers', 'url'=>array('view', 'id'=>$model->router_id)),
	array('label'=>'Manage Routers', 'url'=>array('admin')),
);
?>

<h1>Update Routers <?php echo $model->router_id; ?></h1>

<?php $this->renderPartial('_form', array('model'=>$model)); ?>