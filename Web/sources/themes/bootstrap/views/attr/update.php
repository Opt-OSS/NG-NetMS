<?php
/* @var $this AttrController */
/* @var $model Attr */

$this->breadcrumbs=array(
	'Attrs'=>array('index'),
	$model->name=>array('view','id'=>$model->id),
	'Update',
);


?>

<h1>Update attribute</h1>

<div style ="margin-left: 50px">
<?php $this->renderPartial('_form', array('model'=>$model)); ?>
</div>

<div style="height :30px;"></div>