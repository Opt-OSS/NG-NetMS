<?php

/**
 * Class DiffConf compares configuration of router
 * based on unix command diff
 *
 *
 */
class DiffConf extends CApplicationComponent
{
    public $conf1 ;
    public $conf2 ;
    private $fullname1;
    private $fullname2;

    /**
     * Wrapper: run coppare and run rendering data for showing
     *
     * @return string
     */
    public function main()
    {
       
        $this->createfilefordiff();
        $diffs = $this->renderDiffColumn();
        
        return $diffs;        
    }

    /**
     * set configuration for comparison
     *
     * @param $conf1
     * @param $conf2
     */
    public function setConfigs($conf1,$conf2)
    {
        $this->conf1 = $conf1;
        $this->conf2 = $conf2;
    }

    /**
     * Get full path for first file for comparison
     *
     * @return mixed
     */
    public function getFullpath1(){
        return $this->fullname1;
    }

    /**
     * Get full path for second file for comparison
     *
     * @return mixed
     */
    public function getFullpath2(){
        return $this->fullname2;
    }

    /**
     * Create files for comparison using data from DB
     */
    private function createfilefordiff()
    {
        $basePath = Yii::app()->basePath;
        // create filename for first config
        $name1 = 'conf'.rand(100000,999999);       
        $this->fullname1 = Yii::app()->basePath."/tmp/".$name1.".txt";
        // create filename for second config
        $name2 = 'conf'.rand(100000,999999);
        $this->fullname2 = Yii::app()->basePath."/tmp/".$name2.".txt";
        // get first config from DB
        $contents = stream_get_contents($this->conf1['data']);
        // save first config in file
        file_put_contents($this->fullname1, $contents);
        //get second config from DB
        $contents = stream_get_contents($this->conf2['data']);
        // save second config in file
        file_put_contents($this->fullname2, $contents);         
    }

    /**
     * render data for showing
     *
     * @return string
     */
    private function renderDiffColumn()
    {
        $fullNamePath1 = $this->fullname1;
        $fullNamePath2 = $this->fullname2;
        $orig      =  explode("\n", file_get_contents($fullNamePath1) );
        $diffRes   =  explode("\n", shell_exec("diff $fullNamePath1 $fullNamePath2") );
        $finalFile = '';
        $action = Array();
        $res = '';
        $i=1;
        $lines=1;

        while(!empty($diffRes))
        {
          $diffRes = $this->retrieveDiffAction($diffRes, $action);
          
          if(empty($diffRes))
              continue;
          
          //Preparation for placement
          switch($action['type'])
          {
            case 'a':
                $action['l11']++;
            break;
          }

          //I placed it at the beginning of the difference
          while($i < $action['l11'])
          {
            $finalFile .=  htmlentities(str_pad ("$lines | ", 8, " ", STR_PAD_LEFT).array_shift($orig))."\n";
            $lines++;
            $i++;
          }

          while( ($d=array_shift($action['data'])) )
          {
            //Insert differents
            switch($action['type'])
            {
              case 'a':
                $str = substr($d,2);
                if($str == "") $str = "\n";
                $finalFile .= "<ins>".htmlentities(str_pad ("$lines | ", 8, " ", STR_PAD_LEFT).$str)."</ins>\n";
                $lines++;
              break;

              case 'd':
                $str = substr($d,2);
                if($str == "") $str = "\n";
                $finalFile .= "<del>".htmlentities(str_pad ("      | ", 8, " ", STR_PAD_LEFT).$str)."</del>\n";
              break;

              case 'c':
                $str = substr($d,2);
                if($str == "") $str = "\n";
                
                if($d[0] == '<' )
                {
                          $finalFile .= "<del>".htmlentities(str_pad ("      | ", 8, " ", STR_PAD_LEFT).$str)."</del>\n";
                }
                else if($d[0] == '>' )
                {
                          $finalFile .= "<ins>".htmlentities(str_pad ("$lines | ", 8, " ", STR_PAD_LEFT).$str)."</ins>\n";
                          $lines++;
                }
              break;
            }
          }

          //Preparation for placement
          switch($action['type'])
          {
            case 'd':
            case 'c':
                array_shift($orig);
                $i++;
            break;
          }

                        
          //End of different
          while($i <= $action['l12'])
          {
            array_shift($orig);
            $i++;                   
          }
          
        }


        while( ($r = array_shift($orig)))
        {
          $finalFile .= htmlentities(str_pad ("$lines | ", 8, " ", STR_PAD_LEFT).$r)."\n";
          $lines++;
        }          
        
        $res .= "<pre class='diff2' >";
        $res .= $finalFile;
        $res .= "</pre >";

      return $res;       
    }

    /**
     * parse data for rendering
     *
     * @param $diffRes
     * @param $action
     * @return mixed
     */
    private function retrieveDiffAction($diffRes, &$action)
    {
        $r=$diffRes[0];
      $action['l11'] = $action['l12'] = $action['l21'] = $action['l22'] = 0;
      
      array_shift($diffRes);	// I remove the line just read
      
      if( ($idxType=strpos ( $r , 'd')) )
      {
        $action['type']="d";
      }
      else if( ($idxType=strpos ( $r , 'c')) )
      {
         $action['type']="c";
      }
      else if( ($idxType=strpos ( $r , 'a')) )
      {
         $action['type']="a";
      }
     
      //Seeking the first comma
      $idxComma=strpos ( $r , ',');
      if(!$idxComma)
      {
        //If the first comma is not there I have a number of first line and 
        //one after
        $action['l1n']=1;
        $action['l2n']=1;
        sscanf($r,"%d%c%d", $action['l11'], $action['type'], $action['l21']);
      }
      else if($idxComma < $idxType)
      {
         // If the first comma and placed before the type
         // then I have a two line numbers before
        $action['l1n']=2;

        $idxComma=strpos ( $r , ',', $idxComma);
        if(!$idxComma)
        {
          //here I have a line number after
          $action['l2n']=1;
          sscanf($r,"%d,%d%c%d", $action['l11'],$action['l12'], $action['type'], $action['l21']);
        }
        else
        {
          // here I have two line numbers after
          // here I have a line number after
          $action['l2n']=1;
          sscanf($r,"%d,%d%c%d,%d", $action['l11'],$action['l12'], $action['type'], $action['l21'], $action['l22']);
        }
      }
      else
      {
        // If the first comma and placed after the type
        // then I have a line number before
        $action['l1n']=1;

        $idxComma=strpos ( $r , ',', $idxComma);
        if(!$idxComma)
        {
          // here I have a line number after
          $action['l2n']=1;
          sscanf($r,"%d%c%d", $action['l11'], $action['type'], $action['l21']);
        }
        else
        {
          // here I have two line numbers after
          // here I have a line number after
          $action['l2n']=1;
          sscanf($r,"%d%c%d,%d", $action['l11'], $action['type'], $action['l21'], $action['l22']);
        }
      }
     
        // ONCE READ IN THE LINE OF REVENUE DATA    
      $action['data'] = Array();
      foreach($diffRes as $j => $r)
      {
        $exit=false;

        $c0 = substr($r, 0, 1);
        
        switch($action['type'])
        {
          case 'a':
            if( $c0 != '>') $exit=true;
          break;

          case 'd':
            if( $c0 != '<') $exit=true;
          break;

          case 'c':
            if($c0 != '<' && $c0 != '>' && $c0 != '-') $exit=true;
          break;
        }

        if($exit) break;
        $action['data'][$j]= $r;
        array_shift($diffRes);
      }

      return $diffRes;
    }
}
