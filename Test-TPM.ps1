#requires -Version 1.0
Function Test-MDT_TPM
{
  <#
      .Synopsis
      Returns the status of TPM

      .DESCRIPTION
      Created: Jeff Scripter

      Version:  1.0.1 - 2016_08_16 - Jeff Scripter - Mirrored Get-MDTBDEStatus for keys
      1.0.1 - 2016_08_02 - Jeff Scripter - Added logging and error handling
      1.0.0 - Jeff Scripter - Original

      Details:
      Leverages win32_tpm and uses it's methods to get the latest status for TPM

      Returns:
      0 - Active, Enabled and owned
      1 - Not owned
      2 - Not Active
      3 - Not Enabled
      4 - Doesn't Exist
      .EXAMPLE   
      PS C:\WINDOWS\system32> Test-MDT_TPM -MDTHive 'HKLM:\SOFTWARE\Wow6432Node\Medtronic\Encryption'
      0

  #>

  [OutputType([int])]
  Param
  (
    #Reg path to write out status
    [Parameter(ValueFromPipelineByPropertyName = $true,
    Position = 0)]
    [string]$MDTHive = 'HKLM:\SOFTWARE\Wow6432Node\Medtronic'
  )

  Begin
  {
    $component = "$($MyInvocation.InvocationName)-1.0.1"
    If (Get-Command -Name Write-MDT_LogMessage -ErrorAction Ignore) 
    {
      $blnLog = $true
    }
    $Return = $False
    $loggingLevel = 4
        
    $TPM = Get-WmiObject -Class win32_tpm -Namespace Root\CIMV2\Security\MicrosoftTpm -ErrorAction Ignore  
    Foreach ($Prop in $TPM.Properties )
    {
      If ($blnLog) 
      {
        Write-MDT_LogMessage -message "-TPM.$($Prop.name) = $($Prop.Value)" -component $component -type $loggingLevel
      }
    }
    
    If ([String]$MDTHive -EQ '')
    {
      If ($blnLog) 
      {
        Write-MDT_LogMessage -message "-ERROR- MDThive variable is null; Setting MDThive = $MDTHive" -component $component -type 3
      }
      $MDTHive = 'HKLM:\SOFTWARE\Wow6432Node\Medtronic'
    }
    

    If (-not (Test-Path -Path "$MDTHive\Encryption")) 
    {
      $null = New-Item -Path "$MDTHive\Encryption" -Force
      If ($blnLog) 
      {
        Write-MDT_LogMessage -message "-Creating $MDTHive\Encryption" -component $component -type $loggingLevel
      }
    }
    
    If ($blnLog) 
    {
      Write-MDT_LogMessage -message "-Clearing $MDTHive\Encryption" -component $component -type $loggingLevel
    }
    $null = Set-ItemProperty -Path "$MDTHive\Encryption" -Name 'TPM_On' -Value '' -Force
    $null = Set-ItemProperty -Path "$MDTHive\Encryption" -Name 'TPM_Owned' -Value '' -Force
    $null = Set-ItemProperty -Path "$MDTHive\Encryption" -Name 'TPM_Enabled' -Value '' -Force
    $null = Set-ItemProperty -Path "$MDTHive\Encryption" -Name 'TPM_Activated' -Value '' -Force

  }
  Process
  {
    If ($TPM -eq $null)
    { 
      $null = Set-ItemProperty -Path "$MDTHive\Encryption" -Name 'TPM_On' -Value 'FALSE' -Force
      If ($blnLog) 
      {
        Write-MDT_LogMessage -message '-Return 4 - TPM_On = False ' -component $component -type $loggingLevel
      }
      $Return = 4
    }
    ElseIf ($TPM.IsEnabled().IsEnabled -eq $False) 
    {
      $null = Set-ItemProperty -Path "$MDTHive\Encryption" -Name 'TPM_Enabled' -Value 'FALSE' -Force
      If ($blnLog) 
      {
        Write-MDT_LogMessage -message '-Return 3 - TPM_Enabled = False ' -component $component -type $loggingLevel
      }      
      $Return = 3
    }
    ElseIf ($TPM.IsActivated().IsActivated -eq $False) 
    {
      $null = Set-ItemProperty -Path "$MDTHive\Encryption" -Name 'TPM_Activated' -Value 'FALSE' -Force  
      If ($blnLog) 
      {
        Write-MDT_LogMessage -message '-Return 2 - TPM_Enabled = False ' -component $component -type $loggingLevel
      }            
      $Return = 2
    }
    ElseIf ($TPM.IsOwned().IsOwned -eq $False) 
    { 
      $null = Set-ItemProperty -Path "$MDTHive\Encryption" -Name 'TPM_Owned' -Value 'FALSE' -Force
      If ($blnLog) 
      {
        Write-MDT_LogMessage -message '-Return 1 - TPM_Owned = False ' -component $component -type $loggingLevel
      }                  
      $Return = 1
    }
    Else
    {
      If ($blnLog) 
      {
        Write-MDT_LogMessage -message '-Return 0 - TPM Configured' -component $component -type $loggingLevel
      }
      $null = Set-ItemProperty -Path "$MDTHive\Encryption" -Name 'TPM_On' -Value 'TRUE' -Force
      $null = Set-ItemProperty -Path "$MDTHive\Encryption" -Name 'TPM_Owned' -Value 'TRUE' -Force
      $null = Set-ItemProperty -Path "$MDTHive\Encryption" -Name 'TPM_Enabled' -Value 'TRUE' -Force
      $null = Set-ItemProperty -Path "$MDTHive\Encryption" -Name 'TPM_Activated' -Value 'TRUE' -Force
      $Return = 0
    }

  }
  End
  {

    If ($TPM -NE $null)
    {
      $version = $TPM.SpecVersion.split(',')[0]
      If ($MDTHive -NE '')
      {
        Set-ItemProperty -Path "$MDTHive\Encryption" -Name 'TPM_Version' -Value $version -Force
      }
    }
    Else
    {
      $version = 'Null'
      If ($MDTHive -NE '')
      {
        Set-ItemProperty -Path "$MDTHive\Encryption" -Name 'TPM_Version' -Value $version -Force
      }
    }
    Return $Return
  }
}
     
Test-MDT_TPM

Test-MDT_TPM -Verbose
