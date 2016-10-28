Function Get-BDEPWDProtectors
{
  <#
      .Synopsis
        Returns the current Bitlocker protectors on a disk

      .DESCRIPTION
      Created: Jeff Scripter
      Last Modified: Jeff Scripter

      Version:  1.0.0 - 7/29/2016 - Jeff Scripter - Original
   
      Details: 
        

      Comment:	NA

      Assumptions:	

      Returns: $True  - 
      $False -

      .EXAMPLE


  #>

  [CmdletBinding()]
  [OutputType([Boolean])]
  Param
  (
      # Reg Path to Log settings
    [string]$MDTHive = 'HKLM:\SOFTWARE\Wow6432Node\Medtronic\Encryption',
    
    #Drive Letter To Configure
    [String] $DriveLetter = $Env:Systemdrive
    


  )
    
  Begin
  {
    $component = "$($MyInvocation.InvocationName)-1.0.0"
    If (Get-Command -Name Write-MDT_LogMessage -ErrorAction Ignore) {$blnLog = $true}
    $Return = $False
    $RegexDetails = '( {1,}(\w| ){2,}:(\s)*)(\s{2,}(\w| ){2,}:( |\W{1,})(\{|\}|\d|[ABCDEF]|-|, )*\n){2,3}'
    $RegexKey = '\d{6}(-\d{6}){7}'
    $RegExID = '\{(\d|[ABCDEF]){8}-(\d|[ABCDEF]){4}-(\d|[ABCDEF]){4}-(\d|[ABCDEF]){4}-(\d|[ABCDEF]){12}\}'
  }
  Process
  {
    $ManageBDE = "$env:systemroot\system32\manage-bde.exe"
    If (-not (Test-Path -Path $ManageBDE)){$ManageBDE = "$env:systemroot\Sysnative\manage-bde.exe" }
    $protectorParam= "-protectors -get $DriveLetter"
    $output = Invoke-MDT_CMDWithOutput -filepath $ManageBDE -Arguments $protectorParam -loglevel debug
    
    [regex]::Matches($output[1],'( {1,}(\w| ){2,}:(\s)*)(\s{2,}(\w| ){2,}:( |\W{1,})(\{|\}|\d|[ABCDEF]|-|, )*\n){2,3}')
    If (-not ($output[1] -match 'Password:')){
      $protectorParam= "-protectors -add $DriveLetter -recoverypassword"
      $output = Invoke-MDT_CMDWithOutput -filepath $ManageBDE -Arguments $protectorParam -loglevel debug
      If ($output[0] -eq 0){
        Set-ItemProperty -Path "$MDTHive\Encryption" -Name 'BDEPWDProtectors' -Value 'True' -Force -ErrorAction Ignore
        $Return = $TRUE      
      } 
      Else
      {
        Set-ItemProperty -Path "$MDTHive\Encryption" -Name 'BDEPWDProtectors' -Value 'False' -Force -ErrorAction Ignore            
      }
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
