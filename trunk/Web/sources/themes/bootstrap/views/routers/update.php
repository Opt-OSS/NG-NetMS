<?php
/* @var $this RoutersController */
/* @var $model Routers */

$this->breadcrumbs=array(
	'Routers'=>array('index'),
	$model->name=>array('view','id'=>$model->name),
	'Update',
);

?>

<h1>Update Routers <?php echo $model->name; ?></h1>

<?php $this->renderPartial('_form', array('model'=>$model)); ?>