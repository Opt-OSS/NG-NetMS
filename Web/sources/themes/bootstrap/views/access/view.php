<?php
/* @var $this AccessController */
/* @var $dataProvider CActiveDataProvider */

$this->breadcrumbs = array(
    'Access to devices',
);

?>

<h1>Accesses to devices</h1>


<?php

$gridColumns = array(
    array(
        'name'   => 'idAccessType.name',
        'value'  => '$data->idAccessType->name',
        'header' => 'Access Type'
    ),
    array(
        'class'       => 'bootstrap.widgets.TbButtonColumn',
        'template'    => '{update}',
        'buttons'     => array(
            'update' => array(
                'url' => 'Yii::app()->controller->createUrl("access/routerjoin", array("id"=>$data->id))',
            ),
        ),
        'htmlOptions' => array('style' => 'width: 50px'),
    )
);
$this->widget('bootstrap.widgets.TbExtendedGridView', array(
    'type'             => 'striped bordered',
    'id'               => 'hw-grid',
    'dataProvider'     => $model->search(),
    'enablePagination' => true,
    'template'         => "{items}\n{pager}",
    'columns'          => array_merge(array(
        array(
            'class' => 'bootstrap.widgets.TbRelationalColumn',
            'name'  => 'Access Title',
            'url'   => $this->createUrl('routers/list'),
            'value' => '$data->name',
        )
    ), $gridColumns),

));


?>

<div style="height :30px;"></div>
