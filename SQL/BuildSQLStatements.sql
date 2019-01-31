/* ============================================================================================
   BuildSQLStatements.sql
   ============================================================================================
   This SQL Script exports all Triggers from the Appx-DB ("StateRepository-Machine.srd") and
   dynamically creates new SQL Script Files to Drop and Restore those Triggers.
   ============================================================================================ */

.mode list
.separator ; "\r\n"
.once "[DropTriggers]"

SELECT 'DROP TRIGGER ' || name || ';' AS DropTriggers FROM sqlite_master WHERE type='trigger';

.mode list
.separator ; "\r\n"
.once "[CreateTriggers]"

SELECT Replace(Replace(sql,'; END','; END;'),';END','; END;') AS CreateTriggers FROM sqlite_master WHERE type = 'trigger';