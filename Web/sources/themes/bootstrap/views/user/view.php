<?php
/* @var $this UserController */
/* @var $form CActiveForm  */

$this->pageTitle=Yii::app()->name . ' - Edit user';
$this->breadcrumbs=array(
	'Management','Edit users'
);
?>

<h1>Edit user</h1>

<p>Please fill out the following form :</p>

<div class="form">

<?php $form=$this->beginWidget('bootstrap.widgets.TbActiveForm', array(
        'id'=>'edituser-form',
        'action' => Yii::app()->createUrl('user/update&id='.$_GET['id']),
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
        <?php echo $form->hiddenField($model,'old_password'); ?>
	<?php echo $form->textFieldRow($model,'fname'); ?>
	<?php echo $form->textFieldRow($model,'lname'); ?>
	<?php echo $form->textFieldRow($model,'company'); ?>
	<?php echo $form->textFieldRow($model,'email'); ?>

	<div class="form-actions">
		<?php $this->widget('bootstrap.widgets.TbButton', array(
            'buttonType'=>'submit',
            'type'=>'primary',
            'label'=>'Edit',
        )); ?>
	</div>

<?php $this->endWidget(); ?>

</div><!-- form -->


