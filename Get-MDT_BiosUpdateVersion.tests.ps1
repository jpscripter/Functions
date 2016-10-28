#requires -Version 3.0 -Modules Pester, SQLPS
<#
    .Synopsis
    Runs test cases against <Script>

    .DESCRIPTION
    Created: Jeff Scripter

    Version: 
    1.0.0 - 8/25/2016 - Jeff Scripter - Original


    Tests:
    1) Test1
    2) Test2

      
    Return:
    Test results+

    .EXAMPLE
    Invoke-Pester -Script 'H:\Scripts\Functions\Get-MDT_BiosUpdateVersion.tests.ps1' -CodeCoverage 'H:\Scripts\Functions\Get-MDT_BiosUpdateVersion.ps1' 
Test Date:		 10/04/2016 15:55:42
Test System:	 SCRIPJ1-L8
Test User:		 scripj1
Describing Get-MDT_BiosUpdateVersion
   Context Custom
VERBOSE: Custom Version format.
VERBOSE: Retrieving from c:\users\scripj1\appdata\local\temp\testfake.txt
VERBOSE: -Return = (Custom)  1.5.8.19
    [+] Returned Version 1.5.8.19 186ms
    [+] Returned Arg -Args 21ms
    [+] Returned Exe C:\Users\scripj1\AppData\Local\Temp\Testfake.exe 7ms
    [+] Returned Type Custom 8ms
    [+] Returned Manufacturer Custom 6ms
   Context Lenovo File
VERBOSE: Lenovo system. Using Bios
VERBOSE: -Return = (FL1)  JEET73WW
    [+] Returned Version JEET73WW 104ms
    [+] Returned Arg -s 6ms
    [+] Returned Exe C:\WINDOWS\temp\winuptp.exe 8ms
    [+] Returned Type FL1 6ms
    [+] Returned Manufacturer Lenovo 10ms
   Context Lenovo WMI
VERBOSE: Lenovo system. Using Bios
VERBOSE: -Return = (FL1)  GNET79WW
    [+] Returned Version GNET79WW (2.27 )  101ms
    [+] Returned Arg -s 8ms
    [+] Returned Exe winuptp.exe 8ms
    [+] Returned Type FL1 7ms
    [+] Returned Manufacturer Lenovo 15ms
   Context Skylake File
VERBOSE: Skylake Dell Version found.
VERBOSE: -Return = (Skylake\KabyLake)  1.4.2
    [+] Returned Version 1.4.2  99ms
    [+] Returned Arg -s /s /f /l 6ms
    [+] Returned Exe C:\temp\Invoke-BiosUpdate(w7)\Latitude E7270\Latitude_E7x70_1.4.2.exe 17ms
    [+] Returned Type Skylake\KabyLake 7ms
    [+] Returned Manufacturer Dell 10ms
   Context Skylake WMI
VERBOSE: Skylake Dell Version found.
VERBOSE: -Return = (Skylake\KabyLake)  1.7.3
    [+] Returned Version 1.7.3  116ms
    [+] Returned Arg -s /s /f /l 7ms
    [+] Returned Exe 1.7.3 8ms
    [+] Returned Type Skylake\KabyLake 8ms
    [+] Returned Manufacturer Dell 9ms
   Context Dell Legacy File
VERBOSE: DUP Dell
VERBOSE: -Return = (Legacy)  14
    [+] Returned Version 14  111ms
    [+] Returned Arg -s /s /f /l 7ms
    [+] Returned Exe C:\temp\Invoke-BiosUpdate(w7)\Latitude E4310\E4310A14.exe 9ms
    [+] Returned Type Legacy 19ms
    [+] Returned Manufacturer Dell 12ms
   Context Dell Legacy WMI
VERBOSE: DUP Dell
VERBOSE: -Return = (Legacy)  15
    [+] Returned Version 15  109ms
    [+] Returned Arg -s /s /f /l 11ms
    [+] Returned Exe A15 7ms
    [+] Returned Type Legacy 8ms
    [+] Returned Manufacturer Dell 8ms
   Context HP Cab File
VERBOSE: HP CAB File
VERBOSE: -Return = (HPCab File)  F.61
    [+] Returned Version F.61  2.22s
    [+] Returned Arg -s -f"<CabFile>.cab" 16ms
    [+] Returned Exe hpqFlash 9ms
    [+] Returned Type HPCab File 12ms
    [+] Returned Manufacturer HPCab 17ms
   Context HP Cab WMI
