<?php
/**
 * wizard.php
 *
 * @author Spyros Soldatos <spyros@valor.gr>
 * @link http://code.google.com/p/srbac/
 */

/**
 * The auto creation of auth items main page.<br />
 * The controllers / modules list is on the left and the auth item actions on
 * the right table
 *
 * @author Spyros Soldatos <spyros@valor.gr>
 * @package srbac.views.authitem.manage
 * @since 1.0.2
 */
?>
<?php $module = ""; ?>
<div id="wizardMain" style="margin:10px">
  <table width="100%">
    <tr valign="top">
      <td width="40%" style="vertical-align: top">
        <table class="srbacDataGrid" width="40%" align="left">
          <tr>
            <th width="80%"><?php echo Helper::translate('srbac','Controller')?></th>
            <th colspan="2"><?php echo Helper::translate('srbac','Actions')?></th>
          </tr>
          <?php $prevModule = ""; ?>
          <?php foreach ($controllers as $n=>$controller) { ?>
            <?php if(substr_count($controller, Helper::findModule('srbac')->delimeter)) { ?>
            <?php list($module,$controller) = explode(Helper::findModule('srbac')->delimeter, $controller); ?>
              <?php if($module != $prevModule) { ?>
                <tr>
                <th colspan="3">
                <?php echo Helper::translate('srbac','Module').": ".  $module?></th>
                </tr>
                <?php $prevModule = $module; ?>
                <?php }?>
              <?php } ?>

          <tr>
            <td width="80%"><?php echo $controller ?></td>
            <td>
                <?php
                echo SHtml::ajaxLink(
					SHtml::image($this->module->getIconsPath().'/wizard.png',
						"Autocreate Auth Items for controller ".$controller,
						array(
							'border'=>0,
							'title'=>
								Helper::translate('srbac',
									'Scanning for Auth Items for controller').' '.$controller)
					),
					array('scan','module'=>$module,'controller'=>$controller),
					array(
						'type'=>'POST',
						'update'=>'#controllerActions',
						'beforeSend' => 'function(){
								$("#controllerActions").addClass("srbacLoading");
							}',
						'complete' => 'function(){
								$("#controllerActions").removeClass("srbacLoading");
							}',
					),
					array('name'=>'buttonScan_'.$n)
				);
                ?>
            </td>
            <td>
                <?php
                echo SHtml::ajaxLink(
					SHtml::image($this->module->getIconsPath().'/delete.png',
						"Delete All Auth Items of controller ".$controller,
						array('border'=>0,'title'=>
						Helper::translate('srbac',
							'Delete All Auth Items of controller').' '.$controller)
					),
					array('scan','module'=>$module,'controller'=>$controller,'delete'=>true),
					array(
						'type'=>'POST',
						'update'=>'#controllerActions',
						'beforeSend' => 'function(){
								$("#controllerActions").addClass("srbacLoading");
							}',
						'complete' => 'function(){
								$("#controllerActions").removeClass("srbacLoading");
							}',
					),
					array('name'=>'buttonDelete_'.$n)
				);
                ?>
            </td>
          </tr>
            <?php } ?>
        </table>
      </td>
      <td width="60%"  style="vertical-align: top">
        <table class="srbacDataGrid" width="50%" style="float:left">
          <tr>
            <th width="70%"><?php echo Helper::translate('srbac','Auth items')?></th>
          </tr>
          <tr>
            <td valign="top">
              <div id="controllerActions"></div>
            </td>
          </tr>
        </table>
      </td>
  </table>
</div>