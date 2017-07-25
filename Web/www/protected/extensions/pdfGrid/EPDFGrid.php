<?php
/**
 * EPDF
 * Extensi�n para generar archivos PDF con el framework YII
 * @version 0.4.1
 * @autor norotaro
 */

Yii::import('zii.widgets.grid.CDataColumn');
Yii::import('ext.pdfGrid.fpdf.PDF');

class EPDFGrid extends CWidget
{
	private $_debug = false;

	protected $_pdf;
	protected $_fill = false;
	protected $_columnWidths = array();
	protected $_visibleColumns = 0;
	
	public $dataProvider;
	public $fileName;
	public $config=array();
	public $columns=array();
	/**
	 * @var boolean whether to display the table even when there is no data. Defaults to true.
	 * The {@link emptyText} will be displayed to indicate there is no data.
	 */
	public $showTableOnEmpty=true;
	/**
	 * @var string the text to be displayed in a data cell when a data value is null.
	 * This property will NOT be HTML-encoded when rendering. Defaults to an HTML blank.
	 */
	public $nullDisplay=' ';
	
	/**
	 * @var string the message to be displayed when {@link dataProvider} does not have any data.
	 */
	public $emptyText;
	/**
	 * @var boolean whether to hide the header cells of the grid. When this is true, header cells
	 * will not be rendered. Defaults to false.
	 */
	public $hideHeader=false;

	/**
	 * Creates column objects and initializes them.
	 */
	public function init()
	{
		if($this->columns===array())
		{
			if($this->dataProvider instanceof CActiveDataProvider)
				$this->columns=$this->dataProvider->model->attributeNames();
			else if($this->dataProvider instanceof IDataProvider)
			{
				// use the keys of the first row of data as the default columns
				$data=$this->dataProvider->getData();
				if(isset($data[0]) && is_array($data[0]))
					$this->columns=array_keys($data[0]);
			}
		}
		$id=$this->getId();
		foreach($this->columns as $i=>$column)
		{
			if(is_string($column))
				$column=$this->createDataColumn($column);
			else
			{
				if(!isset($column['class']))
					$column['class']='CDataColumn';
				$column=Yii::createComponent($column, $this);
			}
			if(!$column->visible)
			{
				unset($this->columns[$i]);
				continue;
			}
			$this->_visibleColumns++;
			if($column->id===null)
				$column->id=$id.'_c'.$i;
			$this->columns[$i]=$column;
		}
		
		$default = array(
			'pdfSize'		=> 'A4',
			'title'			=> '',
			'subTitle'		=> '',
			'tableWidth'	=> 275,
			'rowHeight'		=> 6,
			'colAligns'		=> null,
			'colWidths'		=> null,
                        'showBackground'        => false,
			'showLogo'		=> false,
			'imagePath'		=> YiiBase::getPathOfAlias('webroot').'/images/logo.jpg',
                        'imagePath'		=> YiiBase::getPathOfAlias('webroot').'/images/background.jpg',
			'headerDetails'	=> false,
		);

		$this->config = array_merge($default, $this->config);
		
		$this->_pdf = new PDF('L', 'mm', $this->config['pdfSize']);
		$this->_pdf->title = $this->config['title'];
		$this->_pdf->subTitle = $this->config['subTitle'];
		$this->_pdf->tableWidth = $this->config['tableWidth'];
		$this->_pdf->rowHeight = $this->config['rowHeight'];
		$this->_pdf->imagePath = $this->config['imagePath'];
                $this->_pdf->imageBackground = $this->config['imageBackground'];
                $this->_pdf->showBackground = $this->config['showBackground'];
		$this->_pdf->showLogo = $this->config['showLogo'];
		$this->_pdf->headerDetails = $this->config['headerDetails'];
		$this->_pdf->SetAligns($this->config['colAligns']);
		$this->_pdf->SetFont('Arial','B',10);
		$this->_pdf->SetLineWidth(0.5);
		$this->_columnWidths = $this->_calcWidths();
		$this->_pdf->SetWidths($this->_columnWidths);
		$this->_pdf->AliasNbPages();
		$this->_pdf->AddPage();

		foreach($this->columns as $column)
			$column->init();
			
		$this->renderItems();
	}

