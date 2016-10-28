#requires -Version 3.0
Function Test-MDT_Virtual
{
  <#
      .Synopsis
      THis function checks to see if the local system is virual.
    
      .DESCRIPTION
      Author:    Jeff Scripter
      Modified:  Jeff Scripter

      Purpose: 
        Identifies if the system has any indicators of being a virtual machine.

      Return:
        True- Virtual machine
        False- Physical machine

      Overview:
        We determine if the system is virtual in one of three ways:
        1) The name matches (Via regex)
        2) The OU path 
        3) Hardware tests 

      .NOTES
      Comment:	
        

      Assumptions:	
        
    
      Changes:
      2016_09_29 - Original - Jeff Scripter - Original


      Test Script: 
        1) Computername Check
        2) Computername Wildcard Check
        3) OU Path Check
        4) Computername Wildcard Check
        5) Custom Model Check
        6) VRTUAL Check
        7) A M I Check
        8) Xen Check
        9) VMware SN Check
        10) VMware MFG Check
        11) Virtual Check

      .EXAMPLE
          PS H:\> Test-MDT_Virtual -Verbose
          False
  #>

  [CmdletBinding()]
  [OutputType([Boolean])]
  Param
  (
    #Regex pattern array for different OUs that are used to idenify virtual machines
    [String[]] $VMOUPattern = 'VDI Client Machines',
    
    #Regex pattern array for different Model names that are used to idenify virtual machines
    [String[]] $VirtualModelPattern = $Null,
    
    #Regex pattern array for different Computer naming standards that are used to idenify virtual machines
    [String[]] $VMNamingPattern = @('Daas', 'vdi')

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
  
    #computer name tests
    $ComputernameFlag = $False
    Foreach ($Pattern In $VMNamingPattern)
    {
      If($Env:ComputerName -Match $Pattern) 
      {
        $VMType = "Virtual - $Pattern"
        $ComputernameFlag = $true
        If ($blnLog) 
        {
          Write-MDT_LogMessage -message "-Computername Flag($Pattern) - $ComputernameFlag - $VMType - $($WMICompSys.model)" -component $component -type 4
        }
      }
    }
    
    
    #ou Path Tests
    If (Get-Command -Name Write-MDT_LogMessage -ErrorAction Ignore) 
    {
      $blnLog = $true
    }
    $ComputerName = $Env:ComputerName
    $Filter = "(&(objectCategory=Computer)(Name=$ComputerName))"
    Try
    {
      $DirectorySearcher = New-Object -TypeName System.DirectoryServices.DirectorySearcher
      $DirectorySearcher.Filter = $Filter
      $SearcherPath = $DirectorySearcher.FindOne()
      $OUPath = $SearcherPath.GetDirectoryEntry().DistinguishedName
      If ($blnLog) 
      {
        Write-MDT_LogMessage -message "-OUPath Found: $OUPath" -component $component -type 4
      }
    }
    Catch
    {
      $Error.RemoveAt(0)
      If ($blnLog) 
      {
        Write-MDT_LogMessage -message '-Could not connect to Domain Controller' -component $component -type 3
      }
    }
    IF ($OUPath -EQ $Null)
    {
      $OUPath = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy\State\Machine' -Name 'Distinguished-Name' -ErrorAction SilentlyContinue).'Distinguished-Name'
      If ($blnLog) 
      {
        Write-MDT_LogMessage -message "-Using Reg key: $OUPath" -component $component -type $loggingLevel
      }
    }
    
    $OUFlag = $False
    Foreach ($Pattern In $VMOUPattern)
    {
      If($OUPath -Match $Pattern) 
      {
        $VMType = "Virtual - $Pattern"
        $OUFlag = $true
        If ($blnLog) 
        {
          Write-MDT_LogMessage -message "-AD OU Flag($Pattern) - $OUFlag - $VMType - $($WMICompSys.model)" -component $component -type 4
        }
      }
    }
    
    #Starting Hardware Tests
    $BlnHWFlag = $False
    $WMIBios = Get-WmiObject -Class Win32_BIOS
    $WMICompSys = Get-WmiObject -Class Win32_ComputerSystem 
    $VMType = ''
    
    If($WMIBios.Version -match 'VRTUAL') 
    {
      $VMType = 'Virtual - Hyper-V'
      $BlnHWFlag = $true
      If ($blnLog) 
      {
        Write-MDT_LogMessage -message "-Hardware Flag(VRTUAL) - $BlnHWFlag - $VMType - $($WMIBios.Version)" -component $component -type 4
      }
    }
    Elseif($WMIBios.Version -Match 'A M I') 
    {
      $VMType = 'Virtual - Virtual PC'
      $BlnHWFlag = $true
      If ($blnLog) 
      {
        Write-MDT_LogMessage -message "-Hardware Flag(A M I) - $BlnHWFlag - $VMType - $($WMIBios.Version)" -component $component -type 4
      }
    }
    Elseif($WMIBios.Version -Match 'Xen') 
    {
      $VMType = 'Virtual - Xen'
      $BlnHWFlag = $true
      If ($blnLog) 
      {
        Write-MDT_LogMessage -message "-Hardware Flag(Xen) - $BlnHWFlag - $VMType - $($WMIBios.Version)" -component $component -type 4
      }
    }
    Elseif($WMIBios.SerialNumber -Match 'VMware') 
    {
      $VMType = 'Virtual - VMWare'
      $BlnHWFlag = $true
      If ($blnLog) 
      {
        Write-MDT_LogMessage -message "-SerialNumber Flag(VMware) - $BlnHWFlag - $VMType - $($WMIBios.SerialNumber)" -component $component -type 4
      }
    }
    Elseif($WMICompSys.manufacturer -Match 'VMWare') 
    {
      $VMType = 'Virtual - VMWare'
      $BlnHWFlag = $true
      If ($blnLog) 
      {
        Write-MDT_LogMessage -message "-Hardware Flag(VMware) - $BlnHWFlag - $VMType - $($WMICompSys.manufacturer)" -component $component -type 4
      }
    }
    Elseif($WMICompSys.model -Match 'Virtual') 
    {
      $VMType = 'Virtual'
      $BlnHWFlag = $true
      If ($blnLog) 
      {
        Write-MDT_LogMessage -message "-Hardware Flag(Virtual) - $BlnHWFlag - $VMType - $($WMICompSys.model)" -component $component -type 4
      }
    }
    Else 
    {
      Foreach ($Pattern In $VirtualModelPattern)
      {
        if($WMICompSys.model -Match $Pattern) 
        {
          $VMType = "Virtual - $Pattern"
          $BlnHWFlag = $true
          If ($blnLog) 
          {
            Write-MDT_LogMessage -message "-Hardware Flag($Pattern) - $BlnHWFlag - $VMType - $($WMICompSys.model)" -component $component -type 4
          }
        }
      }
    }

    $Return = $BlnHWFlag -or $OUFlag -or $ComputernameFlag
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
