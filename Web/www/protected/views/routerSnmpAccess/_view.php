<div class="view">

		<b><?php echo CHtml::encode($data->getAttributeLabel('id')); ?>:</b>
	<?php echo CHtml::link(CHtml::encode($data->id),array('view','id'=>$data->id)); ?>
	<br />

	<b><?php echo CHtml::encode($data->getAttributeLabel('router_id')); ?>:</b>
	<?php echo CHtml::encode($data->router_id); ?>
	<br />

	<b><?php echo CHtml::encode($data->getAttributeLabel('snmp_access_id')); ?>:</b>
	<?php echo CHtml::encode($data->snmp_access_id); ?>
	<br />


</div>