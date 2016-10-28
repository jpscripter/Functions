Function Set-MDT_Reboot
{
  <#
      .Synopsis
      Configures a reboot hook to restart a script or process after a reboot

      .DESCRIPTION
      Created: Jeff Scripter

      Version:  1.0.2 - 2016_08_14 - Jeff Scripter - Added logging and fixed task sequence clear.
      1.0.1 - 2016_08_03 - Jeff Scripter - Added logging and fixed task sequence clear.
      1.0.0 - Jeff Scripter - Original
   
      Details: 
      In the PE, a variable is created and set to true. The task sequence would then need to catch that variable and reboot.

      Otherwise, we set the Setupkeys in HKLM:\SYSTEM\Setup and kick off the reboot.

      Assumptions:
      Microsoft.SMS.TSEnvironment is unregistered at the end of the task sequence.


      .EXAMPLE
      Set-Reboot -CmdPath $powershell -CmdArg "-command $ScriptLocation\$scriptName -verbose" -WinPE $WinPEVariable

      .EXAMPLE
      Set-Reboot -CmdPath $SQLInstaller -CmdArg $SqlArgs

      .EXAMPLE
      Set-Reboot -Clear

  #>
  [CmdletBinding()]
  [OutputType([int])]
  Param
  (
    # Flag to use winpe flag instead of SetupKey
    [Parameter(Mandatory = $False,
        ValueFromPipelineByPropertyName = $true,
        ParameterSetName = 'Setup',
    Position = 0)]
    [String] $CmdPath,

    # Flag to use winpe flag instead of SetupKey
    [Parameter(Mandatory = $False,
        ValueFromPipelineByPropertyName = $true,
        ParameterSetName = 'Setup',
    Position = 1)]
    [String] $CmdArg,
    
    # 0 doesnt run, 1 reboots after command, 2 allows user to login after command(No Boot)
    [Parameter(Mandatory = $False,
    ParameterSetName = 'Setup')]
    [int] $SetupType = 2,
    
    # Flag to use winpe flag instead of SetupKey
    [Parameter(Mandatory = $False,
        ValueFromPipelineByPropertyName = $true,
        ParameterSetName = 'Setup',
    Position = 2)]
    [string] $WinPE,

    # Time to wait before rebooting. 
    [Parameter(ParameterSetName = 'Setup')]
    [Int] $WaitTime = 20,

    # Message to display before rebooting
    [Parameter(ParameterSetName = 'Setup')]
    [String] $RebootMSG = "System is about to reboot.`r Click ok to proceed with the reboot.",
    
    # Prevents boot
    [Parameter(ParameterSetName = 'Setup')]
    [Switch] $NoBoot ,
    
    # Switch will clear out all 
    [Parameter(Mandatory = $False,
    ParameterSetName = 'clear')]
    [Switch] $Clear

  )

  Begin
  {
    $component = "$($MyInvocation.InvocationName)-1.0.2"
    $loggingLevel = 4
    If (Get-Command -Name Write-MDT_LogMessage -ErrorAction Ignore) 
    {
      $blnLog = $true
    }
    If ($WinPE -ne $Null) 
    {
      Try
      {
        $TSEnv = New-Object -ComObject Microsoft.SMS.TSEnvironment -ErrorAction Ignore
      }
      Catch
      {
        $Error.Remove($Error[0])
        $TSEnv = $Null
      }
    }
    If ($CmdPath -eq $Null) 
    {
      $CmdPath = $MyInvocation.InvocationName.ToString()
      $CmdArg = $MyInvocation.BoundParameters.ToString()
      If ($blnLog) 
      {
        Write-MDT_LogMessage -message '-CMD Path is null' -component $component -type 3
      }
    } 
    If ($WinPE -EQ '')
    {
      $WinPE = $Null
    }
    If ($CmdPath -EQ '')
    {
      $CmdPath = $Null
    }

  }
  Process
  {
    IF($Clear)
    {
      If ((-not $TSEnv))
      {
        $PrevCMD = (Get-ItemProperty -Path 'HKLM:\SYSTEM\Setup' -Name 'CmdLine' -ErrorAction Ignore).CmdLine
        $PrevType = (Get-ItemProperty -Path 'HKLM:\SYSTEM\Setup' -Name 'SetupType' -ErrorAction Ignore).SetupType
        If ($blnLog) 
        {
          Write-MDT_LogMessage -message "-Was ($PrevType) $PrevCMD" -component $component -type $loggingLevel
        }       
          
        $Null = New-ItemProperty -Path 'HKLM:\SYSTEM\Setup' -Name 'CmdLine' -PropertyType 'String' -Value '' -Force
        $Null = New-ItemProperty -Path 'HKLM:\SYSTEM\Setup' -Name 'SetupType' -PropertyType 'DWORD' -Value 0 -Force
        If ($blnLog) 
        {
          Write-MDT_LogMessage -message '-Clearing Restart key' -component $component -type $loggingLevel
        }
      }
      Else
      {
        If ($blnLog) 
        {
          Write-MDT_LogMessage -message "-Was $WinPE = $($TSEnv.Value($WinPE))" -component $component -type $loggingLevel
        }
        $TSEnv.Value($WinPE) = 'False'
        If ($blnLog) 
        {
          Write-MDT_LogMessage -message "-Setting $WinPE = $($TSEnv.Value($WinPE))" -component $component -type $loggingLevel
        } 
      }
    }
    ELSE
    {
      IF ( [String]$CmdPath -eq '' -and $TSEnv -EQ $Null)
      {
        If ($blnLog) 
        {
          Write-MDT_LogMessage -message '-No CMPath is null and not in PE' -component $component -type 3
        }
        Return $False
      } 
      IF (-not (Test-Path -Path $CmdPath -ErrorAction Ignore) -and $TSEnv -EQ $Null)
      {
        If ($blnLog) 
        {
          Write-MDT_LogMessage -message '-CMPath Doesnt Exist' -component $component -type 3
        }
        Return $False
      }
      If ($TSEnv -ne $Null)
      {
        Try
        {
          $TSEnv.Value($WinPE) = 'TRUE'
          If ($blnLog) 
          {
            Write-MDT_LogMessage -message "-Setting $WinPE = True" -component $component -type $loggingLevel
          }
        }
        Catch 
        {
          If ($blnLog) 
          {
            Write-MDT_LogMessage -message "-Error $WinPE = True" -component $component -type 3
          }
        }
      }
      Else 
      {
        $Null = New-ItemProperty -Path 'HKLM:\SYSTEM\Setup' -Name 'CmdLine' -PropertyType 'String' -Value ($CmdPath + ' ' + $CmdArg) -Force
        $Null = New-ItemProperty -Path 'HKLM:\SYSTEM\Setup' -Name 'SetupType' -PropertyType 'DWORD' -Value $SetupType -Force
        If ($blnLog) 
        {
          Write-MDT_LogMessage -message "-Setting OOBE startup = $CmdPath $CmdArg" -component $component -type $loggingLevel
        }
      }
    }
  }
  End
  {
    If (($TSEnv -EQ $Null) -and (-not $Clear))
    {
      If (-Not $NoBoot)
      {
        If ($RebootMSG -NE $Null)
        {
          $job = Start-Job -ArgumentList $RebootMSG -ScriptBlock {
            $Null = Add-Type -AssemblyName Microsoft.VisualBasic
            [Microsoft.VisualBasic.Interaction]::MsgBox($args[0],'OKOnly,SystemModal,Information','Restarting') 
          }
        }
        $Seconds = 0
        while($Seconds -LE $WaitTime -and $job.State -ne 'Completed')
        {
          Start-Sleep -Seconds 1
          $Seconds++
          $job = Get-Job -Id $job.id
        }

        If ($blnLog) 
        {
          Write-MDT_LogMessage -message '-Restarting Computer' -component $component -type $loggingLevel
        }                   
        Restart-Computer
        Exit
      }
    }
    Return $true
  }
}