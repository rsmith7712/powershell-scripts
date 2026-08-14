   C:
   IF NOT EXIST C:\Program Files\Epicor\CRS Merchandising\Allocation\%username% GOTO NOWINDIR
   IF Exist C:\Program Files\Epicor\CRS Merchandising\Allocation\%username% GOTO WINDIREXIST
   
   CD \WIN
   
   
   :NOWINDIR
   Mkdir "C:\Program Files\Epicor\CRS Merchandising\Allocation\%username%"
   copy "C:\Program Files\Epicor\CRS Merchandising\Allocation\Allocation.ini" "C:\Program Files\Epicor\CRS Merchandising\Allocation\%username%\Allocation.ini"
   Start"c:\program files\epicor\crs merchandising\Allocation\Allocation.exe"
   
   :WINDIREXIST
   rmdir CP C:\Program Files\Epicor\CRS Merchandising\Allocation\Allocation.ini C:\Program Files\Epicor\CRS Merchandising\Allocation\%username%
   Copy "C:\Program Files\Epicor\CRS Merchandising\Allocation\Allocation.ini" "C:\Program Files\Epicor\CRS Merchandising\Allocation\%username%\Allocation.ini"
   
   Start"c:\program files\epicor\crs merchandising\Allocation\Allocation.exe"
	