<?php

/**
 * This is the model class for table "discovery_status".
 *
 * The followings are the available columns in table 'discovery_status':
 * @property string $username
 * @property integer $percent
 * @property string $lastchange
 * @property string $finish
 * @property string $start
 * @property integer $ended
 */
class DiscoveryStatus extends CActiveRecord
{
	/**
	 * @return string the associated database table name
	 */
	public function tableName()
	{
		return 'discovery_status';
	}

	/**
	 * @return array validation rules for model attributes.
	 */
	public function rules()
	{
		// NOTE: you should only define rules for those attributes that
		// will receive user inputs.
		return array(
			array('start', 'required'),
			array('percent, ended', 'numerical', 'integerOnly'=>true),
			array('username, lastchange, finish', 'safe'),
			// The following rule is used by search().
			// @todo Please remove those attributes that should not be searched.
			array('username, percent, lastchange, finish, start, ended', 'safe', 'on'=>'search'),
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
			'username' => 'Username',
			'percent' => 'Percent',
			'lastchange' => 'Lastchange',
			'finish' => 'Finish',
			'start' => 'Start',
			'ended' => 'Ended',
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

		$criteria->compare('username',$this->username,true);
		$criteria->compare('percent',$this->percent);
		$criteria->compare('lastchange',$this->lastchange,true);
		$criteria->compare('finish',$this->finish,true);
		$criteria->compare('start',$this->start,true);
		$criteria->compare('ended',$this->ended);

		return new CActiveDataProvider($this, array(
			'criteria'=>$criteria,
		));
	}

	/**
	 * Returns the static model of the specified AR class.
	 * Please note that you should have this exact method in all your CActiveRecord descendants!
	 * @param string $className active record class name.
	 * @return DiscoveryStatus the static model class
	 */
	public static function model($className=__CLASS__)
	{
		return parent::model($className);
	}
}
