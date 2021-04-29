CREATE TABLE dbo.TempLogDeleteOrders(
	Id UNIQUEIDENTIFIER NOT NULL
	,CreatedOn DATETIME2(6) NOT NULL
	,SessionId UNIQUEIDENTIFIER NULL
	,ProcName NVARCHAR(100) NOT NULL
	,LogIdentity UNIQUEIDENTIFIER NULL
	,Step VARCHAR(10) NOT NULL
	,DataIn NVARCHAR(2000) NULL
	,DataOut NVARCHAR(2000) NULL
)
GO

--start loggin in <procedure_name1>
-- @sessionid - input parameter
---<TempLogDeleteOrders>---
DECLARE @logIdentity UNIQUEIDENTIFIER=NEWID();
INSERT INTO TempLogDeleteOrders VALUES
	(NEWID(),GETDATE(),@sessionid,'<procedure_name1>',@logIdentity,'1',NULL,NULL);
---</TempLogDeleteOrders>---

---- any code

---<TempLogDeleteOrders>---
DECLARE @datain NVARCHAR(2000) = CONCAT('{"@param1":"',@param1,'","@param2":"',@param2,'"}');
INSERT INTO TempLogDeleteOrders VALUES
	(NEWID(),GETDATE(),@sessionid,'<procedure_name1>',@logIdentity,'2',@datain,NULL);
---</TempLogDeleteOrders>---

	EXEC <procedure_name2> @param1, @param2, @message OUT, @logIdentity;

---<TempLogDeleteOrders>---
INSERT INTO TempLogDeleteOrders VALUES
	(NEWID(),GETDATE(),@sessionid,'<procedure_name1>',@logIdentity,'3',NULL,@message);
---</TempLogDeleteOrders>---


-----------------code in <procedure_name2>
-- @logIdentity - input parameter, default value='00000000-0000-0000-0000-000000000000'

---<TempLogDeleteOrders>---
DECLARE @data NVARCHAR(2000) = CONCAT('{"@param1":"',@param1,'","@param2":"',@param2,'",...}');
INSERT INTO TempLogDeleteOrders VALUES
	(NEWID(),GETDATE(),NULL,'<procedure_name2>',@logIdentity,'1',@data,NULL);
---</TempLogDeleteOrders>---

---- any code

---<TempLogDeleteOrders>---
SET @data = CONCAT('{"@responseStatus":"',@responseStatus,'","@responseStatusText":"',@responseStatusText,'","@responseBody":"',@responseBody,'"}');
INSERT INTO TempLogDeleteOrders VALUES
	(NEWID(),GETDATE(),NULL,'<procedure_name2>',@logIdentity,'2',NULL,@data);
---</TempLogDeleteOrders>---



--SELECT * INTO #d1
--	FROM [TempLogDeleteOrders]
--	WHERE ProcName='<procedure_name1>'
--		AND CreatedOn BETWEEN '2021-04-21 12:48:00.0' AND '2021-04-21 13:05:00.0'
--		AND Step=1;
SELECT * INTO #d2
	FROM [TempLogDeleteOrders]
	WHERE ProcName='<procedure_name2>'
		--AND CreatedOn BETWEEN '2021-04-21 12:48:00.0' AND '2021-04-21 13:05:00.0'
		AND Step=2;
SELECT * INTO #d3
	FROM [TempLogDeleteOrders]
	WHERE ProcName='<procedure_name2>'
		--AND CreatedOn BETWEEN '2021-04-21 12:48:00.0' AND '2021-04-21 13:05:00.0'
		AND Step=3;
SELECT * INTO #rep3
	FROM [TempLogDeleteOrders]
	WHERE ProcName='<procedure_name1>'
		--AND CreatedOn BETWEEN '2021-04-21 12:48:00.0' AND '2021-04-21 13:05:00.0'
		AND Step=3;
SELECT * INTO #rep2
	FROM [TempLogDeleteOrders]
	WHERE ProcName='<procedure_name1>'
		--AND CreatedOn BETWEEN '2021-04-21 12:48:00.0' AND '2021-04-21 13:05:00.0'
		AND Step=2;
SELECT 
		r2.DataIn 'Счёт_Заказ'
		,d2.CreatedOn 'Начало удаления'
		,d3.CreatedOn 'Конец удаления'
		,DATEDIFF(SECOND,d2.CreatedOn,d3.CreatedOn) 'Время, сек'
		,r3.DataOut 'Результат'
	FROM #d2 d2
		LEFT JOIN #d3 d3 ON d3.LogIdentity=d2.LogIdentity
		LEFT JOIN #rep3 r3 ON r3.LogIdentity=d2.LogIdentity
		LEFT JOIN #rep2 r2 ON r2.LogIdentity=d2.LogIdentity
	ORDER BY d2.CreatedOn DESC;

--DROP TABLE #d1;
DROP TABLE #d2;
DROP TABLE #d3;
DROP TABLE #rep3;
DROP TABLE #rep2;
