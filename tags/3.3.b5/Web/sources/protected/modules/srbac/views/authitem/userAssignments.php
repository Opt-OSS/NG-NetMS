<?php
/**
 * userAssignments.php
 *
 * @author Spyros Soldatos <spyros@valor.gr>
 * @link http://code.google.com/p/srbac/
 */

/**
 * Shows a user's assignments
 *
 * @author Spyros Soldatos <spyros@valor.gr>
 * @package srbac.views.authitem
 * @since 1.0.2
 */
 ?>
<br />
<h1>Assignments of user : '<?php echo $username?>'</h1>
<table class="srbacDataGrid" width="100%">
  <tr>
    <th class="roles"><?php echo Helper::translate('srbac','Roles')?></th>
    <th class="tasks"><?php echo Helper::translate('srbac','Tasks')?></th>
    <th class="operations"><?php echo Helper::translate('srbac','Operations')?></th>
  </tr>
  <tr>
    <td valign="top" colspan="3">
      <table class="roles">
        <?php foreach ($data as $i=>$roles) { ?>
        <tr>
          <td><b><?php echo $i ?></b>
              <?php foreach ($roles as $j=>$tasks) { ?>
            <table class="tasks">
              <tr>
                <td valign="top">
                      <?php echo $j; ?>
                  <table class="operations">
                    <tr>
                      <td valign="top">
                      <?php foreach ($tasks as $j=>$opers) { ?>
                              <?php echo $opers."<br />";  ?>
                              <?php } ?>
                      </td>
                    </tr>
                  </table>
                </td>
              </tr>
            </table>
              <?php }?>
          </td>
        </tr>
        <?php } ?>
      </table>
    </td>
  </tr>
</table>