VERBOSE: HP CAB WMI
VERBOSE: -Return = (HPCab WMI)  F.61
    [+] Returned Version F.61  128ms
    [+] Returned Arg -s -f"<cabFile>" 14ms
    [+] Returned Exe hpqFlash 16ms
    [+] Returned Type HPCab WMI 6ms
    [+] Returned Manufacturer HPCab	 8ms
   Context HP Bin File
VERBOSE: HP Bin Files.
VERBOSE: -Return = (HPBin File)  01.09
    [+] Returned Version 01.09  96ms
    [+] Returned Arg -s -r -f"<Bin>.bin" 10ms
    [+] Returned Exe HPBIOSUPDREC 7ms
    [+] Returned Type HPCab File 7ms
    [+] Returned Manufacturer HPBin 8ms
   Context HP Bin WMI
VERBOSE: HP Bin Files.
VERBOSE: -Return = (HPBIN WMI)  01.30
    [+] Returned Version 1.30  100ms
    [+] Returned Arg -s -f"<BinFile>" 10ms
    [+] Returned Exe HPBIOSUPDREC 8ms
    [+] Returned Type HPCab WMI 9ms
    [+] Returned Manufacturer HPBin	 18ms
   Context Unknown
Write-MDT_LogMessage : Error: Identifying Version for Target bios.
At H:\Scripts\Functions\get-mdt_biosupdateversion.ps1:261 char:11
+           Write-MDT_LogMessage -message 'Error: Identifying Version f ...
+           ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (:) [Write-Error], WriteErrorException
    + FullyQualifiedErrorId : Microsoft.PowerShell.Commands.WriteErrorException,Write-MDT_LogMessage
 
VERBOSE: -Return = ()  
    [+] Unknown Should throw 131ms

#>

#***************************************
#region 1 Params
#***************************************
Param(
  #Bios Update folder/SCCM
  [Switch] $Report

)
#***************************************
#endregion 1 Params
#***************************************

#***************************************
#region 1 sourcing Original File
#- Dot sources the script for functions (Shouldnt be done with scripts)
#***************************************
$here = Split-Path -Parent -Path $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf -Path $MyInvocation.MyCommand.Path).tolower().Replace('.tests.', '.')
. "$here\$sut"
#***************************************
#endregion 1 sourcing Original File
#***************************************

#***************************************
#region 1 Import\Load 
#***************************************
Import-Module -Name SQLAScmdlets
#***************************************
#endregion 1 Import\Load 
#***************************************

#***************************************
#region 1 Standard Variables
#-These are variables I put in all of my scripts and are used for logging, location detection and other general detection.
#***************************************
Set-Location -Path c:
$global:logFile = "$env:windir\temp\$(Split-Path -Leaf -Path $MyInvocation.MyCommand.Path).log"
#***************************************
#endregion 1 Standard Variables
#***************************************

#***************************************
#region 1 Mock Variables
#-These are the variables\objects we use in the different tests
#***************************************

#***************************************
#endregion 1 Mock Variables
#***************************************

#***************************************
#region 1 Main
#***************************************
Write-Output -InputObject "Test Date:`t`t $(Get-Date)"
Write-Output -InputObject "Test System:`t $Env:ComputerName"
Write-Output -InputObject "Test User:`t`t $Env:UserName"

