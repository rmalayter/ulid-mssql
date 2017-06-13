IF NOT EXISTS (
		SELECT *
		FROM sys.VIEWS
		WHERE object_id = OBJECT_ID(N'[dbo].[ulid_view]')
		)
	EXEC dbo.sp_executesql @statement = N'CREATE VIEW [dbo].[ulid_view] AS SELECT 1 AS foo'
GO

ALTER VIEW [dbo].[ulid_view]
AS
SELECT SYSUTCDATETIME() AS dt
	,CRYPT_GEN_RANDOM(10) AS rnd
GO

GRANT SELECT
	ON [dbo].[ulid_view]
	TO PUBLIC
GO

IF NOT EXISTS (
		SELECT *
		FROM sys.objects
		WHERE object_id = OBJECT_ID(N'[dbo].[ulid]')
		)
	EXEC dbo.sp_executesql @statement = N'CREATE FUNCTION [dbo].[ulid]() RETURNS UNIQUEIDENTIFIER AS BEGIN RETURN NULL END'
GO

ALTER FUNCTION [dbo].[ulid] ()
RETURNS UNIQUEIDENTIFIER
AS
BEGIN
	DECLARE @rnd BINARY (10)
	DECLARE @dt DATETIME2
	DECLARE @di BIGINT

	SELECT TOP 1 @dt = dt
		,@rnd = rnd
	FROM dbo.ulid_view

	SET @di = DATEDIFF(hour, CAST('1970-01-01 00:00:00' AS DATETIME2), @dt)
	SET @di = (@di * 60) + DATEPART(minute, @dt)
	SET @di = (@di * 60) + DATEPART(second, @dt)
	SET @di = (@di * 1000) + DATEPART(ms, @dt)

	RETURN CAST(@rnd + SUBSTRING(CAST(@di AS BINARY (8)), 3, 6) AS UNIQUEIDENTIFIER)
END
GO

GRANT EXECUTE
	ON [dbo].[ulid]
	TO PUBLIC
GO

IF NOT EXISTS (
		SELECT *
		FROM sys.objects
		WHERE object_id = OBJECT_ID(N'[dbo].[base32CrockfordEnc]')
			AND type IN (
				N'FN'
				,N'IF'
				,N'TF'
				,N'FS'
				,N'FT'
				)
		)
	EXEC dbo.sp_executesql @statement = N'CREATE FUNCTION [dbo].[base32CrockfordEnc]() RETURNS NVARCHAR(MAX) AS BEGIN RETURN NULL END'
GO

ALTER FUNCTION [dbo].[base32CrockfordEnc] (
	@x VARBINARY(max)
	,@pad INT = 1
	)
RETURNS VARCHAR(max)
AS
BEGIN
	/* modified BASE32 encoding as definied by Crockford at http://www.crockford.com/wrmg/base32.html */
	DECLARE @p INT
	DECLARE @c BIGINT
	DECLARE @s BIGINT
	DECLARE @q BIGINT
	DECLARE @t BIGINT
	DECLARE @o VARCHAR(max)
	DECLARE @op VARCHAR(8)
	DECLARE @alpha CHAR(32)

	SET @alpha = '0123456789ABCDEFGHJKMNPQRSTVWXYZ'
	SET @o = ''
	SET @p = DATALENGTH(@x) % 5 --encode with 40-bit blocks

	IF @p <> 0
		SET @x = @x + SUBSTRING(0x0000000000, 1, 5 - @p)
	SET @c = 0

	WHILE @c < DATALENGTH(@x)
	BEGIN
		SET @s = 0
		SET @t = CAST(SUBSTRING(@x, @c + 1, 5) AS BIGINT)
		SET @op = ''

		WHILE @s < 8
		BEGIN
			SET @q = @t % 32
			SET @op = SUBSTRING(@alpha, @q + 1, 1) + @op
			SET @t = @t / 32
			SET @s = @s + 1
		END

		SET @o = @o + @op
		SET @c = @c + 5
	END

	DECLARE @padc CHAR(1)

	--padding section
	SET @padc = CASE 
			WHEN @pad IS NULL
				OR @pad = 1
				THEN '='
			ELSE ''
			END
	SET @o = CASE 
			WHEN @p = 1
				THEN SUBSTRING(@o, 1, DATALENGTH(@o) - 6) + REPLICATE(@padc, 6)
			WHEN @p = 2
				THEN SUBSTRING(@o, 1, DATALENGTH(@o) - 4) + REPLICATE(@padc, 4)
			WHEN @p = 3
				THEN SUBSTRING(@o, 1, DATALENGTH(@o) - 3) + REPLICATE(@padc, 3)
			WHEN @p = 4
				THEN SUBSTRING(@o, 1, DATALENGTH(@o) - 1) + REPLICATE(@padc, 1)
			ELSE @o
			END

	RETURN LTRIM(RTRIM(@o))
