<?php
/**
 * @var $this AttrValueController
 * @var $model AttrValue
 * @var $access_type AccessType
 * @var $wrapped Access[]
 */

$this->breadcrumbs=array(
	'Access methods'=>array('access/index'),
	'Update',
);



switch ($access_type->id){

    default:
        $form_view =  '_form1';
}

?>

<h1><?php echo $access_type->name; ?>: Update Attribute Value </h1>

<div style ="margin-left: 50px">
    <?php
$this->renderPartial($form_view, array('model'=>$model,
    'arr_attrs'=>$arr_attrs,
    'id_acc'=>$id_acc,
    'wrapped'=>$wrapped,
    'id_acc_type'=>$id_acc_type));
?>
</div>
<div style="height :30px;"></div>
