<?php

/**
 * This is the model class for table "archive_conf".
 *
 * The followings are the available columns in table 'archive_conf':
 * @property string $arc_expire
 * @property string $arc_delete
 * @property string $arc_period
 * @property integer $arc_enable
 * @property string $arc_path
 * @property integer $log_syslog
 * @property integer $log_level
 * @property integer $arc_gzip
 */
class ArchiveConf extends CActiveRecord
{
	/**
	 * @return string the associated database table name
	 */
	public function tableName()
	{
		return 'archive_conf';
	}

	/**
	 * @return array validation rules for model attributes.
	 */
	public function rules()
	{
		// NOTE: you should only define rules for those attributes that
		// will receive user inputs.
		return array(
			array('arc_enable, log_syslog, log_level, arc_gzip, id_conf', 'numerical', 'integerOnly'=>true),
			array('arc_expire, arc_delete', 'length', 'max'=>10),
			array('arc_period', 'length', 'max'=>4),
			array('arc_path', 'length', 'max'=>100),
			// The following rule is used by search().
			// @todo Please remove those attributes that should not be searched.
			array('arc_expire, arc_delete, arc_period, arc_enable, arc_path, log_syslog, log_level, arc_gzip, id_conf', 'safe', 'on'=>'search'),
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
			'arc_expire' => 'ArcTimeout',
			'arc_delete' => 'ArcDelTimeout',
			'arc_period' => 'period for cron',
			'arc_enable' => 'Arc Enable',
			'arc_path' => 'Arc Path',
			'log_syslog' => 'Log Syslog',
			'log_level' => 'Log Level',
			'arc_gzip' => 'Arc Gzip',
            'id_conf' => "Configuration ID"
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

		$criteria->compare('arc_expire',$this->arc_expire,true);
		$criteria->compare('arc_delete',$this->arc_delete,true);
		$criteria->compare('arc_period',$this->arc_period,true);
		$criteria->compare('arc_enable',$this->arc_enable);
		$criteria->compare('arc_path',$this->arc_path,true);
		$criteria->compare('log_syslog',$this->log_syslog);
		$criteria->compare('log_level',$this->log_level);
		$criteria->compare('arc_gzip',$this->arc_gzip);
        $criteria->compare('id_conf',$this->arc_gzip);

		return new CActiveDataProvider($this, array(
			'criteria'=>$criteria,
		));
	}

	/**
	 * Returns the static model of the specified AR class.
	 * Please note that you should have this exact method in all your CActiveRecord descendants!
	 * @param string $className active record class name.
	 * @return ArchiveConf the static model class
	 */
	public static function model($className=__CLASS__)
	{
		return parent::model($className);
	}
}
