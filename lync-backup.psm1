Function LyncBackup {
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

  Param (
    $prodPath = "D:\LyncBackup\Backups\",
    $drPath = "",
    [Parameter(Mandatory=$true)]$poolName = "lyncpool01.contoso.com",
    [Parameter(Mandatory=$true)]$sqlServer = "sqlserver.contoso.com"
  )

  # Variables
  $currDate = get-date -uformat "%a-%m-%d-%Y-%H-%M"
  $prodPathFinal = $prodPath + "$currDate\"
  $drPathFinal = $drPath + "$currDate\"

  # Version Check and Import Lync Module

  $version = Get-CSServerVersion
  IF ($version -like "Microsoft Lync Server 2010") {
    Write-Host -ForegroundColor Green "Microsoft Lync Server 2010 Installed"
    Import-Module "C:\Program Files\Common Files\Microsoft Lync Server 2010\Modules\Lync\Lync.psd1"
  }
  Else {
    Write-Host -ForegroundColor Green "Microsoft Lync Server 2013 Installed"
    Import-Module "C:\Program Files\Common Files\Microsoft Lync Server 2013\Modules\Lync\Lync.psd1"
  }

  # Production

  Write-Host -ForegroundColor Green "Cleaning files on $prodPath"

    #Delete Older Than 30 Days – Production Side
    get-childitem '$prodPath' -recurse | where {$_.lastwritetime -lt (get-date).adddays(-30) -and -not $_.psiscontainer} |% {remove-item $_.fullname -force }
    
    #Delete Empty Folders – Production Side
    $a = Get-ChildItem '$prodPath' -recurse | Where-Object {$_.PSIsContainer -eq $True}
    $a | Where-Object {$_.GetFiles().Count -eq 0} | Remove-Item
    
  # DR

  Write-Host -ForegroundColor Green "Cleaning files on $drPath"

    #Delete Older Than 30 Days – DR Side
    get-childitem '$drPath' -recurse | where {$_.lastwritetime -lt (get-date).adddays(-30) -and -not $_.psiscontainer} |% {remove-item $_.fullname -force }
    
    #Delete Empty Folders – DR Side
    $a = Get-ChildItem '$drPath' -recurse | Where-Object {$_.PSIsContainer -eq $True}
    $a | Where-Object {$_.GetFiles().Count -eq 0} | Remove-Item

  Write-Host -ForegroundColor Green "Backup to server in progress"

  #Create Folder
  New-Item "$prodPathFinal" -Type Directory
  
  #Export CMS/XDS and LIS
  Export-CsConfiguration -FileName "$prodPathFinal XdsConfig.zip"
  Export-CsLisConfiguration -FileName "$prodPathFinal LisConfig.zip"

  #Export RGS Config
  Try {
      Export-CsRgsConfiguration -FileName "$prodPathFinal RgsConfig.zip" -Source ApplicationServer:$poolName 
  }
  Catch {
      Write-Host -ForegroundColor Green "RGS not installed"
  }

  #Export User Information
  IF ($version -like "Microsoft Lync Server 2010") {
    Write-Host -ForegroundColor Green "Lync Server 2010 Installed, exporting user information with dbimpexp.exe"
    D:\LyncTools\LyncBackup\dbimpexp.exe /hrxmlfile:"$prodPath UserData.xml" /sqlserver:$sqlServer
  }
  Else {
    Write-Host -ForegroundColor Green "Lync Server 2013 Installed, exporting user information Export-CSUserData"
    Export-CSUserData -PoolFQDN $poolName -FileName "$prodPathFinal UserData.zip"
  }

  #Export Exchange Contact Information
  Get-CsExUmContact | Select "AutoAttendant","IsSubscriberAccess","Description","DisplayNumber","LineURI", "DisplayName","ProxyAddresses","HomeServer","EnabledForFederation","EnabledForInternetAccess", "PublicNetworkEnabled","EnterpriseVoiceEnabled","EnabledForRichPresence","SipAddress","Enabled",
  "TargetRegistrarPool","VoicePolicy","MobilityPolicy","ConferencingPolicy","PresencePolicy",
  "RegistrarPool","DialPlan","LocationPolicy","ClientPolicy","ClientVersionPolicy","ArchivingPolicy","PinPolicy", "ExternalAccessPolicy","HostedVoicemailPolicy","HostingProvider","Name","DistinguishedName" | Export-Csv -Path "$prodPathFinal ExUMContacts.csv"
  
  Write-Host -ForegroundColor Green "XDS, LIS, User and Exchange UM Contacts backup to server is completed.  Files are located at $prodPath"
  Write-Host -ForegroundColor Green "Please make sure to export Voice Configuration Separately"
  
  #Copy Files to DR Server
  robocopy $prodPathFinal $drPathFinal /MIR

  # End LyncBackup Function
}
