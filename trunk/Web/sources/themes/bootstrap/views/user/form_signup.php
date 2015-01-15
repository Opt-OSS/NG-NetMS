<?php
/* @var $this UserController */
/* @var $form CActiveForm  */

$this->pageTitle=Yii::app()->name . ' - New user';
$this->breadcrumbs=array(
	'Management','New user',
);
?>

<h1>New user</h1>

<p>Please fill out the following form :</p>

<div class="form">

<?php $form=$this->beginWidget('bootstrap.widgets.TbActiveForm', array(
	'id'=>'signup-form',
    'type'=>'horizontal',
	'enableClientValidation'=>true,
	'clientOptions'=>array(
		'validateOnSubmit'=>true,
	),
)); ?>

	<p class="note">Fields with <span class="required">*</span> are required.</p>

	<?php echo $form->textFieldRow($model,'username'); ?>

	<?php echo $form->passwordFieldRow($model,'password'); ?>
	<?php echo $form->passwordFieldRow($model,'password_repeat'); ?>
	<?php echo $form->textFieldRow($model,'fname'); ?>
	<?php echo $form->textFieldRow($model,'lname'); ?>
	<?php echo $form->textFieldRow($model,'company'); ?>
	<?php echo $form->textFieldRow($model,'email'); ?>

	<div class="form-actions">
        <?php 
            $this->widget('bootstrap.widgets.TbButton', array(
            'buttonType'=>'submit',
            'type'=>'primary',
            'label'=>'Sign Up',
        )); ?>
	</div>

<?php $this->endWidget(); ?>

</div><!-- form -->


