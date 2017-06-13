/* tests for ulid functions */
SET NOCOUNT ON

DECLARE @st DATETIME2(7)
DECLARE @et DATETIME2(7)
DECLARE @c INT
DECLARE @cmax INT
DECLARE @frag FLOAT

--number of rows used in tests
SET @cmax = 100000

--ulid as UNIQUEIDENTIFIER test
CREATE TABLE #t (
	pk UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED
	,d NVARCHAR(1000)
	)

SET @c = 0
SET @st = SYSUTCDATETIME()

WHILE @c < @cmax
BEGIN
	INSERT INTO #t (
		pk
		,d
		)
	VALUES (
		dbo.ulid()
		,N'dummy data for testing purposes; this should be a realistic length for narrow tables.'
		)

	SET @c = @c + 1
END

SET @et = SYSUTCDATETIME()
SET @frag = (
		SELECT TOP 1 CAST(avg_fragmentation_in_percent AS VARCHAR(100))
		FROM sys.dm_db_index_physical_stats(DB_ID(), OBJECT_ID(N'#t'), NULL, NULL, NULL)
		)

PRINT 'ulid() as primary key INSERTION TEST: '
PRINT '     rows/sec: ' + CAST(CAST(@cmax AS FLOAT) * 1000 / DATEDIFF(ms, @st, @et) AS VARCHAR(100))
PRINT '     avg_fragmentation_in_percent: ' + CAST(@frag AS VARCHAR(100))

DROP TABLE #t

--newid as UNIQUEIDENTIFIER test
CREATE TABLE #t2 (
	pk UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED
	,d NVARCHAR(1000)
	)

SET @c = 0
SET @st = SYSUTCDATETIME()

WHILE @c < @cmax
BEGIN
	INSERT INTO #t2 (
		pk
		,d
		)
	VALUES (
		NEWID()
		,N'dummy data for testing purposes; this should be a realistic length for narrow tables.'
		)

	SET @c = @c + 1
END

SET @et = SYSUTCDATETIME()
SET @frag = (
		SELECT TOP 1 CAST(avg_fragmentation_in_percent AS VARCHAR(100))
		FROM sys.dm_db_index_physical_stats(DB_ID(), OBJECT_ID(N'#t2'), NULL, NULL, NULL)
		)

PRINT 'newid() as primary key INSERTION TEST: '
PRINT '     rows/sec: ' + CASt(CAST(@cmax AS FLOAT) * 1000 / DATEDIFF(ms, @st, @et) AS VARCHAR(100))
PRINT '     avg_fragmentation_in_percent: ' + CAST(@frag AS VARCHAR(100))

DROP TABLE #t2

--newsequentialID as UNIQUEIDENTIFIER test
CREATE TABLE #t3 (
	pk UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED DEFAULT(newsequentialid())
	,d NVARCHAR(1000)
	)

SET @c = 0
SET @st = SYSUTCDATETIME()

WHILE @c < @cmax
BEGIN
	INSERT INTO #t3 (
		pk
		,d
		)
	VALUES (
		DEFAULT
		,N'dummy data for testing purposes; this should be a realistic length for narrow tables.'
		)

	SET @c = @c + 1
END

SET @et = SYSUTCDATETIME()
SET @frag = (
		SELECT TOP 1 CAST(avg_fragmentation_in_percent AS VARCHAR(100))
		FROM sys.dm_db_index_physical_stats(DB_ID(), OBJECT_ID(N'#t2'), NULL, NULL, NULL)
		)

PRINT 'newsquentialid() as primary key INSERTION TEST: '
PRINT '     rows/sec: ' + CASt(CAST(@cmax AS FLOAT) * 1000 / DATEDIFF(ms, @st, @et) AS VARCHAR(100))
PRINT '     avg_fragmentation_in_percent: ' + CAST(@frag AS VARCHAR(100))

DROP TABLE #t3

--newidStr() as primary key test
CREATE TABLE #t4 (
	pk CHAR(26) PRIMARY KEY CLUSTERED
	,d NVARCHAR(1000)
	)

SET @c = 0
SET @st = SYSUTCDATETIME()

WHILE @c < @cmax
BEGIN
	INSERT INTO #t4 (
		pk
		,d
		)
	VALUES (
		dbo.ulidStr()
		,N'dummy data for testing purposes; this should be a realistic length for narrow tables.'
		)

	SET @c = @c + 1
END

SET @et = SYSUTCDATETIME()
SET @frag = (
		SELECT TOP 1 CAST(avg_fragmentation_in_percent AS VARCHAR(100))
		FROM sys.dm_db_index_physical_stats(DB_ID(), OBJECT_ID(N'#t4'), NULL, NULL, NULL)
		)

PRINT 'ulidStr() as primary key INSERTION TEST: '
PRINT '     rows/sec: ' + CASt(CAST(@cmax AS FLOAT) * 1000 / DATEDIFF(ms, @st, @et) AS VARCHAR(100))
PRINT '     avg_fragmentation_in_percent: ' + CAST(@frag AS VARCHAR(100))

DROP TABLE #t4
