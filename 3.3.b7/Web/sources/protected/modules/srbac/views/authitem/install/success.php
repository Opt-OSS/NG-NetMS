<?php
/**
 * success.php
 *
 * @author Spyros Soldatos <spyros@valor.gr>
 * @link http://code.google.com/p/srbac/
 */

/**
 * The successful installation view.
 *
 * @author Spyros Soldatos <spyros@valor.gr>
 * @package srbac.views.authitem.install
 * @since 1.0.0
 */
 ?>
<h3><?php echo Helper::translate('srbac','Install Srbac')?></h3>
 <div>
    <?php echo Helper::translate('srbac','Srbac installed successfuly'); ?>
 </div>
<div>
    <?php echo SHtml::link(Helper::translate('srbac','Srbac frontpage'),
        array('frontpage')); ?>
 </div>

