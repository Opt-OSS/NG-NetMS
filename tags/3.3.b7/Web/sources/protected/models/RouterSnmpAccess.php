<?php

/**
 * This is the model class for table "router_snmp_access".
 *
 * The followings are the available columns in table 'router_snmp_access':
 * @property integer $id
 * @property integer $router_id
 * @property integer $snmp_access_id
 *
 * The followings are the available model relations:
 * @property Routers $router
 * @property SnmpAccess $snmpAccess
 */
class RouterSnmpAccess extends CActiveRecord
{
	/**
	 * @return string the associated database table name
	 */
	public function tableName()
	{
		return 'router_snmp_access';
	}

	/**
	 * @return array validation rules for model attributes.
	 */
	public function rules()
	{
		// NOTE: you should only define rules for those attributes that
		// will receive user inputs.
		return array(
			array('router_id, snmp_access_id', 'numerical', 'integerOnly'=>true),
			// The following rule is used by search().
			// @todo Please remove those attributes that should not be searched.
			array('id, router_id, snmp_access_id', 'safe', 'on'=>'search'),
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
			'snmpAccess' => array(self::BELONGS_TO, 'SnmpAccess', 'snmp_access_id'),
		);
	}

	/**
	 * @return array customized attribute labels (name=>label)
	 */
	public function attributeLabels()
	{
		return array(
			'id' => 'ID',
			'router_id' => 'Router',
			'snmp_access_id' => 'Snmp Access',
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
		$criteria->compare('router_id',$this->router_id);
		$criteria->compare('snmp_access_id',$this->snmp_access_id);

		return new CActiveDataProvider($this, array(
			'criteria'=>$criteria,
		));
	}

	/**
	 * Returns the static model of the specified AR class.
	 * Please note that you should have this exact method in all your CActiveRecord descendants!
	 * @param string $className active record class name.
	 * @return RouterSnmpAccess the static model class
	 */
	public static function model($className=__CLASS__)
	{
		return parent::model($className);
	}

    /**
     * Return list of router by SNMP access
     *
     * @return mixed
     */
    public function getRouterByAccess()
    {
        $arr_data  = Yii::app()->db->createCommand()
            ->select('r.router_id,r.name ')
            ->from(' router_snmp_access ra,routers r')
            ->where("ra.snmp_access_id ='".$this->snmp_access_id."' AND r.router_id = ra.router_id")
            ->order(' r.router_id ')
            ->queryAll();

        return $arr_data;
    }

    /**
     * check existing record
     *
     * @param $id_a
     * @param $id_r
     * @return mixed
     */
    public function checkAttr($id_a,$id_r)
    {
        $count = RouterSnmpAccess::Model()->count("snmp_access_id=:snmp_access_id AND router_id=:router_id",array("snmp_access_id" => $id_a,"router_id"=>$id_r));
        return $count;
    }

    /**
     * check unique router id
     *
     * @param $id_r
     * @return mixed
     */
    public function checkUniqueRouterId($id_r)
    {
        $count = RouterSnmpAccess::Model()->count("router_id=:router_id",array("router_id"=>$id_r));

        return $count;
    }
}
