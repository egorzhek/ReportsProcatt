DECLARE @Year Int, @YearStr nvarchar(max)

set @Year = 1999

while @Year <= 2040
begin
SET @YearStr = '-- Добавляем файловую группу так
ALTER DATABASE [CacheDB]
ADD FILEGROUP YearFG_' + cast(@Year as nvarchar(max)) + ';
GO
ALTER DATABASE [CacheDB]
ADD FILE   
(  
    NAME = YearFG_' + cast(@Year as nvarchar(max)) + ',
    FILENAME = ''C:\Work\tmp\YearFG_' + cast(@Year as nvarchar(max)) + '.ndf'',
    SIZE = 50MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 10%
)  
TO FILEGROUP YearFG_' + cast(@Year as nvarchar(max)) + ';
GO
'
	print @YearStr
	
	set @Year += 1;
end