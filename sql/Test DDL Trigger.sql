-- ============================================
-- Testa skripts
-- ============================================

-- Izveidot test tabulu
CREATE TABLE dbo.TestTable1 (
    Id INT PRIMARY KEY,
    Name NVARCHAR(100)
);
GO

-- Izmainīt tabulu
ALTER TABLE dbo.TestTable1 ADD Email NVARCHAR(255);
GO

-- Izveidot procedure
CREATE PROCEDURE dbo.usp_TestProc
AS
BEGIN
    SELECT 1;
END;
GO

-- Pārbaudīt log
SELECT * FROM dbo.SchemaChangeLog ORDER BY ChangedAt DESC;

-- Skatīt statistiku
SELECT * FROM dbo.vw_SchemaChangeStats;

-- Cleanup test objekti
DROP PROCEDURE IF EXISTS dbo.usp_TestProc;
DROP TABLE IF EXISTS dbo.TestTable1;
