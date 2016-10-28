Function Start-MDT_DBE
{
  <#
      .Synopsis
      This function is designed to enable bitlocker on a drive regardless of the state of the drive an log the result

      .DESCRIPTION
      Created: Jeff Scripter
      Last Modified: Jeff Scripter

      Version: 
      1.0.0 - 7/29/2016 - Jeff Scripter - Original
      1.0.1 - 8/16/2016 - Jeff Scripter - Updated to fix MDT keys
      1.0.2 - 9/12/2016 - Jeff Scripter - Removed Debug for Verbose
      1.0.3 - 10/11/2016 - Jeff Scripter - Fixed 

      Details: 
        

      Comment:	NA

      Assumptions:	-TPM is enabled, active, and owned;
      -Domain Connectivity
      -partition exists and the OS is generally ready.

      Returns: (Protection Status (0-Not,1-Protected,2-Unavailable))-(ConversionStatus)
      $False - If drive is invalid

      .EXAMPLE
      Start-MDT_DBE
      1-1

      .EXAMPLE
      Start-MDT_DBE -Verbose
      VERBOSE: -C: - Drive Decrypting: 50 %
      VERBOSE: -Return = 0-3
      0-3
  #>

  [CmdletBinding()]
  [OutputType([Boolean])]
  Param
  (
    # Reg Path to Log settings
    [string]$MDTHive = 'HKLM:\SOFTWARE\Wow6432Node\Medtronic',
    
    #Drive Letter To Configure
    [String] $DriveLetter = $Env:Systemdrive
    
  )
    
  Begin
  {
    $component = "$($MyInvocation.InvocationName)-1.0.3"
    If (Get-Command -Name Write-MDT_LogMessage -ErrorAction Ignore) 
    {
      $blnLog = $true
    }
    If (-not (Test-Path -Path $MDTHive))
    {
      $Null = New-Item -Path $MDTHive -ItemType Directory
    }
    If ($DriveLetter -eq $Env:Systemdrive)
    {
      $blnSetKeys = $true
    }
    $Return = $False
    $BDEWMIQuery = "Select * from Win32_EncryptableVolume where DriveLetter='$DriveLetter'"
    $BDEDriveEncrypted = Get-WmiObject -Namespace ROOT\cimv2\Security\MicrosoftVolumeEncryption -Query $BDEWMIQuery
  }
  Process
  {
    If (-Not (Test-Path -Path $DriveLetter))
    {
      Return $False
    }
  
    #get protector data and creates a protector if none exist
    # - this is to get around Manage-dbe not creating protectors by default when running as system.
    $ManageBDE = "$env:systemroot\system32\manage-bde.exe"
    If (-not (Test-Path -Path $ManageBDE))
    {
      $ManageBDE = "$env:systemroot\Sysnative\manage-bde.exe"
    }
    
    $BDEWMIQuery = "Select * from Win32_EncryptableVolume where DriveLetter='$DriveLetter'"
    $BDEDriveEncrypted = Get-WmiObject -Namespace ROOT\cimv2\Security\MicrosoftVolumeEncryption -Query $BDEWMIQuery
    Foreach( $drive in $BDEDriveEncrypted)
    {
      $Protectors = $drive.GetKeyProtectors().VolumeKeyProtectorID
      Foreach($key in $Protectors)
      {
        $keyType = $drive.GetKeyProtectorType($key).KeyProtectorType
        If ($keyType -NE 0 -and $keyType -NE 1)
        {
          Write-MDT_LogMessage -message "Backing up Key Type: $keyType $key" -component $component -type 4
          $BackupParam = "-protectors -adbackup $($drive.DriveLetter) -id $key"
          $output = Invoke-MDT_CMDWithOutput -filepath $ManageBDE -Arguments $BackupParam -loglevel 4
          If ($output[0] -NE 0)
          {
            Write-MDT_LogMessage -message "Failed to Backing up Key Type: $keyType $key" -component $component -type 3
          }
          Else
          {
            Write-MDT_LogMessage -message "Backed up Key Type: $keyType $key" -component $component -type 4
            If ($blnSetKeys)
            {
              Set-ItemProperty -Path "$MDTHive\Encryption" -Name 'BackedUpProtectors' -Value (Get-Date -Format 'yyyyMMdd') -Force -ErrorAction Ignore
            }      
          }                                               
        }
      }
    }
    
    $Summary = "$($BDEDriveEncrypted.GetProtectionStatus().ProtectionStatus)-$($BDEDriveEncrypted.GetConversionStatus().ConversionStatus)"
    If ($blnLog) 
    {
      Write-MDT_LogMessage -message "-Initial Status $($BDEDriveEncrypted.DriveLetter) = $Summary" -component $component -type 4
    }          
    Switch ($BDEDriveEncrypted.GetProtectionStatus().ProtectionStatus){
      $Null 
      {
        # no object
        $Summary = 'Null Object'
        If ($blnLog) 
        {
          Write-MDT_LogMessage -message "-$($BDEDriveEncrypted.DriveLetter) - $Summary" -component $component -type 4
        }    
        If ($blnSetKeys)
        {
          Set-ItemProperty -Path "$MDTHive\Encryption" -Name 'BitlockerConversionStatus' -Value $Summary -Force -ErrorAction Ignore
        }
      }
      0 
      {
        # Disabled /suspended
        Switch ($BDEDriveEncrypted.GetConversionStatus().ConversionStatus){
          0
          { 
            $Summary = 'Decrypted'
            If ($blnLog) 
            {
              Write-MDT_LogMessage -message "-$($BDEDriveEncrypted.DriveLetter) - $Summary" -component $component -type 4
            }
            $EncryptParam = "-on $DriveLetter -RecoveryPassword -SkipHardwareTest"
            $output = Invoke-MDT_CMDWithOutput -filepath $ManageBDE -Arguments $EncryptParam -loglevel 4
            If ($blnSetKeys)
            {
              Set-ItemProperty -Path "$MDTHive\Encryption" -Name 'BitlockerConversionStatus' -Value $Summary -Force -ErrorAction Ignore
            }
          }

          1
          { 
            $Summary = 'Unprotected'
            If ($blnLog) 
            {
              Write-MDT_LogMessage -message "-$($BDEDriveEncrypted.DriveLetter) - $Summary" -component $component -type 4
            }
            If ($Protectors){
              $EnableParams = "-Protectors -enable $DriveLetter"
            }Else{
              $EnableParams = "-protectors -add $DriveLetter -RecoveryPassword"
            }
            $output = Invoke-MDT_CMDWithOutput -filepath $ManageBDE -Arguments $Enables -loglevel 4
            If ($blnSetKeys)
            {
              Set-ItemProperty -Path "$MDTHive\Encryption" -Name 'BitlockerConversionStatus' -Value '$Summary' -Force -ErrorAction Ignore
            }
          }

          2
          { 
            $Summary = "Encryption:$($BDEDriveEncrypted.GetConversionStatus().EncryptionPercentage) %"
            If ($blnLog) 
            {
              Write-MDT_LogMessage -message "-$($BDEDriveEncrypted.DriveLetter) - $Summary" -component $component -type 4
            }
            If ($blnSetKeys)
            {
              Set-ItemProperty -Path "$MDTHive\Encryption" -Name 'BitlockerConversionStatus' -Value $Summary -Force -ErrorAction Ignore
            }
          }

          3
          {
            $Summary = "Drive Decrypting: $($BDEDriveEncrypted.GetConversionStatus().EncryptionPercentage) %"
            If ($blnLog) 
            {
              Write-MDT_LogMessage -message "-$($BDEDriveEncrypted.DriveLetter) - $Summary" -component $component -type 4
            }
            $EncryptParam = "-on $DriveLetter -RecoveryPassword -SkipHardwareTest"
            $output = Invoke-MDT_CMDWithOutput -filepath $ManageBDE -Arguments $EncryptParam -loglevel 4
            If ($blnSetKeys)
            {
              Set-ItemProperty -Path "$MDTHive\Encryption" -Name 'BitlockerConversionStatus' -Value $Summary -Force -ErrorAction Ignore
            }
          }

          4
          {
            $Summary = 'Encryption Paused'
            If ($blnLog) 
            {
              Write-MDT_LogMessage -message "-$($BDEDriveEncrypted.DriveLetter) - $Summary" -component $component -type 4
            }
            $ResumeParam = "-resume $DriveLetter"
            $output = Invoke-MDT_CMDWithOutput -filepath $ManageBDE -Arguments $ResumeParam -loglevel 4
            If ($blnSetKeys)
            {
              Set-ItemProperty -Path "$MDTHive\Encryption" -Name 'BitlockerConversionStatus' -Value $Summary -Force -ErrorAction Ignore
            }
          }

          5
          {
            $Summary = 'Decryption Paused'
            If ($blnLog) 
            {
              Write-MDT_LogMessage -message "-$($BDEDriveEncrypted.DriveLetter) - $Summary" -component $component -type 4
            }
            $EncryptParam = "-on $DriveLetter -RecoveryPassword -SkipHardwareTest"
            $output = Invoke-MDT_CMDWithOutput -filepath $ManageBDE -Arguments $EncryptParam -loglevel 4
            If ($blnSetKeys)
            {
              Set-ItemProperty -Path "$MDTHive\Encryption" -Name 'BitlockerConversionStatus' -Value $Summary -Force -ErrorAction Ignore
            }
          }
          Default
          {
            $Summary = 'Off'
            If ($blnLog) 
            {
              Write-MDT_LogMessage -message "-$($BDEDriveEncrypted.DriveLetter) - $Summary" -component $component -type 4
            }
            If ($blnSetKeys)
            {
              Set-ItemProperty -Path "$MDTHive\Encryption" -Name 'BitlockerConversionStatus' -Value $Summary -Force -ErrorAction Ignore
            }
          }
        }
      }

      1 
      {
        #Status Enabled
        $Summary = 'Fully Encrypted'
        If ($blnLog) 
        {
          Write-MDT_LogMessage -message "-$($BDEDriveEncrypted.DriveLetter) - $Summary" -component $component -type 4
        }
        If ($blnSetKeys)
        {
          Set-ItemProperty -Path "$MDTHive\Encryption" -Name 'BitlockerConversionStatus' -Value $Summary -Force -ErrorAction Ignore
        }
      }

      2 
      {
        # unknown status
        $Summary = 'Unknown'
        If ($blnLog) 
        {
          Write-MDT_LogMessage -message "-$($BDEDriveEncrypted.DriveLetter) - $Summary" -component $component -type 4
        }
        If ($blnSetKeys)
        {
          Set-ItemProperty -Path "$MDTHive\Encryption" -Name 'BitlockerConversionStatus' -Value 'Unknown' -Force -ErrorAction Ignore
        }
      }

      Default 
      {
        # undocumented status
        $Summary = 'Undocumented'
        If ($blnLog) 
        {
          Write-MDT_LogMessage -message "-$($BDEDriveEncrypted.DriveLetter) - $Summary" -component $component -type 4
        }
        If ($blnSetKeys)
        {
          Set-ItemProperty -Path "$MDTHive\Encryption" -Name 'BitlockerConversionStatus' -Value 'Undocumented' -Force -ErrorAction Ignore
        }
      }
    }  
    
    #Evaluate afterwards
    $Return = "$($BDEDriveEncrypted.GetProtectionStatus().ProtectionStatus)-$($BDEDriveEncrypted.GetConversionStatus().ConversionStatus)"
    Switch ($BDEDriveEncrypted.GetProtectionStatus().ProtectionStatus){
      $Null 
      {
        # no object
        $Summary = 'Null Object'
        If ($blnLog) 
        {
          Write-MDT_LogMessage -message "-$($BDEDriveEncrypted.DriveLetter) - $Summary" -component $component -type 4
        }    
        If ($blnSetKeys)
        {
          Set-ItemProperty -Path "$MDTHive\Encryption" -Name 'BitlockerConversionStatus' -Value $Summary -Force -ErrorAction Ignore
        }
      }
      0 
      {
        # Disabled /suspended
        Switch ($BDEDriveEncrypted.GetConversionStatus().ConversionStatus){
          0
          { 
            $Summary = 'Decrypted'
            If ($blnLog) 
            {
              Write-MDT_LogMessage -message "-$($BDEDriveEncrypted.DriveLetter) - $Summary" -component $component -type 4
            }
            If ($blnSetKeys)
            {
              Set-ItemProperty -Path "$MDTHive\Encryption" -Name 'BitlockerConversionStatus' -Value $Summary -Force -ErrorAction Ignore
            }
          }

          1
          { 
            $Summary = 'Unprotected'
            If ($blnLog) 
            {
              Write-MDT_LogMessage -message "-$($BDEDriveEncrypted.DriveLetter) - $Summary" -component $component -type 4
            }
            If ($blnSetKeys)
            {
              Set-ItemProperty -Path "$MDTHive\Encryption" -Name 'BitlockerConversionStatus' -Value '$Summary' -Force -ErrorAction Ignore
            }
          }

          2
          { 
            $Summary = "Encryption:$($BDEDriveEncrypted.GetConversionStatus().EncryptionPercentage) %"
            If ($blnLog) 
            {
              Write-MDT_LogMessage -message "-$($BDEDriveEncrypted.DriveLetter) - $Summary" -component $component -type 4
            }
            If ($blnSetKeys)
            {
              Set-ItemProperty -Path "$MDTHive\Encryption" -Name 'BitlockerConversionStatus' -Value $Summary -Force -ErrorAction Ignore
            }
          }

          3
          {
            $Summary = "Drive Decrypting: $($BDEDriveEncrypted.GetConversionStatus().EncryptionPercentage) %"
            If ($blnLog) 
            {
              Write-MDT_LogMessage -message "-$($BDEDriveEncrypted.DriveLetter) - $Summary" -component $component -type 4
            }
            If ($blnSetKeys)
            {
              Set-ItemProperty -Path "$MDTHive\Encryption" -Name 'BitlockerConversionStatus' -Value $Summary -Force -ErrorAction Ignore
            }
          }

          4
          {
            $Summary = 'Encryption Paused'
            If ($blnLog) 
            {
              Write-MDT_LogMessage -message "-$($BDEDriveEncrypted.DriveLetter) - $Summary" -component $component -type 4
            }
            If ($blnSetKeys)
            {
              Set-ItemProperty -Path "$MDTHive\Encryption" -Name 'BitlockerConversionStatus' -Value $Summary -Force -ErrorAction Ignore
            }
          }

          5
          {
            $Summary = 'Decryption Paused'
            If ($blnLog) 
            {
              Write-MDT_LogMessage -message "-$($BDEDriveEncrypted.DriveLetter) - $Summary" -component $component -type 4
            }
            If ($blnSetKeys)
            {
              Set-ItemProperty -Path "$MDTHive\Encryption" -Name 'BitlockerConversionStatus' -Value $Summary -Force -ErrorAction Ignore
            }
          }
          Default
          {
            $Summary = 'Off'
            If ($blnLog) 
            {
              Write-MDT_LogMessage -message "-$($BDEDriveEncrypted.DriveLetter) - $Summary" -component $component -type 4
            }
            If ($blnSetKeys)
            {
              Set-ItemProperty -Path "$MDTHive\Encryption" -Name 'BitlockerConversionStatus' -Value $Summary -Force -ErrorAction Ignore
            }
          }
        }
      }

      1 
      {
        #Status Enabled
        $Summary = 'Fully Encrypted'
        If ($blnLog) 
        {
          Write-MDT_LogMessage -message "-$($BDEDriveEncrypted.DriveLetter) - $Summary" -component $component -type 4
        }
        If ($blnSetKeys)
        {
          Set-ItemProperty -Path "$MDTHive\Encryption" -Name 'BitlockerConversionStatus' -Value $Summary -Force -ErrorAction Ignore
        }
      }

      2 
      {
        # unknown status
        $Summary = 'Unknown'
        If ($blnLog) 
        {
          Write-MDT_LogMessage -message "-$($BDEDriveEncrypted.DriveLetter) - $Summary" -component $component -type 4
        }
        If ($blnSetKeys)
        {
          Set-ItemProperty -Path "$MDTHive\Encryption" -Name 'BitlockerConversionStatus' -Value 'Unknown' -Force -ErrorAction Ignore
        }
      }

      Default 
      {
        # undocumented status
        $Summary = 'Undocumented'
        If ($blnLog) 
        {
          Write-MDT_LogMessage -message "-$($BDEDriveEncrypted.DriveLetter) - $Summary" -component $component -type 4
        }
        If ($blnSetKeys)
        {
          Set-ItemProperty -Path "$MDTHive\Encryption" -Name 'BitlockerConversionStatus' -Value 'Undocumented' -Force -ErrorAction Ignore
        }
      }
    }  

  }
  End
  {
    If ($blnLog) 
    {
      If ($blnSetKeys)
      {
        Set-ItemProperty -Path "$MDTHive\Encryption" -Name 'BitlockerStatus' -Value ([string]($BDEDriveEncrypted.GetProtectionStatus().ProtectionStatus -eq 1)) -Force -ErrorAction Ignore
      }    
      Write-MDT_LogMessage -message "-Return = $Return" -component $component -type 4 
    }
    Return $Return
  }
}

Start-MDT_DBE -DriveLetter 'c:'  -Verbose 
Pause
Start-MDT_DBE


