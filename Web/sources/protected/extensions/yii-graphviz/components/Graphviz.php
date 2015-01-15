<?php
/**
 * Created by Ascendro S.R.L.
 * User: Michael
 * Date: 14.08.13
 * Time: 14:01
 */
class Graphviz extends CApplicationComponent
{
    public $path = 'dot';
    public $layoutEngine = 'dot';
    public $fileType = 'png';
    public $tmpDirectory = "";

    public function init()
    {
        if (!$this->tmpDirectory) {
            $this->tmpDirectory = sys_get_temp_dir();
        }
        parent::init();
    }

    /**
     * Create GraphvizFiles from a configuration file
     * @param $configurationFile File containing graphviz configuration
     * @param $destination Destination the imagefile should be saved to
     * @param bool $createMap Set to true if a image map should be created
     * @return bool|string False on failure, true on success, image map on success if image map should be created
     */
    public function generateGraphvizFromFile($configurationFile,$destination,$createMap = false) {
        $result = false;
        if ($this->generateImage($configurationFile,$destination)) {
            if ($createMap) {
                $tempFile = tempnam($this->tmpDirectory,"");
                if ($this->generateMap($configurationFile,$tempFile)) {
                    $result = file_get_contents($tempFile);
                } else {
                    $result = true;
                }
                unlink($tempFile);
            } else {
                $result = true;
            }
        }
        return $result;
    }

    /**
     * Create GraphvizFiles from a configuration string
     * @param $configurationString String containing the graphviz configuration
     * @param $destination Destination the imagefile should be saved to
     * @param bool $createMap Set to true if a image map should be created
     * @return bool|string  False on failure, true on success, image map on success if image map should be created
     */
    public function generateGraphvizFromString($configurationString,$destination,$createMap = false) {
        $tempFile = tempnam($this->tmpDirectory,"");
        file_put_contents($tempFile,$configurationString);
        chmod($tempFile, 0644);
        $result = $this->generateGraphvizFromFile($tempFile,$destination,$createMap);
        unlink($tempFile);
        return $result;
    }

    /**
     * Run the graphviz program to generate an image from the source
     * @param $src Sourcefile to read configuration
     * @param $destination Destination file to save result
     * @return bool True if succesfull
     */
    public function generateImage($src,$destination) {
        $cmd = $this->path;
        $cmd .= ' -T'.$this->fileType;
        $cmd .= ' -K'.$this->layoutEngine;
        $cmd .= ' -o'.escapeshellarg($destination); //output
        $cmd .= ' '.escapeshellarg($src); //input
        $cmd .= ' 2>&1';
        exec($cmd, $output, $error);
        if ($error != 0){
            throw new CException("Graphviz image generation error. Code: $error. Command: $cmd Output: ".print_r($output, true)."");
        }
        return true;
    }

    /**
     * Run the graphviz program to generate an map file from the source
     * @param $src Sourcefile to read configuration
     * @param $destination Destination file to save result
     * @return bool True if succesfull
     */
    public function generateMap($src,$destination) {
        $cmd = $this->path;
        $cmd .= ' -Tcmap';
        $cmd .= ' -K'.$this->layoutEngine;
        $cmd .= ' -o'.escapeshellarg($destination); //output
        $cmd .= ' '.escapeshellarg($src); //input
        exec($cmd, $output, $error);
        if ($error != 0){
            return false;
        }
        return true;
    }
}
