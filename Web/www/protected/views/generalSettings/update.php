<?php
$this->breadcrumbs=array(
	'General Settings'=>array('index'),
	$model->name=>array('view','id'=>$model->id),
	'Update',
);

	$this->menu=array(
	array('label'=>'List GeneralSettings','url'=>array('index')),
	array('label'=>'Create GeneralSettings','url'=>array('create')),
	array('label'=>'View GeneralSettings','url'=>array('view','id'=>$model->id)),
	array('label'=>'Manage GeneralSettings','url'=>array('admin')),
	);
	?>

	<h1>Update GeneralSettings <?php echo $model->id; ?></h1>

<?php echo $this->renderPartial('_form',array('model'=>$model)); ?>