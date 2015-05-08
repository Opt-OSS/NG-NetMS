<?php
/* @var $this AccessTypeController */
/* @var $model AccessType */

$this->breadcrumbs=array(
	'Access Types'=>array('index'),
	$model->name=>array('view','id'=>$model->id),
	'Update',
);


?>

<h1>Update access type </h1>
<div style ="margin-left: 50px">
<?php $this->renderPartial('_form', array('model'=>$model)); ?>
</div>

<div style="height :30px;"></div>