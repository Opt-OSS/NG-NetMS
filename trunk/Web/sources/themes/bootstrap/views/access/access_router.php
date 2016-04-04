<?php
/* @var $this AccessController */
/* @var $dataProvider CActiveDataProvider */

$this->breadcrumbs=array(
    'Access methods '=>array('view'),
    'Access to devices',
    $model->getAccessName(),
);


?>

<h1>Access to devices</h1>


<?php echo CHtml::beginForm($this->createUrl('move'),'post'); ?>

<?php echo CHtml::hiddenField('id_access',$model->id_access); ?>

<?php
$this->widget('ext.widgets.multiselects.XMultiSelects',array(
    'leftTitle'=>'<b>Access <i> '.$model->getAccessName().'</i></b>',
    'leftName'=>'Attr[]',
    'leftList'=>$attr_curr,
    'rightTitle'=>'<b>Devices</b>',
    'rightName'=>'Attrn[]',
    'rightList'=>$attr_nocurr,
    'size'=>15,
    'width'=>'219px',
));
/*
?>
    <br />
<?php
$this->widget('ext.widgets.multiselects.XMultiSelects',array(
    'leftTitle'=>'<b>Access <i> '.$model->getAccessName().'</i></b>',
    'leftName'=>'bgp_Attr[]',
    'leftList'=>$bgp_attr_curr,
    'rightTitle'=>'<b>BGB neighbors</b>',
    'rightName'=>'bgp_Attrn[]',
    'rightList'=>$bgp_attr_nocurr,
    'size'=>10,
    'width'=>'219px',
));
*/
?>
<?php echo CHtml::submitButton(Yii::t('ui', 'Save'), array('class'=>'btn btn-red')); ?>&nbsp;
<?php echo CHtml::endForm(); ?>
