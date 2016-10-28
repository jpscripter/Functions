#requires -Version 2.0
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
    If ($WinPE -ne $null) 
    {
      Try
      {
        $TSEnv = New-Object -ComObject Microsoft.SMS.TSEnvironment -ErrorAction Ignore
      }
      Catch
      {
        $TSEnv = $null
      }
    }
    If ($CmdPath -eq $null) 
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
      $WinPE = $null
    }
    If ($CmdPath -EQ '')
    {
      $CmdPath = $null
    }

  }
  Process
  {
    IF($Clear)
    {
      If ((-not $TSEnv))
      {
        $PrevCMD = (Get-ItemProperty -path 'HKLM:\SYSTEM\Setup' -name 'CmdLine' -ErrorAction Ignore).CmdLine
        $PrevType = (Get-ItemProperty -path 'HKLM:\SYSTEM\Setup' -name 'SetupType' -ErrorAction Ignore).SetupType
        If ($blnLog) 
        {
          Write-MDT_LogMessage -message "-Was ($PrevType) $PrevCMD" -component $component -type $loggingLevel
        }       
          
        $null = New-ItemProperty -path 'HKLM:\SYSTEM\Setup' -name 'CmdLine' -PropertyType 'String' -value '' -Force
        $null = New-ItemProperty -path 'HKLM:\SYSTEM\Setup' -name 'SetupType' -PropertyType 'DWORD' -value 0 -Force
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
      IF ( [String]$CmdPath -eq '' -and $TSEnv -EQ $null)
      {
        If ($blnLog) 
        {
          Write-MDT_LogMessage -message '-No CMPath is null and not in PE' -component $component -type 3
        }
        Return $False
      } 
      IF (-not (Test-Path -Path $CmdPath -ErrorAction Ignore) -and $TSEnv -EQ $null)
      {
        If ($blnLog) 
        {
          Write-MDT_LogMessage -message '-CMPath Doesnt Exist' -component $component -type 3
        }
        Return $False
      }
      If ($TSEnv -ne $null)
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
        $null = New-ItemProperty -path 'HKLM:\SYSTEM\Setup' -name 'CmdLine' -PropertyType 'String' -value ($CmdPath + ' ' + $CmdArg) -Force
        $null = New-ItemProperty -path 'HKLM:\SYSTEM\Setup' -name 'SetupType' -PropertyType 'DWORD' -value $SetupType -Force
        If ($blnLog) 
        {
          Write-MDT_LogMessage -message "-Setting OOBE startup = $CmdPath $CmdArg" -component $component -type $loggingLevel
        }
      }
    }
  }
  End
  {
    If (($TSEnv -EQ $null) -and (-not $Clear))
    {
      If (-Not $NoBoot)
      {
        If ($RebootMSG -NE $null)
        {
          $job = Start-Job -ArgumentList $RebootMSG -ScriptBlock {
            $null = [reflection.assembly]::loadwithpartialname('Microsoft.VisualBasic')
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

Set-MDT_Reboot -CmdPath $env:comspec -CmdArg '/k dir c:\' -NoBoot -RebootMSG 'Test boot'
Set-MDT_Reboot -Clear 
. Set-MDT_Reboot -CmdPath $env:comspec -CmdArg '/k dir c:\' -verbose -NoBoot
Set-MDT_Reboot -Clear -verbose
. Set-MDT_Reboot -CmdPath 'test' -CmdArg '/k dir c:\' -verbose -NoBoot
Set-MDT_Reboot -Clear -verbose
