<?php
$this->breadcrumbs=array(
	'List of networks not to be scanned',
);

?>
<h1>List of networks not to be scanned</h1>

<?php


$this->widget('bootstrap.widgets.TbGridView', array(
'type'            => 'striped bordered condensed',
'id'              => 'routers-grid',
'dataProvider'    => $model->search(),
'enablePagination'=>true,
'enableSorting' => false,
'template'=>"{items}{pager}",
'columns'         => array(
array('name'=>'addr', 'header'=>'Subnet'),
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
'bootstrap.widgets.TbButton', array( 'label' => 'Add network to list ','type'=>'info',
'url'=>Yii::app()->createUrl("scanException/create"))
);
?>