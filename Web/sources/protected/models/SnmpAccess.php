<?php

/**
 * This is the model class for table "snmp_access".
 *
 * The followings are the available columns in table 'snmp_access':
 * @property integer $id
 * @property string $community_ro
 * @property string $community_rw
 *
 * The followings are the available model relations:
 * @property RouterSnmpAccess[] $routerSnmpAccesses
 */
class SnmpAccess extends CActiveRecord
{
	/**
	 * @return string the associated database table name
	 */
	public function tableName()
	{
		return 'snmp_access';
	}

	/**
	 * @return array validation rules for model attributes.
	 */
	public function rules()
	{
		// NOTE: you should only define rules for those attributes that
		// will receive user inputs.
		return array(
			array('community_ro, community_rw', 'safe'),
			// The following rule is used by search().
			// @todo Please remove those attributes that should not be searched.
			array('id, community_ro, community_rw', 'safe', 'on'=>'search'),
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
			'routerSnmpAccesses' => array(self::HAS_MANY, 'RouterSnmpAccess', 'snmp_access_id'),
		);
	}

	/**
	 * @return array customized attribute labels (name=>label)
	 */
	public function attributeLabels()
	{
		return array(
			'id' => 'ID',
			'community_ro' => 'Community Ro',
			'community_rw' => 'Community Rw',
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
		$criteria->compare('community_ro',$this->community_ro,true);
		$criteria->compare('community_rw',$this->community_rw,true);

		return new CActiveDataProvider($this, array(
			'criteria'=>$criteria,
		));
	}

    /**
     * action before saving data in DB
     *
     * @return mixed
     */
    protected function beforeSave()
    {
        if(!empty($this->community_ro))
            $this->community_ro = Cripto::encrypt($this->community_ro);
        if(!empty($this->community_rw))
            $this->community_rw = Cripto::encrypt($this->community_rw);

        return parent::beforeSave();

    }

	/**
	 * Returns the static model of the specified AR class.
	 * Please note that you should have this exact method in all your CActiveRecord descendants!
	 * @param string $className active record class name.
	 * @return SnmpAccess the static model class
	 */
	public static function model($className=__CLASS__)
	{
		return parent::model($className);
	}
}
