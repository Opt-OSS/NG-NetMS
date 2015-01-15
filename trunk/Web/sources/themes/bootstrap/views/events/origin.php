<?php
/* @var $this EventsController */

$this->widget('bootstrap.widgets.TbBreadcrumbs', array(
    'links'=>array('Events','Summary of activity by origin')));
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
                array('buttonType' => 'submit', 'label' => 'Search','type'=>'primary','htmlOptions'=>array('id'=>'originsubmit','style'=>'vertical-align: top;'))
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
            var delete_cookie = function(name) {
                document.cookie = name + '=;expires=Thu, 01 Jan 1970 00:00:01 GMT;';
            };
            $('#datetimepicker1').datetimepicker('setDate', null);
            $('#datetimepicker2').datetimepicker('setDate', null);
            delete_cookie('from_date');
            delete_cookie('to_date');
            $('#originsubmit').click();
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

<script type="text/javascript">
    var arr = '<?php echo $piegoogle ?>';
    var arr1 = '<?php echo $piegoogle1 ?>';
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
     <span style="text-align:center"><h2>
             <?php
             $this->widget('bootstrap.widgets.TbLabel', array(
                 'type'=>'info', // 'success', 'warning', 'important', 'info' or 'inverse'
                 'label'=>'Cumulative severity',
                 'htmlOptions' =>array('style'=>'font-size: 24px; line-height: 24px;margin-top :20px;margin-bottom : 20px;'),
             ));
             ?>
         </h2></span>
     <div style="width:1107px">
         <div id="chart_div1" style ="width:550px;float:left;"></div>
         <div id="chart1_div1" style ="width:550px;float:right;"></div>
     </div>
<?php }
      else
      {
          echo "<div class='well'>";
          echo "<h3>Data not found</h3>";
          echo "</div>";
      }
?>