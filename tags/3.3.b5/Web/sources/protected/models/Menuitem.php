<?php

/**
 * This is the model class for table "menuitem".
 *
 * The followings are the available columns in table 'menuitem':
 * @property integer $id
 * @property string $name
 * @property integer $parentid
 * @property string $label
 * @property integer $ordervalue
 * @property string $route
 * @property string $accesslevel
 * @property integer $depthlevel
 * @property string $menutypeid
 * @property string $adminnotes
 * @property integer $active
 * @property string $created
 * @property string $modified
 * @property string $deleted
 * @property string $icon
 */
class Menuitem extends CActiveRecord
{
	/**
	 * @return string the associated database table name
	 */
	public function tableName()
	{
		return 'menuitem';
	}

	/**
	 * @return array validation rules for model attributes.
	 */
	public function rules()
	{
		// NOTE: you should only define rules for those attributes that
		// will receive user inputs.
		return array(
			array('parentid, ordervalue, depthlevel, active', 'numerical', 'integerOnly'=>true),
			array('name, route, accesslevel, icon', 'length', 'max'=>255),
			array('label', 'length', 'max'=>50),
			array('menutypeid', 'length', 'max'=>100),
			array('adminnotes, created, modified, deleted', 'safe'),
			// The following rule is used by search().
			// @todo Please remove those attributes that should not be searched.
			array('id, name, parentid, label, ordervalue, route, accesslevel, depthlevel, menutypeid, adminnotes, active, created, modified, deleted, icon', 'safe', 'on'=>'search'),
		);
	}

	/**
	 * @return array relational rules.
	 */
	public function relations()
	{
		// NOTE: you may need to adjust the relation name and the related
		// class name for the relations automatically generated below.
		return array(
		);
	}

	/**
	 * @return array customized attribute labels (name=>label)
	 */
	public function attributeLabels()
	{
		return array(
			'id' => 'ID',
			'name' => 'Name',
			'parentid' => 'Parentid',
			'label' => 'Label',
			'ordervalue' => 'Ordervalue',
			'route' => 'Route',
			'accesslevel' => 'Accesslevel',
			'depthlevel' => 'Depthlevel',
			'menutypeid' => 'Menutypeid',
			'adminnotes' => 'Adminnotes',
			'active' => 'Active',
			'created' => 'Created',
			'modified' => 'Modified',
			'deleted' => 'Deleted',
			'icon' => 'Icon',
		);
	}

	/**
	 * Retrieves a list of models based on the current search/filter conditions.
	 *
	 * Typical usecase:
	 * - Initialize the model fields with values from filter form.
	 * - Execute this method to get CActiveDataProvider instance which will filter
	 * models according to data in model fields.
	 * - Pass data provider to CGridView, CListView or any similar widget.
	 *
	 * @return CActiveDataProvider the data provider that can return the models
	 * based on the search/filter conditions.
	 */
	public function search()
	{
		// @todo Please modify the following code to remove attributes that should not be searched.

		$criteria=new CDbCriteria;

		$criteria->compare('id',$this->id);
		$criteria->compare('name',$this->name,true);
		$criteria->compare('parentid',$this->parentid);
		$criteria->compare('label',$this->label,true);
		$criteria->compare('ordervalue',$this->ordervalue);
		$criteria->compare('route',$this->route,true);
		$criteria->compare('accesslevel',$this->accesslevel,true);
		$criteria->compare('depthlevel',$this->depthlevel);
		$criteria->compare('menutypeid',$this->menutypeid,true);
		$criteria->compare('adminnotes',$this->adminnotes,true);
		$criteria->compare('active',$this->active);
		$criteria->compare('created',$this->created,true);
		$criteria->compare('modified',$this->modified,true);
		$criteria->compare('deleted',$this->deleted,true);
		$criteria->compare('icon',$this->icon,true);

		return new CActiveDataProvider($this, array(
			'criteria'=>$criteria,
		));
	}

	protected function beforeSave()
	{
		if(parent::beforeSave())
		{
			if($this->isNewRecord)
			{
				$this->created=$this->modified=date("Y-m-d H:i:s");
				$this->depthlevel = 1;
				$this->active=1;
			}
			else
				$this->modified=date("Y-m-d H:i:s");
			return true;
		}
		else
			return false;
	}

	/**
	 * get menu items of main menu
	 *
	 * @return array
	 */
	public  function getHighLevel(){
		$arr_ret = array();
		$arr_data2 = Yii::app()->db->createCommand()
			->select('id,name')
			->where("parentid is NULL ")
			->from('menuitem')
			->order('name')
			->queryAll();
		for($i=0;$i<count($arr_data2);$i++)
		{
			$key = $arr_data2[$i]['id'];
			$val = $arr_data2[$i]['name'];
			$arr_ret[$key] = $val;
		}
		return $arr_ret;
	}

	public function getOperationList(){
		$arr_ret=array();
		$arr_data2 = Yii::app()->db->createCommand()
			->select('name')
			->where("type=0 ")
			->from('AuthItem')
			->order('name')
			->queryAll();
		for($i=0;$i<count($arr_data2);$i++)
		{
			$val = $arr_data2[$i]['name'];
			$arr_ret[$val] = $val;
		}
		return $arr_ret;
	}
	/**
	 * Returns the static model of the specified AR class.
	 * Please note that you should have this exact method in all your CActiveRecord descendants!
	 * @param string $className active record class name.
	 * @return Menuitem the static model class
	 */
	public static function model($className=__CLASS__)
	{
		return parent::model($className);
	}
}
