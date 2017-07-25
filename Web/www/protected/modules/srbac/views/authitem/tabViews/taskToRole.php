<?php
/**
 * taskToRole.php
 *
 * @author Spyros Soldatos <spyros@valor.gr>
 * @link http://code.google.com/p/srbac/
 */

/**
 * The tab view for assigning tasks to roles
 *
 * @author Spyros Soldatos <spyros@valor.gr>
 * @package srbac.views.authitem.tabViews
 * @since 1.0.0
 */
 ?>
<!-- ROLES -> TASKS -->
<?php
$criteria = new CDbCriteria();
$criteria->condition = "type=2";
$criteria->order = "name";
?>
<div class="srbac">
  <?php echo SHtml::beginForm(); ?>
  <?php echo SHtml::errorSummary($model); ?>
  <table width="100%">
    <tr><th colspan="2"><?php echo Helper::translate('srbac','Assign Tasks to Roles') ?></th></tr>
    <tr>
      <th width="50%">
      <?php echo SHtml::label(Helper::translate('srbac',"Role"),'role'); ?></th>
      <td width="50%" rowspan="2">
        <div id="tasks">
          <?php
          $this->renderPartial('tabViews/roleAjax',
              array('model'=>$model,'userid'=>$userid,'data'=>$data,'message'=>$message));
          ?>
        </div>
      </td>
    </tr>
    <tr valign="top">
      <td><?php echo SHtml::activeDropDownList(AuthItem::model(),'name[0]',
        SHtml::listData(AuthItem::model()->findAll($criteria), 'name', 'name'),
        array('size'=>$this->module->listBoxNumberOfLines,'class'=>'dropdown','ajax' => array(
        'type'=>'POST',
        'url'=>array('getTasks'),
        'update'=>'#tasks',
        'beforeSend' => 'function(){
                      $("#loadMessRole").addClass("srbacLoading");
                  }',
        'complete' => 'function(){
                      $("#loadMessRole").removeClass("srbacLoading");
                  }'
        ),
        )); ?>
      </td>
    </tr>
  </table>
  <br />
  <?php echo SHtml::endForm(); ?>
</div>