<?php
/**
 * @var $model GeneralSettings
 */
$this->breadcrumbs=array(
	'General Settings'=>array('admin'),
	'Manage',
);

/*$this->menu=array(
array('label'=>'Create General Settings','url'=>array('create')),
);
*/
?>

<h1>Manage General Settings</h1>


<?php $this->widget('bootstrap.widgets.TbGridView',array(
'id'=>'general-settings-grid',
'type'            => 'striped bordered condensed',
'dataProvider'=>$model->search(),
//'filter'=>$model,
    'enableSorting' => false,
'columns'=>array(
//		'id',
		'label',
    array(  'name'=>'value',
            'type' => 'raw',
            'value'=>array($model,'valueFormated'),
            'header'=>'Value of attribute',
            'filter'=>''),
    array(
        'class'=>'bootstrap.widgets.TbButtonColumn',
        'template'=>'{update}',
        'buttons'=>array(
            'update'=>array(),
        ),
)))); ?>
