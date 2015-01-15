<?php
/* @var $this AccessController */
/* @var $model Access */

$this->breadcrumbs=array(
	'Access methods'=>array('index'),
	'Create',
);

?>

<h1>Create New Access</h1>
<div style ="margin-left: 50px">
<?php $this->renderPartial('_form', array('model'=>$model)); ?>
</div>

<div style="height :30px;"></div>
