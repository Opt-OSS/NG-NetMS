<?php

/**
 * This is the model class for table "access_type".
 *
 * The followings are the available columns in table 'access_type':
 * @property integer $id
 * @property string $name
 */
class AccessType extends CActiveRecord
{
	/**
	 * @return string the associated database table name
	 */
	public function tableName()
	{
		return 'access_type';
	}

	/**
	 * @return array validation rules for model attributes.
	 */
	public function rules()
	{
		// NOTE: you should only define rules for those attributes that
		// will receive user inputs.
		return array(
            array('name', 'required'),
			array('name', 'length', 'max'=>40),
			// The following rule is used by search().
			// @todo Please remove those attributes that should not be searched.
			array('id, name', 'safe', 'on'=>'search'),
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
            'accesses' => array(self::HAS_MANY, 'Access', 'id_access_type'),
        );
	}

	/**
	 * @return array customized attribute labels (name=>label)
	 */
	public function attributeLabels()
	{
		return array(
			'id' => 'ID',
			'name' => 'Name',
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
		$criteria->compare('name',$this->name,true);

		return new CActiveDataProvider($this, array(
			'criteria'=>$criteria,
		));
	}

	/**
	 * Returns the static model of the specified AR class.
	 * Please note that you should have this exact method in all your CActiveRecord descendants!
	 * @param string $className active record class name.
	 * @return AccessType the static model class
	 */
	public static function model($className=__CLASS__)
	{
		return parent::model($className);
	}

    public function findAttrAccess()
    {
        $arr_data  = Yii::app()->db->createCommand()
            ->select('ar.id,ar.name from ')
            ->where(" aa.id_access_type ='".$this->id_access_type ."' and aa.id_attr = ar.id ")
            ->from(' attr_access as aa, attr as ar  ')
            ->order(' ar.id ')
            ->queryAll();

        return $arr_data;
    }

    /**
     * Return Name property
     *
     * @return mixed
     */
    public function getName()
    {
        return   Yii::app()->db->createCommand()
            ->select('name ')
            ->where(" id ='".$this->id ."'")
            ->from(' access_type  ')
            ->queryScalar();
    }
}
