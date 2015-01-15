<?php
$this->breadcrumbs=array(
	'SNMP Access methods'=>array('index'),
);

?>

<h1>SNMP Access to devices</h1>



<?php

$gridColumns = array( array('name'=>'community_ro','value'=> 'Cripto::decrypt($data->community_ro)', 'header'=>'Community RO'),
                     array('name'=>'community_rw', 'value'=> 'Cripto::decrypt($data->community_rw)','header'=>'Community RW'),
    array(
    'class'=>'bootstrap.widgets.TbButtonColumn',
    'template'=>'{update}',
    'buttons'=>array(
        'update'=>array(
            'url'=>'Yii::app()->controller->createUrl("snmpAccess/routerjoin", array("id"=>$data->id))',
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
            'name' => 'SNMP Access method ID',
            'url' => $this->createUrl('routers/listSnmp'),
            'value' => '$data->id',
        )
    ), $gridColumns),

));


?>

<div style="height :30px;"></div>
