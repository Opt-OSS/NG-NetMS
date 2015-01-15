<?php
/**
 * update.php
 *
 * @author Spyros Soldatos <spyros@valor.gr>
 * @link http://code.google.com/p/srbac/
 */

/**
 * A view used when an auth item is updated
 *
 * @author Spyros Soldatos <spyros@valor.gr>
 * @package srbac.views.authitem.manage
 * @since 1.0.0
 */
 ?>
<?php echo $this->renderPartial('manage/_form', array(
	'model'=>$model,
	'update'=>true,
), false, true); ?>