<?php

/**
 * This is the model class for table "archives".
 *
 * The followings are the available columns in table 'archives':
 * @property integer $archive_id
 * @property string $start_time
 * @property string $end_time
 * @property string $file_name
 * @property boolean $in_db
 */
class Archives extends CActiveRecord
{
	/**
	 * @return string the associated database table name
	 */
	public function tableName()
	{
		return 'archives';
	}

	/**
	 * @return array validation rules for model attributes.
	 */
	public function rules()
	{
		// NOTE: you should only define rules for those attributes that
		// will receive user inputs.
		return array(
			array('start_time, end_time, file_name', 'required'),
			array('file_name', 'length', 'max'=>64),
			array('in_db', 'safe'),
			// The following rule is used by search().
			// @todo Please remove those attributes that should not be searched.
			array('archive_id, start_time, end_time, file_name, in_db', 'safe', 'on'=>'search'),
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
			'archive_id' => 'Archive',
			'start_time' => 'Start Time',
			'end_time' => 'End Time',
			'file_name' => 'File Name',
			'in_db' => 'In Db',
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

		$criteria->compare('archive_id',$this->archive_id);
/*		$criteria->compare('start_time',$this->start_time,true);
		$criteria->compare('end_time',$this->end_time,true);*/
        $criteria->compare("to_char(start_time, 'YYYY-MM-DD HH24:MI:SS')",$this->start_time,true);
        $criteria->compare("to_char(end_time, 'YYYY-MM-DD HH24:MI:SS')",$this->end_time,true);
		$criteria->compare('file_name',$this->file_name,true);
		$criteria->compare('in_db',$this->in_db);

		return new CActiveDataProvider($this, array(
			'criteria'=>$criteria,
		));
	}

	/**
	 * Returns the static model of the specified AR class.
	 * Please note that you should have this exact method in all your CActiveRecord descendants!
	 * @param string $className active record class name.
	 * @return Archives the static model class
	 */
	public static function model($className=__CLASS__)
	{
		return parent::model($className);
	}
}
