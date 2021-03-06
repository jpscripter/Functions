﻿#requires -Version 1.0
Function Get-MDT_DBEStatus 
{
  <#
      .Synopsis
        

      .DESCRIPTION
      Created: Jeff Scripter
      Last Modified: Jeff Scripter

      Version:  1.0.1 - 8/16/2016 - Jeff Scripter - Updated to fix MDT keys
      1.0.0 - 7/29/2016 - Jeff Scripter - Original
   
      Details: 
        

      Comment:	NA

      Assumptions:	

      Returns: $True  - 
      $False -

      .EXAMPLE
      Get-MDT_DBEStatus
      1-1
      .EXAMPLE
      Get-MDT_DBEStatus -Verbose
      VERBOSE: -C: - Drive Decrypting: 50 %
      VERBOSE: -Return = 0-3
      0-3
  #>

  [OutputType([bool])]
  Param
  (
    # Reg Path to Log settings
    [string]$MDTHive = 'HKLM:\SOFTWARE\Wow6432Node\Medtronic',
    
    #Drive Letter To Configure
    [String] $DriveLetter = $Env:Systemdrive 
      
  )
    
  Begin
  {
    $component = "$($MyInvocation.InvocationName)-1.0.1"
    If (Get-Command -Name Write-MDT_LogMessage -ErrorAction Ignore) 
    {
      $blnLog = $true
    }
    $Return = $False
    If (-not (Test-Path -Path $MDTHive))
    {
      $Null = New-Item -Path $MDTHive -ItemType Directory
    }
    If ($DriveLetter -eq $Env:Systemdrive)
    {
      $blnSetKeys = $true
    }
    $BDEWMIQuery = "Select * from Win32_EncryptableVolume where DriveLetter='$DriveLetter'"
    $BDEDriveEncrypted = Get-WmiObject -Namespace ROOT\cimv2\Security\MicrosoftVolumeEncryption -Query $BDEWMIQuery
  }
  Process
  {
    #***************************************
    #region Test protectors
    #***************************************
    #get protector data and creates a protector if none exist
    # - this is to get around Manage-dbe not creating protectors by default when running as system.
    $ManageBDE = "$env:systemroot\system32\manage-bde.exe"
    If (-not (Test-Path -Path $ManageBDE))
    {
      $ManageBDE = "$env:systemroot\Sysnative\manage-bde.exe"
    }
    $protectorParam = "-protectors -get $Env:Systemdrive"
    $output = Invoke-MDT_CMDWithOutput -filepath $ManageBDE -Arguments $protectorParam -loglevel debug
    If (-not ($output[1] -match 'Password:'))
    {
      If ($blnLog) 
      {
        Write-MDT_LogMessage -message "-No Key Protectors $($BDEDriveEncrypted.DriveLetter)." -component $component -type 2
      }
    }
    Else
    {
      If ($blnLog) 
      {
        Write-MDT_LogMessage -message "-Key Protectors $($BDEDriveEncrypted.DriveLetter) are present." -component $component -type 4
      }
    }
    #***************************************
    #endregion Test protectors
    #***************************************
      
    #***************************************
    #region Get BDE Status
    #***************************************
    If (-Not (Test-Path -Path $DriveLetter))
    {
      Return $False
    }
    
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
    #***************************************
    #endregion Get BDE Status
    #***************************************
  }
  End
  {
    If ($blnLog) 
    {
      Write-MDT_LogMessage -message "-Return = $Return" -component $component -type 4
    }
    If ($blnSetKeys)
    {
      Set-ItemProperty -Path "$MDTHive\Encryption" -Name 'BitlockerStatus' -Value ([string]($BDEDriveEncrypted.GetProtectionStatus().ProtectionStatus -eq 1)) -Force -ErrorAction Ignore
    }
    Return $Return
  }
}

Get-MDT_DBEStatus -verbose 