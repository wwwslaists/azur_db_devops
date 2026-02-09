-- ============================================
-- Schema Change Tracking Setup
-- ============================================

USE TestDB;
GO

-- 1. Izveidot log tabulu
IF OBJECT_ID('dbo.devops_SchemaChangeLog', 'U') IS NOT NULL
    DROP TABLE dbo.devops_SchemaChangeLog;
GO

CREATE TABLE dbo.devops_SchemaChangeLog (
    ChangeId INT IDENTITY(1,1) PRIMARY KEY,
    ObjectName NVARCHAR(256),
    SchemaName NVARCHAR(128),
    ObjectType NVARCHAR(60),
    ChangeType NVARCHAR(50),
    ChangedBy NVARCHAR(128),
    ChangedAt DATETIME2 DEFAULT SYSDATETIME(),
    SQLCommand NVARCHAR(MAX),
    Processed BIT DEFAULT 0,
    ProcessedAt DATETIME2 NULL,
    PipelineRunId NVARCHAR(100) NULL,
    
    INDEX IX_Processed_ChangedAt (Processed, ChangedAt)
);
GO

-- 2. Stored procedure lai iegūtu neapstrādātās izmaiņas
CREATE OR ALTER PROCEDURE dbo.usp_devops_GetUnprocessedSchemaChanges
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        ChangeId,
        ObjectName,
        SchemaName,
        ObjectType,
        ChangeType,
        ChangedBy,
        ChangedAt,
        SQLCommand
    FROM dbo.devops_SchemaChangeLog
    WHERE Processed = 0
    ORDER BY ChangedAt ASC;
END;
GO

-- 3. Stored procedure lai atzīmētu kā apstrādātas
CREATE OR ALTER PROCEDURE dbo.usp_devops_MarkSchemaChangesProcessed
    @ChangeIds NVARCHAR(MAX),  -- Comma-separated IDs
    @PipelineRunId NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Izveidot temp tabulu no CSV
    CREATE TABLE #ChangeIds (ChangeId INT);
    
    INSERT INTO #ChangeIds (ChangeId)
    SELECT CAST(value AS INT)
    FROM STRING_SPLIT(@ChangeIds, ',');
    
    -- Update records
    UPDATE scl
    SET 
        Processed = 1,
        ProcessedAt = SYSDATETIME(),
        PipelineRunId = @PipelineRunId
    FROM dbo.devops_SchemaChangeLog scl
    INNER JOIN #ChangeIds ci ON scl.ChangeId = ci.ChangeId;
    
    -- Return updated count
    SELECT @@ROWCOUNT AS ProcessedCount;
    
    DROP TABLE #ChangeIds;
END;
GO

-- 4. View lai skatītu statistiku
CREATE OR ALTER VIEW dbo.vw_devops_SchemaChangeStats
AS
SELECT 
    CAST(ChangedAt AS DATE) AS ChangeDate,
    ChangeType,
    ObjectType,
    COUNT(*) AS ChangeCount,
    SUM(CASE WHEN Processed = 1 THEN 1 ELSE 0 END) AS ProcessedCount,
    SUM(CASE WHEN Processed = 0 THEN 1 ELSE 0 END) AS PendingCount
FROM dbo.SchemaChangeLog
GROUP BY CAST(ChangedAt AS DATE), ChangeType, ObjectType;
GO

-- 5. Cleanup procedure (dzēst vecākus par 30 dienām)
CREATE OR ALTER PROCEDURE dbo.usp_devops_CleanupSchemaChangeLog
    @RetentionDays INT = 30
AS
BEGIN
    SET NOCOUNT ON;
    
    DELETE FROM dbo.devops_SchemaChangeLog
    WHERE 
        Processed = 1
        AND ProcessedAt < DATEADD(DAY, -@RetentionDays, SYSDATETIME());
    
    SELECT @@ROWCOUNT AS DeletedRows;
END;
GO
