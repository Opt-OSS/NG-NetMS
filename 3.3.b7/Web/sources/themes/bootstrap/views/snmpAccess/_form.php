<?php $form=$this->beginWidget('bootstrap.widgets.TbActiveForm',array(
	'id'=>'snmp-access-form',
	'enableAjaxValidation'=>false,
)); ?>

<p class="help-block">Fields with <span class="required">*</span> are required.</p>

<?php echo $form->errorSummary($model); ?>

    <div class="row" style ="margin-left: 5px">
    <?php echo $form->labelEx($model,'name'); ?>
    <?php echo $form->textField($model,'name',array('size'=>50,'maxlength'=>50)); ?>
    <?php echo $form->error($model,'name'); ?>
    </div>

	<?php echo $form->textAreaRow($model,'community_ro',array('rows'=>6, 'cols'=>50, 'class'=>'span8')); ?>

	<?php echo $form->textAreaRow($model,'community_rw',array('rows'=>6, 'cols'=>50, 'class'=>'span8')); ?>

<div class="form-actions">
	<?php $this->widget('bootstrap.widgets.TbButton', array(
			'buttonType'=>'submit',
			'type'=>'primary',
			'label'=>$model->isNewRecord ? 'Create' : 'Save',
		)); ?>
</div>

<?php $this->endWidget(); ?>
