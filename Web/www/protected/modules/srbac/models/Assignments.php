<?php
/**
 * Assignments class file.
 *
 * @author Spyros Soldatos <spyros@valor.gr>
 * @link http://code.google.com/p/srbac/
 */

/**
 * Assignments model is the authManager model that defines which operations /
 * tasks / roles are assigned to which user.
 *
 * @author Spyros Soldatos <spyros@valor.gr>
 * @package srbac.models
 * @since 1.0.0
 */

class Assignments extends CActiveRecord {
/**
 * The followings are the available columns in table 'authassignment':
 * @var string $itemname
 * @var string $userid
 * @var string $bizrule
 * @var string $data
 */

/**
 * Returns the static model of the specified AR class.
 * @return CActiveRecord the static model class
 */
  public static function model($className=__CLASS__) {
    return parent::model($className);
  }

  public function getDbConnection() {
    return Yii::app()->authManager->db;
  }

  /**
   * @return string the associated database table name
   */
  public function tableName() {
    return Yii::app()->authManager->assignmentTable;
  }

  /**
   * @return array validation rules for model attributes.
   */
  public function rules() {
    return array(
    array('itemname','length','max'=>64),
    array('userid','length','max'=>64),
    array('itemname, userid', 'required'),
    array('user_id,itemname,bizrule,data','safe'),
    );
  }

  /**
   * @return array relational rules.
   */
  public function relations() {
  // NOTE: you may need to adjust the relation name and the related
  // class name for the relations automatically generated below.
    return array(
    );
  }

  /**
   * @return array customized attribute labels (name=>label)
   */
  public function attributeLabels() {
    return array(
    'itemname'=>Helper::translate('srbac','Itemname'),
    'userid'=>Helper::translate('srbac','User id'),
    'bizrule'=>Helper::translate('srbac','Bizrule'),
    'data'=>Helper::translate('srbac','Data'),
    );
  }
}