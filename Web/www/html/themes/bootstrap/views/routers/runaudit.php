<?php
/* @var $this RoutersController */

$this->breadcrumbs = array(
    'Management',
);
?>

<?php if (Yii::app()->user->hasFlash('runaudit')) { ?>

    <?php
    $this->widget('bootstrap.widgets.TbAlert', array(
        'closeText' => FALSE,
        'alerts'    => array('runaudit'),
    ));
    ?>

    <?php

    /*    $url = Yii::app()->createUrl('routers/runaudit');
        Yii::app()->request->redirect($url);*/
    //echo CHtml::refresh(10, Yii::app()->createUrl('routers/runaudit'));
    ?>
    <script>

        jQuery(document).ready(function ($) {
            console.log('running');
            $('#selPeriod').prop("disabled", true);
            $('#yw1').prop("disabled", true);
            $('#yw2').prop("disabled", true);
            test();
        });
    </script>
    <?php
}
if (1) {
    $cur_disc = trim($model1->value);

    ?>

    <script type="text/javascript"
            src="<?php echo Yii::app()->baseUrl; ?>/js/libs/jquery-cron/cron/jquery-cron-min.js"></script>

    <link type="text/css" href="<?php echo Yii::app()->baseUrl; ?>/js/libs/jquery-cron/cron/jquery-cron.css"
          rel="stylesheet"/>
    <!--    <script type="text/javascript" src="--><?php //echo Yii::app()->baseUrl; ?><!--/js/libs/jquery-cron/gentleSelect/jquery-gentleSelect.js"></script>-->
    <!--    <link type="text/css" href="--><?php //echo Yii::app()->baseUrl; ?><!--/js/libs/jquery-cron/gentleSelect/jquery-gentleSelect.css" rel="stylesheet" /-->
    <script>
        var cron_field;
        jQuery(document).ready(function ($) {
            cron_field = $('#cron_builder').cron({
                    initial     : '<?=$cur_disc ?>',
                    onChange    : function () {
                        $('#cron_generated_value').text($(this).cron("value"));
                    },
                    customValues: {
                        "15 Minutes": "*/15 * * * *",
                        "30 Minutes": "*/30 * * * *",
                        "6 hours"   : "0 */6 * * *",
                        "12 hours"  : "0 */12 * * *",
                    },
//                useGentleSelect: true,
                }
            )
            ; // apply cron with default options
            //disable minute interval
            $('.cron-period option[value=minute]').prop({ disabled: true }).css({ display: 'none' });
            $(".dropdown-menu li a").click(function () {
                var selText = $(this).text();
                $(this).parents('.btn-group').find('.dropdown-toggle').html(selText + ' <span class="caret"></span>');
            });
        });
        function save_periodic() {
            var period = cron_field.cron('value');
            $('#cron_current_value').text('Saving to DB ...');
            $('#save_periofic').prop({ disabled: true }).text('Saving to DB ...');
            jQuery.ajax({
                url     : '<?php echo Yii::app()->createUrl('generalSettings/setperiod'); ?>',
                type    : 'POST',
                data    : { label: period, scanner_t: $('#scanner').val() },
                cache   : false,
                dataType: 'json',
                success : function (data) {
                    if (data.ok == 1) {

                        $('#cron_current_value').text(period);
                    } else {
                        alert('Save to DB Error');
                        $('#cron_current_value').text('Save to DB Error');
                    }
                }
            }).always(function () {
                $('#save_periofic').prop({ disabled: false }).text('Save periodic discovery');
            });
        }


    </script>
    <?php

    ?>

    <script>
        var started = false;
        function test() {
            if (started){
                return;
            }
            $('#selPeriod').prop("disabled", true);
            $("#yw1").prop("disabled", true);
            $("#yw2").prop("disabled", true);
            $(".progress").show();
            $("#progress1").html('0%');
            started=true;
            show_progress3(0);
        }

        var over50 = false;
        function show_progress3(progress_key) {
            var url = '<?php echo Yii::app()->controller->createUrl("routers/percentage"); ?>';

            var jqxhr = $.getJSON(url + "&key=" + progress_key, function (data) {
                console.log('success');

                var data = parseInt(data.percent);
                if (data < 16) {
                    $("#progress1").html('');
                    $("#progress2").html('');
                    $("#progress3").html('');
                    $("#progress1").css('width', data + '%');
                    $("#progress2").css('width', '0%');
                    $("#progress3").css('width', '0%');
                    $("#progress1").html(data + '%');
                }
                else if (data < 51) {
                    over50    = true;
                    var data1 = data - 15;
                    $("#progress1").html('');
                    $("#progress2").html('');
                    $("#progress3").html('');
                    $("#progress1").css('width', '15%');
                    $("#progress2").css('width', data1 + '%');
                    $("#progress3").css('width', '0%');
                    $("#progress2").html(data + '%');
                }
                else if (data < 100) {
                    over50    = true;
                    var data2 = data - 50;
                    $("#progress1").html('');
                    $("#progress2").html('');
                    $("#progress3").html('');
                    $("#progress1").css('width', '15%');
                    $("#progress2").css('width', '35%');
                    $("#progress3").css('width', data2 + '%');
                    $("#progress3").html(data + '%');
                }

                if (data < 0 || (data == 0 && over50)) {
                    $('#selPeriod').prop("disabled", false);
                    $("#yw1").prop("disabled", false);
                    $("#yw2").prop("disabled", false);
                    $("#progress3").html("<span style='color:green'>Done</done>");
                    started=false;
                } else {
                    setTimeout("show_progress3(" + data + ")", 2000);
                }
            })
                .fail(function (jqxhr, textStatus, error) {
                    var err = textStatus + ", " + error;
                    console.log("Request Failed: " + err);
                });
        }


        function show_progress(val) {

            var finish = parseInt(val) + parseInt(10);
            var data   = getRandomInt(val, finish);
            if (data < 36) {
                $("#progress1").html('');
                $("#progress2").html('');
                $("#progress3").html('');
                $("#progress1").css('width', data + '%');
                $("#progress2").css('width', '0%');
                $("#progress3").css('width', '0%');
                $("#progress1").html(data + '%');
            }
            else if (data < 56) {
                var data1 = data - 35;
                $("#progress1").html('');
                $("#progress2").html('');
                $("#progress3").html('');
                $("#progress1").css('width', '35%');
                $("#progress2").css('width', data1 + '%');
                $("#progress3").css('width', '0%');
                $("#progress2").html(data + '%');
            }
            else {
                var data2 = data - 55;
                $("#progress1").html('');
                $("#progress2").html('');
                $("#progress3").html('');
                $("#progress1").css('width', '35%');
                $("#progress2").css('width', '20%');
                $("#progress3").css('width', data2 + '%');
                $("#progress3").html(data + '%');
            }

            if (data == 100) {
                $("#progress3").html("Done");
            } else {
                setTimeout("show_progress(" + data + ")", 2000);
            }
        }


        function sleep(milliseconds) {
            var start = new Date().getTime();
            for (var i = 0; i < 1e7; i++) {
                if ((new Date().getTime() - start) > milliseconds) {
                    break;
                }
            }
        }

        function getRandomInt(min, max) {
            return Math.floor(Math.random() * (max - min + 1)) + min;
        }
    </script>
    <?php

    $form = $this->beginWidget('bootstrap.widgets.TbActiveForm', array(
        'id'          => 'inlineForm',
        'type'        => 'inline',
        'htmlOptions' => array('class' => 'well'),
    )); ?>
    <input type="hidden" name="tumbler" id="tumbler" value="1">

    <h5>Subnets scanner</h5>
    <?php if ($model2->value > 0) { ?>
        <input type="hidden" name="scanner" id="scanner" value="1">
        <?php
    } else {
        ?>
        <input type="hidden" name="scanner" id="scanner" value="0">
        <?php
    }
    ?>
    <input id="TheCheckBox" type="checkbox" class="BSswitch" name="scanner-checkbox" id="TheCheckBox"
           data-off-color="danger" data-on-color="success">


    <?php $this->widget('bootstrap.widgets.TbButton', array(
        'buttonType'  => 'ajaxSubmit',
        'label'       => 'Run Initial discovery',
        'type'        => 'danger',
        'htmlOptions' => array('style' => "margin-left:35px;", 'onclick' => "js:test();")
    )) ?>


    <br><br>
    <h5>Audit schedule</h5>
    <div id="cron_builder_help" style='display:none;font-family:"Courier New", Courier, monospace;'>
        <div style="white-space: pre-line">
            .---------------- minute (0 - 59)
            | .------------- hour (0 - 23)
            | | .---------- day of month (1 - 31)
            | | | .------- month (1 - 12) OR jan,feb,mar,apr ...
            | | | | .---- day of week (0 - 6) (Sunday=0 or 7) OR sun,mon,tue,wed,thu,fri,sat
            | | | | |
            * * * * *
        </div>
        <div><span id="cron_current_value"><?= $cur_disc ?></span> Current cronjob schedule</div>
        <div><span id="cron_generated_value"></span> New cronjob schedule</div>
        <br><br>
    </div>

    <div class="row">
        <div class="span12">
            <div id="cron_builder"></div>
        </div>
    </div>
    <br><br>
    <div class="row">

        <a href="javascript:" onclick="save_periodic()" id="save_periofic" class="span4 btn btn-primary">Save periodic
            discovery</a>
        <span class="span4"></span>
        <a href="javascript:" onclick="$('#cron_builder_help').slideToggle()" class="span4 btn btn-info">Help</a>
    </div>
    <?php $this->endWidget();
} ?>
<script>
    <?php if($model2->value > 0){?>
    $("[name='scanner-checkbox']").bootstrapSwitch('state', true);
    <?php
    }
    else
    {
    ?>
    $("[name='scanner-checkbox']").bootstrapSwitch('state', false);
    <?php
    }
    ?>
    $('.BSswitch').on('switchChange.bootstrapSwitch', function (event, state) {
        if (state) {
            $('#scanner').attr('value', '1');
        }
        else {
            $('#scanner').attr('value', '0');
        }
    });
</script>


<div class="progress progress-striped" style="display:none">
    <div class="bar bar-success" id="progress1" style="width: 0%;"></div>
    <div class="bar bar-warning" id="progress2" style="width: 0%;"></div>
    <div class="bar bar-info" id="progress3" style="width: 0%;"></div>
</div>


