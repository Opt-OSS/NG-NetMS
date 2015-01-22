<?php
/* @var $this RoutersController */

$this->breadcrumbs=array(
	'Management',
);
?>

<?php if(Yii::app()->user->hasFlash('runaudit')){ ?>

<?php $this->widget('bootstrap.widgets.TbAlert', array(
    'alerts'=>array('runaudit'),
)); } else{ ?>
    <?php

    $this->beginWidget('bootstrap.widgets.TbModal', array('id'=>'periodset','htmlOptions' => array('style'=>'width: 400px;max-height:500px'))); ?>

    <div class="modal-header">
        <a class="close" data-dismiss="modal">&times;</a>
        <h4>Schedule periodic discovery every </h4>
    </div>

    <div class="modal-body">
        <form id="perioddiscovery">
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
                if(period.substr(0, 5)  =='Every')
                {
                    alert ("Select period, please");
                }
                else
                {
                    var arr_per = {label:period};
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

        function viewForm() {
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
                    $("#periodset").modal("show");
                }
    </script>
<?php

    $form = $this->beginWidget('bootstrap.widgets.TbActiveForm', array(
        'id'=>'inlineForm',
        'type'=>'inline',
        'htmlOptions'=>array('class'=>'well'),
    )); ?>
<input type="hidden" name="tumbler" id="tumbler" value="1">
<input type="hidden" name="scanner" id="scanner" value="0">
    <h5>Subnets scanner</h5>

<input id="TheCheckBox" type="checkbox" class="BSswitch" name="scanner-checkbox" id="TheCheckBox" data-off-color="danger" data-on-color="success">
<?php $this->widget('bootstrap.widgets.TbButton', array('buttonType'=>'submit', 'label'=>'Run Initial discovery','type' => 'danger','htmlOptions'=>array('style'=>"margin-left:35px;",))); ?>
    <?php
    $cur_disc = array_search($model1->value, Yii::app()->params['cronperiods']);
    $this->widget(
        'bootstrap.widgets.TbButton', array('buttonType' => 'ajaxSubmit', 'label' => "Schedule periodic discovery (current: every $cur_disc)", 'type' => 'info',
            'htmlOptions'=>array('style'=>"margin-left:35px;",'onclick' => "js: viewForm();return false;"),)
    );
    ?>

<?php $this->endWidget(); }?>
<script>
    $("[name='scanner-checkbox']").bootstrapSwitch('state',false);
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
