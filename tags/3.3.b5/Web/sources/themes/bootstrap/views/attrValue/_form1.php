<?php
/* @var $this AttrValueController */
/* @var $model AttrValue */
/* @var $form CActiveForm */
?>

<div class="form">

<?php $form=$this->beginWidget('CActiveForm', array(
	'id'=>'attr-value-form',
	// Please note: When you enable ajax validation, make sure the corresponding
	// controller action is handling ajax validation correctly.
	// There is a call to performAjaxValidation() commented in generated controller code.
	// See class documentation of CActiveForm for details on this.
	'enableAjaxValidation'=>false,
));
?>
    <p class="note">Fields with <span class="required">*</span> are required.</p>
<?php
$amount_arr = count($arr_attrs);
for($i =0 ;$i<$amount_arr; $i++)
{
?>



	<?php echo $form->errorSummary($model); ?>

		<?php echo $form->hiddenField($model,"[$i]id_access"); ?>
        <?php echo CHtml::hiddenField("id_attr_access[$i]" , $arr_attrs[$i]['id_t']); ?>


	<div class="row">
        <?php echo $form->labelEx($model,'value',array('label'=>$arr_attrs[$i]['name'])); ?>
		<?php echo $form->textArea($model,"[$i]value",array('value'=>$arr_attrs[$i]['value'],'rows'=>6, 'cols'=>50)); ?>
		<?php echo $form->error($model,'value'); ?>
	</div>
<?php } ?>
	<div class="row buttons">
		<?php echo  CHtml::submitButton('Save');; ?>
	</div>

<?php $this->endWidget(); ?>

</div><!-- form -->