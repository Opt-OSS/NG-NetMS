<?php

/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

/**
 * Description of SHtml
 *
 * @author lordovol
 */
class SHtml extends CHtml {

  /**
   * Generates a button.
   * @param string the button label
   * @param array additional HTML attributes. Besides normal HTML attributes, a few special
   * attributes are also recognized (see {@link clientChange} and {@link tag} for more details.)
   * @return string the generated button tag
   * @see clientChange
   */
  public static function button($label='button', $htmlOptions=array()) {
    if (!isset($htmlOptions['name']))
      $htmlOptions['name'] = self::ID_PREFIX . self::$count++;
    if (!isset($htmlOptions['type']))
      $htmlOptions['type'] = 'button';
    if (!isset($htmlOptions['value']))
      $htmlOptions['value'] = $label;
    $htmlOptions['live']=false;
    self::clientChange('click', $htmlOptions);
    return self::tag('input', $htmlOptions);
  }

  /**
	 * Generates a push button that can submit the current form in POST method.
	 * @param string the button label
	 * @param mixed the URL for the AJAX request. If empty, it is assumed to be the current URL. See {@link normalizeUrl} for more details.
	 * @param array AJAX options (see {@link ajax})
	 * @param array additional HTML attributes. Besides normal HTML attributes, a few special
	 * attributes are also recognized (see {@link clientChange} and {@link tag} for more details.)
	 * @return string the generated button
	 */
	public static function ajaxSubmitButton($label,$url,$ajaxOptions=array(),$htmlOptions=array())
	{
		$ajaxOptions['type']='POST';
    $htmlOptions['live']=false;
		return self::ajaxButton($label,$url,$ajaxOptions,$htmlOptions);
	}

  /**
   * Generates a link that can initiate AJAX requests.
   * @param string the link body (it will NOT be HTML-encoded.)
   * @param mixed the URL for the AJAX request. If empty, it is assumed to be the current URL. See {@link normalizeUrl} for more details.
   * @param array AJAX options (see {@link ajax})
   * @param array additional HTML attributes. Besides normal HTML attributes, a few special
   * attributes are also recognized (see {@link clientChange} and {@link tag} for more details.)
   * @return string the generated link
   * @see normalizeUrl
   * @see ajax
   */
  public static function ajaxLink($text, $url, $ajaxOptions=array(), $htmlOptions=array()) {
    if (isset($url['id'])) {
      $url['id'] = urlencode($url['id']);
    }
    if (!isset($htmlOptions['href']))
      $htmlOptions['href'] = '#';
    $ajaxOptions['url'] = $url;
    $htmlOptions['ajax'] = $ajaxOptions;
    $htmlOptions['live']=false;
    self::clientChange('click', $htmlOptions);
    return self::tag('a', $htmlOptions, $text);
  }

  /**
   * Generates a push button that can initiate AJAX requests.
   * @param string the button label
   * @param mixed the URL for the AJAX request. If empty, it is assumed to be the current URL. See {@link normalizeUrl} for more details.
   * @param array AJAX options (see {@link ajax})
   * @param array additional HTML attributes. Besides normal HTML attributes, a few special
   * attributes are also recognized (see {@link clientChange} and {@link tag} for more details.)
   * @return string the generated button
   */
  public static function ajaxButton($label, $url, $ajaxOptions=array(), $htmlOptions=array()) {
    $ajaxOptions['url'] = $url;
    $htmlOptions['ajax'] = $ajaxOptions;
    $htmlOptions['live']=false;
    return self::button($label, $htmlOptions);
  }

  /**
	 * Generates the JavaScript with the specified client changes.
	 * @param string event name (without 'on')
	 * @param array HTML attributes which may contain the following special attributes
	 * specifying the client change behaviors:
	 * <ul>
	 * <li>submit: string, specifies the URL that the button should submit to. If empty, the current requested URL will be used.</li>
	 * <li>params: array, name-value pairs that should be submitted together with the form. This is only used when 'submit' option is specified.</li>
	 * <li>csrf: boolean, whether a CSRF token should be submitted when {@link CHttpRequest::enableCsrfValidation} is true. Defaults to false.
	 * This option has been available since version 1.0.7. You may want to set this to be true if there is no enclosing
	 * form around this element. This option is meaningful only when 'submit' option is set.</li>
	 * <li>return: boolean, the return value of the javascript. Defaults to false, meaning that the execution of
	 * javascript would not cause the default behavior of the event. This option has been available since version 1.0.2.</li>
	 * <li>confirm: string, specifies the message that should show in a pop-up confirmation dialog.</li>
	 * <li>ajax: array, specifies the AJAX options (see {@link ajax}).</li>
	 * </ul>
	 * @param boolean whether the event should be "live" (a jquery event concept). Defaults to true.
	 * This parameter has been available since version 1.1.1.
	 */
	protected static function clientChange($event,&$htmlOptions){
    $htmlOptions['live']=false;
    parent::clientChange($event, $htmlOptions);
  }

}
?>