END
GO

GRANT EXECUTE
	ON [dbo].[base32CrockfordEnc]
	TO PUBLIC
GO

IF NOT EXISTS (
		SELECT *
		FROM sys.objects
		WHERE object_id = OBJECT_ID(N'[dbo].[base32CrockfordDec]')
			AND type IN (
				N'FN'
				,N'IF'
				,N'TF'
				,N'FS'
				,N'FT'
				)
		)
	EXEC dbo.sp_executesql @statement = N'CREATE FUNCTION [dbo].[base32CrockfordDec]() RETURNS VARBINARY(MAX) AS BEGIN RETURN NULL END'
GO

ALTER FUNCTION [dbo].[base32CrockfordDec] (@x VARCHAR(max))
RETURNS VARBINARY(max)
AS
BEGIN
	/* RFC 4648 compliant BASE32 decoding function, takes varchar data to decode as only parameter*/
	DECLARE @p INT
	DECLARE @c BIGINT
	DECLARE @s BIGINT
	DECLARE @q BIGINT
	DECLARE @t BIGINT
	DECLARE @o VARBINARY(max)
	DECLARE @alpha CHAR(32)

	SET @alpha = '0123456789ABCDEFGHJKMNPQRSTVWXYZ'
	SET @o = CAST('' AS VARBINARY(max))
	SET @p = 0 --initialize padding character count
		--we can strip off padding characters since BASE32 is unambiguous without them
	SET @x = REPLACE(@x, '=', '')
	SET @p = DATALENGTH(@x) % 8 --encode with 40-bit blocks

	IF @p <> 0
		SET @x = @x + SUBSTRING('00000000', 1, 8 - @p)
	SET @x = UPPER(@x)
	SET @x = REPLACE(@x, 'I', '1')
	SET @x = REPLACE(@x, 'O', '0')
	SET @c = 1

	WHILE @c < DATALENGTH(@x) + 1
	BEGIN
		SET @s = 0
		SET @t = 0

		WHILE @s < 8 --accumulate 8 characters (40 bits) at a time in a bigint
		BEGIN
			SET @t = @t * 32
			SET @t = @t + (CHARINDEX(SUBSTRING(@x, @c, 1), @alpha, 1) - 1)
			SET @s = @s + 1
			SET @c = @c + 1
		END

		SET @o = @o + SUBSTRING(CAST(@t AS BINARY (8)), 4, 5)
	END

	--remove padding section
	SET @o = CASE 
			WHEN @p = 2
				THEN SUBSTRING(@o, 1, DATALENGTH(@o) - 4)
			WHEN @p = 4
				THEN SUBSTRING(@o, 1, DATALENGTH(@o) - 3)
			WHEN @p = 5
				THEN SUBSTRING(@o, 1, DATALENGTH(@o) - 2)
			WHEN @p = 7
				THEN SUBSTRING(@o, 1, DATALENGTH(@o) - 1)
			ELSE @o
			END

	RETURN @o
END
GO

GRANT EXECUTE
	ON [dbo].[base32CrockfordDec]
	TO PUBLIC
GO

IF NOT EXISTS (
		SELECT *
		FROM sys.objects
		WHERE object_id = OBJECT_ID(N'[dbo].[ulidStr]')
		)
	EXEC dbo.sp_executesql @statement = N'CREATE FUNCTION [dbo].[ulidStr]() RETURNS VARCHAR(100) AS BEGIN RETURN NULL END'
GO

ALTER FUNCTION [dbo].[ulidStr] ()
RETURNS VARCHAR(100)
AS
BEGIN
	DECLARE @temp BINARY (16)

	SET @temp = CAST(dbo.ulid() AS BINARY (16))

	RETURN [dbo].[base32CrockfordEnc](SUBSTRING(@temp, 11, 6) + SUBSTRING(@temp, 1, 10), 0)
END
GO

GRANT EXECUTE
	ON [dbo].[ulidStr]
	TO PUBLIC
GO


