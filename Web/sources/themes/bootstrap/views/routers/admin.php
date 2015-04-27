<?php
/* @var $this RoutersController */
/* @var $model Routers */

$this->breadcrumbs=array(
	'Devices'=>array('index'),
	'Manual control',
);


?>

<h1>Devices manual control</h1>


<?php



$this->widget('bootstrap.widgets.TbGridView', array(
    'type'            => 'striped bordered condensed',
    'id'              => 'routers-grid',
    'dataProvider'    => $dataProvider,
    'enablePagination'=>true,
    'template'=>"{items}{pager}",
    'columns'         => array(
        array('name'=>'name', 'header'=>'Name'),
        array('name'=>'eq_vendor', 'header'=>'Vendor'),
        array('name'=>'eq_type', 'header'=>'Model'),
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
    'bootstrap.widgets.TbButton', array( 'label' => 'Create device manually ','type'=>'info',
        'url'=>Yii::app()->createUrl("routers/create"))
);
?>

<div style="height :30px;"></div>