<?php
/* @var $this AccessController */
/* @var $dataProvider CActiveDataProvider */

$this->breadcrumbs=array(
    'Access methods '=>array('view'),
    'Access to devices',
    $model->getAccessName(),
);


?>

<h1>Access for routers</h1>


<?php echo CHtml::beginForm($this->createUrl('move'),'post'); ?>

<?php echo CHtml::hiddenField('id_access',$model->id_access); ?>

<?php
$this->widget('ext.widgets.multiselects.XMultiSelects',array(
    'leftTitle'=>'<b>Access <i> '.$model->getAccessName().'</i></b>',
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
