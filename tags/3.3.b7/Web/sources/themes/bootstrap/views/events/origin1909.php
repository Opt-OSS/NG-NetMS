<?php
/* @var $this EventsController */

$this->breadcrumbs=array(
	'Events','Summary activities by origin'
);
$form = $this->beginWidget(
    'bootstrap.widgets.TbActiveForm', array(
        'id' => 'inlineEventsOriginForm',
        'enableAjaxValidation'=>true,
        'type' => 'inline',
    )
);
?>

    <div class="well">
        <span style ="margin :10px">FROM</span>
        <div id="datetimepicker1" class="input-append date">
            <input name = "from_date" id = "from_date" value = "<?php $value1 = isset(Yii::app()->request->cookies['from_date']) ? Yii::app()->request->cookies['from_date']->value : '';echo $value1; ?>" data-format="dd/MM/yyyy hh:mm:ss" type="text"></input>
    <span class="add-on">
      <i data-time-icon="icon-time" data-date-icon="icon-calendar">
      </i>
    </span>
        </div>
        <span style ="margin :10px">TO</span>
        <div id="datetimepicker2" class="input-append date">
            <input name = "to_date" value = "<?php $value2 = isset(Yii::app()->request->cookies['to_date']) ? Yii::app()->request->cookies['to_date']->value : '';echo $value2 ?>" data-format="dd/MM/yyyy hh:mm:ss" type="text"></input>
    <span class="add-on">
      <i data-time-icon="icon-time" data-date-icon="icon-calendar">
      </i>
    </span>
        </div>
        <span style ="margin :10px">
            <?php
           /* $this->widget(
                'bootstrap.widgets.TbButton', array('buttonType' => 'ajaxSubmit', 'label' => 'Search','type'=>'primary',
                    'htmlOptions'=>array('style'=>'vertical-align: top;','onclick' => "js: submitForm();return false;"),)
            );*/
            $this->widget(
                'bootstrap.widgets.TbButton',
                array('buttonType' => 'submit', 'label' => 'Search','type'=>'primary','htmlOptions'=>array('style'=>'vertical-align: top;'))
            );
            echo '</span><span>';
            $this->widget(
                'bootstrap.widgets.TbButton', array('buttonType' => 'ajaxSubmit', 'label' => 'Reset','type'=>'danger',
                    'htmlOptions'=>array('style'=>'vertical-align: top;','onclick' => "js: resetForm();return false;"),)
            );
            ?>
        </span>
    </div>
    <script type="text/javascript">

        function resetForm() {
            $('#datetimepicker1').datetimepicker('setDate', null);
            $('#datetimepicker2').datetimepicker('setDate', null);
        }
        $(function() {
            $('#datetimepicker1').datetimepicker({
                language: 'en-En'
            });
            $('#datetimepicker2').datetimepicker({
                language: 'en-En'
            });
        });
    </script>


