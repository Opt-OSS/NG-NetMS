<?php
$this->breadcrumbs=array(
	'General Settings'=>array('admin'),
	'Update',
);

/*	$this->menu=array(
	array('label'=>'Create General Settings','url'=>array('create')),
	array('label'=>'Manage General Settings','url'=>array('admin')),
	);*/
	?>

	<h1>Update <?php echo $model->label; ?></h1>

<?php echo $this->renderPartial('_form',array('model'=>$model)); ?>