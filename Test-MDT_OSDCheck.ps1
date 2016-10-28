#requires -Version 2
Function Test-MDT_OSDCheck
{
  <#
      .Synopsis
      Runs a preflight check for OSD task sequence

      .DESCRIPTION
      Created: was requested by Bob Underwood for Windows 10 project

      Version:  1.0.1 - Jeff Scripter 7/28/2016 - added logging
      1.0.0 - Patrick Davis- Original
   
      Details: 
      Will check registry service add/remove programs or file and return TRUE if there, FALSE if not there

      Assumptions:
      we have read permissions to the location and log-MDT_message is loaded as well

  #>
  param ( 
    [Parameter(Mandatory = $true)]
    [string]$path,
    [Parameter(Mandatory = $true)]
    [ValidateSet('File','reg','Arp','Service')]
    [string]$type,
    [string]$PropertyName = $Null, 
    [String]$PropertyValue = $Null,
    [switch]$NonverboseLogging
  )
  Begin
  {
    $component = "$($MyInvocation.InvocationName)-1.0.1"
    If ($NonverboseLogging)
    {
      $loggingLevel = 1
    }
    Else
    {
      $loggingLevel = 4
    }
    If (Get-Command -Name Write-MDT_LogMessage -ErrorAction Ignore) 
    {
      $blnLog = $true
    }
    $Return = $False
  }

  Process
  {
    switch ($type){
      ('Arp')
      {
        $Arp = Test-Path -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$path"
        $Arp32 = Test-Path -Path "HKLM:\SOFTWARE\wow6432node\Microsoft\Windows\CurrentVersion\Uninstall\$path"
        If ($Arp) 
        {
          $Item = Get-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$path" 
          If($Item.GetValue($PropertyName) -Like $PropertyValue -or  $PropertyName -eq '')
          {
            $Return = $true
            If (Test-Path -Path variable:Global:LogFile) 
            {
              If ($blnLog) 
              {
                Write-Verbose -Message "$(Write-MDT_LogMessage -message "-ARP found: HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$path" -component $component -type $loggingLevel)"
              }
            }
          }
        }
        ElseIf ($Arp32) 
        {
          $Item = Get-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$path" 
          If($Item.GetValue($PropertyName) -Like $PropertyValue -or  $PropertyName -eq '')
          {
            $Return = $true
            If (Test-Path -Path variable:Global:LogFile) 
            {
              If ($blnLog) 
              {
                Write-Verbose -Message "$(Write-MDT_LogMessage -message "-ARP32 found: HKLM:\SOFTWARE\wow6432node\Microsoft\Windows\CurrentVersion\Uninstall\$path" -component $component -type $loggingLevel)"
              }
            }
          }
        }
      }
      ('Reg')
      {
        $Reg = Test-Path -Path $path
        $Reg32 = Test-Path -Path $path.replace('SOFTWARE','SOFTWARE\wow6432node')
        If ($Reg) 
        {
          $Item = Get-Item -Path $path
          If($Item.GetValue($PropertyName) -Like $PropertyValue -or  $PropertyName -eq '')
          {
            $Return = $true
            If (Test-Path -Path variable:Global:LogFile) 
            {
              If ($blnLog) 
              {
                Write-Verbose -Message "$(Write-MDT_LogMessage -message "-REG found: $path" -component $component -type $loggingLevel)"
              }
            }
          }
        }
        If ($Reg32) 
        {
          $Item = Get-Item -Path $path.replace('SOFTWARE','SOFTWARE\wow6432node')
          If($Item.GetValue($PropertyName) -Like $PropertyValue -or $PropertyName -eq '')
          {
            $Return = $true
            If (Test-Path -Path variable:Global:LogFile) 
            {
              If ($blnLog) 
              {
                Write-Verbose -Message "$(Write-MDT_LogMessage -message "-REG32 Found: $($path.replace('SOFTWARE','SOFTWARE\wow6432node'))" -component $component -type $loggingLevel)"
              }
            }
          }
        }
      }
      ('Service')
      {
        $Service = Test-Path -Path "HKLM:\SYSTEM\CurrentControlSet\Services\$path"
        If ($Service) 
        {
          $Item = Get-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Services\$path"
          If($Item.GetValue($PropertyName) -Like $PropertyValue -or  $PropertyName -eq '')
          {
            $Return = $true
            If (Test-Path -Path variable:Global:LogFile) 
            {
              If ($blnLog) 
              {
                Write-Verbose -Message "$(Write-MDT_LogMessage -message "-Service found: HKLM:\SYSTEM\CurrentControlSet\Services\$path" -component $component -type $loggingLevel)"
              }
            }
          }
        }
      }
      ('File')
      {
        $Filetype = Test-Path -Path $path
        $Filetype32 = (Test-Path -Path $path.replace('System32','sysnative')) -and ($path -NE $path.replace('System32','sysnative'))
        If ($Filetype) 
        {
          $Item = Get-Item -Path $path
          IF ($PropertyName -eq '')
          {
            $Return = $true                  
            If (Test-Path -Path variable:Global:LogFile) 
            {
              If ($blnLog) 
              {
                Write-Verbose -Message "$(Write-MDT_LogMessage -message "-File Path found: $path" -component $component -type $loggingLevel)"
              }
            }
          }
          Else
          {
            If(([version]($Item.versioninfo.$PropertyName.replace(',','.').replace(' ',''))).CompareTo([version]$PropertyValue) -NE 1)
            {
              $Return = $true                  
              If (Test-Path -Path variable:Global:LogFile) 
              {
                If ($blnLog) 
                {
                  Write-Verbose -Message "$(Write-MDT_LogMessage -message "-Path found: $path" -component $component -type $loggingLevel)"
                }
              }
            }
          }
          If ($Filetype32) 
          {
            If ( $PropertyName -eq '')
            {
              $Return = $true
              If (Test-Path -Path variable:Global:LogFile) 
              {
                If ($blnLog) 
                {
                  Write-Verbose -Message "$(Write-MDT_LogMessage -message "-Sysnative Path found: $($path.replace('System32','sysnative'))" -component $component -type $loggingLevel)"
                }
              }
            }
            Else
            {
              $Item = Get-Item -Path $path.replace('System32','sysnative')
              If(([version]($Item.versioninfo.$PropertyName.replace(',','.').replace(' ',''))).CompareTo([version]$PropertyValue) -NE 1)
              {
                $Return = $true
                If (Test-Path -Path variable:Global:LogFile) 
                {
                  If ($blnLog) 
                  {
                    Write-Verbose -Message "$(Write-MDT_LogMessage -message "-Sysnative Path found: $($path.replace('System32','sysnative'))" -component $component -type $loggingLevel)"
                  }
                }
              }
            }
          }
        }
      }
    }
  }
  END{
    If ($blnLog) 
    {
      Write-Verbose -Message "$(Write-MDT_LogMessage -message "-Return - $Return" -component $component -type $loggingLevel)"
    }
    Return $Return 
  }
}

 
. Test-MDT_OSDCheck -type reg -path 'HKLM:\SOFTWARE\Microsoft\PowerShell\3\PowerShellEngine' -NonverboseLogging -verbose
Test-MDT_OSDCheck -type reg -path 'HKLM:\SOFTWARE\Microsoft\PowerShell\3\PowerShellEngine' -PropertyName 'PSCompatibleVersion' -PropertyValue '4.0' -NonverboseLogging
Test-MDT_OSDCheck -type reg -path 'HKLM:\SOFTWARE\Microsoft\PowerShell\3\PowerShellEngine' -PropertyName 'PSCompatibleVersion' -PropertyValue '*5.0*' -NonverboseLogging
Test-MDT_OSDCheck -type File -path 'C:\Program Files\DellTPad\ApMouCpl.dll'  -NonverboseLogging
Test-MDT_OSDCheck -type File -path 'C:\Program Files\DellTPad\ApMouCpl.dll' -PropertyName fileversion -PropertyValue '8.1.1.33' 
Test-MDT_OSDCheck -type File -path 'C:\Program Files\DellTPad\ApMouCpl.dll' -PropertyName fileversion -PropertyValue '8.1.1.0' -NonverboseLogging -verbose