<?php
/**
 * saveAllowed.php
 *
 * @author Spyros Soldatos <spyros@valor.gr>
 * @link http://code.google.com/p/srbac/
 */

/**
 * The view that displays the items that are saved in the alwaysAllowed file
 *
 * @author Spyros Soldatos <spyros@valor.gr>
 * @package srbac.views.authitem
 * @since 1.1.0
 */
?>
<div>
  <?php echo Helper::translate("srbac", "The following authItems are saved in the always allowed file"); ?>
  <?php echo ":".$this->module->getAlwaysAllowedFile(); ?>
</div>
<br />
<?php foreach ($allowed as $item) { ?>
<div style="text-align:left;font-weight:bold">
    <?php echo $item."<br />";?>
</div>
<?php } ?>