Describe  -Name 'Get-MDT_BiosUpdateVersion' -Fixture {
  #***************************************
  #region 2 Custom
  #***************************************
  Context -Name 'Custom' -Fixture {
    $FakeExepath = "$env:temp\Testfake.exe"
    New-Item -Path $FakeExepath -Force
    $FakeVersion = '1.5.8.19'
    $FakeArg = '-Args'
    Out-File -FilePath $FakeExepath.replace('.exe','.txt') -InputObject $FakeVersion -Force 
    Out-File -FilePath $FakeExepath.replace('.exe','.txt') -InputObject $FakeArg -Append -Force 
    
    $UpdateInfo = . Get-MDT_BiosUpdateVersion -String $FakeExepath -Verbose
    Remove-Item -Path $FakeExepath -Force
    Remove-Item -Path $FakeExepath.replace('.exe','.txt') -Force
    
    It -name "Returned Version $FakeVersion" -test {
      $UpdateInfo.Version | Should be $FakeVersion
    }
    It -name "Returned Arg $FakeArg" -test {
      $UpdateInfo.Arguments | Should be $FakeArg
    }
    It -name "Returned Exe $FakeExepath" -test {
      $UpdateInfo.UpdateFile | Should be $FakeExepath
    }
    It -name 'Returned Type Custom' -test {
      $UpdateInfo.Type | Should be 'Custom'
    }
    It -name 'Returned Manufacturer Custom' -test {
      $UpdateInfo.Manufacturer | Should be 'Custom'
    }
  }
  #***************************************
  #endregion 2 Custom
  #***************************************

  #***************************************
  #region 2 Lenovo
  #***************************************
  Context -Name 'Lenovo File' -Fixture {
    $LenovoExepath = "$env:temp\ThinkPad S1 Yoga 12\JEET73WW\`$01JE000.FL1"
    $UpdateInfo = . Get-MDT_BiosUpdateVersion -String $LenovoExepath -Verbose
    
    It -name 'Returned Version JEET73WW' -test {
      $UpdateInfo.Version | Should be 'JEET73WW'
    }
    It -name 'Returned Arg -s' -test {
      $UpdateInfo.Arguments | Should be '-s'
    }
    It -name 'Returned Exe C:\WINDOWS\temp\winuptp.exe' -test {
      $UpdateInfo.UpdateFile | Should Match 'winuptp'
    }
    It -name 'Returned Type FL1' -test {
      $UpdateInfo.Type | Should be 'FL1'
    }
    It -name 'Returned Manufacturer Lenovo' -test {
      $UpdateInfo.Manufacturer | Should Match 'Lenovo'
    }
  }
  #***************************************
  #endregion 2 Lenovo
  #***************************************
  
  #***************************************
  #region 2 Lenovo
  #***************************************
  Context -Name 'Lenovo WMI' -Fixture {
    $LenovoWMI = 'GNET79WW (2.27 )'
    $UpdateInfo = . Get-MDT_BiosUpdateVersion -String $LenovoWMI -Verbose
    
    It -name "Returned Version $LenovoWMI " -test {
      $UpdateInfo.Version | Should be 'GNET79WW'
    }
    It -name 'Returned Arg -s' -test {
      $UpdateInfo.Arguments | Should be '-s'
    }
    It -name 'Returned Exe winuptp.exe' -test {
      $UpdateInfo.UpdateFile | Should Match 'winuptp'
    }
    It -name 'Returned Type FL1' -test {
      $UpdateInfo.Type | Should be 'FL1'
    }
    It -name 'Returned Manufacturer Lenovo' -test {
      $UpdateInfo.Manufacturer | Should Match 'Lenovo'
    }
  }
  #***************************************
  #endregion 2 Lenovo
  #***************************************
  
  #***************************************
  #region 2 Skylake File
  #***************************************
  Context -Name 'Skylake File' -Fixture {
    $SkylakeFile = 'C:\temp\Invoke-BiosUpdate(w7)\Latitude E7270\Latitude_E7x70_1.4.2.exe'
    $UpdateInfo = . Get-MDT_BiosUpdateVersion -String $SkylakeFile -Verbose
    
    It -name 'Returned Version 1.4.2 ' -test {
      $UpdateInfo.Version | Should be '1.4.2'
    }
    It -name 'Returned Arg -s /s /f /l' -test {
      $UpdateInfo.Arguments | Should Match '/s /f /l=".*1\.4\.2.*log"'
    }
    It -name "Returned Exe $SkylakeFile" -test {
      $UpdateInfo.UpdateFile | Should be $SkylakeFile
    }
    It -name 'Returned Type Skylake\KabyLake' -test {
      $UpdateInfo.Type | Should be 'Skylake\KabyLake'
    }
    It -name 'Returned Manufacturer Dell' -test {
      $UpdateInfo.Manufacturer | Should Match 'Dell'
    }
  }
  #***************************************
  #endregion 2 Skylake File
  #***************************************
 
  #***************************************
  #region 2 Skylake WMI
  #***************************************
  Context -Name 'Skylake WMI' -Fixture {
    $SkylakeWMI = '1.7.3'
    $UpdateInfo = . Get-MDT_BiosUpdateVersion -String $SkylakeWMI -Verbose
    
    It -name "Returned Version $SkylakeWMI " -test {
      $UpdateInfo.Version | Should be $SkylakeWMI
    }
    It -name 'Returned Arg -s /s /f /l' -test {
      $UpdateInfo.Arguments | Should Match '/s /f /l=".*1\.7\.3.*log"'
    }
    It -name "Returned Exe $SkylakeWMI" -test {
      $UpdateInfo.UpdateFile | Should Be $SkylakeWMI
    }
    It -name 'Returned Type Skylake\KabyLake' -test {
      $UpdateInfo.Type | Should be 'Skylake\KabyLake'
    }
    It -name 'Returned Manufacturer Dell' -test {
      $UpdateInfo.Manufacturer | Should Match 'Dell'
    }
  }
  #***************************************
  #endregion 2 Skylake WMI
  #***************************************
  
  
  #***************************************
  #region 2 Dell Legacy File
  #***************************************
  Context -Name 'Dell Legacy File' -Fixture {
    $DellLegacyFile = 'C:\temp\Invoke-BiosUpdate(w7)\Latitude E4310\E4310A14.exe'
    $UpdateInfo = . Get-MDT_BiosUpdateVersion -String $DellLegacyFile -Verbose
    
    It -name 'Returned Version 14 ' -test {
      $UpdateInfo.Version | Should be 14
    }
    It -name 'Returned Arg -s /s /f /l' -test {
      $UpdateInfo.Arguments | Should Match '/s /f /l=".*14.*log"'
    }
    It -name "Returned Exe $DellLegacyFile" -test {
      $UpdateInfo.UpdateFile | Should be $DellLegacyFile
    }
    It -name 'Returned Type Legacy' -test {
      $UpdateInfo.Type | Should be 'Legacy'
    }
    It -name 'Returned Manufacturer Dell' -test {
      $UpdateInfo.Manufacturer | Should Match 'Dell'
    }
  }
  #***************************************
  #endregion 2 Dell Legacy File
  #***************************************
 
  #***************************************
  #region 2 Dell Legacy WMI
  #***************************************
  Context -Name 'Dell Legacy WMI' -Fixture {
    $DellLegacyWMI = 'A15'
    $UpdateInfo = . Get-MDT_BiosUpdateVersion -String $DellLegacyWMI -Verbose
    
    It -name 'Returned Version 15 ' -test {
      $UpdateInfo.Version | Should be 15
    }
    It -name 'Returned Arg -s /s /f /l' -test {
      $UpdateInfo.Arguments | Should Match '/s /f /l=".*15.*log"'
    }
    It -name "Returned Exe $DellLegacyWMI" -test {
      $UpdateInfo.UpdateFile | Should Be $DellLegacyWMI
    }
    It -name 'Returned Type Legacy' -test {
      $UpdateInfo.Type | Should be 'Legacy'
    }
    It -name 'Returned Manufacturer Dell' -test {
      $UpdateInfo.Manufacturer | Should Match 'Dell'
    }
  }
  #***************************************
  #endregion 2 Dell Legacy WMI
  #***************************************
  
  #***************************************
  #region 2 HP Cab File
  #***************************************
  Context -Name 'HP Cab File' -Fixture {
    Out-File -FilePath "$($env:temp)\ver.txt" -InputObject "_ROM_ 68SCF v0F.61 06/11/2015 ROLL_BACK_WARNING`nPATCH_RANGE_FOR_EFI_UPDATE 0x198000 0x100 0xFF" -Force 
    Start-Process -FilePath 'Makecab.exe' -ArgumentList """$($env:temp)\ver.txt"" ver.cab /l ""$env:temp"""
    Start-Sleep -Seconds 2
    $CabFile = "$($env:temp)\ver.cab"
    $UpdateInfo = . Get-MDT_BiosUpdateVersion -String $CabFile -Verbose
    Remove-Item -Path "$($env:temp)\ver.cab" -ErrorAction Ignore
    
    It -name 'Returned Version F.61 ' -test {
      $UpdateInfo.Version | Should be 'F.61'
    }
    It -name 'Returned Arg -s -f"<CabFile>.cab"' -test {
      $UpdateInfo.Arguments | Should be "-s -f""$($env:temp)\ver.cab"""
    }
    It -name 'Returned Exe hpqFlash' -test {
      $UpdateInfo.UpdateFile | Should Match 'hpqFlash'
    }
    It -name 'Returned Type HPCab File' -test {
      $UpdateInfo.Type | Should be 'HPCab File'
    }
    It -name 'Returned Manufacturer HPCab' -test {
      $UpdateInfo.Manufacturer | Should Match 'HPCab'
    }
  }
  #***************************************
  #endregion 2 HP Cab File
  #***************************************
 
  #***************************************
  #region 2 HP Cab WMI
  #***************************************
  Context -Name 'HP Cab WMI' -Fixture {
    $HPCabWMI = '68ICF Ver. F.61'
    $UpdateInfo = . Get-MDT_BiosUpdateVersion -String $HPCabWMI -Verbose
    
    It -name 'Returned Version F.61 ' -test {
      $UpdateInfo.Version | Should be 'F.61'
    }
    It -name 'Returned Arg -s -f"<cabFile>"' -test {
      $UpdateInfo.Arguments | Should Match '-s -f".*CAB"'
    }
    It -name 'Returned Exe hpqFlash' -test {
      $UpdateInfo.UpdateFile | Should Match 'hpqFlash'
    }
    It -name 'Returned Type HPCab WMI' -test {
      $UpdateInfo.Type | Should be 'HPCab WMI'
    }
    It -name 'Returned Manufacturer HPCab	' -test {
      $UpdateInfo.Manufacturer | Should Be 'HPCab'
    }
  }
  #***************************************
  #endregion 2 HP Cab WMI
  #***************************************
  #***************************************
  #region 2 HP Bin File
  #***************************************
  Context -Name 'HP Bin File' -Fixture {
    $CabFile = 'C:\temp\Invoke-BiosUpdate(w7)\HP EliteBook 820 G2\M71_0109.bin'
    $UpdateInfo = . Get-MDT_BiosUpdateVersion -String $CabFile -Verbose
    
    It -name 'Returned Version 01.09 ' -test {
      $UpdateInfo.Version | Should be '01.09'
    }
    It -name 'Returned Arg -s -r -f"<Bin>.bin"' -test {
      $UpdateInfo.Arguments | Should Match '-s -r -f".*.bin"'
    }
    It -name 'Returned Exe HPBIOSUPDREC' -test {
      $UpdateInfo.UpdateFile | Should Match 'HPBIOSUPDREC'
    }
    It -name 'Returned Type HPCab File' -test {
      $UpdateInfo.Type | Should be 'HPBin File'
    }
    It -name 'Returned Manufacturer HPBin' -test {
      $UpdateInfo.Manufacturer | Should Match 'HPBin'
    }
  }
  #***************************************
  #endregion 2 HP Bin File
  #***************************************
 
  #***************************************
  #region 2 HP Bin WMI
  #***************************************
  Context -Name 'HP Bin WMI' -Fixture {
    $HPCabWMI = 'L71 Ver. 01.30'
    $UpdateInfo = . Get-MDT_BiosUpdateVersion -String $HPCabWMI -Verbose
    
    It -name 'Returned Version 1.30 ' -test {
      $UpdateInfo.Version | Should be '01.30'
    }
    It -name 'Returned Arg -s -f"<BinFile>"' -test {
      $UpdateInfo.Arguments | Should Match '-s -r -f".*.bin"'
    }
    It -name 'Returned Exe HPBIOSUPDREC' -test {
      $UpdateInfo.UpdateFile | Should Match 'HPBIOSUPDREC'
    }
    It -name 'Returned Type HPCab WMI' -test {
      $UpdateInfo.Type | Should be 'HPBin WMI'
    }
    It -name 'Returned Manufacturer HPBin	' -test {
      $UpdateInfo.Manufacturer | Should Be 'HPBin'
    }
  }
  #***************************************
  #endregion 2 HP Bin WMI
  #***************************************
  #***************************************
  #region 2 Unknown
  #***************************************
  Context -Name 'Unknown' -Fixture {
    $Unknown = 'test'
    It -name 'Unknown Should be false' -test {
      Get-MDT_BiosUpdateVersion -String $Unknown -Verbose | Should be False
    }
  }
  #***************************************
  #endregion 2 Unknown
  #***************************************
}






