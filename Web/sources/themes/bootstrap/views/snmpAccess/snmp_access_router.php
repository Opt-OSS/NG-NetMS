<?php
/* @var $this AccessController */
/* @var $dataProvider CActiveDataProvider */

$this->breadcrumbs=array(
    'SNMP Access methods '=>array('view'),
    'SNMP Access to devices',
     $model->snmp_access_id,
);


?>

<h1>Access for routers</h1>


<?php echo CHtml::beginForm($this->createUrl('move'),'post'); ?>

<?php echo CHtml::hiddenField('id_access',$model->snmp_access_id); ?>

<?php
$this->widget('ext.widgets.multiselects.XMultiSelects',array(
    'leftTitle'=>'<b>Snmp Access <i> '.$model->snmp_access_id.'</i></b>',
    'leftName'=>'Attr[]',
    'leftList'=>$attr_curr,
    'rightTitle'=>'<b>Routers</b>',
    'rightName'=>'Attrn[]',
    'rightList'=>$attr_nocurr,
    'size'=>20,
    'width'=>'200px',
));

?>
    <br />
<?php echo CHtml::submitButton(Yii::t('ui', 'Save'), array('class'=>'btn btn-red')); ?>&nbsp;
<?php echo CHtml::endForm(); ?>
