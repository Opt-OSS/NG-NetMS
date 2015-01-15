<?php
/* @var $this AttrValueController */
/* @var $model AttrValue */

$this->breadcrumbs=array(
	'Access methods'=>array('access/index'),
	'Update',
);


?>

<h1>Update Attributes Value <?php echo $model->id; ?></h1>

<div style ="margin-left: 50px">
<?php $this->renderPartial('_form1', array('model'=>$model,
    'arr_attrs'=>$arr_attrs,
    'id_acc'=>$id_acc,
    'id_acc_type'=>$id_acc_type));
?>
</div>
<div style="height :30px;"></div>
