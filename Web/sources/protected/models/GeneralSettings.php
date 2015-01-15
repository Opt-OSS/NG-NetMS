<?php

/**
 * This is the model class for table "general_settings".
 *
 * The followings are the available columns in table 'general_settings':
 * @property integer $id
 * @property string $name
 * @property string $value
 */
class GeneralSettings extends CActiveRecord
{
	/**
	 * @return string the associated database table name
	 */
	public function tableName()
	{
		return 'general_settings';
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
			array('name', 'length', 'max'=>50),
			array('value', 'length', 'max'=>255),
            array('label', 'length', 'max'=>100),
			// The following rule is used by search().
			// @todo Please remove those attributes that should not be searched.
			array('id, name, value,label,order_view', 'safe', 'on'=>'search'),
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
			'id' => 'ID',
			'name' => 'Attribute',
			'value' => 'Value of Attribute',
            'label' =>'Attribute Name',
		);
	}

    protected function beforeSave()
    {
        if(!empty($this->value) && $this->name !='chiave')
        {
            if($this->name !='perioddiscovery')
                     $this->value = Cripto::encrypt($this->value);
        }



        return parent::beforeSave();

    }


    public static function valueFormated($model)
    {
        if($model->name !='chiave' && $model->name !='perioddiscovery')
        {
            return  trim(Cripto::decrypt($model->value));
        }
        else
        {
            return $model->value;
        }
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
		$criteria->compare('value',$this->value,true);
        $criteria->addNotInCondition('name',array('chiave','perioddiscovery'));
        $criteria->order = 'order_view ASC';


        return new CActiveDataProvider($this, array(
			'criteria'=>$criteria,
		));
	}

	/**
	 * Returns the static model of the specified AR class.
	 * Please note that you should have this exact method in all your CActiveRecord descendants!
	 * @param string $className active record class name.
	 * @return GeneralSettings the static model class
	 */
	public static function model($className=__CLASS__)
	{
		return parent::model($className);
	}
}
