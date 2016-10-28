#requires -Version 2.0
Function Get-MDT_BiosUpdateVersion
{
  <#
      .Synopsis
      Used to identify the different bios versions from either WMI format or File path.

      .DESCRIPTION
      Author:    Jeff Scripter
      Modified:  Jeff Scripter

      Purpose: 
      This is used to extract version information from the confusing formatting of different Manufacturers SMbios version. Then we can use camparison operators. We could then use this to analyze systems in the bios update script, Bios download script, and Project impact from CM data.

      Return:
      Object = Bios Version, Manufacturer, Type, Update Exe, Update Parameters

      Overview:
      $Manufacturer = 'Custom'
      ([regex]::match($String,'(?i)[A|P][0-9]{2}').Length -ne 0) 
      $BIOSVersion = [regex]::match($String,'(?i)[A|P][0-9]{2}').Value
      $Manufacturer = 'Dell(Legacy)'
      ([regex]::match($String,'(?i)F\.[0-9]{2}').Length -ne 0) 
      $BIOSVersion = [regex]::match($String,'(?i)F\.[0-9]{2}').value
      $Manufacturer = 'HP(Cab)'
      ([regex]::match($String,'(?i)\w{4,5}\d{1,2}(W{1,2}|AUS)').Length -ne 0) 
      $BIOSVersion = [regex]::match($String,'(?i)\w{4,5}\d{1,2}(W{1,2}|AUS)').value
      $Manufacturer = 'Lenovo'
      ([regex]::match($String,'[0-9]{1,3}(\.)[0-9]{1,4}(\.)[0-9]{1,4}').Length -ne 0 ) 
      $BIOSVersion = [regex]::match($String,'[0-9]{1,3}(\.)[0-9]{1,4}(\.)[0-9]{1,4}').Value
      $Manufacturer = 'Dell(Skylake)'
      ([regex]::match($String,'[0-9]{1,2}(\.[0-9]{1,2}){1,2}').Length -ne 0) 
      $BIOSVersion = [regex]::match($String,"[0-9]{1,2}(\.[0-9]{1,2}){1,2}").Value
      $Manufacturer = 'HP(BIN)'
      ([regex]::match($String,'[0-9]{4}').Length -ne 0) 
      $BIOSVersion = [regex]::match($String,"[0-9]{4}").Value.Insert(2,'.')
      $Manufacturer = 'HP(BIN File)'


      .NOTES
      Comment:	
        

      Assumptions:	
      1) we are dealing with HP, Lenovo or Dell bios versions. 
      2) HP, Lenovo, Dell systems havent changed their Versioning standards since October 2016
    
      Changes:
      2016_10_01 - Original - Jeff Scripter - Original


      Test Script: 
      1) 'Custom'      - If there is an accompanying File
      2) 'Dell(Legacy)' - A## format for Older Dells
      3) 'HP(Cab)'      - Extract Cab File for Ver.txt
      4) 'Lenovo'       - Lenovo's weird format
      5) 'Dell(Skylake)'- #.#.# format for Dell
      6) 'HP(BIN)'      - ##.## format for HP
      7) 'HP(BIN File)' - #### - Converted to ##.## format for HP

      .EXAMPLE

  #>

  [CmdletBinding()]
  [OutputType([Boolean])]
  Param
  (
    #File path or WMI SMBios Version string.
    [String] $String 

  )
    
  Begin
  {
    $component = "$($MyInvocation.InvocationName)-1.0.0"
    If (Get-Command -Name Write-MDT_LogMessage -ErrorAction Ignore) 
    {
      $blnLog = $true
    }
    $Return = $False
    $DateTime = Get-Date -Format 'yyyyMMddhhmmss'
    $OSArchitecture = (Get-WMIObject Win32_OperatingSystem).OSArchitecture
  }
  
  Process
  {
    $BIOSVersion = ''
    $Manufacturer = ''
    $Type = ''
    $EXEFile = ''
    $StandardArgs = ''
      
    Switch ($true) { 
      #Custom 
      ((Test-Path -Path ($String.tolower().replace('.exe','.txt'))) -and ($String -imatch '\.exe')) 
      {     
        If ($blnLog) 
        {
          Write-MDT_LogMessage -message 'Custom Version format.'  -component $component -type 4
          Write-MDT_LogMessage -message "Retrieving from $($String.tolower().replace('.exe','.txt'))"  -component $component -type 4
        }
        $BiosInfo = Get-Content -Path $String.replace('.exe','.txt')
        $BIOSVersion = $BiosInfo[0]
        $EXEFile = $String
        $StandardArgs = $BiosInfo[1]
        $Manufacturer = 'Custom'
        $Type = 'Custom'
        Break
      }

      #Lenovo
      ([regex]::match($String,'(?i)\w{4,5}\d{1,2}(W{1,2}|AUS)').Length -ne 0) 
      { 
        If ($blnLog) 
        {
          Write-MDT_LogMessage -message 'Lenovo system. Using Bios'  -component $component -type 4
        }
        $BIOSVersion = [regex]::match($String,'(?i)\w{4,5}\d{1,2}(W{1,2}|AUS)').value
        $EXEFile = "$($env:WINDIR)\temp\winuptp.exe"
        $StandardArgs = '-s'
        $Manufacturer = 'Lenovo'
        $Type = 'FL1'
        Break
      }
      
      #Dell Pre-Skylake
      ([regex]::match($String.split('\')[-1],'(?i)[A|P][0-9]{2}').Length -ne 0) 
      {
        If ($blnLog) 
        {
          Write-MDT_LogMessage -message 'DUP Dell'  -component $component -type 4
        }
        $BIOSVersion = [regex]::match($String.split('\')[-1],'(?i)[A|P][0-9]{2}').Value.remove(0,1)
        $EXEFile = $String
        $StandardArgs = "/s /f /l=""$($env:WINDIR)\temp\$String-$DateTime.log"""
        $Manufacturer = 'Dell'
        $Type = 'Legacy'
        Break
      }
       
      #HP cab version format
      ($String -match '\.cab') 
      {
        If ($blnLog) 
        {
          Write-MDT_LogMessage -message 'HP CAB File'  -component $component -type 4
        }
        $shell = New-Object -ComObject shell.application
        $vertxt = $shell.NameSpace($String).items()|Where-Object -FilterScript {
          $_.path -imatch 'ver.txt'
        }
        If (Test-Path -Path "$($env:TEMP)\ver.txt") 
        {
          Remove-Item -Path "$($env:TEMP)\ver.txt" -Force
        }
        $shell.NameSpace($env:TEMP).copyhere($vertxt)
        $verContent = Get-Content -Path "$($env:TEMP)\ver.txt"
        $BIOSVersion = [regex]::match($verContent,'(?i)F\.[0-9]{2}').value
        IF ($OSArchitecture -eq '64-bit')
        {
          $EXEFile = "$($env:WINDIR)\temp\hpqFlash64.exe"
        }
        Else
        {
          $EXEFile = "$($env:WINDIR)\temp\hpqFlash.exe"
        }
        $StandardArgs = "-s -f""$String"""
        $Manufacturer = 'HPCab'
        $Type = 'HPCab File'
        Break
      }
      #HP cab version format
      ([regex]::match($String.split('\')[-1],'(?i)F\.[0-9]{2}').Length -ne 0) 
      {
        If ($blnLog) 
        {
          Write-MDT_LogMessage -message 'HP CAB WMI'  -component $component -type 4
        }
        $BIOSVersion = [regex]::match($String.split('\')[-1],'(?i)F\.[0-9]{2}').value
        IF ($OSArchitecture -eq '64-bit')
        {
          $EXEFile = "$($env:WINDIR)\temp\hpqFlash64.exe"
        }
        Else
        {
          $EXEFile = "$($env:WINDIR)\temp\hpqFlash.exe"
        }
        $StandardArgs = '-s -f""<CabFile>.cab""'
        $Manufacturer = 'HPCab'
        $Type = 'HPCab WMI'
        Break
      }
      
      #Dell Skylake
      ([regex]::match($String.split('\')[-1],'[0-9]{1,3}(\.)[0-9]{1,4}(\.)[0-9]{1,4}').Length -ne 0 ) 
      { 
        If ($blnLog) 
        {
          Write-MDT_LogMessage -message 'Skylake Dell Version found.'  -component $component -type 4
        }
        $BIOSVersion = [regex]::match($String.split('\')[-1],'[0-9]{1,3}(\.)[0-9]{1,4}(\.)[0-9]{1,4}').Value
        $StandardArgs = "/s /f /l=""$($env:WINDIR)\temp\$BIOSVersion-$DateTime.log"""
        $EXEFile = $String
        $Manufacturer = 'Dell'
        $Type = 'Skylake\KabyLake'
        Break
      }
      
      #HP Bin WMI format
      ([regex]::match($String.split('\')[-1],'[0-9]{1,2}(\.[0-9]{1,2}){1,2}').Length -ne 0) 
      {
        If ($blnLog) 
        {
          Write-MDT_LogMessage -message 'HP Bin Files.'  -component $component -type 4
        }
        $BIOSVersion = [regex]::match($String.split('\')[-1],'[0-9]{1,2}(\.[0-9]{1,2}){1,2}').Value
        IF ($OSArchitecture -eq '64-bit')
        {
          $EXEFile = "$($env:WINDIR)\temp\HPBIOSUPDREC64.exe"
        }
        Else
        {
          $EXEFile = "$($env:WINDIR)\temp\HPBIOSUPDREC.exe"
        }
        $StandardArgs = '-s -r -f"BinFilePath.bin"'
        $Manufacturer = 'HPBin'
        $Type = 'HPBIN WMI'
        Break
      }
       
      #HP Bin file format
      ([regex]::match($String.split('\')[-1],'[0-9]{4}').Length -ne 0) 
      {
        If ($blnLog) 
        {
          Write-MDT_LogMessage -message 'HP Bin Files.'  -component $component -type 4
        }
        $BIOSVersion = [regex]::match($String.split('\')[-1],'[0-9]{4}').Value.Insert(2,'.')
        IF ($OSArchitecture -eq '64-bit')
        {
          $EXEFile = "$($env:WINDIR)\temp\HPBIOSUPDREC64.exe"
        }
        Else
        {
          $EXEFile = "$($env:WINDIR)\temp\HPBIOSUPDREC.exe"
        }
        $StandardArgs = "-s -r -f""$String"""
        $Manufacturer = 'HPBin'
        $Type = 'HPBin File'
        Break
      }
      
      # error
      Default 
      {
        If ($blnLog) 
        {
          Write-MDT_LogMessage -message 'Error: Identifying Version for Target bios.'  -component $component -type 3
        }
      }
    }
    
    If ($BIOSVersion){
      $Properties = @{
        Version      = $BIOSVersion
        Manufacturer = $Manufacturer
        type         = $Type
        UpdateFile   = $EXEFile
        Arguments    = $StandardArgs
      }
      $Return = New-Object -TypeName psobject -Property $Properties
    }
  }
  
  End
  {
    If ($blnLog) 
    {
      Write-MDT_LogMessage -message "-Return = ($($Return.type))  $($Return.Version)" -component $component -type 4
    }
    Return $Return
  }
}
