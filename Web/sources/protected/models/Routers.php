<?php

/**
 * This is the model class for table "routers".
 *
 * The followings are the available columns in table 'routers':
 * @property integer $router_id
 * @property string $name
 * @property string $ip_addr
 * @property string $eq_type
 * @property string $eq_vendor
 * @property string $location
 * @property string $status
 * @property string $icon_color
 *
 * The followings are the available model relations:
 * @property RouterGraph[] $routerGraphs
 * @property Network[] $networks
 * @property Network[] $networks1
 * @property PhInt[] $phInts
 * @property InvHw[] $invHws
 * @property Interfaces[] $interfaces
 * @property InvSw[] $invSws
 */
class Routers extends CActiveRecord
{
	/**
	 * @return string the associated database table name
	 */
	public function tableName()
	{
		return 'routers';
	}

	/**
	 * @return array validation rules for model attributes.
	 */
	public function rules()
	{
		// NOTE: you should only define rules for those attributes that
		// will receive user inputs.
		return array(
			array('name,eq_vendor', 'required'),
			array('name', 'length', 'max'=>32),
			array('eq_type, eq_vendor', 'length', 'max'=>50),
			array('location', 'length', 'max'=>255),
			array('status, icon_color', 'length', 'max'=>20),
			array('ip_addr', 'safe'),
			// The following rule is used by search().
			// @todo Please remove those attributes that should not be searched.
			array('router_id, name, ip_addr, eq_type, eq_vendor, location, status, icon_color', 'safe', 'on'=>'search'),
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
			'routerGraphs' => array(self::HAS_MANY, 'RouterGraph', 'router_id'),
			'networks' => array(self::HAS_MANY, 'Network', 'router_id_a'),
			'networks1' => array(self::HAS_MANY, 'Network', 'router_id_b'),
			'phInts' => array(self::HAS_MANY, 'PhInt', 'router_id'),
			'invHws' => array(self::HAS_MANY, 'InvHw', 'router_id'),
			'interfaces' => array(self::HAS_MANY, 'Interfaces', 'router_id'),
			'invSws' => array(self::HAS_MANY, 'InvSw', 'router_id'),
		);
	}

	/**
	 * @return array customized attribute labels (name=>label)
	 */
	public function attributeLabels()
	{
		return array(
			'router_id' => 'Router',
			'name' => 'Name',
			'ip_addr' => 'Ip Addr',
			'eq_type' => 'Model',
			'eq_vendor' => 'Vendor',
			'location' => 'Location',
			'status' => 'Status',
			'icon_color' => 'Icon Color',
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
		$criteria->compare('router_id',$this->router_id);
		$criteria->compare('name',$this->name,true);
		$criteria->compare('text(ip_addr)',$this->ip_addr,true);
		$criteria->compare('eq_type',$this->eq_type,true);
		$criteria->compare('eq_vendor',$this->eq_vendor,true);
		$criteria->compare('location',$this->location,true);
		$criteria->compare('status',$this->status,true);
		$criteria->compare('icon_color',$this->icon_color,true);

		return new CActiveDataProvider($this, array(
			'criteria'=>$criteria,
		));
	}


    /**
     * Return router name by router id
     *
     * @return mixed
     */
    public function routerNameForId()
    {
        $query = "SELECT name FROM routers WHERE router_id = '".$this->router_id."'";

        return Yii::app()->db->createCommand($query)
            ->queryScalar();
    }

    /**
     * Return list of all routers
     *
     * @return mixed
     */
    public function getAll()
    {
        $arr_data  = Yii::app()->db->createCommand()
            ->select('router_id,name ')
            ->from(' routers')
            ->order(' router_id ')
            ->queryAll();

        return $arr_data;
    }


    protected function afterDelete()
    {
        Events::model()->deleteAll('origin_id=' .$this->router_id);

    }

        /**
	 * Returns the static model of the specified AR class.
	 * Please note that you should have this exact method in all your CActiveRecord descendants!
	 * @param string $className active record class name.
	 * @return Routers the static model class
	 */
	public static function model($className=__CLASS__)
	{
		return parent::model($className);
	}
}
