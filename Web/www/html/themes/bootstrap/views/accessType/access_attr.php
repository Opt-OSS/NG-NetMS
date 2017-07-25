<?php
/* @var $this AccessTypeController */
/* @var $dataProvider CActiveDataProvider */

$this->breadcrumbs=array(
    'Access Attributes'=>array('admin'),
    $model->getName(),
    'Attributes',
);


?>

<h1>Access Attributes</h1>


<?php echo CHtml::beginForm($this->createUrl('move'),'post'); ?>

<?php echo CHtml::hiddenField('id',$model->id); ?>

<?php
$this->widget('ext.widgets.multiselects.XMultiSelects',array(
    'leftTitle'=>'Attributes of '.$model->getName(),
    'leftName'=>'Attr[]',
    'leftList'=>$attr_curr,
    'rightTitle'=>'Attributes',
    'rightName'=>'Attrn[]',
    'rightList'=>$attr_nocurr,
    'size'=>20,
    'width'=>'200px',
));

?>
    <br />
<?php echo CHtml::submitButton(Yii::t('ui', 'Save'), array('class'=>'btn btn-red')); ?>&nbsp;
<?php echo CHtml::endForm(); ?>