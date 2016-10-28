Function Set-MDT_BDEPWDProtectors
{
  <#
      .Synopsis
      Ensures that the Bitlocker recoverypassword exists on the drive

      .DESCRIPTION
      Created: Jeff Scripter
      Last Modified: Jeff Scripter

      Version:  1.0.0 - 8/05/2016 - Jeff Scripter - Original
   
      Details: 
      This is designed to test to make sure the drive is protected with recoverypassword. If it 
      Doesnt exist, it is created.

      Comment:	NA

      Assumptions:	
      - OS has Manage-bde and supports bitlocker.
      - Requires admin rights

      Returns: $True  - Protectors are present/added
      $False -If protectors are not present

      .EXAMPLE
      Set-MDT_BDEPWDProtectors -DriveLetter c: -ForceADBackup -Verbose 
      VERBOSE: -Key Protectors  are present.
      VERBOSE: Backing up Key Type: 3 {635F92E1-EC45-4ABE-8052-E557423A2ADA}
      VERBOSE: Backed up Key Type: 3 {635F92E1-EC45-4ABE-8052-E557423A2ADA}
      VERBOSE: -Return = True
      True

  #>

  [CmdletBinding()]
  [OutputType([Boolean])]
  Param
  (
    # Reg Path to Log settings
    [string]$MDTHive = 'HKLM:\SOFTWARE\Wow6432Node\Medtronic\Encryption',
    
    #Deletes protectors and Regenerates them
    [Switch] $Reset,
    
    # Forces the keys to be backed up to AD
    [Switch] $ForceADBackup,
    
    #Drive Letter To Configure
    [Parameter(ValueFromPipelineByPropertyName = $true,
    Position = 0)]
    [String] $DriveLetter = $Env:Systemdrive

  )
    
  Begin
  {
    $component = "$($MyInvocation.InvocationName)-1.0.0"
    If (Get-Command -Name Write-MDT_LogMessage -ErrorAction Ignore) 
    {
      $blnLog = $true
    }
    $Return = $False
  }
  Process
  {
    # get utility if running 64 bit or 32 bit
    $ManageBDE = "$env:systemroot\system32\manage-bde.exe"
    If (-not (Test-Path -Path $ManageBDE))
    {
      $ManageBDE = "$env:systemroot\Sysnative\manage-bde.exe"
    }
    
    #Check for protectors
    $protectorParam = "-protectors -get $DriveLetter"
    $output = Invoke-MDT_CMDWithOutput -FilePath $ManageBDE -Arguments $protectorParam -loglevel debug
    If (-not ($output[1] -match 'Password:'))
    {
      #Add because they are not there
      $protectorParam = "-protectors -add $DriveLetter -recoverypassword"
      $output = Invoke-MDT_CMDWithOutput -FilePath $ManageBDE -Arguments $protectorParam -loglevel debug
      If ($output[0] -eq 0)
      {
        #successfully added
        Set-ItemProperty -Path "$MDTHive\Encryption" -Name 'BDEPWDProtectors' -Value 'True' -Force -ErrorAction Ignore
        Write-MDT_LogMessage -message "-Key Protectors $($BDEDriveEncrypted.DriveLetter) Created!" -component $component -type 4                    
        $Return = $true      
      } 
      Else
      {
        #failed to add protectors
        Set-ItemProperty -Path "$MDTHive\Encryption" -Name 'BDEPWDProtectors' -Value 'False' -Force -ErrorAction Ignore            
      }
    }
    Else
    {
      If ($Reset)
      {
        #regenerating Protectors
        $OldOutput = $output
        $protectorParam = "-protectors -Delete $DriveLetter -Type recoverypassword"
        $output = Invoke-MDT_CMDWithOutput -FilePath $ManageBDE -Arguments $protectorParam -loglevel debug
        
        $protectorParam = "-protectors -add $DriveLetter -recoverypassword"
        $output = Invoke-MDT_CMDWithOutput -FilePath $ManageBDE -Arguments $protectorParam -loglevel debug
        
        #Check again
        $protectorParam = "-protectors -get $DriveLetter"
        $output = Invoke-MDT_CMDWithOutput -FilePath $ManageBDE -Arguments $protectorParam -loglevel debug
        If ($output[1] -match 'Password:')
        {
          #protectors are present
          Set-ItemProperty -Path "$MDTHive\Encryption" -Name 'BDEPWDProtectors' -Value 'True' -Force -ErrorAction Ignore                
          If ( $output -NE $OldOutput)
          {
            #protectors Replaced
            $Return = $true
            Write-MDT_LogMessage -message "-Key Protectors $($BDEDriveEncrypted.DriveLetter) Reset!" -component $component -type 4            
          }
          Else
          {
            #Protectors Not Changed
            $Return = $False
            Write-MDT_LogMessage -message "-Key Protectors $($BDEDriveEncrypted.DriveLetter) Not Reset." -component $component -type 3  
          }
        }
      }
      Write-MDT_LogMessage -message "-Key Protectors $($BDEDriveEncrypted.DriveLetter) are present." -component $component -type 4
      Set-ItemProperty -Path "$MDTHive\Encryption" -Name 'BDEPWDProtectors' -Value 'True' -Force -ErrorAction Ignore      
      $Return = $true
    }
    If ($Return)
    {
      If ($ForceADBackup)
      {
        $BDEWMIQuery = 'Select * from Win32_EncryptableVolume'
        $BDEDriveEncrypted = Get-WmiObject -Namespace ROOT\cimv2\Security\MicrosoftVolumeEncryption -Query $BDEWMIQuery
        Foreach( $drive in $BDEDriveEncrypted)
        {
          $Protectors = $drive.GetKeyProtectors().VolumeKeyProtectorID
          Foreach($key in $Protectors)
          {
            $keyType = $drive.GetKeyProtectorType($key).KeyProtectorType
            If ($keyType -NE 0 -and $keyType -NE 1)
            {
              $BackupParam = "-protectors -adbackup $($drive.DriveLetter) -id $key"
              $output = Invoke-MDT_CMDWithOutput -filepath $ManageBDE -Arguments $BackupParam -loglevel debug
              If ($output[0] -NE 0)
              {
                Write-MDT_LogMessage -message "Failed to Backing up Key Type: $keyType $key" -component $component -type 3
              }
              Else
              {
                Write-MDT_LogMessage -message "Backed up Key Type: $keyType $key" -component $component -type 4
                Set-ItemProperty -Path "$MDTHive\Encryption" -Name 'BackedUpProtectors' -Value (Get-Date -Format 'yyyyMMdd') -Force -ErrorAction Ignore      
              }                                               
            }
          }
        }
      }
    }
  }
  End
  {
    If ($blnLog) 
    {
      Write-MDT_LogMessage -message "-Return = $Return" -component $component -type 4
    }
    Return $Return
  }
}
