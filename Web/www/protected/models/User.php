<?php

/**
 * This is the model class for table "tbl_user".
 *
 * The followings are the available columns in table 'tbl_user':
 * @property integer $id
 * @property string $username
 * @property string $password
 * @property string $email
 */
class User extends CActiveRecord
{
	const SCENARIO_SIGNUP = 'signup';
	public $password_repeat;
        public $old_password;
	/**
	 * @return string the associated database table name
	 */
	public function tableName()
	{
		return 'tbl_user';
	}

	/**
	 * @return array validation rules for model attributes.
	 */
	public function rules()
	{
		// NOTE: you should only define rules for those attributes that
		// will receive user inputs.
		return array(
			array('username, email, fname, lname', 'required'),
			array('username, fname, lname,company', 'length', 'max'=>128),
			array('password', 'length', 'min'=>6, 'max'=>64),
                        array('password', 'required', 'on'=>self::SCENARIO_SIGNUP),
			array('password_repeat', 'required', 'on'=>self::SCENARIO_SIGNUP),
			array('password_repeat', 'length', 'min'=>6, 'max'=>64),
			array('password_repeat', 'safe'),
			array('password_repeat', 'compare', 'compareAttribute'=>'password', 'skipOnError'=>true, 'on'=>self::SCENARIO_SIGNUP),
                        array('password_repeat', 'compare', 'compareAttribute'=>'password', 'skipOnError'=>true, 'on'=>'update'),
			array('email', 'checkemail', 'on'=>self::SCENARIO_SIGNUP),
			array('email', 'length', 'min'=>6, 'max'=>50),
			array('username,email', 'unique'),
			// The following rule is used by search().
			array('id, username,  email,fname,lname,company', 'safe', 'on'=>'search'),
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
			'username' => 'Username',
			'password' => 'Password',
			'email' => 'Email',
			'fname' => 'First Name',
			'lname' => 'Last Name',
			'company' => 'Company',
			'password_repeat' => 'Repeat password',
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

		$criteria->compare('id',$this->id);
		$criteria->compare('username',$this->username,true);
		$criteria->compare('email',$this->email,true);
		$criteria->compare('fname',$this->fname,true);
		$criteria->compare('lname',$this->lname,true);
		$criteria->compare('company',$this->company,true);

		return new CActiveDataProvider($this, array(
			'criteria'=>$criteria,
		));
	}

	/**
	 * Assign role User to new user
	 */
	public function afterSave() {
		$auth=Yii::app()->authManager;
		if ($this->isNewRecord) {
			$auth->assign('User', $this->id);
		}
		return true;
	}

	/**
	 * Action before data deleting
	 */
	public function beforeDelete() {
		$auth=Yii::app()->authManager;
		$sql="SELECT Itemname FROM AuthAssignment WHERE userid=:id";
		$command=Yii::app()->db->createCommand($sql);
		$command->bindValue(':id',$this->id);
		$u_role = $command->queryScalar();
		$auth->revoke($u_role, $this->id);
		$auth->save();
		return true;
	}

	/**
	 * Returns the static model of the specified AR class.
	 * Please note that you should have this exact method in all your CActiveRecord descendants!
	 * @param string $className active record class name.
	 * @return User the static model class
	 */
	public static function model($className=__CLASS__)
	{
		return parent::model($className);
	}

    /**
     * Validate email
     *
     * @param $attribute
     * @param $params
     */
    public function checkemail($attribute,$params){
		$pattern = "/^([a-zA-Z0-9])+([a-zA-Z0-9\._-])*@([a-zA-Z0-9_-])+([a-zA-Z0-9\._-]+)+$/";
		if(!preg_match($pattern, $this->$attribute))
			$this->addError($attribute, 'Wrong email');

	}
}
