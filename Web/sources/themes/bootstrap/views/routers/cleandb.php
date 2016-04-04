<?php
/* @var $this RoutersController */

$this->breadcrumbs=array(
	'Management',
);
?>

<?php if(Yii::app()->user->hasFlash('cleandb')){ ?>

<?php $this->widget('bootstrap.widgets.TbAlert', array(
    'alerts'=>array('cleandb'),
)); } else{ ?>

<?php

    $form = $this->beginWidget('bootstrap.widgets.TbActiveForm', array(
        'id'=>'inlineForm',
        'type'=>'inline',
        'htmlOptions'=>array('class'=>'well'),
    )); ?>
<input type="hidden" name="tumbler" id="tumbler" value="1">
<?php $this->widget('bootstrap.widgets.TbButton', array('buttonType'=>'submit', 'label'=>'Clean data in DB','type' => 'danger')); ?>
    <h5> deletes ALL Events, Assets, Routers, Routers access bindings</h5>

<?php $this->endWidget(); }?>

