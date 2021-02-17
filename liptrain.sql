*/
IF SCHEMA_ID('web') IS NULL BEGIN	
	EXECUTE('CREATE SCHEMA [web]');
END
GO

IF USER_ID('restAPI') IS NULL BEGIN	
	CREATE USER [restAPI] WITH PASSWORD = '8s0v0AYIB7o';	
END

/*
	Grant execute permission to created users
*/
GRANT EXECUTE ON SCHEMA::[web] TO [restAPI];
GO

/*
	Return details on a specific sentence
*/
CREATE OR ALTER PROCEDURE web.get_sentence
@Json NVARCHAR(MAX)
AS
SET NOCOUNT ON;
DECLARE @SentenceId INT = JSON_VALUE(@Json, '$.SentenceId');
SELECT 
	[SentenceId], 
	[SentenceText] 	
FROM 
	[Sentence] 
WHERE 
	[SentenceID] = @SentenceId
FOR JSON PATH
GO

/*
	Delete a specific customer
*/
CREATE OR ALTER PROCEDURE web.delete_sentence
@Json NVARCHAR(MAX)
AS
SET NOCOUNT ON;
DECLARE @SentenceId INT = JSON_VALUE(@Json, '$.SentenceID');
DELETE FROM [Sentence] WHERE SentenceId = @SentenceId;
SELECT * FROM (SELECT SentenceId = @SentenceId) D FOR JSON AUTO;
GO

/*
	Update (Patch) a specific customer
*/
CREATE OR ALTER PROCEDURE web.patch_sentence
@Json NVARCHAR(MAX)
AS
SET NOCOUNT ON;
DECLARE @SentenceId INT = JSON_VALUE(@Json, '$.SentenceID');
WITH [source] AS 
(
	SELECT * FROM OPENJSON(@Json) WITH (
		[SentenceID] INT, 
		[SentenceText] NVARCHAR(256)
			)
)
UPDATE
	t
SET
	t.[SentenceText] = COALESCE(s.[SentenceText], t.[SentenceText])
FROM
	[Sentence] t
INNER JOIN
	[source] s ON t.[SentenceId] = s.[SentenceId]
WHERE
	t.SentenceId = @SentenceId;

DECLARE @Json2 NVARCHAR(MAX) = N'{"SentenceId": ' + CAST(@SentenceId AS NVARCHAR(9)) + N'}'
EXEC web.get_sentence @Json2;
GO

/*
	Create a new sentence
*/

CREATE OR ALTER PROCEDURE web.put_sentence
@Json NVARCHAR(MAX)
AS
SET NOCOUNT ON;
DECLARE @SentenceId INT = NEXT VALUE FOR Sentence.SentenceId;
WITH [source] AS 
(
	SELECT * FROM OPENJSON(@Json) WITH (		
		[SentenceText] NVARCHAR(256) 
			)
)
INSERT INTO [Sentence] 
(
	SentenceID, 
	SentenceText 	
	
)

SELECT
	@SentenceId, 
	SentenceText 
FROM
	[source]
;


DECLARE @Json2 NVARCHAR(MAX) = N'{"SentenceID": ' + CAST(@SentenceId AS NVARCHAR(9)) + N'}'
EXEC web.get_sentence @Json2;
GO

CREATE OR ALTER PROCEDURE web.get_sentences
AS
SET NOCOUNT ON;
-- Cast is needed to corretly inform pyodbc of output type is NVARCHAR(MAX)
-- Needed if generated json is bigger then 4000 bytes and thus pyodbc trucates it
-- https://stackoverflow.com/questions/49469301/pyodbc-truncates-the-response-of-a-sql-server-for-json-query
SELECT CAST((
	SELECT 
		[SentenceId], 
		[SentenceText]
	FROM 
		[Sentence] 
	FOR JSON PATH) AS NVARCHAR(MAX)) AS JsonResult
GO
