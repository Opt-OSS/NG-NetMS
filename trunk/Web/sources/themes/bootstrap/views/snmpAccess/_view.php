<div class="view">

		<b><?php echo CHtml::encode($data->getAttributeLabel('id')); ?>:</b>
	<?php echo CHtml::link(CHtml::encode($data->id),array('view','id'=>$data->id)); ?>
	<br />

	<b><?php echo CHtml::encode($data->getAttributeLabel('community_ro')); ?>:</b>
	<?php echo CHtml::encode($data->community_ro); ?>
	<br />

	<b><?php echo CHtml::encode($data->getAttributeLabel('community_rw')); ?>:</b>
	<?php echo CHtml::encode($data->community_rw); ?>
	<br />


</div>