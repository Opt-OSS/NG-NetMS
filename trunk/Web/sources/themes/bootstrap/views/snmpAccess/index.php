<?php
Yii::import("application.components.Cripto");
$this->breadcrumbs=array(
	'SNMP Access methods',
);

?>

<h1>SNMP Access methods</h1>



<?php



$this->widget('bootstrap.widgets.TbGridView', array(
    'type'            => 'striped bordered condensed',
    'id'              => 'routers-grid',
    'dataProvider'    => $dataProvider,
    'enablePagination'=>true,
    'template'=>"{items}{pager}",
    'columns'         => array(
        array('name'=>'id', 'header'=>'ID'),
        array('name'=>'community_ro', 'value'=> 'Cripto::hidedata($data->community_ro)', 'header'=>'Community RO'),
        array('name'=>'community_rw', 'value'=> 'Cripto::hidedata($data->community_rw)', 'header'=>'Community RW'),
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
        'url'=>Yii::app()->createUrl("snmpAccess/create"))
);
?>

<div style="height :30px;"></div>
