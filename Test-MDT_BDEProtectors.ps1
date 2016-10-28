Function Test-BDEPWDProtectors
{
  <#
      .Synopsis
        Tests to make sure the password bitlocker exist

      .DESCRIPTION
      Created: Jeff Scripter
      Last Modified: Jeff Scripter

      Version:  1.0.0 - 8/05/2016 - Jeff Scripter - Original
   
      Details: 
        This test to make sure that the recovery passwords are on the drive specified for bitlocker.

      Comment:	NA

      Assumptions:	
        - Manage-BDE exists
        - Administrator rights

      Returns: $True  - RecoveryPassword exists on the drive
      $False - No recoverypassword does not exit on the drive

      .EXAMPLE
      Test-BDEPWDProtectors c: -verbose -debug
      DEBUG: -CMD(Win - False ;Shell - False): C:\WINDOWS\system32\manage-bde.exe -protectors -get c:
      DEBUG: -Return -1 - BitLocker Drive Encryption: Configuration Tool version 10.0.10011
      Copyright (C) 2013 Microsoft Corporation. All rights reserved.

      Volume C: [OSDisk]
      All Key Protectors

      ERROR: No key protectors found.

      VERBOSE: -Return = False
      False

  #>

  [CmdletBinding()]
  [OutputType([Boolean])]
  Param
  (
      # Reg Path to Log settings
    [string]$MDTHive = 'HKLM:\SOFTWARE\Wow6432Node\Medtronic\Encryption',
    
    #Drive Letter To Configure
    [Parameter(ValueFromPipelineByPropertyName = $true,
    Position = 0)]
    [String] $DriveLetter = $Env:Systemdrive

  )
    
  Begin
  {
    $component = "$($MyInvocation.InvocationName)-1.0.0"
    If (Get-Command -Name Write-MDT_LogMessage -ErrorAction Ignore) {$blnLog = $true}
    $Return = $False
  }
  Process
  {
    #get Manage-bde path for 32 or 64 bit runspaces
    $ManageBDE = "$env:systemroot\system32\manage-bde.exe"
    If (-not (Test-Path -Path $ManageBDE)){$ManageBDE = "$env:systemroot\Sysnative\manage-bde.exe" }
    
    #Tests If recoverypasswords exist.
    $protectorParam= "-protectors -get $DriveLetter"
    $output = Invoke-MDT_CMDWithOutput -filepath $ManageBDE -Arguments $protectorParam -loglevel debug
    If (-not ($output[1] -match 'Password:')){
      Set-ItemProperty -Path "$MDTHive\Encryption" -Name 'BDEPWDProtectors' -Value 'False' -Force -ErrorAction Ignore            
    }Else{
      Write-MDT_LogMessage -message "-Key Protectors $($BDEDriveEncrypted.DriveLetter) are present." -component $component -type 4
      Set-ItemProperty -Path "$MDTHive\Encryption" -Name 'BDEPWDProtectors' -Value 'True' -Force -ErrorAction Ignore      
      $Return = $True
    }
  }
  End
  {
    If ($blnLog) {Write-MDT_LogMessage -message "-Return = $Return" -component $component -type 4}
    Return $Return
  }
}

Test-BDEPWDProtectors c: 
Test-BDEPWDProtectors c: -verbose
Test-BDEPWDProtectors c: -verbose -debug