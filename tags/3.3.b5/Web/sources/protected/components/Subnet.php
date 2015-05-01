<?php
require 'Net/IPv4.php';

/**
 * Class Subnet builds IP map
 */

class Subnet extends CApplicationComponent
{
    
    private $arr = array();
    private $arr_ip = array();
    private $arr_iname = array();
    private $arr_rname = array();
    private $arr_descr = array();
    public  $gamma = array();
    public  $res = array();

    /**
     * wrapper : run process
     *
     * @return array
     */
    public function getTree()
    {
        $this->formTree();
        return $this->res;
    }

    /**
     * Create tree of Ips
     */
    public function formTree()
    {
        $arr1 = $this->getAllInterfaces();
        $this->formSubnets($arr1);
        $this->formNodes();
        $this->formLeafs();
        $this->lastSort();
        
    }

    /**
     * Get intrfaces from DB
     *
     * @return array
     */
    private function getAllInterfaces()
    {
        $arr_ret = array();
        $interfaces=Interfaces::model()->with('router')->findAll(array('order'=>'t.ip_addr asc',));
        $i = 0;
        
        foreach($interfaces as $interf)
        {
            $arr_ret[$i]['ip_addr'] = $interf->ip_addr;
            $arr_ret[$i]['mask'] = $interf->mask;
            $arr_ret[$i]['iname'] = $interf->name;
            $arr_ret[$i]['rname'] = $interf->router->name;
            if(!empty($interf->descr))
            {
                $arr_ret[$i]['descr'] = $interf->descr;
            }
            else
            {
                $parent_ph_int = PhInt::model()->findByPk($interf->ph_int_id);
                $arr_ret[$i]['descr'] = $parent_ph_int->descr;
            }
            $i++;
        }

        return $arr_ret;
    }

    /**
     * Create Subnets
     *
     * @param $arr_in
     */
    private function formSubnets($arr_in)
    {
        $arr_network = array();
        $arr_mask = array();
        $arr_cidr =array();
        $arr_range = array();
        $arr_parent =array();
        $arr_classes = array();
        $arr_sort =array();
        $arr_sort1 =array();
        $arr_sort2 =array();
        $arr_sort3 =array();
        $arr_sort5 =array();
        $arr_main =array();
        $arr_network[0] = '0.0.0.0';
        $arr_mask[0]='0.0.0.0';
        $arr_cidr[0]=0;
        $arr_range[0]='0.0.0.0/0';
        $arr_classes[0]='N';
        $arr_main[0] = '0.0.0.0/0';
        $this->arr_ip[0] = '0.0.0.0';
        $kolv = count($arr_in);
        $j=1;
        $k=1;

        for($i=0;$i<$kolv;$i++)
        {   
           $ip_calc = new Net_IPv4();
           $arr1 = $arr_in[$i];
// Set variables
           $ip_calc->ip = $arr1['ip_addr'];
           $ip_calc->netmask = $arr1['mask'];
           $octets = explode('.',$ip_calc->ip);
           $error = $ip_calc->calculate();
           
           if (!is_object($error))
            {
                // if returned true, output
                $arr_network[$j] = trim($ip_calc->network);
                $this->arr_ip[$j] = trim($ip_calc->ip);
                $arr_cidr[$j] = $this->mask2cidr($ip_calc->netmask);
                $arr_range[$j] = trim($ip_calc->network)."/".$this->mask2cidr($ip_calc->netmask);
                $arr_mask[$j] = $ip_calc->netmask;
                $this->arr_iname[$j] = trim($arr1['iname']);
                $this->arr_rname[$j] = trim($arr1['rname']);
                $arr_classes[$j]= $this->getClassfulNet($octets[0]);
                $this->arr_descr[$j] = trim($arr1['descr']);

                if($arr_classes[$j] == 'A')
                {
                  $arr_main[$k] = $octets[0].'.0.0.0/8';
                  $k++;
                }
                else if($arr_classes[$j] == 'B')
                {
                  $arr_main[$k] = $octets[0].'.'.$octets[1].'.0.0/16';
                  $k++;
                }
                else if($arr_classes[$j] == 'C')
                {
                  $arr_main[$k] = $octets[0].'.'.$octets[1].'.'.$octets[2].'.0/24';
                  $k++;
                }
                else if($arr_cidr[$j]!=32)
                {
                    $arr_main[$k] = $arr_range[$j];
                    $k++;
                }

                $j++;
            }
            else
            {
              // otherwise handle error
              echo "An error occured: ".$error->getMessage();
            }
        }
        
        $arr_new = array_merge($arr_main,$arr_range);
        $arr_new1 = array_unique($arr_new);
        
        foreach($arr_new1 as $valore)
        {
            $octets1 = explode('.',$valore);
            $mmask = explode('/',$octets1[3]);
            if($mmask[1]<32)
            {
                $this->arr[] = $valore;       
                $arr_sort[]=$octets1[0];
                $arr_sort1[]=$octets1[1];
                $arr_sort2[]=$octets1[2];
                $arr_sort3[]=$octets1[3];
                $arr_sort5[]=(int)$mmask[1];
            }
        }
        
        array_multisort($arr_sort, SORT_ASC, SORT_NUMERIC, $arr_sort1, SORT_ASC, SORT_NUMERIC, $arr_sort2, SORT_ASC, SORT_NUMERIC, $arr_sort3, SORT_ASC, SORT_NUMERIC, $arr_sort5,SORT_ASC, SORT_NUMERIC, $this->arr);
        
        foreach($this->arr as $kl=>$vl)
        {
            $this->gamma[$kl] = $this->getIPRange($vl);
        }
    }

