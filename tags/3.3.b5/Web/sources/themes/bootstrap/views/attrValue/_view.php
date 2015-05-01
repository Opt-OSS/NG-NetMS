<?php
/* @var $this AttrValueController */
/* @var $data AttrValue */
?>

<div class="view">

	<b><?php echo CHtml::encode($data->getAttributeLabel('id')); ?>:</b>
	<?php echo CHtml::link(CHtml::encode($data->id), array('view', 'id'=>$data->id)); ?>
	<br />

	<b><?php echo CHtml::encode($data->getAttributeLabel('id_attr_access')); ?>:</b>
	<?php echo CHtml::encode($data->id_attr_access); ?>
	<br />

	<b><?php echo CHtml::encode($data->getAttributeLabel('id_access')); ?>:</b>
	<?php echo CHtml::encode($data->id_access); ?>
	<br />

	<b><?php echo CHtml::encode($data->getAttributeLabel('value')); ?>:</b>
	<?php echo CHtml::encode($data->value); ?>
	<br />


</div>