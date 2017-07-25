<?php

class ChartJs extends CApplicationComponent
{
    /**
    * @var boolean indicates whether assets should be republished on every request.
    */
    public $forceCopyAssets = false;

    /**
    * @var assets handle
    */
    protected $_assetsUrl;

    /**
    * Register the ChartJS lib
    */
    public function init()
    {
        $cs = Yii::app()->getClientScript();
        $cs->registerCoreScript('jquery');
        $jsFilename = YII_DEBUG ? 'Chart.js' : 'Chart.min.js';
        $cssFilename = YII_DEBUG ? 'styles.css' : 'styles.min.css';
        $cs->registerScriptFile($this->getAssetsUrl().'/js/'.$jsFilename, CClientScript::POS_HEAD);
        $cs->registerCssFile($this->getAssetsUrl() . "/css/".$cssFilename, '');
    }

    /**
    * Returns the URL to the published assets folder.
    * @return string the URL
    */
    protected function getAssetsUrl()
    {
        if (isset($this->_assetsUrl))
            return $this->_assetsUrl;
        else
        {
            $assetsPath = Yii::getPathOfAlias('chartjs.assets');
            $assetsUrl = Yii::app()->assetManager->publish($assetsPath, false, -1, $this->forceCopyAssets);
            return $this->_assetsUrl = $assetsUrl;
        }
    }

    /**
    * Returns the extension version number.
    * @return string the version
    */
    public function getVersion()
    {
        return '0.0.1';
    }
}
