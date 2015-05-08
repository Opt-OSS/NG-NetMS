<?php

/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

/**
 * Description of SDbAuthManager
 *
 * @author ssoldatos
 */
class SDbAuthManager extends CDbAuthManager {

  /**
   * Performs access check for the specified user.
   * @param string the name of the operation that need access check
   * @param mixed the user ID. This should can be either an integer and a string representing
   * the unique identifier of a user. See {@link IWebUser::getId}.
   * @param array name-value pairs that would be passed to biz rules associated
   * with the tasks and roles assigned to the user.
   * @return boolean whether the operations can be performed by the user.
   */
  public function checkAccess($itemName, $userId, $params=array()) {
    if (!empty($this->defaultRoles) && in_array($itemName,$this->defaultRoles)) {
      return true;
    }
    $sql = "SELECT name, type, description, t1.bizrule, t1.data, t2.bizrule AS bizrule2, t2.data AS data2 FROM {$this->itemTable} t1, {$this->assignmentTable} t2 WHERE name=itemname AND userid=:userid";
    $command = $this->db->createCommand($sql);
    $command->bindValue(':userid', $userId);

    // check directly assigned items
    $names = array();
    foreach ($command->queryAll() as $row) {
      Yii::trace('Checking permission "' . $row['name'] . '"', 'system.web.auth.CDbAuthManager');
      if ($this->executeBizRule($row['bizrule2'], $params, unserialize($row['data2']))
        && $this->executeBizRule($row['bizrule'], $params, unserialize($row['data']))) {
        if (strtolower($row['name']) === strtolower($itemName)) {
          return true;
        }
        $names[] = $row['name'];
      }
    }

    // check all descendant items
    while ($names !== array()) {
      $items = $this->getItemChildren($names);
      $names = array();
      foreach ($items as $item) {
        Yii::trace('Checking permission "' . $item->getName() . '"', 'system.web.auth.CDbAuthManager');
        if ($this->executeBizRule($item->getBizRule(), $params, $item->getData())) {
          if (strtolower($item->getName()) === strtolower($itemName)) {
            return true;
          }
          $names[] = $item->getName();
        }
      }
    }

    return false;
  }

}
?>
