<?php
/**
 * ChPolar class file.
 * @author Stefan Meiwald <stefanmeiwald@yahoo.com>
 * @license http://www.opensource.org/licenses/bsd-license.php New BSD License
 * @package chartjs.widgets
 * @since 0.0.1
 */

/**
 * ChartJs Polar Chart widget.
 * @see http://www.chartjs.org/docs/#polarAreaChart
 */ 
class Graph extends CWidget
{
    /**
     * Relative to the webroot alias
     */
    const PICTURE_STORAGE = 'graphs/';


    /**
     * @var configuration Graphviz Configuration as String
     */
    public $configuration = "";

    /**
     * @var Graphviz Component used for generating the graph
     */
    public $graphvizComponent = NULL;

    public $alt = "";

    public $title = "";

    public $map = false;

    private $_graphDirectory = null;
    
    public function init() {
        parent::init();
        $this->_graphDirectory = Yii::getPathOfAlias('webroot') . DIRECTORY_SEPARATOR . static::PICTURE_STORAGE;

        if(!file_exists($this->_graphDirectory))
        {
            mkdir($this->_graphDirectory,0777,true);
        }

        Yii::import('ext.yii-graphviz.components.Graphviz');
        if (!$this->graphvizComponent) {
            $this->graphvizComponent = new Graphviz();
        }
        
    }

    /**
     * Runs the widget.
     */
    public function run()
    {
        $hash = md5($this->configuration);
        $graphFile = $this->_graphDirectory . $hash . ".png";
        $mapFile = $this->_graphDirectory . $hash . ".map";

        $result = "";
        if (!file_exists($graphFile)) {
            $result = $this->graphvizComponent->generateGraphvizFromString($this->configuration,$graphFile,$this->map);
        }
        
        if ($this->map) {
            if (!file_exists($mapFile)) {
                if (!$result) {
                    $result = $this->graphvizComponent->generateGraphvizFromString($this->configuration,$graphFile,$this->map);
                }
                file_put_contents($mapFile,$result);
            }

            $mapContents = file_get_contents($mapFile);

            echo '<map name="map'.$hash.'" id="map'.$hash.'">'.$mapContents.'</map>';
        }

        echo '<img src="'.Yii::app()->baseUrl . '/' . static::PICTURE_STORAGE.$hash.'.png" name="graph'.$hash.'" id="graph'.$hash.'" title="'.$this->title.'" alt="'.$this->alt.'" '.(($this->map)?'usemap="#map'.$hash.'"':'').' >';
    }

}
