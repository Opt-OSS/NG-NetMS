<?php
$this->breadcrumbs=array(
	'SNMP Access methods'=>array('index'),
	'Update',
);


	?>

	<h1>Update SNMP Access method <?php echo $model->id; ?></h1>

<?php echo $this->renderPartial('_form',array('model'=>$model)); ?>
