/* ============================================================================================
   ExportPackageList.sql
   ============================================================================================
   This SQL Script creates a Dump of all Packages listed in the Appx-DB and thier respective
   IsInbox-Value and exports this List into a Text File.
   ============================================================================================ */

.mode column
.headers on

SELECT PackageFullName,IsInbox FROM Package ORDER BY IsInbox DESC;