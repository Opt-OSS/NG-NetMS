<?php
/* @var $this AccessController */
/* @var $dataProvider CActiveDataProvider */

$this->breadcrumbs=array(
	'Access methods',
);

?>

<h1>Access methods</h1>



<?php

$gridColumns = array(array('name' => 'idAccessType.name','value' => '$data->idAccessType->name', 'header' => 'Access Type'),array(
    'class'=>'bootstrap.widgets.TbButtonColumn',
    'template'=>'{update}{delete}',
    'buttons'=>array(
        'update'=>array(
            'url'=>'Yii::app()->controller->createUrl("attrValue/update", array("id"=>$data->id,"id_access_type"=>$data->idAccessType->id))',
        ),
        'delete' => array(

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
            'name' => 'Access Title',
            'url' => $this->createUrl('attrValue/index'),
            'value' => '$data->name',
        )
    ), $gridColumns),

));


$this->widget(
'bootstrap.widgets.TbButton', array( 'label' => 'Create new access ','type'=>'info',
'url'=>Yii::app()->createUrl("access/create"))
);
?>

<div style="height :30px;"></div>
