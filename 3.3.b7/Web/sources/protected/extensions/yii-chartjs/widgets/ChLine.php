<?php
/**
 * ChLine class file.
 * @author Stefan Meiwald <stefanmeiwald@yahoo.com>
 * @license http://www.opensource.org/licenses/bsd-license.php New BSD License
 * @package chartjs.widgets
 * @since 0.0.1
 */

/**
 * ChartJs Line Chart widget.
 * @see http://www.chartjs.org/docs/#lineChart
 */ 
class ChLine extends CWidget
{
    const CONTAINER_PREFIX = 'yii_chartjs_line_';

    /**
     * @var array the options for the ChartJS Javascript plugin.
     */
    public $options = array();
    /**
     * @var array labels for the chart
     */
    public $labels = array();
    /**
     * @var array data and color information for the chart
     */
    public $datasets = array();
    /**
     * @var array the HTML attributes for the widget container.
     */
    public $htmlOptions = array();
    /**
     * @var chart width
     */
    public $width = 400;
    /**
     * @var chart height
     */
    public $height = 400;
    /**
     * @var html id of canvas element
     */
    public $htmlId;
    /**
     * @var widget count to generate html id
     */
    private static $_containerId = 0;

    /**
     * Initializes the widget.
     */
    public function init()
    {
        if (!empty($this->htmlOptions['id'])) {
            $this->htmlId = $this->htmlOptions['id'];
        } else {
            $this->htmlId = self::CONTAINER_PREFIX.self::getNextId();
        }

        $this->htmlOptions['width'] = $this->width;
        $this->htmlOptions['height'] = $this->height;
        $this->htmlOptions['id'] = $this->htmlId;

        echo CHtml::openTag('canvas', $this->htmlOptions);
    }

    /**
     * Runs the widget.
     */
    public function run()
    {
        echo CHtml::closeTag('canvas');

        $data = CJSON::encode(
            array(
                'labels' => $this->labels, 
                'datasets' => $this->datasets
            )
        );
        $options = CJSON::encode($this->options);

        $cs = Yii::app()->getClientScript();
        $cs->registerScript(
            __CLASS__.'#'.$this->htmlId, 
            "var chart = new Chart($(\"#".$this->htmlId."\").get(0).getContext(\"2d\")).Line(".$data.",".$options.");"
        );
    }

    /**
     * Returns the next html id to avoid duplicated ids
     */
    static public function getNextId()
    {
        return self::$_containerId++;
    }
}
