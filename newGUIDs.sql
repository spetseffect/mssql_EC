/*
@K - сколько гуидов надо сгенерировать

*/
DECLARE @K INT = 20;
DECLARE @I INT = 0;
DECLARE @Q NVARCHAR(MAX);
WHILE (@I < @K)
BEGIN
	SET @Q = CONCAT(@Q,' SELECT NEWID() ');
	IF (@I < @K - 1) SET @Q = CONCAT(@Q,' UNION ');
	SET @I = @I + 1;
END;
EXEC(@Q);