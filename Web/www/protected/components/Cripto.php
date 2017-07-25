<?php

/**
 * Class Cripto is class to crypt data using  TRIPLEDES
 *
 */
class Cripto extends CApplicationComponent
{
    /**
     * Encrypt data
     *
     * @param $text
     * @return string
     */
    public static function encrypt($text)
    {
        $iv='12345678';//stub for iv
        $key = Cripto::getKey();
        $cipher = mcrypt_module_open(MCRYPT_TRIPLEDES,'','ecb','');
        mcrypt_generic_init($cipher, $key, $iv);
        $text = $text. str_repeat(' ',8-(strlen($text)%8) );
        $decrypted = mcrypt_generic($cipher,$text);
        mcrypt_generic_deinit($cipher);

        return base64_encode($decrypted);
    }

    /**
     * Decrypt data
     *
     * @param $encrypted_text
     * @return string
     */
    public static function decrypt($encrypted_text)
    {
        if(!empty($encrypted_text))
        {
            $iv='12345678';//stub for iv
            $key = Cripto::getKey();
            $cipher = mcrypt_module_open(MCRYPT_TRIPLEDES,'','ecb','');
            mcrypt_generic_init($cipher, $key, $iv);
            $decrypted = mdecrypt_generic($cipher,base64_decode($encrypted_text));
            mcrypt_generic_deinit($cipher);
        }
        else
        {
            $decrypted = '';
        }

        return $decrypted;
    }

    /**
     * get key from DB
     *
     * @return string
     */
    private static function getKey()
    {

        $chiave = Yii::app()->db->createCommand()
            ->select('value')
            ->from('general_settings')
            ->where("name='chiave'")
            ->queryScalar();

        $key = pack('H*', str_pad($chiave, 16*3, '0'));

        return $key;
    }

    /**
     * update symbols  in password to *
     *
     */
    public static function hidedata($str)
    {

        $str_length = strlen($str);
        for($i =0; $i < $str_length; $i++)
        {
            $str[$i] = '*';
        }

        return $str;
    }
}