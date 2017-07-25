<?php
/**
 * createItems.php
 *
 * @author Spyros Soldatos <spyros@valor.gr>
 * @link http://code.google.com/p/srbac/
 */

/**
 * The auth items auto creation view
 *
 * @author Spyros Soldatos <spyros@valor.gr>
 * @package srbac.views.authitem.manage
 * @since 1.0.2
 */
 ?>
<?php
$script = "jQuery('#cb_createTasks').click(function(){
$('#userTask').toggle('fast');
$('#adminTask').toggle('fast');
});";

Yii::app()->clientScript->registerScript("cb",$script,CClientScript::POS_READY);
?>
<div class="srbacForm">
  <?php echo SHtml::form() ?>
  <div class="action">
    <?php echo "<b>".$controller."</b>" ?>
  </div>
  <?php if (count($actions)>0) { ?>
  <div>
      <?php echo SHtml::checkBoxList("actions", "", $actions,
      array("checkAll"=>"<b>".Helper::translate('srbac','Check All')."</b>")); ?>
  </div>
  <?php } ?>
  <?php if(!$delete) {?>
  <div class="simple">
    <hr style="color:red">
      <?php echo Helper::translate('srbac',"Pages that access is always allowed").":" ?>
      <?php foreach ($allowed as $al) { ?>
    <div class="simple">
          <?php echo $al; ?>
    </div>
      <?php }?>
  </div>
  <?php } ?>

  <div class="simple">
    <hr>
    <?php $cb_title = $delete ? "Delete Tasks" : "Create tasks"; ?>
    <?php $button_title = $delete ? "Delete" : "Create"; ?>
    <?php $button_action = $delete ? "autoDeleteItems" : "autoCreateItems"; ?>
    <?php if(!$taskViewingExists || !$taskAdministratingExists || $delete) { ?>
      <?php echo Helper::translate('srbac',$cb_title) ?>
      <?php echo SHtml::checkBox("createTasks", true, array("id"=>"cb_createTasks")); ?>
    <?php } ?>
  </div>
  <?php if(($taskViewingExists && $delete) || (!$taskViewingExists && !$delete)) { ?>
  <div class="simple">
      <?php echo SHtml::textField("tasks[user]", $task."Viewing",array("id"=>"userTask","readonly"=>true)); ?>
  </div>
  <?php } ?>
  <?php if(($taskAdministratingExists && $delete)|| (!$taskAdministratingExists && !$delete)) {?>
  <div class="simple">
      <?php echo SHtml::textField("tasks[admin]", $task."Administrating",array("id"=>"adminTask","readonly"=>true)); ?>
  </div>
  <?php } ?>
  <div class="simple">
    <?php echo SHtml::hiddenField("controller", $controller) ?>
  </div>
  <div class="action">
    <?php echo SHtml::ajaxButton(Helper::translate('srbac',$button_title),
    array($button_action),
    array(
    'type'=>'POST',
    'update'=>'#controllerActions',
    'beforeSend' => 'function(){
                      $("#controllerActions").addClass("srbacLoading");
                  }',
    'complete' => 'function(){
                      $("#controllerActions").removeClass("srbacLoading");
                  }',
    )); ?>
  </div>
  <?php echo SHtml::endForm()?>
</div>
