/*
	Create schema
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
	Delete a specific sentence
*/
CREATE OR ALTER PROCEDURE web.delete_sentence
@Json NVARCHAR(MAX)
AS
SET NOCOUNT ON;
DECLARE @SentenceId INT = JSON_VALUE(@Json, '$.SentenceId');
DELETE FROM [Sentence] WHERE SentenceId = @SentenceId;
SELECT * FROM (SELECT SentenceId = @SentenceId) D FOR JSON AUTO;
GO

/*
	Update (Patch) a specific sentence
*/
CREATE OR ALTER PROCEDURE web.patch_sentence
@Json NVARCHAR(MAX)
AS
SET NOCOUNT ON;
DECLARE @SentenceId INT = JSON_VALUE(@Json, '$.SentenceId');
WITH [source] AS 
(
	SELECT * FROM OPENJSON(@Json) WITH (
		[SentenceId] INT, 
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

CREATE OR ALTER PROCEDURE web.get_sentencebytext
@Json NVARCHAR(MAX)
AS
SET NOCOUNT ON 
DECLARE @SentenceText NVARCHAR(256) = JSON_VALUE(@Json, '$.SentenceText')
SELECT 
	[SentenceId], 
	[SentenceText] 	
FROM 
	[Sentence] 
WHERE 
	[SentenceText] = @SentenceText
FOR JSON PATH
GO


/*
	Create a new sentence
*/


CREATE OR ALTER PROCEDURE web.put_sentence
@Json NVARCHAR(MAX)
AS
SET NOCOUNT ON;
DECLARE @SentenceText NVARCHAR(256) = JSON_VALUE(@Json,'$.SentenceText'); 
WITH [source] AS 
(
	SELECT * FROM OPENJSON(@Json) WITH (		
		[SentenceText] NVARCHAR(256) 
			)
)
INSERT INTO [Sentence] 
(   
	SentenceText 	
)

SELECT
	SentenceText
FROM
	[source]

;

DECLARE @Json2 NVARCHAR(MAX) = N'{"SentenceText":"' +@SentenceText + N'"}';
PRINT @Json2
EXEC web.get_sentencebytext @Json2;
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



/*
	Return details on a specific user
*/
CREATE OR ALTER PROCEDURE web.get_user
@Json NVARCHAR(MAX)
AS
SET NOCOUNT ON;
DECLARE @PersonId INT = JSON_VALUE(@Json, '$.UserId');
SELECT 
	[PersonId], 
	[Email],
	[DateJoined] 	
FROM 
	[Person] 
WHERE 
	[PersonId] = @PersonId
FOR JSON PATH
GO

/*
	Delete a specific user
*/
CREATE OR ALTER PROCEDURE web.delete_user
@Json NVARCHAR(MAX)
AS
SET NOCOUNT ON;
DECLARE @UserId INT = JSON_VALUE(@Json, '$.UserId');
DELETE FROM [Person] WHERE PersonId = @UserId;
SELECT * FROM (SELECT UserId = @UserId) D FOR JSON AUTO;
GO

/*
	Update (Patch) a specific user
*/
CREATE OR ALTER PROCEDURE web.patch_user
@Json NVARCHAR(MAX)
AS
SET NOCOUNT ON;
DECLARE @UserId INT = JSON_VALUE(@Json, '$.UserId');
WITH [source] AS 
(
	SELECT * FROM OPENJSON(@Json) WITH (
		[UserId] INT, 
		[email] NVARCHAR(256)
			)
)
UPDATE
	t
SET
	t.[Email] = COALESCE(s.[email], t.[Email])
FROM
	[Person] t
INNER JOIN
	[source] s ON t.[PersonId] = s.[UserId]
WHERE
	t.PersonId = @UserId;

DECLARE @Json2 NVARCHAR(MAX) = N'{"UserId": ' + CAST(@UserId AS NVARCHAR(9)) + N'}'
EXEC web.get_user @Json2;
GO

/*
	Create a new sentence
*/

CREATE OR ALTER PROCEDURE web.put_user
@Json NVARCHAR(MAX)
AS
SET NOCOUNT ON;
DECLARE @email NVARCHAR(256) = JSON_VALUE(@Json, '$.email')
PRINT @email
DECLARE @DateJoined DATE = GETDATE();
WITH [source] AS 
(
	SELECT * FROM OPENJSON(@Json) WITH (		
		[email] NVARCHAR(256) 
			)
)
INSERT INTO [Person] 
( 
	Email,
	DateJoined
	
)

SELECT
	Email,
	@DateJoined
FROM
	[source]
;

DECLARE @Json2 NVARCHAR(MAX) = N'{"email":"' + CAST(@email AS NVARCHAR) + N'"}'
PRINT @Json2
EXEC web.get_userbyemail @Json2;
GO

CREATE OR ALTER PROCEDURE web.get_users
AS
SET NOCOUNT ON;
-- Cast is needed to corretly inform pyodbc of output type is NVARCHAR(MAX)
-- Needed if generated json is bigger then 4000 bytes and thus pyodbc trucates it
-- https://stackoverflow.com/questions/49469301/pyodbc-truncates-the-response-of-a-sql-server-for-json-query
SELECT CAST((
	SELECT 
		[PersonId], 
		[Email],
		[DateJoined]
	FROM 
		[Person] 
	FOR JSON PATH) AS NVARCHAR(MAX)) AS JsonResult
GO


/*
	Return details on a specific video
*/
CREATE OR ALTER PROCEDURE web.get_video
@Json NVARCHAR(MAX)
AS
SET NOCOUNT ON;
DECLARE @VideoId INT = JSON_VALUE(@Json, '$.VideoId');
SELECT 
	[VideoId], 
	[PersonId],
	[SentenceId],
	[StoragePath]
FROM 
	[Video] 
WHERE 
	[VideoId] = @VideoId
FOR JSON PATH
GO


/*
	Delete a specific video
*/
CREATE OR ALTER PROCEDURE web.delete_video
@Json NVARCHAR(MAX)
AS
SET NOCOUNT ON;
DECLARE @VideoId INT = JSON_VALUE(@Json, '$.VideoId');
DELETE FROM [Video] WHERE VideoId = @VideoId;
SELECT * FROM (SELECT VideoId = @VideoId) D FOR JSON AUTO;
GO

/*
	Edit existing Video
*/

CREATE OR ALTER PROCEDURE web.patch_video
@Json NVARCHAR(MAX)
AS
SET NOCOUNT ON;
DECLARE @VideoId INT = JSON_VALUE(@Json, '$.VideoId');
WITH [source] AS 
(
	SELECT * FROM OPENJSON(@Json) WITH (
		[VideoId] INT, 
		[UserId] INT,
		[SentenceId] INT,
		[StoragePath] NVARCHAR(256)
			)
		 
)


UPDATE
	t
SET
	t.[PersonId] = COALESCE(s.[UserId], t.[PersonId]),
	t.[SentenceId]= COALESCE(s.[SentenceId],t.[SentenceId]),
	t.[StoragePath]=COALESCE(s.[StoragePath],t.[StoragePath])
FROM
	[Video] t
INNER JOIN
	[source] s ON t.[VideoId] = s.[VideoId]
WHERE
	t.VideoId = @VideoId;

DECLARE @Json2 NVARCHAR(MAX) = N'{"VideoId": ' + CAST(@VideoId AS NVARCHAR(9)) + N'}'
EXEC web.get_video @Json2;
GO

/*
	Add a new video
*/

CREATE OR ALTER PROCEDURE web.get_videobystorage
@Json NVARCHAR(MAX)
AS
SET NOCOUNT ON;
DECLARE @StoragePath NVARCHAR(MAX) = JSON_VALUE(@Json, '$.StoragePath');
SELECT 
	[VideoId], 
	[PersonId],
	[SentenceId],
	[StoragePath]
FROM 
	[Video] 
WHERE 
	[StoragePath] = @StoragePath
FOR JSON PATH
GO







CREATE OR ALTER PROCEDURE web.put_video
@Json NVARCHAR(MAX)
AS
SET NOCOUNT ON;
DECLARE @StoragePath NVARCHAR(MAX) = JSON_VALUE(@Json, '$.StoragePath');
WITH [source] AS 
(
	SELECT * FROM OPENJSON(@Json) WITH (		
		[UserId] INT,
		[SentenceId] INT,
		[StoragePath] NVARCHAR(256)
			)
)
INSERT INTO [Video] 
( 
	PersonId,
	SentenceId,
	StoragePath
	
)

SELECT
	UserId,
	SentenceId,
	StoragePath
FROM
	[source]
;

DECLARE @Json2 NVARCHAR(MAX) = N'{"StoragePath":"' + @StoragePath + N'"}'
EXEC web.get_videobystorage @Json2;
GO



CREATE OR ALTER PROCEDURE web.get_videos
AS
SET NOCOUNT ON;
-- Cast is needed to corretly inform pyodbc of output type is NVARCHAR(MAX)
-- Needed if generated json is bigger then 4000 bytes and thus pyodbc trucates it
-- https://stackoverflow.com/questions/49469301/pyodbc-truncates-the-response-of-a-sql-server-for-json-query
SELECT CAST((
	SELECT 
		[PersonId], 
		[SentenceId],
		[StoragePath]
	FROM 
		[Video] 
	FOR JSON PATH) AS NVARCHAR(MAX)) AS JsonResult
GO

CREATE OR ALTER PROCEDURE web.get_userbyemail
@Json NVARCHAR(MAX)
AS
SET NOCOUNT ON;
SET CONCAT_NULL_YIELDS_NULL OFF;
DECLARE @email NVARCHAR(256) = JSON_VALUE(@Json, '$.email');
SELECT ISNULL(CAST((
SELECT
	[PersonId],
	[Email],
	[DateJoined]
FROM
	[Person]
WHERE
	[Email]=@email
FOR JSON PATH) AS NVARCHAR(MAX)),'{}') AS JsonResult
GO