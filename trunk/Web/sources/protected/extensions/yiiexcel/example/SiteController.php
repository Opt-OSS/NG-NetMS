<?php

class SiteController extends Controller{

    public function actionExcel(){
        $objPHPExcel = new PHPExcel();

        // Set document properties
        $objPHPExcel->getProperties()->setCreator("K'iin Balam")
             ->setLastModifiedBy("K'iin Balam")
             ->setTitle("YiiExcel Test Document")
             ->setSubject("YiiExcel Test Document")
             ->setDescription("Test document for YiiExcel, generated using PHP classes.")
             ->setKeywords("office PHPExcel php YiiExcel UPNFM")
             ->setCategory("Test result file");        
        
        // Add some data
        $objPHPExcel->setActiveSheetIndex(0)
            ->setCellValue('A1', 'Hello')
            ->setCellValue('B2', 'world!')
            ->setCellValue('C1', 'Hello')
            ->setCellValue('D2', 'world!');
        
        // Miscellaneous glyphs, UTF-8
        $objPHPExcel->setActiveSheetIndex(0)
            ->setCellValue('A4', 'Miscellaneous glyphs')
            ->setCellValue('A5', 'éàèùâêîôûëïüÿäöüç');
        
        // Rename worksheet
        $objPHPExcel->getActiveSheet()->setTitle('YiiExcel');
        
        // Set active sheet index to the first sheet, so Excel opens this as the first sheet
        $objPHPExcel->setActiveSheetIndex(0);
        
        // Save a xls file
        $filename = 'YiiExcel';
        header('Content-Type: application/vnd.ms-excel');
        header('Content-Disposition: attachment;filename="'.$filename.'.xls"');
        header('Cache-Control: max-age=0');
        
        $objWriter = PHPExcel_IOFactory::createWriter($objPHPExcel, 'Excel5');

        $objWriter->save('php://output');
        unset($this->objWriter);
        unset($this->objWorksheet);
        unset($this->objReader);
        unset($this->objPHPExcel);
        exit();
    }//fin del método actionExcel
}
