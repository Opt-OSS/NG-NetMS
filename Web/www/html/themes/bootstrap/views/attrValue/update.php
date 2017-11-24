<?php
/**
 * @var $this AttrValueController
 * @var $model AttrValue
 * @var $access_type AccessType
 * @var $wrapped Access[]
 */

$this->breadcrumbs = array(
    'Access methods' => array('access/index'),
    'Update',
);
$access_name=(new Access())->findByPk($id_acc)->name;
$access_type_name=(new AccessType())->findByPk($id_acc_type)->name;

$form_view = '_form1';
?>

<h1>Edit access method <?php echo $access_type_name ?>: &laquo;<?php echo $access_name ?>&raquo;</h1>

<div style="margin-left: 50px">
    <?php
    $this->renderPartial($form_view, array('model'       => $model,
                                           'arr_attrs'   => $arr_attrs,
                                           'id_acc'      => $id_acc,
                                           'id_acc_type' => $id_acc_type));
    ?>
</div>
<div style="height :30px;"></div>
