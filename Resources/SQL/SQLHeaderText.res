/* ============================================================================================
   Automatically generated modification script for Microsoft Appx-Deplyoment Database
   ============================================================================================
   This Script manipulates the Microsoft Appx-Deplyoment Database "StateRepository-Machine.srd"
   which resides in "%ProgramData%\Microsoft\Windows\AppRepository\StateRepository-Machine.srd"
   to lock or unlock system protected Appx-Packages that they can be uninstalled via Settings
   Dialog or PowerShell Commands.
   The lock state of an Appx-Package is controlled by the "IsInbox" value within the "Package"
   Table. A Value of 1 protects the Package from being uninstalled, a value of 0 unprotects the
   Package.
   Because of a DB-Error generated when changing an IsInbox Value since the newest Build of
   Windows 10 (1809), all triggers have to be removed from the database first. After applying
   the update commands all triggers are beeing recreated by this script.
   ============================================================================================ */