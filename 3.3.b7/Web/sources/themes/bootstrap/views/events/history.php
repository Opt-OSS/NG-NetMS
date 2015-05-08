<?php
/* @var $this EventsController */


$this->widget('bootstrap.widgets.TbBreadcrumbs', array(
    'links'=>array('Events','Summary of activity by origin'=>'index.php?r=events/summarybyorigin', 'History '.$model->origin),
));

?>

<script type="text/javascript">

    var arr = '<?php echo $datachart;?>';

    var start_prev = '<?php echo $stop_prev;?>';
    var start_next = '<?php echo $stop_next;?>';
    var step = '<?php echo $step?>';
    var router = '<?php echo $model->origin_id;?>';
    var router_name = '<?php echo $model->origin;?>';
    var max_dat = '<?php echo $max_dat;?>';
    var min_dat = '<?php echo $min_dat;?>';
    var flag1 = '<?php echo $flag1;?>';
    var flag2 = '<?php echo $flag2;?>';
    var fr_to = '<?php echo $from_to;?>';
    var arr1 = JSON.parse(arr)
    // Load the Visualization API and the controls package.
    google.load('visualization', '1.0', {'packages':['controls','linechart']});
   // google.load('visualization', '1.1', {'packages':['controls','linechart']});
    // Set a callback to run when the Google Visualization API is loaded.
    //google.setOnLoadCallback(drawDashboard);
    google.setOnLoadCallback(function(){ drawDashboard(arr1) })

    $(function(){
        showButtons(flag1,'buttonNext');
        showButtons(flag2,'buttonPrev');
    })


</script>

<div class="well">
<?php
    $form = $this->beginWidget(
    'bootstrap.widgets.TbActiveForm', array(
    'id' => 'inlinehistoryForm',
    'type' => 'inline',
    )
    );
?>
    <label >END OF PERIOD : </label>
    <div id="datetimepicker3" class="input-append date">
        <input name = "from_to" id = "from_to" value = "<?php $value1 = isset(Yii::app()->request->cookies['to_date']) ? Yii::app()->request->cookies['to_date']->value : '';echo $value1; ?>" data-format="dd/MM/yyyy hh:mm:ss" type="text"></input>
    <span class="add-on">
      <i data-time-icon="icon-time" data-date-icon="icon-calendar">
      </i>
    </span>
    <span style ="margin :15px">

            <label >CHART STEP : </label>
    </span>
    <span style ="margin :5px">
        <select id="step" name="step">
                    <option value="1">1 sec</option>
                    <option value="2">2 sec</option>
                    <option value="5">5 sec</option>
                    <option value="10">10 sec</option>
                    <option value="15">15 sec</option>
                    <option value="30">30 sec</option>
                    <option value="60">1 min</option>
                    <option value="120">2 min</option>
                    <option value="300">5 min</option>
                    <option value="600">10 min</option>
                    <option value="900">15 min</option>
                    <option value="1800">30 min</option>
                    <option value="3600" selected >1 hour</option>
                    <option value="10800">3 hour</option>
                    <option value="21600">6 hour</option>
                    <option value="43200">12 hours</option>
                    <option value="86400">24 hours</option>


        </select>
    </span>

    </span>
    </div>
    <span style ="margin :10px">
            <?php
            $this->widget(
                'bootstrap.widgets.TbButton', array('buttonType' => 'ajaxSubmit', 'label' => 'Build','type'=>'primary',
                    'htmlOptions'=>array('style'=>'vertical-align: top;','onclick' => "js: buildChart();return false;"),)
            );
            $this->endWidget();
            unset($form);
            ?>
    </span>
</div>
<script type="text/javascript">
    $(function() {
        $('#datetimepicker3').datetimepicker({
            language: 'en-En',
            endDate: new Date(max_dat),
            startDate: new Date(min_dat)
        });
    });
</script>
<div id="nav_chart_div" style="width: 820px; ">
    <?php
    $this->widget('bootstrap.widgets.TbButton', array(
        'label'=>'',
        'type'=>'success', // null, 'primary', 'info', 'success', 'warning', 'danger' or 'inverse'
//'size'=>'small', // null, 'large', 'small' or 'mini'
        'icon' => 'icon-chevron-left icon-white',
        'htmlOptions'=>array('id'=>'buttonPrev'),
    ));

    $this->widget('bootstrap.widgets.TbButton', array(
        'label'=>'',
        'type'=>'success', // null, 'primary', 'info', 'success', 'warning', 'danger' or 'inverse'
//    'size'=>'small', // null, 'large', 'small' or 'mini'
        'icon' => 'icon-chevron-right icon-white',
        'htmlOptions'=>array('id'=>'buttonNext','style'=>'float:right'),
    ));
    ?>
</div>

<div style="clear:both;">
<input type=hidden id='firstdate' name='firstdate' value="">
<input type=hidden id='lastdate' name='lastdate' value="">
<div id="dashboard_div" style="width: 1300px;margin-left:-120px">
<div id="chart_div" style="width: 1300px; height: 500px;"></div>
    <div  style=" height: 25px;"></div>
    <div id="filter_div" style="width: 1060px; height: 200px;"></div>
