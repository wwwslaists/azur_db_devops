-- ============================================
-- DDL Trigger - Notver visas schema izmaiņas
-- ============================================

USE TestDB;
GO

-- Drop ja eksistē
IF EXISTS (SELECT * FROM sys.triggers WHERE parent_class = 0 AND name = 'trg_CaptureSchemaChanges')
    DROP TRIGGER trg_CaptureSchemaChanges ON DATABASE;
GO

CREATE TRIGGER trg_CaptureSchemaChanges
ON DATABASE
FOR 
    -- Tables
    CREATE_TABLE, ALTER_TABLE, DROP_TABLE,
    -- Stored Procedures
    CREATE_PROCEDURE, ALTER_PROCEDURE, DROP_PROCEDURE,
    -- Views
    CREATE_VIEW, ALTER_VIEW, DROP_VIEW,
    -- Functions
    CREATE_FUNCTION, ALTER_FUNCTION, DROP_FUNCTION,
    -- Indexes
    CREATE_INDEX, ALTER_INDEX, DROP_INDEX,
    -- Constraints (optional)
    ADD_CONSTRAINT, DROP_CONSTRAINT,
    -- Triggers
    CREATE_TRIGGER, ALTER_TRIGGER, DROP_TRIGGER
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @EventData XML = EVENTDATA();
    DECLARE @ObjectName NVARCHAR(256);
    DECLARE @SchemaName NVARCHAR(128);
    DECLARE @ObjectType NVARCHAR(60);
    DECLARE @EventType NVARCHAR(50);
    DECLARE @LoginName NVARCHAR(128);
    DECLARE @SQLCommand NVARCHAR(MAX);
    
    -- Izvilkt datus no XML
    SELECT
        @EventType = @EventData.value('(/EVENT_INSTANCE/EventType)[1]', 'NVARCHAR(50)'),
        @ObjectName = @EventData.value('(/EVENT_INSTANCE/ObjectName)[1]', 'NVARCHAR(256)'),
        @SchemaName = @EventData.value('(/EVENT_INSTANCE/SchemaName)[1]', 'NVARCHAR(128)'),
        @ObjectType = @EventData.value('(/EVENT_INSTANCE/ObjectType)[1]', 'NVARCHAR(60)'),
        @LoginName = @EventData.value('(/EVENT_INSTANCE/LoginName)[1]', 'NVARCHAR(128)'),
        @SQLCommand = @EventData.value('(/EVENT_INSTANCE/TSQLCommand/CommandText)[1]', 'NVARCHAR(MAX)');
    
    -- Ignorēt izmaiņas SchemaChangeLog tabulā (avoid recursion)
    IF @ObjectName = 'SchemaChangeLog' AND @SchemaName = 'dbo'
        RETURN;
    
    -- Ignorēt service accounts (optional)
    IF @LoginName LIKE '%service%' OR @LoginName LIKE '%azuredevops%'
        RETURN;
    
    -- Ielogot izmaiņas
    BEGIN TRY
        INSERT INTO dbo.SchemaChangeLog (
            ObjectName,
            SchemaName,
            ObjectType,
            ChangeType,
            ChangedBy,
            SQLCommand
        )
        VALUES (
            ISNULL(@ObjectName, 'N/A'),
            ISNULL(@SchemaName, 'dbo'),
            ISNULL(@ObjectType, 'UNKNOWN'),
            @EventType,
            @LoginName,
            @SQLCommand
        );
    END TRY
    BEGIN CATCH
        -- Neko nedarīt - lai DDL command nefeilo
        -- Vari pievienot error logging šeit
    END CATCH;
END;
GO

-- Aktivizēt trigger
ENABLE TRIGGER trg_CaptureSchemaChanges ON DATABASE;
GO

PRINT 'DDL Trigger izveidots un aktivizēts';
