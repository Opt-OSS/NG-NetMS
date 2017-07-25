<?php

/**
 * This is the model class for table "interfaces".
 *
 * The followings are the available columns in table 'interfaces':
 * @property integer $router_id
 * @property integer $ph_int_id
 * @property integer $ifc_id
 * @property string $name
 * @property string $ip_addr
 * @property string $mask
 * @property string $descr
 *
 * The followings are the available model relations:
 * @property Routers $router
 * @property PhInt $ph_int
 */
class Interfaces extends CActiveRecord
{
	/**
	 * @return string the associated database table name
	 */
	public function tableName()
	{
		return 'interfaces';
	}

	/**
	 * @return array validation rules for model attributes.
	 */
	public function rules()
	{
		// NOTE: you should only define rules for those attributes that
		// will receive user inputs.
		return array(
			array('router_id, ph_int_id, name', 'required'),
			array('router_id, ph_int_id', 'numerical', 'integerOnly'=>true),
			array('name', 'length', 'max'=>32),
			array('descr', 'length', 'max'=>100),
			array('ip_addr, mask', 'safe'),
			// The following rule is used by search().
			array('router_id, ph_int_id, ifc_id, name, ip_addr, mask, descr', 'safe', 'on'=>'search'),
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
			'router' => array(self::BELONGS_TO, 'Routers', 'router_id'),
            'ph_int' => array(self::BELONGS_TO, 'PhInt', 'ph_int_id'),
		);
	}

	/**
	 * @return array customized attribute labels (name=>label)
	 */
	public function attributeLabels()
	{
		return array(
			'router_id' => 'Router',
			'ph_int_id' => 'Ph Int',
			'ifc_id' => 'Ifc',
			'name' => 'Name',
			'ip_addr' => 'Ip Addr',
			'mask' => 'Mask',
			'descr' => 'Descr',
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

		$criteria=new CDbCriteria;

		$criteria->compare('router_id',$this->router_id);
		$criteria->compare('ph_int_id',$this->ph_int_id);
		$criteria->compare('ifc_id',$this->ifc_id);
		$criteria->compare('name',$this->name,true);
		$criteria->compare('ip_addr',$this->ip_addr,true);
		$criteria->compare('mask',$this->mask,true);
		$criteria->compare('descr',$this->descr,true);

		return new CActiveDataProvider($this, array(
			'criteria'=>$criteria,
		));
	}

	/**
	 * Returns the static model of the specified AR class.
	 * Please note that you should have this exact method in all your CActiveRecord descendants!
	 * @param string $className active record class name.
	 * @return Interfaces the static model class
	 */
	public static function model($className=__CLASS__)
	{
		return parent::model($className);
	}
        
}