#***************************************
#region 2 Compare to Ent
#***************************************
If ($Report)
{ 
  $exclude = @('HPBIOSUPDREC.exe', 'HPQFlash.exe', 'HPBIOSUPDREC64.exe', 'hpqFlash64.exe', 'chklghd2.exe', 'WinFlash64.exe', 'wininfo.exe', 'wininfo64.exe', 'WinFlash32s.exe', 'WINUPTP.EXE', 'WINUPTP64.EXE', 'WinFlash64s.exe', 'WinFlash32.exe', 'chklogo.exe')
  $Include = @('*.exe', '*.bin', '*.cab', '*.FL1')
  $query = "
    select SMBiosBiosVersion0, Count (Distinct bios.resourceid) as systemcount
    from V_GS_PC_Bios bios
    Inner join V_GS_Computer_System CS
    on cs.resourceid = bios.resourceid
    inner join V_GS_Computer_System_Product CSP
    on CSP.resourceid = bios.resourceid
    Where CSP.version0 = '!!Model!!'
    or cs.model0 = '!!Model!!'
    group by SMBiosBiosVersion0
    Order by SMBiosBiosVersion0
  "
  $Path = '\\mspmsbmgmt12.stgent.stgcore.medtronic.com\MDTOSDSrc\Build_Versions\OSD_CM12_W7_16.1\BiosUpdate'
    
  If (-not (Test-Path -Path $Path))
  {
    $OpenFolderDialog = New-Object -TypeName System.Windows.Forms.FolderBrowserDialog
    $null = $OpenFolderDialog.ShowDialog()
    $Path  = $OpenFolderDialog.FileName 
  }
  $Updates = Get-ChildItem -Path $Path 
  $W7 = "$env:UserProfile\Desktop\W7BiosDump.csv"
  $SCCMBios = "$env:UserProfile\Desktop\EntBiosModels.csv"

  Foreach ($U in $Updates)
  {
    $Details = Get-MDT_BiosUpdateVersion -String $U.fullname -Verbose
    $line = [String]::join("`t",$U.fullname,$Details.UpdateFile, $Details.Arguments, $Details.version, $Details.type, $Details.Manufacturer) 
    Add-Content -Path $W7 -Value $line 
  }

  Set-Location -Path c:
  $models = Get-ChildItem -Directory -Path $Path

  Foreach ($model in $models)
  {
    $Updates = Get-ChildItem -Path $model.FullName -Exclude $exclude -Include $Include -Recurse 
    $Versions = @()
    If ($Updates.count -NE $null)
    {
      Foreach ($U in $Updates)
      {
        $Versions += Get-MDT_BiosUpdateVersion -String $U.fullname -Verbose
      }
    }
    Else
    {
      $Versions = Get-MDT_BiosUpdateVersion -String $Updates.fullname -Verbose
    }
  
    $HighestVersion = $Versions|
    Sort-Object -Property version|
    Select-Object -Last 1
    $Dataset = Invoke-Sqlcmd -ServerInstance mspm1bmgmt20 -Database CM_CM0 -Query $query.replace('!!Model!!',$model.name) 
    $LowerThan = ''
    $HigherThan = ''
    $TotalLower = 0
    $TotalEqualorHigher = 0
    Foreach ($Row in $Dataset)
    { 
      If ([STRING]$Row.SMBiosBiosVersion0 -eq '')
      {
        Continue
      }
      $Details = Get-MDT_BiosUpdateVersion -String $Row.SMBiosBiosVersion0 -Verbose
      If ($Details.Version.CompareTo($HighestVersion.Version) -eq -1)
      { 
        $LowerThan += "$($Row.SMBiosBiosVersion0)($($Row.systemcount));"
        $TotalLower += $Row.systemcount
      }
      Else
      {
        $HigherThan += "$($Row.SMBiosBiosVersion0)($($Row.systemcount));"
        $TotalEqualorHigher += $Row.systemcount
      }
    }
    $Columns = @($model, $HighestVersion.Manufacturer, $HighestVersion.Type, $HighestVersion.Version, $Updates.count , $HighestVersion.UpdateFile, $HighestVersion.Arguments, $LowerThan, $TotalLower, $HigherThan, $TotalEqualorHigher)
    $line = [String]::join("`t",$Columns) 
    Add-Content -Path $SCCMBios -Value $line
  }
}
#***************************************
#endregion 2 Compare to Ent
#***************************************


#***************************************
#endregion 1 Main
#***************************************