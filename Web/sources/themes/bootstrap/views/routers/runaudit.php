<?php
/* @var $this RoutersController */

$this->breadcrumbs=array(
	'Management',
);
?>

<?php if(Yii::app()->user->hasFlash('runaudit')){ ?>

<?php
    $this->widget('bootstrap.widgets.TbAlert', array(
    'closeText' => false,
    'alerts'=>array('runaudit'),
));
?>

    <?php

/*    $url = Yii::app()->createUrl('routers/runaudit');
    Yii::app()->request->redirect($url);*/
     echo CHtml::refresh(10, Yii::app()->createUrl('routers/runaudit'));

} else{ ?>
    <?php

    $this->beginWidget('bootstrap.widgets.TbModal', array('id'=>'periodset','htmlOptions' => array('style'=>'width: 400px;max-height:500px'))); ?>

    <div class="modal-header">
        <a class="close" data-dismiss="modal">&times;</a>
        <h4>Schedule periodic discovery every </h4>
    </div>

    <div class="modal-body">
        <form id="perioddiscovery">
            <input type="hidden" name="scanner_t" id="scanner_t" value=""/>
            <div class="well carousel-search hidden-sm">
                <div class="btn-group"> <a class="btn btn-default dropdown-toggle btn-select" data-toggle="dropdown" href="#"> <span class="caret"></span></a>
                    <ul class="dropdown-menu">
                        <li><a href="#">15 min</a></li>
                        <li><a href="#">30 min</a></li>
                        <li><a href="#">hour</a></li>
                        <li><a href="#">6 hours</a></li>
                        <li><a href="#">12 hours</a></li>
                        <li><a href="#">day</a></li>
                        <li><a href="#">week</a></li>
                    </ul>
                </div>
            </div>
        </form>
    </div>
    <script>
        $(".dropdown-menu li a").click(function(){
            var selText = $(this).text();
            $(this).parents('.btn-group').find('.dropdown-toggle').html(selText+' <span class="caret"></span>');
        });

    </script>

    <div class="modal-footer">
        <div class="btn-group">
            <button type="button" id="btnSearch" class="btn btn-primary">Save</button>
        </div>
        <?php $this->widget('bootstrap.widgets.TbButton', array(
            'label'=>'Close',
            'url'=>'#',
            'htmlOptions'=>array('data-dismiss'=>'modal'),
        )); ?>
        <script>
            $("#btnSearch").click(function(){
                var period = $('.btn-select').text();
                var scanner_t = $(".modal-body #scanner_t").val();
                if(period.substr(0, 5)  =='Every')
                {
                    alert ("Select period, please");
                }
                else
                {
                    var arr_per = {label:period,scanner_t:scanner_t};
                    $.ajax({
                        url     : '<?php echo Yii::app() -> createUrl('generalSettings/setperiod'); ?>',
                        type    : 'POST',
                        data    : arr_per,
                        cache   : false,
                        dataType:'json',
                        success : function(data) {
                            $('#yw2').html('Schedule periodic discovery (current: every '+period+')')
                        }
                    });
                    $("#periodset").modal("hide");
                }

            });
        </script>
    </div>

    <?php $this->endWidget(); ?>

    <script>

        function viewForm(scanner) {
                    $('.modal-body').css('height', '300px');
                    $.ajax({
                        url     : '<?php echo Yii::app() -> createUrl('generalSettings/getperiod'); ?>',
                        type    : 'POST',
                        cache   : false,
                        dataType:'json',
                        success : function(data) {
                            $('.btn-group').find('.dropdown-toggle').html(data.label+' <span class="caret"></span>');
                        }
                    });
                    $(".modal-body #scanner_t").val( scanner );
                    $("#periodset").modal("show");
                }
        function test() {

            $("#yw1").prop("disabled",true);
            $("#yw2").prop("disabled",true);
            $( ".progress" ).show();
            $("#progress1").html('0%');
            show_progress3(0);


            /*           $( ".progress" ).show();
            $("#progress1").html('0%');
            show_test();

            show_progress(0);
*/
        }


        function show_progress3(progress_key)
        {
            var url = '<?php echo Yii::app()->controller->createUrl("routers/percentage"); ?>';

            var jqxhr = $.getJSON(url + "&key=" + progress_key, function(data) {
                console.log('success');

                var data = parseInt(data.percent);
                if(data < 16)
                {
                    $("#progress1").html('');
                    $("#progress2").html('');
                    $("#progress3").html('');
                    $("#progress1").css('width',data+'%');
                    $("#progress2").css('width','0%');
                    $("#progress3").css('width','0%');
                    $("#progress1").html(data+'%');
                }
                else if(data < 51)
                {
                    var data1 = data - 15;
                    $("#progress1").html('');
                    $("#progress2").html('');
                    $("#progress3").html('');
                    $("#progress1").css('width','15%');
                    $("#progress2").css('width',data1+'%');
                    $("#progress3").css('width','0%');
                    $("#progress2").html(data+'%');
                }
                else
                {
                    var data2 = data - 50;
                    $("#progress1").html('');
                    $("#progress2").html('');
                    $("#progress3").html('');
                    $("#progress1").css('width','15%');
                    $("#progress2").css('width','35%');
                    $("#progress3").css('width',data2+'%');
                    $("#progress3").html(data+'%');
                }

                if (data == 100) {
                    $("#progress3").html("Done");
                    $("#yw1").prop("disabled",false);
                    $("#yw2").prop("disabled",false);
                } else {
                    setTimeout("show_progress3("+data+")", 2000);
                }
            })
                .fail(function( jqxhr, textStatus, error ) {
                    var err = textStatus + ", " + error;
                    console.log( "Request Failed: " + err );
                });
        }


        function show_progress(val)
        {

            var finish = parseInt(val)+parseInt(10);
            var data = getRandomInt(val,finish);
            if(data < 36)
            {
                $("#progress1").html('');
                $("#progress2").html('');
                $("#progress3").html('');
                $("#progress1").css('width',data+'%');
                $("#progress2").css('width','0%');
                $("#progress3").css('width','0%');
                $("#progress1").html(data+'%');
            }
        else if(data < 56)
        {
            var data1 = data - 35;
            $("#progress1").html('');
            $("#progress2").html('');
            $("#progress3").html('');
            $("#progress1").css('width','35%');
            $("#progress2").css('width',data1+'%');
            $("#progress3").css('width','0%');
            $("#progress2").html(data+'%');
        }
        else
        {
            var data2 = data - 55;
            $("#progress1").html('');
            $("#progress2").html('');
            $("#progress3").html('');
            $("#progress1").css('width','35%');
            $("#progress2").css('width','20%');
            $("#progress3").css('width',data2+'%');
            $("#progress3").html(data+'%');
        }

            if (data == 100) {
                $("#progress3").html("Done");
            } else {
                setTimeout("show_progress("+data+")", 2000);
            }
        }


        function sleep(milliseconds) {
            var start = new Date().getTime();
            for (var i = 0; i < 1e7; i++) {
                if ((new Date().getTime() - start) > milliseconds){
                    break;
                }
            }
        }

        function getRandomInt(min, max)
        {
            return Math.floor(Math.random() * (max - min + 1)) + min;
        }
    </script>
<?php

    $form = $this->beginWidget('bootstrap.widgets.TbActiveForm', array(
        'id'=>'inlineForm',
        'type'=>'inline',
        'htmlOptions'=>array('class'=>'well'),
    )); ?>
<input type="hidden" name="tumbler" id="tumbler" value="1">

    <h5>Subnets scanner</h5>
    <?php if($model2->value > 0){?>
        <input type="hidden" name="scanner" id="scanner" value="1">
<?php
    }
    else
    {
?>
    <input type="hidden" name="scanner" id="scanner" value="0">
<?php
    }
?>
    <input id="TheCheckBox" type="checkbox" class="BSswitch" name="scanner-checkbox" id="TheCheckBox" data-off-color="danger" data-on-color="success">


    <?php $this->widget('bootstrap.widgets.TbButton', array('buttonType'=>'ajaxSubmit', 'label'=>'Run Initial discovery','type' => 'danger','htmlOptions'=>array('style'=>"margin-left:35px;",'onclick' => "js:test();"))) ?>
    <?php
    $cur_disc = array_search($model1->value, Yii::app()->params['cronperiods']);
    $this->widget(
        'bootstrap.widgets.TbButton', array('buttonType' => 'ajaxSubmit', 'label' => "Schedule periodic discovery (current: every $cur_disc)", 'type' => 'info',
            'htmlOptions'=>array('style'=>"margin-left:35px;",'onclick' => "js:var scan_t = $('#scanner').val(); viewForm(scan_t);return false;"),)
    );
    ?>

<?php $this->endWidget(); }?>
<script>
    <?php if($model2->value > 0){?>
    $("[name='scanner-checkbox']").bootstrapSwitch('state',true);
    <?php
    }
    else
    {
?>
    $("[name='scanner-checkbox']").bootstrapSwitch('state',false);
    <?php
        }
    ?>
    $('.BSswitch').on('switchChange.bootstrapSwitch', function (event, state) {
        if(state)
        {
            $('#scanner').attr('value','1');
        }
        else
        {
            $('#scanner').attr('value','0');
        }
    });
</script>





<div class="progress progress-striped" style ="display:none">
    <div class="bar bar-success" id = "progress1" style="width: 0%;"></div>
    <div class="bar bar-warning" id = "progress2" style="width: 0%;"></div>
    <div class="bar bar-info" id = "progress3" style="width: 0%;"></div>
</div>