<?php
$this->endWidget();
$this->widget('bootstrap.widgets.TbGridView', array(
        'type'            => 'striped bordered condensed',
        'id'              => 'events-grid',
        'dataProvider'    => $model->search(),
        'filter'          => $model,  
        'enablePagination'=>true,
        'template'=>"{items}{pager}",
        'columns'         => array(
        array('name'=>'origin', 'header'=>'Router'),
        'numofevents',
        'sumseverity',
            array(
            'class'=>'bootstrap.widgets.TbButtonColumn',
             'template'=>'{view}',
                        'buttons'=>array(       
                                'view' => array(
                                  'url'=>'Yii::app()->controller->createUrl("events/origindet", array("origin"=>$data["origin"],"origin_id"=>$data["origin_id"]))',
                                ),
                            ),
            'htmlOptions'=>array('style'=>'width: 50px'),
            ),
        ),

    ));
 if ($flag) {
?>

<div style="height: 700px;margin-bottom:20px;">
    <?php
    $this->widget('bootstrap.widgets.TbLabel', array(
        'type'=>'info', // 'success', 'warning', 'important', 'info' or 'inverse'
        'label'=>'Number of events',
        'htmlOptions' =>array('style'=>'font-size: 24px; line-height: 24px;margin-top :20px;margin-bottom : 20px;'),
    ));
    ?>
<div>

<?php

        $this->widget(
            'chartjs.widgets.ChPolar',
            array(
                'width' => 600,
                'height' => 300,
                'htmlOptions' => array("id"=>'chart1',"margin"=> "10px auto"),
                'drawLabels' => true,
                'datasets' => $pollar,
                'options' => array('scaleStepWidth'=> 1000,)
            )
        );
?>
</div>
    <?php
    $this->widget('bootstrap.widgets.TbLabel', array(
        'type'=>'info', // 'success', 'warning', 'important', 'info' or 'inverse'
        'label'=>'Severity',
        'htmlOptions' =>array('style'=>'font-size: 24px; line-height: 24px;margin-top :20px;margin-bottom : 20px;'),
    ));
    ?>
<div style="float:right">

<?php $this->widget(
        'chartjs.widgets.ChPolar',
        array(
            'width' => 600,
            'height' => 300,
            'htmlOptions' => array("id"=>'chart2',"margin"=> "10px auto"),
            'drawLabels' => true,
            'datasets' => $pollar1,
            'options' => array()
        )
    );
    ?>
</div>
</div>

<div style="height: 700px;margin-bottom:20px;">
    <?php
    $this->widget('bootstrap.widgets.TbLabel', array(
        'type'=>'info', // 'success', 'warning', 'important', 'info' or 'inverse'
        'label'=>'Number of events',
        'htmlOptions' =>array('style'=>'font-size: 24px; line-height: 24px;margin-top :20px;margin-bottom : 20px;'),
    ));
    ?>
    <div>

<?php
$this->widget(
    'chartjs.widgets.ChPie',
    array(
        'width' => 600,
        'height' => 300,
        'htmlOptions' => array(),
        'drawLabels' => true,
        'datasets' => $pollar,
        'options' => array('segmentShowStroke' => true,)
    )
);
?>
    </div>
    <?php
    $this->widget('bootstrap.widgets.TbLabel', array(
        'type'=>'info', // 'success', 'warning', 'important', 'info' or 'inverse'
        'label'=>'Severity',
        'htmlOptions' =>array('style'=>'font-size: 24px; line-height: 24px;margin-top :20px;margin-bottom : 20px;'),
    ));
    ?>
    <div style="float:right">
<?php
$this->widget(
    'chartjs.widgets.ChPie',
    array(
        'width' => 600,
        'height' => 300,
        'htmlOptions' => array(),
        'drawLabels' => true,
        'datasets' => $pollar1,
        'options' => array()
    )
);

?>
    </div>
</div>
<div style="height: 700px;margin-bottom:20px;">
    <?php
    $this->widget('bootstrap.widgets.TbLabel', array(
        'type'=>'info', // 'success', 'warning', 'important', 'info' or 'inverse'
        'label'=>'Number of events',
        'htmlOptions' =>array('style'=>'font-size: 24px; line-height: 24px;margin-top :20px;margin-bottom : 20px;'),
    ));
    ?>
    <div>
<?php
$this->widget(
    'chartjs.widgets.ChDoughnut',
    array(
        'width' => 600,
        'height' => 300,
        'htmlOptions' => array(),
        'drawLabels' => true,
        'datasets' => $pollar,
        'options' => array()
    )
);
?>
    </div>
    <?php
    $this->widget('bootstrap.widgets.TbLabel', array(
        'type'=>'info', // 'success', 'warning', 'important', 'info' or 'inverse'
        'label'=>'Severity',
        'htmlOptions' =>array('style'=>'font-size: 24px; line-height: 24px;margin-top :20px;margin-bottom : 20px;'),
    ));
    ?>
    <div style="float:right">
<?php
$this->widget(
    'chartjs.widgets.ChDoughnut',
    array(
        'width' => 600,
        'height' => 300,
        'htmlOptions' => array(),
        'drawLabels' => true,
        'datasets' => $pollar1,
        'options' => array()
    )
);
?>
    </div>
</div>
<div style="height: 350px;margin-top:20px;margin-bottom:20px;">
    <?php
    $this->widget('bootstrap.widgets.TbLabel', array(
        'type'=>'info', // 'success', 'warning', 'important', 'info' or 'inverse'
        'label'=>'Number of events',
        'htmlOptions' =>array('style'=>'font-size: 24px; line-height: 24px;margin-top :20px;margin-bottom : 20px;'),
    ));
    ?>
<div>
<?php
$this->widget(
    'chartjs.widgets.ChBars',
    array(
        'width' => 600,
        'height' => 300,
        'htmlOptions' => array(),
        'labels' => $labels,
        'datasets' => array(
            array(
                "fillColor" => "#ff00ff",
                "strokeColor" => "rgba(151,187,205,0.8)",
                "fillColor" => "rgba(151,187,205,0.5)",
                "highlightFill" => "rgba(151,187,205,0.75)",
                "highlightStroke" => "rgba(151,187,205,1)",
                "data" => $valore
            )
        ),
        'options' => array()
    )
);
?>
    </div>
</div>
<script type="text/javascript">
    var arr = '<?php echo $piegoogle ?>';
    $(function(){
        bindFunctions();
    })
</script>
<span style="text-align:center"><h2>
        <?php
        $this->widget('bootstrap.widgets.TbLabel', array(
            'type'=>'info', // 'success', 'warning', 'important', 'info' or 'inverse'
            'label'=>'Number of events',
            'htmlOptions' =>array('style'=>'font-size: 24px; line-height: 24px;margin-top :20px;margin-bottom : 20px;'),
        ));
        ?>
    </h2></span>
<div style="width:1107px">
<div id="chart_div" style ="width:550px;float:left;"></div>
<div id="chart1_div" style ="width:550px;float:right;"></div>
</div>
<?php }
      else
      {
          echo "<div class='well'>";
          echo "<h3>Data not found</h3>";
          echo "</div>";
      }
?>