<?php
/**
 * Emenu widget for yii
 *
 * @author Nikolay Belichuk <belichuk@hotmail.com>
 * @version 1.1
 * @link http://www.yiiframework.com/
 * @copyright Copyright &copy; 2012-2013 by Nikolay Belichuk
 * @license GNU General Public License
 */
class EMenu extends CWidget
{
	public $tag = 'ul';
	public $subtag = 'li';
	public $id = "";
	public $items = array();
	private $_route = array();

	public function init()
	{
		if( empty($this->items) )
			return;
		$menuClass = 'accordion-menu';
		$cs = Yii::app()->clientScript;

		$dirname = basename(dirname(__FILE__));
		$assets = Yii::getPathOfAlias('ext.'.$dirname);
		$assetUrl = Yii::app()->assetManager->publish($assets);
		$css = $assetUrl . '/assets/css/accordionmenu.css';
		$js = $assetUrl . '/assets/js/accordionmenu.min.js';

		Yii::app()->clientScript->registerCSSFile( $css );
		Yii::app()->clientScript->registerScriptFile( $js );

		$content = '';
		$i=0;
		if (isset(Yii::app()->controller->module))
			$this->_route[$i++] = Yii::app()->controller->module->getName();

		$this->_route[$i++] = Yii::app()->controller->id;
		$this->_route[$i++] = Yii::app()->controller->action->id;
	
		foreach ($this->items as $item) {
			$content .= $this->renderTag($item);
		}

		$htmlOptions = array(
			'id' => empty($this->id) ? null : $this->id,
			'class' => $menuClass
		);

		echo CHtml::tag($this->tag, $htmlOptions, $content);
		Yii::app()->clientScript->registerScript(
			'accordionMenu',
			"$('.".$menuClass."').accordionMenu();", 
			CClientScript::POS_READY
		);
	}

	private function renderTag($item, $level=1)
	{
		$menu = '';
		$submenu = '';
		$toggle  = '';
		$nextlevel = $level + 1;

		if( isset($item['sub']) && is_array($item['sub']) )
		{
			foreach ($item['sub'] as $sub) 
			{
				$submenu .= $this->renderTag($sub, $nextlevel);
			}
			$toggle = CHtml::tag('span', array('class'=>'arrow'), '');
		}

		$content = CHtml::link($item['name'], $item['link']);

	  
		$subclass = array('level'.$level);
		$toggleclass = array('toggler');    
		if( !empty($item['active']) )
		{
			$active = explode('/', $item['active']);
			if( ($level == 1) && ($this->_route[0] == $active[0]) )
			{
				$subclass[] = 'current';
				$subclass[] = 'active';
				$toggleclass[] = 'active';
			}

			if( array_diff($this->_route, $active) == array() )
				$subclass[] = 'active';
		}

		if (isset($item['autoexpand']) && $item['autoexpand'])
		{
			if (!in_array('active', $subclass))
			{
				$subclass[] = 'active';
				$toggleclass[] = 'active';
			}
		}		

		if( $level == 1 ){
			$icon_class = isset($item['icon']) ? $item['icon'] : 'none';
			$icon_class = 'menu_icon ' . 'icon-' . $icon_class;
			$icon   = CHtml::tag('span', array('class'=> $icon_class), '');
/*			$icon_class= 'icon-' . $icon_class;
			$icon = CHtml::tag('i', array('class'=> $icon_class), '');*/
			$toggleOptions = array(
				'class' => implode(' ', $toggleclass)
			);
			$toggleContent = $icon . $toggle . $content;
			$content  = CHtml::tag('div', $toggleOptions, $toggleContent);
		}		

		if (!empty($submenu))
		{
			$htmlOptions = array('class' => 'level'.$nextlevel);
			$submenu = CHtml::tag($this->tag, $htmlOptions, $submenu);	
			$content .= $submenu;
		}

		$menu .= CHtml::tag($this->subtag, array('class'=> implode(' ', $subclass)), $content);		
		return $menu;
	}
}
