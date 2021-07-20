USE [CacheDB]
GO
-- создаём функцию секционирования
GO
CREATE PARTITION FUNCTION [YEAR_Partition_Function_Time](DateTime) AS 
RANGE RIGHT FOR VALUES 
(
	N'2000-01-01',
	N'2001-01-01',
	N'2002-01-01',
	N'2003-01-01',
	N'2004-01-01',
	N'2005-01-01',
	N'2006-01-01',
	N'2007-01-01',
	N'2008-01-01',
	N'2009-01-01',

	N'2010-01-01',
	N'2011-01-01',
	N'2012-01-01',
	N'2013-01-01',
	N'2014-01-01',
	N'2015-01-01',
	N'2016-01-01',
	N'2017-01-01',
	N'2018-01-01',
	N'2019-01-01',

	N'2020-01-01',
	N'2021-01-01',
	N'2022-01-01',
	N'2023-01-01',
	N'2024-01-01',
	N'2025-01-01',
	N'2026-01-01',
	N'2027-01-01',
	N'2028-01-01',
	N'2029-01-01',

	N'2030-01-01',
	N'2031-01-01',
	N'2032-01-01',
	N'2033-01-01',
	N'2034-01-01',
	N'2035-01-01',
	N'2036-01-01',
	N'2037-01-01',
	N'2038-01-01',
	N'2039-01-01',
	N'2040-01-01'
)
GO
-- создаём схему секционирования
GO
CREATE PARTITION SCHEME [YEAR_Partition_Scheme_Time]
    AS PARTITION YEAR_Partition_Function_Time
    TO
	(
		YearFG_1999,
		YearFG_2000,
		YearFG_2001,
		YearFG_2002,
		YearFG_2003,
		YearFG_2004,
		YearFG_2005,
		YearFG_2006,
		YearFG_2007,
		YearFG_2008,
		YearFG_2009,

		YearFG_2010,
		YearFG_2011,
		YearFG_2012,
		YearFG_2013,
		YearFG_2014,
		YearFG_2015,
		YearFG_2016,
		YearFG_2017,
		YearFG_2018,
		YearFG_2019,

		YearFG_2020,
		YearFG_2021,
		YearFG_2022,
		YearFG_2023,
		YearFG_2024,
		YearFG_2025,
		YearFG_2026,
		YearFG_2027,
		YearFG_2028,
		YearFG_2029,

		YearFG_2030,
		YearFG_2031,
		YearFG_2032,
		YearFG_2033,
		YearFG_2034,
		YearFG_2035,
		YearFG_2036,
		YearFG_2037,
		YearFG_2038,
		YearFG_2039,
		YearFG_2040
	) ;  
GO

--DROP PARTITION SCHEME [YEAR_Partition_Scheme_Time]
--DROP PARTITION FUNCTION [YEAR_Partition_Function_Time]