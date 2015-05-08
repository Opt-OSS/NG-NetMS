<?php
$this->breadcrumbs=array(
	'General Settings'=>array('index'),
	'Create',
);

$this->menu=array(
array('label'=>'List GeneralSettings','url'=>array('index')),
array('label'=>'Manage GeneralSettings','url'=>array('admin')),
);
?>

<h1>Create GeneralSettings</h1>

<?php echo $this->renderPartial('_form', array('model'=>$model)); ?>