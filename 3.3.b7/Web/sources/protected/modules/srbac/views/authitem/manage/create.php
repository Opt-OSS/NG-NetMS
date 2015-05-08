<?php
/**
 * create.php
 *
 * @author Spyros Soldatos <spyros@valor.gr>
 * @link http://code.google.com/p/srbac/
 */

/**
 * The create new auth item view.
 *
 * @author Spyros Soldatos <spyros@valor.gr>
 * @package srbac.views.authitem.manage
 * @since 1.0.0
 */
 ?>
<div class="title"><?php echo Helper::translate('srbac','Create New Item') ?></div>

<?php echo $this->renderPartial('manage/_form', array(
	'model'=>$model,
	'update'=>false,
), false, true); ?>