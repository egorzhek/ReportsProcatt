USE [CacheDB]
GO
CREATE TABLE [dbo].[WalkTypes]
(
	[WALK] [int] NOT NULL,
	[TYPE] [smallint] NOT NULL,
	[OperName] [nvarchar](255) NOT NULL,
CONSTRAINT [PK_WalkTypes] PRIMARY KEY CLUSTERED
(
	[WALK] ASC,
	[TYPE] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
INSERT INTO [dbo].[WalkTypes] ( [WALK], [TYPE], [OperName])
VALUES
(98, 1, 'Обмен паев (Покупка)'),
(98, -1, 'Обмен паев (Продажа)'),
(107, 1, 'Покупка паев'),
(198, 1, 'Ввод паев'),
(199, -1, 'Вывод паев'),
(205, -1, 'Продажа паев');
GO
-- SELECT * FROM [dbo].[WalkTypes]