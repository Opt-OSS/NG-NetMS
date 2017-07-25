<?php
$this->breadcrumbs=array(
	'General Settings'=>array('admin'),
	'Create',
);

$this->menu=array(
array('label'=>'Manage General Settings','url'=>array('admin')),
);
?>

<h1>Create GeneralSettings</h1>

<?php echo $this->renderPartial('_form', array('model'=>$model)); ?>