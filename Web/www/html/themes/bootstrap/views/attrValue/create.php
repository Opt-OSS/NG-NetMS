<?php
/* @var $this AttrValueController */
/* @var $model AttrValue */

$this->breadcrumbs=array(
    'Accesses'=>array('access/index'),
	'Create',
);
$access_name=(new Access())->findByPk($id_acc)->name;
$access_type_name=(new AccessType())->findByPk($id_acc_type)->name;
?>

<h1>Create Attributes Value</h1>
<div style ="margin-left: 50px">
<?php $this->renderPartial('_form1', array('model'=>$model,
                                          'arr_attrs'=>$arr_attrs,
                                          'id_acc'=>$id_acc,
                                          'id_acc_type'=>$id_acc_type));
?>
</div>
<div style="height :30px;"></div>
