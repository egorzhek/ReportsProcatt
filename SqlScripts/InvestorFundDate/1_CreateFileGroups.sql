-- Нужно определить физическое местоположение файлов, на каких дисках
USE [CacheDB]
GO
-- Добавляем файловую группу так
ALTER DATABASE [CacheDB]
ADD FILEGROUP YearFG_1999;
GO
ALTER DATABASE [CacheDB]
ADD FILE   
(  
    NAME = YearFG_1999,
    FILENAME = 'C:\Work\tmp\YearFG_1999.ndf',
    SIZE = 50MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 10%
)  
TO FILEGROUP YearFG_1999;
GO
-- Добавляем файловую группу так
ALTER DATABASE [CacheDB]
ADD FILEGROUP YearFG_2000;
GO
ALTER DATABASE [CacheDB]
ADD FILE   
(  
    NAME = YearFG_2000,
    FILENAME = 'C:\Work\tmp\YearFG_2000.ndf',
    SIZE = 50MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 10%
)  
TO FILEGROUP YearFG_2000;
GO
-- Добавляем файловую группу так
ALTER DATABASE [CacheDB]
ADD FILEGROUP YearFG_2001;
GO
ALTER DATABASE [CacheDB]
ADD FILE   
(  
    NAME = YearFG_2001,
    FILENAME = 'C:\Work\tmp\YearFG_2001.ndf',
    SIZE = 50MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 10%
)  
TO FILEGROUP YearFG_2001;
GO
-- Добавляем файловую группу так
ALTER DATABASE [CacheDB]
ADD FILEGROUP YearFG_2002;
GO
ALTER DATABASE [CacheDB]
ADD FILE   
(  
    NAME = YearFG_2002,
    FILENAME = 'C:\Work\tmp\YearFG_2002.ndf',
    SIZE = 50MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 10%
)  
TO FILEGROUP YearFG_2002;
GO
-- Добавляем файловую группу так
ALTER DATABASE [CacheDB]
ADD FILEGROUP YearFG_2003;
GO
ALTER DATABASE [CacheDB]
ADD FILE   
(  
    NAME = YearFG_2003,
    FILENAME = 'C:\Work\tmp\YearFG_2003.ndf',
    SIZE = 50MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 10%
)  
TO FILEGROUP YearFG_2003;
GO
-- Добавляем файловую группу так
ALTER DATABASE [CacheDB]
ADD FILEGROUP YearFG_2004;
GO
ALTER DATABASE [CacheDB]
ADD FILE   
(  
    NAME = YearFG_2004,
    FILENAME = 'C:\Work\tmp\YearFG_2004.ndf',
    SIZE = 50MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 10%
)  
TO FILEGROUP YearFG_2004;
GO
-- Добавляем файловую группу так
ALTER DATABASE [CacheDB]
ADD FILEGROUP YearFG_2005;
GO
ALTER DATABASE [CacheDB]
ADD FILE   
(  
    NAME = YearFG_2005,
    FILENAME = 'C:\Work\tmp\YearFG_2005.ndf',
    SIZE = 50MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 10%
)  
TO FILEGROUP YearFG_2005;
GO
-- Добавляем файловую группу так
ALTER DATABASE [CacheDB]
ADD FILEGROUP YearFG_2006;
GO
ALTER DATABASE [CacheDB]
ADD FILE   
(  
    NAME = YearFG_2006,
    FILENAME = 'C:\Work\tmp\YearFG_2006.ndf',
    SIZE = 50MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 10%
)  
TO FILEGROUP YearFG_2006;
GO
-- Добавляем файловую группу так
ALTER DATABASE [CacheDB]
ADD FILEGROUP YearFG_2007;
GO
ALTER DATABASE [CacheDB]
ADD FILE   
(  
    NAME = YearFG_2007,
    FILENAME = 'C:\Work\tmp\YearFG_2007.ndf',
    SIZE = 50MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 10%
)  
TO FILEGROUP YearFG_2007;
GO
-- Добавляем файловую группу так
ALTER DATABASE [CacheDB]
ADD FILEGROUP YearFG_2008;
GO
ALTER DATABASE [CacheDB]
ADD FILE   
(  
    NAME = YearFG_2008,
    FILENAME = 'C:\Work\tmp\YearFG_2008.ndf',
    SIZE = 50MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 10%
)  
TO FILEGROUP YearFG_2008;
GO
-- Добавляем файловую группу так
ALTER DATABASE [CacheDB]
ADD FILEGROUP YearFG_2009;
GO
ALTER DATABASE [CacheDB]
ADD FILE   
(  
    NAME = YearFG_2009,
    FILENAME = 'C:\Work\tmp\YearFG_2009.ndf',
    SIZE = 50MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 10%
)  
TO FILEGROUP YearFG_2009;
GO
-- Добавляем файловую группу так
ALTER DATABASE [CacheDB]
ADD FILEGROUP YearFG_2010;
GO
ALTER DATABASE [CacheDB]
ADD FILE   
(  
    NAME = YearFG_2010,
    FILENAME = 'C:\Work\tmp\YearFG_2010.ndf',
    SIZE = 50MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 10%
)  
TO FILEGROUP YearFG_2010;
GO
-- Добавляем файловую группу так
ALTER DATABASE [CacheDB]
ADD FILEGROUP YearFG_2011;
GO
ALTER DATABASE [CacheDB]
ADD FILE   
(  
    NAME = YearFG_2011,
    FILENAME = 'C:\Work\tmp\YearFG_2011.ndf',
    SIZE = 50MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 10%
)  
TO FILEGROUP YearFG_2011;
GO
-- Добавляем файловую группу так
ALTER DATABASE [CacheDB]
ADD FILEGROUP YearFG_2012;
GO
ALTER DATABASE [CacheDB]
ADD FILE   
(  
    NAME = YearFG_2012,
    FILENAME = 'C:\Work\tmp\YearFG_2012.ndf',
    SIZE = 50MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 10%
)  
TO FILEGROUP YearFG_2012;
GO
-- Добавляем файловую группу так
ALTER DATABASE [CacheDB]
ADD FILEGROUP YearFG_2013;
GO
ALTER DATABASE [CacheDB]
ADD FILE   
(  
    NAME = YearFG_2013,
    FILENAME = 'C:\Work\tmp\YearFG_2013.ndf',
    SIZE = 50MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 10%
)  
TO FILEGROUP YearFG_2013;
GO
-- Добавляем файловую группу так
ALTER DATABASE [CacheDB]
ADD FILEGROUP YearFG_2014;
GO
ALTER DATABASE [CacheDB]
ADD FILE   
(  
    NAME = YearFG_2014,
    FILENAME = 'C:\Work\tmp\YearFG_2014.ndf',
    SIZE = 50MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 10%
)  
TO FILEGROUP YearFG_2014;
GO
-- Добавляем файловую группу так
ALTER DATABASE [CacheDB]
ADD FILEGROUP YearFG_2015;
GO
ALTER DATABASE [CacheDB]
ADD FILE   
(  
    NAME = YearFG_2015,
    FILENAME = 'C:\Work\tmp\YearFG_2015.ndf',
    SIZE = 50MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 10%
)  
TO FILEGROUP YearFG_2015;
GO
-- Добавляем файловую группу так
ALTER DATABASE [CacheDB]
ADD FILEGROUP YearFG_2016;
GO
ALTER DATABASE [CacheDB]
ADD FILE   
(  
    NAME = YearFG_2016,
    FILENAME = 'C:\Work\tmp\YearFG_2016.ndf',
    SIZE = 50MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 10%
)  
TO FILEGROUP YearFG_2016;
GO
-- Добавляем файловую группу так
ALTER DATABASE [CacheDB]
ADD FILEGROUP YearFG_2017;
GO
ALTER DATABASE [CacheDB]
ADD FILE   
(  
    NAME = YearFG_2017,
    FILENAME = 'C:\Work\tmp\YearFG_2017.ndf',
    SIZE = 50MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 10%
)  
TO FILEGROUP YearFG_2017;
GO
-- Добавляем файловую группу так
ALTER DATABASE [CacheDB]
ADD FILEGROUP YearFG_2018;
GO
ALTER DATABASE [CacheDB]
ADD FILE   
(  
    NAME = YearFG_2018,
    FILENAME = 'C:\Work\tmp\YearFG_2018.ndf',
    SIZE = 50MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 10%
)  
TO FILEGROUP YearFG_2018;
GO
-- Добавляем файловую группу так
ALTER DATABASE [CacheDB]
ADD FILEGROUP YearFG_2019;
GO
ALTER DATABASE [CacheDB]
ADD FILE   
(  
    NAME = YearFG_2019,
    FILENAME = 'C:\Work\tmp\YearFG_2019.ndf',
    SIZE = 50MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 10%
)  
TO FILEGROUP YearFG_2019;
GO
-- Добавляем файловую группу так
ALTER DATABASE [CacheDB]
ADD FILEGROUP YearFG_2020;
GO
ALTER DATABASE [CacheDB]
ADD FILE   
(  
    NAME = YearFG_2020,
    FILENAME = 'C:\Work\tmp\YearFG_2020.ndf',
    SIZE = 50MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 10%
)  
TO FILEGROUP YearFG_2020;
GO
-- Добавляем файловую группу так
ALTER DATABASE [CacheDB]
ADD FILEGROUP YearFG_2021;
GO
ALTER DATABASE [CacheDB]
ADD FILE   
(  
    NAME = YearFG_2021,
    FILENAME = 'C:\Work\tmp\YearFG_2021.ndf',
    SIZE = 50MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 10%
)  
TO FILEGROUP YearFG_2021;
GO
-- Добавляем файловую группу так
ALTER DATABASE [CacheDB]
ADD FILEGROUP YearFG_2022;
GO
ALTER DATABASE [CacheDB]
ADD FILE   
(  
    NAME = YearFG_2022,
    FILENAME = 'C:\Work\tmp\YearFG_2022.ndf',
    SIZE = 50MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 10%
)  
TO FILEGROUP YearFG_2022;
GO
-- Добавляем файловую группу так
ALTER DATABASE [CacheDB]
ADD FILEGROUP YearFG_2023;
GO
ALTER DATABASE [CacheDB]
ADD FILE   
(  
    NAME = YearFG_2023,
    FILENAME = 'C:\Work\tmp\YearFG_2023.ndf',
    SIZE = 50MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 10%
)  
TO FILEGROUP YearFG_2023;
GO
-- Добавляем файловую группу так
ALTER DATABASE [CacheDB]
ADD FILEGROUP YearFG_2024;
GO
ALTER DATABASE [CacheDB]
ADD FILE   
(  
    NAME = YearFG_2024,
    FILENAME = 'C:\Work\tmp\YearFG_2024.ndf',
    SIZE = 50MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 10%
)  
TO FILEGROUP YearFG_2024;
GO
-- Добавляем файловую группу так
ALTER DATABASE [CacheDB]
ADD FILEGROUP YearFG_2025;
GO
ALTER DATABASE [CacheDB]
ADD FILE   
(  
    NAME = YearFG_2025,
    FILENAME = 'C:\Work\tmp\YearFG_2025.ndf',
    SIZE = 50MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 10%
)  
TO FILEGROUP YearFG_2025;
GO
-- Добавляем файловую группу так
ALTER DATABASE [CacheDB]
ADD FILEGROUP YearFG_2026;
GO
ALTER DATABASE [CacheDB]
ADD FILE   
(  
    NAME = YearFG_2026,
    FILENAME = 'C:\Work\tmp\YearFG_2026.ndf',
    SIZE = 50MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 10%
)  
TO FILEGROUP YearFG_2026;
GO
-- Добавляем файловую группу так
ALTER DATABASE [CacheDB]
ADD FILEGROUP YearFG_2027;
GO
ALTER DATABASE [CacheDB]
ADD FILE   
(  
    NAME = YearFG_2027,
    FILENAME = 'C:\Work\tmp\YearFG_2027.ndf',
    SIZE = 50MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 10%
)  
TO FILEGROUP YearFG_2027;
GO
-- Добавляем файловую группу так
ALTER DATABASE [CacheDB]
ADD FILEGROUP YearFG_2028;
GO
ALTER DATABASE [CacheDB]
ADD FILE   
(  
    NAME = YearFG_2028,
    FILENAME = 'C:\Work\tmp\YearFG_2028.ndf',
    SIZE = 50MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 10%
)  
TO FILEGROUP YearFG_2028;
GO
-- Добавляем файловую группу так
ALTER DATABASE [CacheDB]
ADD FILEGROUP YearFG_2029;
GO
ALTER DATABASE [CacheDB]
ADD FILE   
(  
    NAME = YearFG_2029,
    FILENAME = 'C:\Work\tmp\YearFG_2029.ndf',
    SIZE = 50MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 10%
)  
TO FILEGROUP YearFG_2029;
GO
-- Добавляем файловую группу так
ALTER DATABASE [CacheDB]
ADD FILEGROUP YearFG_2030;
GO
ALTER DATABASE [CacheDB]
ADD FILE   
(  
    NAME = YearFG_2030,
    FILENAME = 'C:\Work\tmp\YearFG_2030.ndf',
    SIZE = 50MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 10%
)  
TO FILEGROUP YearFG_2030;
GO
-- Добавляем файловую группу так
ALTER DATABASE [CacheDB]
ADD FILEGROUP YearFG_2031;
GO
ALTER DATABASE [CacheDB]
ADD FILE   
(  
    NAME = YearFG_2031,
    FILENAME = 'C:\Work\tmp\YearFG_2031.ndf',
    SIZE = 50MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 10%
)  
TO FILEGROUP YearFG_2031;
GO
-- Добавляем файловую группу так
ALTER DATABASE [CacheDB]
ADD FILEGROUP YearFG_2032;
GO
ALTER DATABASE [CacheDB]
ADD FILE   
(  
    NAME = YearFG_2032,
    FILENAME = 'C:\Work\tmp\YearFG_2032.ndf',
    SIZE = 50MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 10%
)  
TO FILEGROUP YearFG_2032;
GO
-- Добавляем файловую группу так
ALTER DATABASE [CacheDB]
ADD FILEGROUP YearFG_2033;
GO
ALTER DATABASE [CacheDB]
ADD FILE   
(  
    NAME = YearFG_2033,
    FILENAME = 'C:\Work\tmp\YearFG_2033.ndf',
    SIZE = 50MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 10%
)  
TO FILEGROUP YearFG_2033;
GO
-- Добавляем файловую группу так
ALTER DATABASE [CacheDB]
ADD FILEGROUP YearFG_2034;
GO
ALTER DATABASE [CacheDB]
ADD FILE   
(  
    NAME = YearFG_2034,
    FILENAME = 'C:\Work\tmp\YearFG_2034.ndf',
    SIZE = 50MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 10%
)  
TO FILEGROUP YearFG_2034;
GO
-- Добавляем файловую группу так
ALTER DATABASE [CacheDB]
ADD FILEGROUP YearFG_2035;
GO
ALTER DATABASE [CacheDB]
ADD FILE   
(  
    NAME = YearFG_2035,
    FILENAME = 'C:\Work\tmp\YearFG_2035.ndf',
    SIZE = 50MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 10%
)  
TO FILEGROUP YearFG_2035;
GO
-- Добавляем файловую группу так
ALTER DATABASE [CacheDB]
ADD FILEGROUP YearFG_2036;
GO
ALTER DATABASE [CacheDB]
ADD FILE   
(  
    NAME = YearFG_2036,
    FILENAME = 'C:\Work\tmp\YearFG_2036.ndf',
    SIZE = 50MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 10%
)  
TO FILEGROUP YearFG_2036;
GO
-- Добавляем файловую группу так
ALTER DATABASE [CacheDB]
ADD FILEGROUP YearFG_2037;
GO
ALTER DATABASE [CacheDB]
ADD FILE   
(  
    NAME = YearFG_2037,
    FILENAME = 'C:\Work\tmp\YearFG_2037.ndf',
    SIZE = 50MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 10%
)  
TO FILEGROUP YearFG_2037;
GO
-- Добавляем файловую группу так
ALTER DATABASE [CacheDB]
ADD FILEGROUP YearFG_2038;
GO
ALTER DATABASE [CacheDB]
ADD FILE   
(  
    NAME = YearFG_2038,
    FILENAME = 'C:\Work\tmp\YearFG_2038.ndf',
    SIZE = 50MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 10%
)  
TO FILEGROUP YearFG_2038;
GO
-- Добавляем файловую группу так
ALTER DATABASE [CacheDB]
ADD FILEGROUP YearFG_2039;
GO
ALTER DATABASE [CacheDB]
ADD FILE   
(  
    NAME = YearFG_2039,
    FILENAME = 'C:\Work\tmp\YearFG_2039.ndf',
    SIZE = 50MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 10%
)  
TO FILEGROUP YearFG_2039;
GO
-- Добавляем файловую группу так
ALTER DATABASE [CacheDB]
ADD FILEGROUP YearFG_2040;
GO
ALTER DATABASE [CacheDB]
ADD FILE   
(  
    NAME = YearFG_2040,
    FILENAME = 'C:\Work\tmp\YearFG_2040.ndf',
    SIZE = 50MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 10%
)  
TO FILEGROUP YearFG_2040;
GO