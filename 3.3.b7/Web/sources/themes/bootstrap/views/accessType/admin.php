<?php
/* @var $this AccessTypeController */
/* @var $model AccessType */


$this->breadcrumbs=array(
    'Access Attributes',
);
?>


<?php

$gridColumns = array(array('name' => 'id', 'header' => 'ID'),array(
    'class'=>'bootstrap.widgets.TbButtonColumn',
    'template'=>'{update}',
    'buttons'=>array(
        'update'=>array(
            'url'=>'Yii::app()->controller->createUrl("accessType/edit", array("id"=>$data->id))',
        ),
        'delete' => array(
//                                  'url'=>'Yii::app()->controller->createUrl("ports/delete", array("id"=>$data[id],"command"=>"delete"))',
        ),
    ),
    'htmlOptions'=>array('style'=>'width: 50px'),
));
$this->widget('bootstrap.widgets.TbExtendedGridView', array(
    'type' => 'striped bordered',
    'id' => 'hw-grid',
    'dataProvider' => $model->search(),
    'enablePagination' => true,
    'template' => "{items}\n{pager}",
    'columns' => array_merge(array(
        array(
            'class' => 'bootstrap.widgets.TbRelationalColumn',
            'name' => 'name',
            'url' => $this->createUrl('attrAccess/index'),
            'value' => '$data->name',
        )
    ), $gridColumns),

));
?>
