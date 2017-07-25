<?php
/* @var $this AttrValueController */
/* @var $model AttrValue */

$this->breadcrumbs=array(
    'Accesses'=>array('access/index'),
	'Create',
);
?>

<h1>Create Attributes Value</h1>
<div style ="margin-left: 50px">
<?php $this->renderPartial('_form', array('model'=>$model,
                                          'arr_attrs'=>$arr_attrs,
                                          'id_acc'=>$id_acc,
                                          'id_acc_type'=>$id_acc_type));
?>
</div>
<div style="height :30px;"></div>
