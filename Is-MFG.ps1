
function Test-MDT_IsMFG 
{
  <#
      .Synopsis
      Checks if The locatl system is a MFG/Restricted system

      .DESCRIPTION
      Created: Jeff Scripter

      Version:  1.0.0 - Jeff Scripter - Original
                1.0.1 - Paddy Davis   - 7/11/2016 - splitting this into two functions, one to check ethernet and one to check manufacturing
                1.0.2 - Jeff Scripter - 7/28/2016 - Added logging
        
    
      Looks are both the MDTClass reg key and the ou path to determine if the system is MFG

      Assumptions:
      Write-MDT_LogMessage is available


      .EXAMPLE
      Test-IsMFG
      > False


  #>

  [CmdletBinding()]
  [OutputType([int])]
  Param
  (
    # List of ou names that you are looking to restrict
    [String[]]$RestrictedOUs = @('OU=MITX', 'OU=HighlyManaged', 'OU=COMPUTERS_VALIDATED', 'OU=LINE MACHINES', 'OU=MANUFACTURING COMPUTERS', 'OU=LINE MACHINE NO MANDATORY PROFILE')
  )

  Begin
  {
    $component = "$($MyInvocation.InvocationName)-1.0.2"
    $loggingLevel = 4
    If (Get-Command -Name Write-MDT_LogMessage -ErrorAction Ignore) {$blnLog = $true}
    $ComputerName = $env:computername
    $Filter = "(&(objectCategory=Computer)(Name=$ComputerName))"
    $componant = 'MFG-Check'
    Try
    {
      $DirectorySearcher = New-Object -TypeName System.DirectoryServices.DirectorySearcher
      $DirectorySearcher.Filter = $Filter
      $SearcherPath = $DirectorySearcher.FindOne()
      $OUPath = $SearcherPath.GetDirectoryEntry().DistinguishedName
      If ($blnLog) {Write-MDT_LogMessage -message "-OUPath Found: $OUPath" -component $component -type $loggingLevel}
    }
    Catch
    {
      $Error.remove($Error[0])
      If ($blnLog) {Write-MDT_LogMessage -message '-Could not connect to Domain Controller' -component $component -type 3}
    }

    IF ($OUPath -EQ $Null)
    {
      $OUPath = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy\State\Machine' -Name 'Distinguished-Name' -ErrorAction SilentlyContinue).'Distinguished-Name'
      If ($blnLog) {Write-MDT_LogMessage -message "-Using Reg key: $OUPath" -component $component -type $loggingLevel}
    }
        
    $Class = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Wow6432Node\Medtronic\Workstation Settings' -Name 'MDTClass' -ErrorAction SilentlyContinue).MDTClass
    If ($Class -eq $Null)
    {
      $Class = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Medtronic\Workstation Settings' -Name 'MDTClass' -ErrorAction SilentlyContinue).MDTClass
    }
    If ($Class -eq $Null) 
    {
      $Class = 0 
    }
    If ($blnLog) {Write-MDT_LogMessage -message "-Class: $Class" -component $component -type $loggingLevel}
    $IsMFG = $false
  }
  Process
  {
    # Check Class first
    Switch ($Class){
      0 
      {

      }
      1 
      {
        $IsMFG = $true
      }
      2 
      {
        $IsMFG = $true
      }
      3 
      {
        $IsMFG = $true
      }
      4 
      {
        $IsMFG = $true
      }
      Default 
      {
        $IsMFG = $true
      }
    } 
    If ($blnLog) {Write-MDT_LogMessage -message "-Class Found: $Class" -component $component -type $loggingLevel} 
    If ($blnLog) {Write-MDT_LogMessage -message "-IsMFG Found: $IsMFG" -component $component -type $loggingLevel}
        
    If ($OUPath -eq $Null)
    {
      $IsMFG = $true
    }
    Else
    {
      #look for Restricted OUs
      Foreach ($MFGOU in $RestrictedOUs)
      {
        If ($OUPath -imatch $MFGOU) 
        {
          $IsMFG = $true
          If ($blnLog) {Write-MDT_LogMessage -message "-OU Flag Found ($MFGOU): $OUPath" -component $component -type $loggingLevel}  
        }
      }
    }
        
  }
  End
  {
    If ($blnLog) {Write-MDT_LogMessage -message "-Return: $ismfg" -component $component -type $loggingLevel}  
    Return $IsMFG
  }
}

[boolean](Test-MDT_IsMFG  -Verbose)
Test-MDT_IsMFG -RestrictedOUs 'workstation'  -verbose
Test-MDT_IsMFG -RestrictedOUs 'workstation'