<?php
/**
 * assign.php
 *
 * @author Spyros Soldatos <spyros@valor.gr>
 * @link http://code.google.com/p/srbac/
 */

/**
 * The Assign tabview view
 *
 * @author Spyros Soldatos <spyros@valor.gr>
 * @package srbac.views.authitem
 * @since 1.0.0
 */
?>
<?php $this->breadcrumbs = array(
    'Management / Rbac Assign'
)
?>
<?php if($this->module->getMessage() != ""){ ?>
<div id="srbacError">
  <?php echo $this->module->getMessage();?>
</div>
<?php } ?>
<?php if($this->module->getShowHeader()) {
  $this->renderPartial($this->module->header);
}
?>
<div>
  <?php

  $this->renderPartial("frontpage");

  $tabs = array(
      'tab1'=>array(
      'title'=>Helper::translate('srbac','Users'),
      'view'=>'tabViews/roleToUser',
      ),
      'tab2'=>array(
      'title'=>Helper::translate('srbac','Roles'),
      'view'=>'tabViews/taskToRole',
      ),
      'tab3'=>array(
      'title'=>Helper::translate('srbac','Tasks'),
      'view'=>'tabViews/operationToTask',
      ),
  );
  ?>
  <div class="horTab">
    <?php 
    Helper::publishCss($this->module->css);
    $this->widget('system.web.widgets.CTabView',
        array('tabs'=>$tabs,
        'viewData'=>array('model'=>$model,'userid'=>$userid,'message'=>$message,'data'=>$data),
        'cssFile'=>$this->module->getCssUrl(),
    ));
    ?>
  </div>
</div>
<?php if($this->module->getShowFooter()) {
  $this->renderPartial($this->module->footer);
}
?>
