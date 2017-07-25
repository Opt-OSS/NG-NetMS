<?php

/**
 * This is the model class for table "router_graph".
 *
 * The followings are the available columns in table 'router_graph':
 * @property integer $router_id
 * @property double $x
 * @property double $y
 *
 * The followings are the available model relations:
 * @property Routers $router
 */
class RouterGraph extends CActiveRecord
{
	/**
	 * @return string the associated database table name
	 */
	public function tableName()
	{
		return 'router_graph';
	}

	/**
	 * @return array validation rules for model attributes.
	 */
	public function rules()
	{
		// NOTE: you should only define rules for those attributes that
		// will receive user inputs.
		return array(
			array('router_id, x, y', 'required'),
			array('router_id', 'numerical', 'integerOnly'=>true),
			array('x, y', 'numerical'),
			// The following rule is used by search().
			array('router_id, x, y', 'safe', 'on'=>'search'),
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
			'x' => 'X',
			'y' => 'Y',
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
		$criteria->compare('x',$this->x);
		$criteria->compare('y',$this->y);

		return new CActiveDataProvider($this, array(
			'criteria'=>$criteria,
		));
	}

	/**
	 * Returns the static model of the specified AR class.
	 * Please note that you should have this exact method in all your CActiveRecord descendants!
	 * @param string $className active record class name.
	 * @return RouterGraph the static model class
	 */
	public static function model($className=__CLASS__)
	{
		return parent::model($className);
	}
}