	/**
	 * Creates a {@link CDataColumn} based on a shortcut column specification string.
	 * @param string $text the column specification string
	 * @return CDataColumn the column instance
	 */
	protected function createDataColumn($text)
	{
		if(!preg_match('/^([\w\.]+)(:(\w*))?(:(.*))?$/',$text,$matches))
			throw new CException(Yii::t('zii',
				'The column must be specified in the format of "Name:Type:Label",
				where "Type" and "Label" are optional.'));
		$column=new CDataColumn($this);
		$column->name=$matches[1];
		if(isset($matches[3]) && $matches[3]!=='')
			$column->type=$matches[3];
		if(isset($matches[5]))
			$column->header=$matches[5];
		return $column;
	}

	/**
	 * Renders the data items for the grid view.
	 */
	protected function renderItems()
	{
		if($this->dataProvider->getItemCount()>0 || $this->showTableOnEmpty) {
			$this->renderTableHeader();
			$this->renderTableBody();
		} else
			$this->_renderEmptyText();
		
		if($this->_debug)
			Yii::app()->end();
		else {
			$this->_pdf->Output($this->fileName.' ('.date('Y-m-d').').pdf','D');
			exit();
		}
	}

	/**
	 * Renders the table header.
	 */
	protected function renderTableHeader()
	{
		if(!$this->hideHeader)
		{
			// Colores y fuente en negrita
			$this->_pdf->SetFillColor(105, 168, 205);
			$this->_pdf->SetTextColor(255);
			$this->_pdf->SetBold();

			$rowHeader = array();
			
			foreach($this->columns as $i=>$column) {
                            if(isset($column->header))
                                    $rowHeader[] = $column->header;
                            else
                                    $rowHeader[] = $column->grid->dataProvider->model->getAttributeLabel($column->name);
                                    
				//$this->_pdf->Cell($this->_columnWidths[$i],$this->headerHeight,$data,0,0,'C',true);
			}
			$this->_pdf->Row($rowHeader, array('fill'=>true, 'header'=>true));
		}
	}
	
	/**
	 * Renders the table body.
	 */
	protected function renderTableBody()
	{
		$data=$this->dataProvider->getData();
		$n=count($data);
		
		// Restauraci�n de colores y fuentes
		$this->_pdf->SetFillColor(229, 241, 244);
		$this->_pdf->SetTextColor(0);
		$this->_pdf->SetFont('');

		if($n>0)
		{
			for($row=0;$row<$n;++$row)
				$this->renderTableRow($row);
		}
		else
			$this->_renderEmptyText();
	}

	/**
	 * Renders a table body row.
	 * @param integer $row the row number (zero-based).
	 */
	protected function renderTableRow($row)
	{
		$rowData = array();
		foreach($this->columns as $i=>$column) {
			$data=$this->dataProvider->data[$row];
			
			if($column->value!==null)
				$value=$column->evaluateExpression($column->value,array('data'=>$data,'row'=>$row));
			else if($column->name!==null)
				$value=CHtml::value($data,$column->name);
				
			$rowData[] = $value===null ? $this->nullDisplay : $this->_formatString($value);
		}
		$this->_pdf->Row($rowData, array('fill'=>$this->_fill));
		$this->_fill = !$this->_fill;
	}
	
	/**
	 * Renders the empty message when there is no data.
	 */
	protected function _renderEmptyText()
	{
		$emptyText=$this->emptyText===null ? Yii::t('zii','No results found.') : $this->emptyText;
		$this->_pdf->Cell(array_sum($this->_columnWidths),$this->config['rowHeight'],$emptyText,0,0,'L');
	}
	
	protected function _calcWidths()
	{
		$widths = array();
		$params = $this->config['colWidths'];
		$visibleCols = $this->_visibleColumns;
		
		if(!$params) {
		
			$w = $this->_pdf->tableWidth/$visibleCols;
			for($i = 0; $i<$visibleCols; $i++)
				$widths[] = $w;
				
		} else if(is_array($params)){
			
			//verificar que la cantidad de los parametros no supere a la cantidad de columnas visibles
			if(count($params) > $visibleCols)
				throw new Exception('La cantidad de parametros supera a las columnas visibles');
			//verificar que la suma de los parametros no supere a la longitud max de la tabla
			if(array_sum($params) > $this->_pdf->tableWidth)
				throw new Exception('La suma de los parametros supera a la longitud max de la tabla');
			
			$nulls = 0; //cantidad de columnas que no se configuraron
			$confWidth = 0; //longitud total de las columnas que se configur�
			for($i = 0; $i<$visibleCols; $i++) {
				if(empty($params[$i]))
					$nulls++;
				else
					$confWidth += $params[$i];
			}
			
			//establecer la longitud de las columnas que no fueron configuradas
			$w = $nulls ? ($this->_pdf->tableWidth - $confWidth) / $nulls : 0;
			
			//establecer la longitud de cada columna
			for($i = 0; $i<$visibleCols; $i++) {
				$widths[] = empty($params[$i]) ? $w : $params[$i];
			}
			
		} else
			throw new Exception('El parametro $config[widths] debe ser un array');
		
		return $widths;
	}
	
	protected function _formatString($string)
	{
		$string = strtolower(utf8_decode($string));
		return ucwords($string);
	}
	
	/**
	 * Combina columnas e imprime un texto
	 * @param string $print Texto a imprimir
	 * @param mixed $config Permite las siguientes configuraciones:
	 * 		from: Nro de columna (cero based) desde la cual se est� imprimiendo, default: 0
	 * 		to: Nro de columna (cero based) hasta la cual se imprimir�, default: �ltima columna
	 * 		border: Imprimir bordes, default: 0
	 * 		align: Alineaci�n del texto, default: 'L'
	 * 		fill: Imprimir relleno, default: $this->_fill
	 * 		ln: parametro ln para fpdf::Cell(), default: 1
	 */
	protected function _combineColumns($print='',$config=array())
	{
		$default = array(
			'from'		=> 0,
			'to'		=> $this->_visibleColumns-1,
			'border'	=> 0,
			'align'		=> 'L',
			'fill'		=> $this->_fill,
			'ln'		=> 1,
		);

		$config = array_merge($default, $config);
		
		$b  = $this->$config['border'];
		$a  = $this->$config['align'];
		$f  = $this->$config['fill'];
		$ln = $this->$config['ln'];
		
		$w = 0;
		for($i=$this->$config['from']; $i<=$this->$config['to']; $i++) {
			$w += $this->_columnWidths[$i];
		}
		
		$this->_pdf->Cell($w,$this->config['rowHeight'],$print,$b,$ln,$a,$f);
		if($f) $this->_fill = !$this->_fill;
	}
}