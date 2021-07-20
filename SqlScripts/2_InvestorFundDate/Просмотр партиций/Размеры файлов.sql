USE [CacheDB]
GO
SELECT fg.data_space_id AS FGID,
   (f.file_id) AS File_Id,
   -- As provided by OP, size on disk in bytes.
   CAST(f.size AS FLOAT) * 8.00 * 1024 AS Size_On_Disk_Bytes,
   ROUND((CAST(f.size AS FLOAT) * 8.00/1024)/1024,3) AS Actual_File_Size,
   ROUND(CAST((f.size) AS FLOAT)/128,2) AS Reserved_MB,
   ROUND(CAST((FILEPROPERTY(f.name,'SpaceUsed')) AS FLOAT)/128,2) AS Used_MB,
   ROUND((CAST((f.size) AS FLOAT)/128)-(CAST((FILEPROPERTY(f.name,'SpaceUsed'))AS FLOAT)/128),2) AS Free_MB,
   f.name,
   f.physical_name
FROM sys.database_files f 
    LEFT JOIN sys.filegroups fg
    ON f.data_space_id = fg.data_space_id