<?php
$this->breadcrumbs=array(
	'Archive Manager'=>array('index'),
	'Manage Archives',
);

?>

<h1>Manage Archives</h1>


<?php $this->widget('bootstrap.widgets.TbGridView',array(
'id'=>'archives-grid',
'dataProvider'=>$model->search(),
'type' => 'striped bordered condensed',
'filter'=>$model,
'columns'=>array(
		'archive_id',
		'start_time',
		'end_time',
		'file_name',
    array(
        'header' => 'Loaded<br> in DB',
        'type'=>'raw',
        'value' => '($data->in_db > 0) ? "<span class=\"icon-ok\"></span>" : "<span class=\"icon-minus\"></span>"',
        'htmlOptions'=>array('style' => 'text-align: center;'),
    ),
array(
'class'=>'bootstrap.widgets.TbButtonColumn',
    'template'=>'{add}{drop} ',
    'buttons'=>array
    (
        'add' => array
        (
            'label'=>'Load',
            'icon'=>'share',
            'url'=>'Yii::app()->createUrl("archives/admin", array("archive_id"=>$data->archive_id,"act"=>1))',
            'options'=>array(
                'class'=>'btn btn-small',
            ),
            'visible'=>'$data->in_db < 1'
        ),
        'drop' => array
        (
            'label'=>'Remove',
            'icon'=>'remove',
            'url'=>'Yii::app()->createUrl("archives/admin", array("archive_id"=>$data->archive_id,"act"=>0))',
            'options'=>array(
                'class'=>'btn btn-small btn-danger',
            ),
            'visible'=>'$data->in_db == 1'
        ),
    )
),
/*    array(
        'header' => 'action',
        'type'=>'raw',
        'value' => '($data->in_db > 0) ? "<a href=\"#\";><span class=\"icon-remove\"></span></a>" : "<a href=\"#\";><span class=\"icon-share\"></span></a>"',
        'htmlOptions'=>array('style' => 'text-align: center;'),
    ),
*/
),
)); ?>
