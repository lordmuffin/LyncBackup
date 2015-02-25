# LyncBackup
Microsoft 2010 &amp; 2013 Backup

    <#
  .SYNOPSIS
  Backup Lync Server 2010 and 2013.
  .DESCRIPTION
  This function is used to backup both Lync Server 2010 and 2013.  It will backup XDS, LIS, User Information and Exchange UM Contacts.
  It will also cycle backups for 30 days between production location and DR location.
  The Function will auto-detect your version of Lync Server.
  .EXAMPLE
  LyncBackup -prodPath "D:\LyncBackup\Backups" -drPath "\\dr\Lync\Backup\Backups" -poolName "lyncpool01.contoso.com" -sqlServer "sqlserver.contoso.com"
  .EXAMPLE
  LyncBackup -poolName "lyncpool01.contoso.com" -sqlServer "sqlserver.contoso.com"
  .PARAMETER prodPath
  The production backup location.  Usually on the local server running this function.
  Defaults to D:\LyncBackup\Backups
  .PARAMETER drPath
  The DR backup location.  Usually located on an offsite filserver.
  .PARAMETER poolName
  FQDN of the Lync Pool. Use only one.
  .PARAMETER sqlServer
  FQDN of the SQL Server used by the Lync Pool you are backing up. Use only one.
  .NOTES
  NAME: LyncBackup
  AUTHOR: Andrew Jackson
  LASTEDIT: 2/23/2015
  Credits to Richard Brynteson for original efforts and great documentation! www.masteringlync.com
  Supported Lync Server Versions:
  2010 and 2013
  .LINK
  www.masteringlync.com
  www.andrewpjackson.com
  #>
