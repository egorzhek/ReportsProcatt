CREATE TABLE [dbo].[Assets_Strategy]
(
	[strategyguid] [uniqueidentifier] NOT NULL,
	[strategy] [nvarchar](200) NOT NULL,
CONSTRAINT [PK_Assets_Strategy] PRIMARY KEY CLUSTERED
(
	[strategyguid] ASC
) ON [PRIMARY]
) ON [PRIMARY]
GO
CREATE TABLE [dbo].[RefreshAssetsLog]
(
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[JSONText] [nvarchar](max) NULL,
	[RecordDate] [datetime] NULL,
	[Error] [nvarchar](max) NULL,
CONSTRAINT [PK_RefreshAssetsLog] PRIMARY KEY CLUSTERED
(
	[Id] ASC
) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[RefreshAssetsLog] ADD
CONSTRAINT [DF_RefreshAssetsLog_RecordDate]
DEFAULT (getdate()) FOR [RecordDate]
GO
CREATE OR ALTER PROCEDURE [dbo].[app_RefreshAssets]
(
	@JSON NVarchar(max)
)
as begin
	set nocount on;

	declare @Error nvarchar(max);

	begin try
		drop table if exists #JsonAssets;

		create table #JsonAssets
		(
			num nvarchar(200) NULL,
			strategy nvarchar(200) NULL,
			strategyguid uniqueidentifier
		);

		insert into #JsonAssets(num, strategy, strategyguid)
		select num, strategy, strategyguid
		FROM OPENJSON(@JSON)
		WITH (
			num nvarchar(200) '$.num',
			strategy nvarchar(200) '$.strategy',
			strategyguid uniqueidentifier '$.strategyguid'
		);

		-- залить новые стратегии
		insert into dbo.Assets_Strategy (strategy, strategyguid)
		select
			a.strategy, a.strategyguid
		from
		(
			select
				strategy, strategyguid
			from #JsonAssets
			group by
				strategy, strategyguid
		) as a
		left join dbo.Assets_Strategy as b on a.strategyguid = b.strategyguid
		where b.strategyguid is null;

		update b set
			strategyguid = a.strategyguid, laststrategyupdate = GETDATE()
		from #JsonAssets as a
		join dbo.Assets_Info as b on a.num = b.NUM;
	end try
	begin catch
		set @Error = ERROR_MESSAGE();

		insert into dbo.RefreshAssetsLog (JSONText, Error)
		values (@JSON, @Error);
	end catch
end
GO