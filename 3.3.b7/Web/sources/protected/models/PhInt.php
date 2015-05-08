<?php

/**
 * This is the model class for table "ph_int".
 *
 * The followings are the available columns in table 'ph_int':
 * @property integer $router_id
 * @property integer $ph_int_id
 * @property string $name
 * @property string $state
 * @property string $condition
 * @property string $descr
 * @property string $speed
 *
 * The followings are the available model relations:
 * @property Routers $router
 */
class PhInt extends CActiveRecord
{
	/**
	 * @return string the associated database table name
	 */
	public function tableName()
	{
		return 'ph_int';
	}

	/**
	 * @return array validation rules for model attributes.
	 */
	public function rules()
	{
		// NOTE: you should only define rules for those attributes that
		// will receive user inputs.
		return array(
			array('router_id, name', 'required'),
			array('router_id', 'numerical', 'integerOnly'=>true),
			array('name', 'length', 'max'=>128),
			array('state, condition', 'length', 'max'=>8),
			array('descr', 'length', 'max'=>256),
			array('speed', 'length', 'max'=>20),
			// The following rule is used by search().
			// @todo Please remove those attributes that should not be searched.
			array('router_id, ph_int_id, name, state, condition, descr, speed', 'safe', 'on'=>'search'),
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
			'name' => 'Name',
			'state' => 'State',
			'condition' => 'Condition',
			'descr' => 'Descr',
			'speed' => 'Speed',
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
		$criteria->compare('ph_int_id',$this->ph_int_id);
		$criteria->compare('name',$this->name,true);
		$criteria->compare('state',$this->state,true);
		$criteria->compare('condition',$this->condition,true);
		$criteria->compare('descr',$this->descr,true);
		$criteria->compare('speed',$this->speed,true);

		return new CActiveDataProvider($this, array(
			'criteria'=>$criteria,
		));
	}

	/**
	 * Returns the static model of the specified AR class.
	 * Please note that you should have this exact method in all your CActiveRecord descendants!
	 * @param string $className active record class name.
	 * @return PhInt the static model class
	 */
	public static function model($className=__CLASS__)
	{
		return parent::model($className);
	}
}
