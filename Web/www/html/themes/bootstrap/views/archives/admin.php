<?php
use NGNMS\Emsgd;

$this->breadcrumbs = array(
    'Archive Manager' => array('index'),
    'Manage Archives',
);

?>

<h1>Manage Archives</h1>
<?
$show_buttons ='true';
$loading = (new JobMachineClient('archive.load'))->get_running_tasks();
$unloading = (new JobMachineClient('archive.unload'))->get_running_tasks();

$str = [];
foreach($loading as $i){
    $p = json_decode($i['parameters']);
    $str[] = '<div class="jm-alert alert alert-info">Archive #'.$p->archive_id.' is loading</div>';
}
foreach($unloading as $i){
    $p = json_decode($i['parameters']);
    $str[] = '<div class="jm-alert alert alert-info"> Archive #'.$p->archive_id.' is unloading </div>';
}

if ($str) {
    $show_buttons = 'false';
    echo join('',$str);
    ?>
    <script>
        jQuery(document).ready(function ($) {
            setTimeout(function(){location.reload()},10000);
            setInterval(function(){
                $('.jm-alert').each(function (el) {
                    this.innerHTML +=  '.'
                })
            },1000);
        })
    </script>
<?
}


$this->widget('bootstrap.widgets.TbGridView', array(
    'id' => 'archives-grid',
    'dataProvider' => $model->search(),
    'type' => 'striped bordered condensed',
    'filter' => $model,
    'columns' => array(
        'archive_id',
        'start_time',
        'end_time',
        'file_name',
        array(
            'header' => 'Loaded<br> in DB',
            'type' => 'raw',
            'value' => '($data->in_db > 0) ? "<span class=\"icon-ok\"></span>" : "<span class=\"icon-minus\"></span>"',
            'htmlOptions' => array('style' => 'text-align: center;'),
        ),
        array(
            'class' => 'bootstrap.widgets.TbButtonColumn',
            'template' => '{add}{drop} ',
            'buttons' => array
            (
                'add' => array
                (
                    'label' => 'Load',
                    'icon' => 'share',
                    'url' => 'Yii::app()->createUrl("archives/admin", array("archive_id"=>$data->archive_id,"act"=>1))',
                    'options' => array(
                        'class' => 'btn btn-small',
                    ),
                    'visible' => $show_buttons.' && $data->in_db < 1'
                ),
                'drop' => array
                (
                    'label' => 'Unload',
                    'icon' => 'remove',
                    'url' => 'Yii::app()->createUrl("archives/admin", array("archive_id"=>$data->archive_id,"act"=>0))',
                    'options' => array(
                        'class' => 'btn btn-small btn-danger',
                    ),
                    'visible' => $show_buttons.' && $data->in_db == 1'
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
