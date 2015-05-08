<?php
/* @var $this AccessTypeController */
/* @var $data AccessType */
?>

<?php

$this->widget('bootstrap.widgets.TbDetailView', array(
    'data'=>array('id'=>$data->id, 'name'=>$data->name),
    'attributes'=>array(
        array('name'=>'id', 'label'=>CHtml::encode($data->getAttributeLabel('id')),
            array('name'=>'name', 'label'=>CHtml::encode($data->getAttributeLabel('name'))),
        ),
    )));
?>
