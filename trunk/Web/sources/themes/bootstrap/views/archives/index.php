<?php
$this->breadcrumbs=array(
	'Archive Manager',
);
?>

<h1>Archive Manager</h1>


<?php
$form = $this->beginWidget(
'bootstrap.widgets.TbActiveForm',
array(
'id' => 'verticalForm',
'htmlOptions' => array('class' => 'well'), // for inset effect
)
);
?>
<div class="form-group">
    <label class="nav-header"  style = "margin-left: 70px" for="older_time"> Archive alarms older than </label>
    <div style = "margin-left: 50px">
        <input type="text" style = "margin-left: 20px;margin-right: 189px;margin-top:10px" name="older_time" id="older_time" style="width: 200px;margin-right : 170px">
        <input id="TheCheckBox" type="checkbox" class="BSswitch"  name="archive-enable" id="TheCheckBox" onText="Enable" offText="Disable" data-off-color="danger" data-on-color="success" >

    </div>
</div>
<div class="form-group">
    <label class="nav-header" style = "margin-left: 70px" for="expired_time"> Delete alarams every </label>
    <div style = "margin-left: 50px">
        <input type="text" style = "margin-left: 20px;margin-top:9px" name="expired_time" id="expired_time" style="width: 200px;">
        <?php $this->widget(
            'bootstrap.widgets.TbButton',
            array(
                'label' => 'Manage Archives',
                'type' => 'primary',
                'url' => array('admin'),
                'htmlOptions'=>array('style'=>"margin-left:192px;width : 230px")
            )
        );
        ?>
    </div>
</div>
<div class="form-group">
    <label class="nav-header" style = "margin-left: 70px" for="delete_time"> Delete archives older than </label>
    <div style = "margin-left: 50px">
        <input type="text" style = "margin-left: 20px;margin-top:9px" name="delete_time" id="delete_time" style="width: 200px;">
        <?php $this->widget('bootstrap.widgets.TbButton', array('buttonType'=>'ajaxSubmit', 'label'=>'Apply','type' => 'success','htmlOptions'=>array('style'=>"margin-left:192px;width : 110px",'onclick' => "js:test();"))) ?>
        <?php $this->widget('bootstrap.widgets.TbButton', array( 'label'=>'Cancel','type' => 'info','url' => array('site/index'), 'htmlOptions'=>array('style'=>"margin-left:30px;width : 88px"))) ?>
    </div>
</div>
<br/>
<div class="form-group">
    <div>

    </div>
</div>




<script>

    $.fn.bootstrapSwitch.defaults.onText = 'Archiving Enabled';
    $.fn.bootstrapSwitch.defaults.offText = 'Archiving Disabled';
    $("[name='archive-enable']").bootstrapSwitch('state',false);

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
    function test() {

       alert('Ura!!!');
    }
</script>
<?php
$this->endWidget();
unset($form);
?>

