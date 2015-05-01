<?php
/* @var $this RoutersController */
/* @var $model Routers */
/* @var $form CActiveForm */
?>

<div class="form">

<?php $form=$this->beginWidget('CActiveForm', array(
	'id'=>'routers-form',
	// Please note: When you enable ajax validation, make sure the corresponding
	// controller action is handling ajax validation correctly.
	// There is a call to performAjaxValidation() commented in generated controller code.
	// See class documentation of CActiveForm for details on this.
	'enableAjaxValidation'=>false,
)); ?>

	<p class="note">Fields with <span class="required">*</span> are required.</p>

	<?php echo $form->errorSummary($model); ?>

	<div class="row">
		<?php echo $form->labelEx($model,'name'); ?>
		<?php echo $form->textField($model,'name',array('size'=>32,'maxlength'=>32)); ?>
		<?php echo $form->error($model,'name'); ?>
	</div>

	<div class="row">
		<?php echo $form->labelEx($model,'ip_addr'); ?>
		<?php echo $form->textField($model,'ip_addr'); ?>
		<?php echo $form->error($model,'ip_addr'); ?>
	</div>

	<div class="row">
		<?php echo $form->labelEx($model,'eq_type'); ?>
		<?php echo $form->textField($model,'eq_type',array('size'=>50,'maxlength'=>50)); ?>
		<?php echo $form->error($model,'eq_type'); ?>
	</div>

	<div class="row">
		<?php echo $form->labelEx($model,'eq_vendor'); ?>
		<?php echo $form->textField($model,'eq_vendor',array('size'=>50,'maxlength'=>50)); ?>
		<?php echo $form->error($model,'eq_vendor'); ?>
	</div>

	<div class="row">
		<?php echo $form->labelEx($model,'location'); ?>
		<?php echo $form->textField($model,'location',array('size'=>60,'maxlength'=>255)); ?>
		<?php echo $form->error($model,'location'); ?>
	</div>

	<div class="row">
		<?php echo $form->labelEx($model,'status'); ?>
		<?php echo $form->textField($model,'status',array('size'=>20,'maxlength'=>20)); ?>
		<?php echo $form->error($model,'status'); ?>
	</div>

	<div class="row">
		<?php echo $form->labelEx($model,'icon_color'); ?>
		<?php echo $form->textField($model,'icon_color',array('size'=>20,'maxlength'=>20)); ?>
		<?php echo $form->error($model,'icon_color'); ?>
	</div>

	<div class="row buttons">
		<?php echo CHtml::submitButton($model->isNewRecord ? 'Create' : 'Save'); ?>
	</div>

<?php $this->endWidget(); ?>

</div><!-- form -->