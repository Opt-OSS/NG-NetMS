<?php
/* @var $this RoutersController */
/* @var $model Routers */
/* @var $form CActiveForm */
?>

<?php

    $form = $this->beginWidget('bootstrap.widgets.TbActiveForm', array(
    'id'=>'inlineForm',
    'type'=>'inline',
    'htmlOptions'=>array('class'=>'well'),
    )); ?>

<?php echo $form->textFieldRow($model, 'name'); ?>
<?php  echo $form->dropDownList(
    $model,
    'eq_vendor',
    Yii::app()->params['vendors'],
    array(
        'prompt' => 'Select vendor for this device',
        'options' => array(rtrim($model->eq_vendor) => array('selected'=>true)),
        'style' => 'margin-right: 9px;'
    )
); ?>
<?php echo $form->textFieldRow($model, 'eq_type'); ?>

<?php $this->widget('bootstrap.widgets.TbButton', array('buttonType'=>'submit', 'label'=>$model->isNewRecord ? 'Create' : 'Save')); ?>

<?php $this->endWidget(); ?>