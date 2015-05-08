<?php

/**
 * This is the model class for table "network".
 *
 * The followings are the available columns in table 'network':
 * @property integer $link_id
 * @property integer $router_id_a
 * @property integer $ifc_id_a
 * @property integer $router_id_b
 * @property integer $ifc_id_b
 * @property string $link_type
 *
 * The followings are the available model relations:
 * @property Routers $routerIdA
 * @property Routers $routerIdB
 */
class Network extends CActiveRecord
{
	/**
	 * @return string the associated database table name
	 */
	public function tableName()
	{
		return 'network';
	}

	/**
	 * @return array validation rules for model attributes.
	 */
	public function rules()
	{
		// NOTE: you should only define rules for those attributes that
		// will receive user inputs.
		return array(
			array('router_id_a, router_id_b', 'required'),
			array('router_id_a, ifc_id_a, router_id_b, ifc_id_b', 'numerical', 'integerOnly'=>true),
			array('link_type', 'length', 'max'=>4),
			// The following rule is used by search().
			// @todo Please remove those attributes that should not be searched.
			array('link_id, router_id_a, ifc_id_a, router_id_b, ifc_id_b, link_type', 'safe', 'on'=>'search'),
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
			'routerIdA' => array(self::BELONGS_TO, 'Routers', 'router_id_a'),
			'routerIdB' => array(self::BELONGS_TO, 'Routers', 'router_id_b'),
		);
	}

	/**
	 * @return array customized attribute labels (name=>label)
	 */
	public function attributeLabels()
	{
		return array(
			'link_id' => 'Link',
			'router_id_a' => 'Router Id A',
			'ifc_id_a' => 'Ifc Id A',
			'router_id_b' => 'Router Id B',
			'ifc_id_b' => 'Ifc Id B',
			'link_type' => 'Link Type',
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

		$criteria->compare('link_id',$this->link_id);
		$criteria->compare('router_id_a',$this->router_id_a);
		$criteria->compare('ifc_id_a',$this->ifc_id_a);
		$criteria->compare('router_id_b',$this->router_id_b);
		$criteria->compare('ifc_id_b',$this->ifc_id_b);
		$criteria->compare('link_type',$this->link_type,true);

		return new CActiveDataProvider($this, array(
			'criteria'=>$criteria,
		));
	}

	/**
	 * Returns the static model of the specified AR class.
	 * Please note that you should have this exact method in all your CActiveRecord descendants!
	 * @param string $className active record class name.
	 * @return Network the static model class
	 */
	public static function model($className=__CLASS__)
	{
		return parent::model($className);
	}
}
