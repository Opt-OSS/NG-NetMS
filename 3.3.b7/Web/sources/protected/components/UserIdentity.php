<?php

/**
 * UserIdentity represents the data needed to identity a user.
 * It contains the authentication method that checks if the provided
 * data can identity the user.
 */
class UserIdentity extends CUserIdentity
{
	private $_id;

    /**
     * authenticate user
     *
     * @return bool
     */
    public function authenticate()
	{
		$record=User::model()->findByAttributes(array('username'=>$this->username));
		if($record===null)
			$this->errorCode=self::ERROR_USERNAME_INVALID;
		else if($record->password!==md5($this->password))
			$this->errorCode=self::ERROR_PASSWORD_INVALID;
		else
		{
			$this->_id=$record->id;
			$this->setState('title', $record->username);
			$this->errorCode=self::ERROR_NONE;
		}
		return !$this->errorCode;
	}

    /**
     * Get id of user
     *
     * @return mixed
     */
    public function getId()
	{
		return $this->_id;
	}
}
