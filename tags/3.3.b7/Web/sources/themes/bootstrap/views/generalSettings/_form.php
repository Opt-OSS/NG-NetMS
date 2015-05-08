<?php $form=$this->beginWidget('bootstrap.widgets.TbActiveForm',array(
	'id'=>'general-settings-form',
	'enableAjaxValidation'=>false,
)); ?>

<p class="help-block">Fields with <span class="required">*</span> are required.</p>

<?php echo $form->errorSummary($model); ?>

    <?php echo $form->hiddenField($model,'name'); ?>
	<?php echo $form->textFieldRow($model,'label',array('class'=>'span5','maxlength'=>100,"readonly"=>true)); ?>
    <?php if($model->name != 'type access'){ ?>
	<?php echo $form->textFieldRow($model,'value',array('class'=>'span5','maxlength'=>255)); ?>
<?php
    }
    else
    {
        echo '<label for="GeneralSettings_value">Value of Attribute</label>';
        echo $form->dropDownList($model,'value',
        CHtml::listData(AccessType::model()->findAll(), 'name', 'name'),
        array('empty'=>'Select here...','class'=>'span5'));
    }
?>


<div class="form-actions">
	<?php $this->widget('bootstrap.widgets.TbButton', array(
			'buttonType'=>'submit',
			'type'=>'primary',
			'label'=>$model->isNewRecord ? 'Create' : 'Save',
		)); ?>
</div>

<?php $this->endWidget(); ?>