    /**
     * Create nodes
     */
    private function formNodes()
    {
        $this->res[0]['id'] = (string)0;
        $this->res[0]['parent'] = "#";
        $this->res[0]['text'] = $this->arr[0];
        $this->res[0]['state']['opened'] = true;
        $this->res[0]['cl'] = "";
        $this->res[0]['iname'] = '';
        $this->res[0]['rname'] = '';
        $this->res[0]["li_attr"]["class"] = "" ;
        
        for($k=1; $k<count($this->arr);$k++)
        {
            $this->res[$k]['id'] = (string)$k;
            $this->res[$k]['text'] = $this->arr[$k];
            $this->res[$k]['state']['opened'] = true;
            $nets = explode(".",$this->arr[$k]);
            $net = Net_IPv4::parseAddress($this->arr[$k]);
            $klass = $this->getClassNet($net->bitmask,$nets[0]);
            $this->res[$k]['cl'] = $klass;
            if(empty($klass))
            { 
            $this->res[$k]["li_attr"]["class"] = "blue" ;
            }
            else
            {
                $this->res[$k]["li_attr"]["class"] = "green" ;
                }
            $this->res[$k]['iname'] = '';
            $this->res[$k]['rname'] = '';
            
            for($jl =0;$jl<$k;$jl++)
            {
                if($this->gamma[$k]['start']>=$this->gamma[$jl]['start'] && $this->gamma[$k]['stop']<=$this->gamma[$jl]['stop'] )
                    {
                        $this->res[$k]['parent'] = (string)$jl;
                    }
                }
        }
    }

    /**
     * Create leafs of tree
     */
    private function formLeafs()
    {
        $ind_shift = count($this->arr);
        for($l=1;$l<count($this->arr_ip);$l++)
        {
            $koef = $ind_shift + $l-1;
            $this->res[$koef]['id'] = (string)$koef;
            $this->res[$koef]['text'] = $this->arr_ip[$l];
            $this->res[$koef]['cl'] = $this->arr_descr[$l];
            $this->res[$koef]['iname'] = $this->arr_iname[$l];
            $this->res[$koef]['rname'] = $this->arr_rname[$l];
            $this->res[$koef]["li_attr"]["class"] = "normal" ;
            $ip_l = Net_IPv4::ip2double($this->arr_ip[$l]);
            
            for($jl =0;$jl<$ind_shift;$jl++)
            {
                if($ip_l>=$this->gamma[$jl]['start'] && $ip_l<=$this->gamma[$jl]['stop'] )
                    {
                        $this->res[$koef]['parent'] = (string)$jl;
                    }
            }
        }
    }

    /**
     * Get Net cllsses
     *
     * @param $oct0
     * @return string
     */
    private function getClassfulNet($oct0)
    {
        if($oct0<1)
        {
            return 'N';
        }
        else if($oct0<128)
        {
            return 'A';
        }
        else if($oct0<192)
        {
            return 'B';
        }
        else if($oct0<224)
        {
            return 'C';
        }
        else
        {
             return 'N';
            }
    }

    /**
     * Get network classes using mask
     *
     * @param $btmask
     * @param $btfb
     * @return string
     */
    private function getClassNet($btmask,$btfb)
    {
        $str="";
        if($btmask == 8 && $btfb >= 0 && $btfb < 128)
        {
            $str = "Network class A";
        }
        else if ($btmask == 16 && $btfb>=128 && $btfb <192)
        {
            $str = "Network class B";
        }
        else if ($btmask == 24 && $btfb>=192 && $btfb <224)
        {
            $str = "Network class C";
        }
        
        return $str;
    }

    /**
     * Convert mask to cidr
     *
     * @param $mask
     * @return int
     */
    private function mask2cidr($mask) 
    {
        $mask = preg_split( "/[.]/", $mask );
        $bits = 0;
        foreach ($mask as $octect) {
            $bin = decbin($octect);
            $bin = str_replace ( "0" , "" , $bin);
            $bits = $bits + strlen($bin);
        }
        return $bits;
    }

    /**
     * Match cidr
     *
     * @param $ip
     * @param $range
     * @return bool
     */
    private function cidr_match($ip, $range)
    {
        list ($subnet, $bits) = preg_split('////', $range);
        $ip = ip2long($ip);
        $subnet = ip2long($subnet);
        $mask = -1 << (32 - $bits);
        $subnet &= $mask; # nb: in case the supplied subnet wasn't correctly aligned
        return ($ip & $mask) == $subnet;
    }

    /**
     * Get ranges of IP
     *
     * @param $cidr
     * @return array
     */
    private function getIPRange($cidr )
    {
        $net = Net_IPv4::parseAddress($cidr);
        return array('start'=>Net_IPv4::ip2double($net->network),'stop'=>Net_IPv4::ip2double($net->broadcast));
    }

    /**
     * Sort array of IP
     */
    private function lastSort()
    {
        $ip_text = array();
        foreach($this->res as $key => $row) 
        {
           $ip_text[$key]  = $row['text'];
        }
        
        array_multisort($ip_text, SORT_ASC, SORT_NUMERIC, $this->res);
    }
    
}

