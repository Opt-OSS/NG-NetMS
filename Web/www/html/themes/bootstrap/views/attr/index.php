<?php
/* @var $this AccessTypeController */
/* @var $dataProvider CActiveDataProvider */

$this->breadcrumbs=array(
    'Attributes of access types',
);


?>

<h1>Attributes of acceess types</h1>


<?php



$this->widget('bootstrap.widgets.TbGridView', array(
    'type'            => 'striped bordered condensed',
    'id'              => 'routers-grid',
    'dataProvider'    => $dataProvider,
    'enablePagination'=>true,
    'template'=>"{items}{pager}",
    'columns'         => array(
        array('name'=>'id', 'header'=>'ID'),
        array('name'=>'name', 'header'=>'Name'),
        array(
            'class'=>'bootstrap.widgets.TbButtonColumn',
            'template'=>'{update}{delete}',
            'buttons'=>array(
                'update'=>array(),
                'delete' => array(
                ),
            ),
            'htmlOptions'=>array('style'=>'width: 50px'),
        ),
    ),

));

$this->widget(
    'bootstrap.widgets.TbButton', array( 'label' => 'Create access type ','type'=>'info',
        'url'=>Yii::app()->createUrl("attr/create"))
);
?>

<div style="height :30px;"></div>
