<?php
/**
 * unauthorized.php
 *
 * @author Spyros Soldatos <spyros@valor.gr>
 * @link http://code.google.com/p/srbac/
 */

/**
 * Default page shown when a not authorized user tries to access a page
 *
 * @author Spyros Soldatos <spyros@valor.gr>
 * @package srbac.views.authitem
 * @since 1.0.2
 */
 ?>
<h2 style="color:red">
<?php echo "Error:".$error["code"]." '".$error["title"]."'" ?></h2>
<p>
  <?php echo $error["message"] ?>
</p>

