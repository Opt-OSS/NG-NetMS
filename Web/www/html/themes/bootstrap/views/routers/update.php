<?php
/* @var $this RoutersController */
/* @var $model Routers */

$this->breadcrumbs=array(
	'Devices'=>array('index'),
	$model->name=>array('view','id'=>$model->router_id),
	'Update',
);

?>

<h1>Update Devices <?php echo $model->name; ?></h1>

<?php $this->renderPartial('_form', array('model'=>$model)); ?>