</div>
<div  style=" height: 40px;"></div>
<div id="dataevents">
    <?php

    $this->widget(
        'bootstrap.widgets.TbButton',
        array(  'buttonType' => 'link',
            'label' => 'Show events',
            'url' => array('events/datatableevents',
                'origin_id'=>$model->origin_id,'origin'=>$model->origin,'start_d'=>$stop_prev,'end_d'=>$stop_next),
            'type'=>'info',
            'htmlOptions'=>array(
                'style'=>'vertical-align: top;',
                'target'=>'_blank',
                'id'=>'test1',
                'onclick'=>'js: var o_hr = $("#test1").attr("href"); var res = o_hr.split("&");  res[3]="start_d="+parseDat($("#firstdate").val());res[4]="&end_d="+parseDat($("#lastdate").val());var n_hr = res[0]+ "&" +res[1] +"&"+res[2]+"&"+res[3]+"&"+res[4];$("#test1").attr("href",n_hr)',

            ),
        )
    );
?>
</div>
<div  style=" height: 40px;"></div>


<script>
    $('#buttonPrev').click(function(){
            $.ajax({
                url     : '<?php echo Yii::app() -> createUrl('events/history'); ?>',
                type    : 'POST',
                data    : {start_d: start_prev, origin_id:router ,step:step, origin:router_name},
                cache   : false,
                dataType:'json',
                success : function(data) {
                    arr_data = JSON.parse(data[0]);
                    arr_chart = JSON.parse(data[1]);
                    console.log(arr_data);
                    start_prev = arr_data[0];
                    start_next = arr_data[1];
                    flag1 = arr_data[2];
                    flag2 = arr_data[3];
                    fr_to = arr_data[4];
                    $('#from_to').val(fr_to)
                    showButtons(flag1,'buttonNext');
                    showButtons(flag2,'buttonPrev');
                    drawDashboard(arr_chart) ;

                }
            });
     });

    $('#buttonNext').click(function(){
        $.ajax({
            url     : '<?php echo Yii::app() -> createUrl('events/history'); ?>',
            type    : 'POST',
            data    : {start_d: start_next, origin_id:router ,step:step, origin:router_name},
            cache   : false,
            dataType:'json',
            success : function(data) {
                arr_data = JSON.parse(data[0]);
                arr_chart = JSON.parse(data[1]);
                console.log(arr_chart)
                start_prev = arr_data[0];
                start_next = arr_data[1];
                flag1 = arr_data[2];
                flag2 = arr_data[3];
                fr_to = arr_data[4];
                $('#from_to').val(fr_to);
                showButtons(flag1,'buttonNext');
                showButtons(flag2,'buttonPrev');
                drawDashboard(arr_chart) ;

            }
        });
    });

        function buildChart() {
            var zn = $('#from_to').val();
            start_next = parseDat(zn);
            var stop_date = $('#from_to').val().split(" ");
            if(stop_date !="")
            {
                var dat1 = stop_date[0].split("/");
                var dat2 = stop_date[1].split(":");
                start_next = dat1[2]+"-"+dat1[1]+"-"+dat1[0]+" "+ dat2[0]+":"+dat2[1]+":"+dat2[2];
            }
            else
            {
                start_next ="";
            }
            step = $('#step').val();
            $.ajax({
                url     : '<?php echo Yii::app() -> createUrl('events/history'); ?>',
                type    : 'POST',
                data    : {start_d: start_next, origin_id:router ,step:step, origin:router_name},
                cache   : false,
                dataType:'json',
                success : function(data) {
                    arr_data = JSON.parse(data[0]);
                    arr_chart = JSON.parse(data[1]);
                    console.log(arr_data);
                    start_prev = arr_data[0];
                    start_next = arr_data[1];
                    flag1 = arr_data[2];
                    flag2 = arr_data[3];
                    fr_to = arr_data[4];
                    $('#from_to').val(fr_to)
                    showButtons(flag1,'buttonNext');
                    showButtons(flag2,'buttonPrev');
                    drawDashboard(arr_chart) ;

                }
            });

    };

    function buildEventsTable()
    {
        var val1=$('#firstdate').val();
        var val2= $('#lastdate').val();
        var dat1 = parseDat(val1);
        var dat2 = parseDat(val2);
        $.ajax({
            url     : '<?php echo Yii::app() -> createUrl('events/datatableevents'); ?>',
            type    : 'POST',
            data    : {start_d: dat1, end_d:dat2 ,origin_id:router, origin:router_name},
            cache   : false,
            dataType:'html',
            success : function(data) {
                $('#dataevents').html(data)


            }
        });


    }

    function parseDat(val)
    {
        var stop_date = val.split(" ");
        if(stop_date !="")
        {
            var dat1 = stop_date[0].split("/");
            var dat2 = stop_date[1].split(":");
            dat3 = dat1[2]+"-"+dat1[1]+"-"+dat1[0]+" "+ dat2[0]+":"+dat2[1]+":"+dat2[2];
        }
        else
        {
            dat3 ="";
        }

        return dat3;
    }

</script>