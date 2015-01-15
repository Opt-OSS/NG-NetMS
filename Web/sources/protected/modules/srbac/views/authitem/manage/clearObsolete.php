<?php
/**
 * clearObsolete.php
 *
 * @author Spyros Soldatos <spyros@valor.gr>
 * @link http://code.google.com/p/srbac/
 */

/**
 * A view for deleting authItems of controllers that no longer exist
 *
 * @author Spyros Soldatos <spyros@valor.gr>
 * @package srbac.views.authitem.manage
 * @since 1.1.1
 */
?>
<?php if ($items) { ?>

<div style="margin:10px" id="obsoleteList">
  <table class="srbacDataGrid" style="width:50%">
    <tr><th>
          <?php echo Helper::translate("srbac","The following items doesn't seem to belong to a controller"); ?>
      </th>
    <tr>
    <tr><td>
        <div class="srbacForm">
            <?php echo SHtml::beginForm()?>
          <div>
              <?php echo SHtml::checkBoxList("items", "", $items, array("checkAll"=>Helper::translate('srbac','Check All')));?>
          </div>
          <div class="action">
              <?php echo SHtml::ajaxButton(Helper::translate('srbac', 'Delete'),
              array("deleteObsolete"),
              array(
              'type'=>'POST',
              'update'=>'#obsoleteList',
              'beforeSend' => 'function(){
         $("#wiobsoleteListzard").addClass("srbacLoading");
        }',
              'complete' => 'function(){
        $("#obsoleteList").removeClass("srbacLoading");
       }',
              ),
              array(
              'name'=>'buttonSave',
              ));?>
          </div>
            <?php echo SHtml::endForm()?>
        </div>
      </td>
    </tr>

  </table>
</div>

  <?php } else { ?>
<table class="srbacDataGrid" style="width:50%">
  <tr>
    <th>
        <?php echo Helper::translate("srbac", "No authItems that don't belong to a controller were found");?>
    </th>
  </tr>
</table>
  <?php }?>
