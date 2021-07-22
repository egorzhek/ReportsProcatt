DECLARE @ToDateStr     Nvarchar(50) = @DateToSharp;
DECLARE @FromDateStr   Nvarchar(50) = @DateFromSharp;
DECLARE @InvestorIdStr Nvarchar(50) = @ContractIdSharp;

select
	ActiveDateToName = 'Активы на 28.12.2017',
	ActiveDateToValue = 135423743.00,
	ProfitName = 'Доход за период 20.04.2007 - 28.12.2017',
	ProfitValue = 56794533.78,
	ProfitProcentValue = 25.11,
	OpenDate = '20.04.2007',
	LS_NUM = '2940000083',
	EndSumAmount = 75643.89,
	FundName = 'Субъект 17356',
	InvestorName = 'Субъект 16541',
	ContractNumber = '317265/ДУ-ФЛ-2021',
	Fee = 643.89,
	ContractOpenDate = '21.04.2007',
	SuccessFee = 43.89

select ActiveName = 'Активы на 20.04.2007', ActiveValue = 29448888.50, Sort = 1
union
select 'Пополнения', 854000000.00, 2
union
select 'Выводы', 804819679.28, 3
union
select 'Дивиденды', 23456.15, 4
union
select 'Купоны', 13567.25, 5
order by 3

select
Date = cast('2007-04-20' as Date), RATE = 1332.68
union
select cast('2007-04-21' as Date), 1333.00
union
select cast('2007-04-22' as Date), 1334.00
union
select cast('2007-04-23' as Date), 1332.00
union
select cast('2007-04-24' as Date), 1335.00



select ActiveName = 'Всего', ActiveValue = 37023.40, Sort = 1, Color = '#FFFFFF'
union
select 'Дивиденды', 23456.15, 4, '#7FE5F0'
union
select 'Купоны', 13567.25, 5, '#4CA3DD'
order by 3


-- Дивиденты, купоны
select
Date = cast('2007-04-20' as Date), Dividends = 1332.68, Coupons = 50.68
union
select cast('2007-04-21' as Date), 1333.00, 34.00
union
select cast('2007-04-22' as Date), 0.00, 0.00
union
select cast('2007-04-23' as Date), 1332.00, 1220.00
union
select cast('2007-04-24' as Date), 0.00, 500.00
union
select cast('2007-04-25' as Date), 660.00, 0.00
union
select cast('2007-04-26' as Date), 0.00, 0.00
union
select cast('2007-04-27' as Date), 1335.00, 1513.00

-- Детализация купонов и дивидендов

select
[Date] = '20.04.2007', -- Дата выплаты
[ToolName] = 'Сбербанк', -- Инструмент
[PriceType] = 'Дивиденды', -- Тип выплаты
[ContractName] = 'Стратегия ДУ "Агрессивная"', -- Название договора
[Price] = 123.12 -- Cумма в валюте выплаты
union
select
'21.04.2007',
'ВТБ',
'Купоны',
'Стратегия ДУ "Консервативная"',
24.14


select
[Date] = '20.04.2007', -- Дата
[OperName] = 'Покупка', -- Тип операции
[ISIN] = 'RU011',
[ToolName] = 'Сбербанк', -- Инструмент
[Price] = 100.15, -- Цена бумаги
[PaperAmount] = 12.00, -- Количество бумаг
[Valuta] = N'₽', -- Валюта
[Cost] = 123.12, -- Сумма сделки
[Fee] = 12.13, -- Комиссия
[Status] = 'Исполнена' -- Статус
union
select
[Date] = '21.04.2007', 
[OperName] = 'Продажа',
[ISIN] = 'RU012',
[ToolName] = 'ВТБ',
[Price] = 123.12,
[PaperAmount] = 123.00,
[Valuta] = N'₽',
[Cost] = 225.12,
[Fee] = 2.13,
[Status] = 'Исполнена'


-- Дерево - четыре уровня вложенности
-- tree1
select ValutaId = 145, ValutaName = 'Рубли'
--union
--select ValutaId = 148, ValutaName = 'Доллары'

-- tree2
select TypeId = 1, ValutaId = 145, TypeName = 'Денежные средства'
union
select TypeId = 2, ValutaId = 145, TypeName = 'Акции'
union
select TypeId = 3, ValutaId = 145, TypeName = 'Облигации'
--
union
select TypeId = 4, ValutaId = 148, TypeName = 'Денежные средства'
union
select TypeId = 5, ValutaId = 148, TypeName = 'Акции'
union
select TypeId = 6, ValutaId = 148, TypeName = 'Облигации'


-- tree3
select ChildId = 1, TypeId = 1, ChildName = 'Брокерский счёт АО ГПБ', PriceName = N'500 ₽', Ammount = '', Detail = N''
union
select ChildId = 2, TypeId = 1, ChildName = 'Брокерский счёт АО Открытие брокер', PriceName = N'500 ₽', Ammount = '', Detail = N''
union
select ChildId = 3, TypeId = 2, ChildName = 'Сбербанк, ао', PriceName = N'105,45 ₽', Ammount = '1 шт.', Detail = N'+5,43 ₽ (+4,7%)'
union
select ChildId = 4, TypeId = 3, ChildName = 'ОФЗ, 26257', PriceName = N'125,22 ₽', Ammount = '11 шт.', Detail = N'-15,48 ₽ (-11,2%)'

-- tree4
select Child2Id = 1, ChildId = 4, Child2Name = 'ОФЗ, 26257', PriceName = N'125,22 ₽', Ammount = '5 шт.', Detail = N'-15,48 ₽ (-11,2%)'
union
select Child2Id = 2, ChildId = 4, Child2Name = 'ОФЗ, 26257', PriceName = N'125,22 ₽', Ammount = '1 шт.', Detail = N'-15,48 ₽ (-11,2%)'