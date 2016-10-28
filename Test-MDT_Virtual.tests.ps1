#requires -Version 2.0 -Modules Pester
<#
    .Synopsis
    Runs test cases against Test-MDT_Virtual.ps1

    .DESCRIPTION
    Created: Jeff Scripter

    Version: 
    1.0.0 - 9/25/2016 - Jeff Scripter - Original


    Tests:
   Context Computername Check
   Context Computername Wildcard Check
   Context OU Path Check
   Context Computername Wildcard Check
   Context Custom Model Check
   Context VRTUAL Check
   Context A M I Check
   Context Xen Check
   Context VMware SN Check
   Context VMware MFG Check
   Context Virtual Check

      
    Return:
VERBOSE: Test Date:		 09/26/2016 12:45:34
VERBOSE: Test System:	 SCRIPJ1-L8
VERBOSE: Test User:		 scripj1
Describing Test-MDT_Virtual.ps1
   Context Computername Check
VERBOSE: -Computername Flag(RIP) - True - Virtual - RIP - 
VERBOSE: -OUPath Found: CN=SCRIPJ1-L8,OU=Workstations,OU=MoundsviewHQ,OU=MSP,OU=MIT,DC=ent,DC=core,DC=medtronic,DC=com
VERBOSE: -Return = True
    [+] Sub-String of computername Returned True 3.42s
   Context Computername Wildcard Check
VERBOSE: -Computername Flag(.*) - True - Virtual - .* - 
VERBOSE: -OUPath Found: CN=SCRIPJ1-L8,OU=Workstations,OU=MoundsviewHQ,OU=MSP,OU=MIT,DC=ent,DC=core,DC=medtronic,DC=com
VERBOSE: -Return = True
    [+] Wildcard regex match = true 266ms
   Context OU Path Check
VERBOSE: -OUPath Found: CN=SCRIPJ1-L8,OU=Workstations,OU=MoundsviewHQ,OU=MSP,OU=MIT,DC=ent,DC=core,DC=medtronic,DC=com
VERBOSE: -AD OU Flag(CN=SCRIPJ1-L8) - True - Virtual - CN=SCRIPJ1-L8 - 
VERBOSE: -Return = True
    [+] Returned Last CN of OU 142ms
   Context Computername Wildcard Check
VERBOSE: -OUPath Found: CN=SCRIPJ1-L8,OU=Workstations,OU=MoundsviewHQ,OU=MSP,OU=MIT,DC=ent,DC=core,DC=medtronic,DC=com
VERBOSE: -AD OU Flag(.*) - True - Virtual - .* - 
VERBOSE: -Return = True
    [+] Wildcard regex match OU = true 104ms
   Context Custom Model Check
VERBOSE: -OUPath Found: CN=SCRIPJ1-L8,OU=Workstations,OU=MoundsviewHQ,OU=MSP,OU=MIT,DC=ent,DC=core,DC=medtronic,DC=com
VERBOSE: -Hardware Flag(Latitude E7450) - True - Virtual - Latitude E7450 - Latitude E7450
VERBOSE: -Return = True
    [+] Returned True 154ms
   Context VRTUAL Check
VERBOSE: -OUPath Found: CN=SCRIPJ1-L8,OU=Workstations,OU=MoundsviewHQ,OU=MSP,OU=MIT,DC=ent,DC=core,DC=medtronic,DC=com
VERBOSE: -Hardware Flag(VRTUAL) - True - Virtual - Hyper-V - VRTUAL machine
VERBOSE: -Return = True
    [+] WMI Was Mocked for Win32_Bios version = VRTUAL 321ms
    [+] Returned $True 24ms
   Context A M I Check
VERBOSE: -OUPath Found: CN=SCRIPJ1-L8,OU=Workstations,OU=MoundsviewHQ,OU=MSP,OU=MIT,DC=ent,DC=core,DC=medtronic,DC=com
VERBOSE: -Hardware Flag(A M I) - True - Virtual - Virtual PC - A M I machine
VERBOSE: -Return = True
    [+] WMI Was Mocked for Win32_Bios version = A M I 134ms
    [+] Returned $True 24ms
   Context Xen Check
VERBOSE: -OUPath Found: CN=SCRIPJ1-L8,OU=Workstations,OU=MoundsviewHQ,OU=MSP,OU=MIT,DC=ent,DC=core,DC=medtronic,DC=com
VERBOSE: -Hardware Flag(Xen) - True - Virtual - Xen - Xen machine
VERBOSE: -Return = True
    [+] WMI Was Mocked for Win32_Bios version = Xen 200ms
    [+] Returned $True 15ms
   Context VMware SN Check
VERBOSE: -OUPath Found: CN=SCRIPJ1-L8,OU=Workstations,OU=MoundsviewHQ,OU=MSP,OU=MIT,DC=ent,DC=core,DC=medtronic,DC=com
VERBOSE: -SerialNumber Flag(VMware) - True - Virtual - VMWare - VMware 1 15 896 456
VERBOSE: -Return = True
    [+] WMI Was Mocked for Win32_Bios Sn = VMware 137ms
    [+] Returned $True 13ms
   Context VMware MFG Check
VERBOSE: -OUPath Found: CN=SCRIPJ1-L8,OU=Workstations,OU=MoundsviewHQ,OU=MSP,OU=MIT,DC=ent,DC=core,DC=medtronic,DC=com
VERBOSE: -Hardware Flag(VMware) - True - Virtual - VMWare - VMware machine
VERBOSE: -Return = True
    [+] WMI Was Mocked for Win32_ComputerSystem 126ms
    [+] Returned $True 23ms
   Context Virtual Check
VERBOSE: -OUPath Found: CN=SCRIPJ1-L8,OU=Workstations,OU=MoundsviewHQ,OU=MSP,OU=MIT,DC=ent,DC=core,DC=medtronic,DC=com
VERBOSE: -Hardware Flag(Virtual) - True - Virtual - Virtual machine Virtual machine
VERBOSE: -Return = True
    [+] WMI Was Mocked for Win32_ComputerSystem 201ms
    [+] Returned $True 12ms
Tests completed in 5.32s
Passed: 17 Failed: 0 Skipped: 0 Pending: 0

Code coverage report:
Covered 92.31 % of 91 analyzed commands in 1 file.

    .EXAMPLE
    Invoke-Pester -Script H:\Scripts\Functions\Test-MDT_Virtual.tests.ps1 -CodeCoverage  H:\Scripts\Functions\Test-MDT_Virtual.ps1


#>


#***************************************
#region 1 sourcing Original File
#- Dot sources the script for functions (Shouldnt be done with scripts)
#***************************************
$here = Split-Path -Parent -Path $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf -Path $MyInvocation.MyCommand.Path).tolower().Replace('.tests.', '.')
. "$here\$sut"
#***************************************
#endregion 1 sourcing Original File
#***************************************

#***************************************
#region 1 Import\Load 
#***************************************
. 'H:\Scripts\Functions\Write-MDT_LogMessage.ps1'
#***************************************
#endregion 1 Import\Load 
#***************************************

#***************************************
#region 1 Standard Variables
#-These are variables I put in all of my scripts and are used for logging, location detection and other general detection.
#***************************************
$global:logFile = "$env:windir\temp\$(Split-Path -Leaf -Path $MyInvocation.MyCommand.Path).log"
#***************************************
#endregion 1 Standard Variables
#***************************************

#***************************************
#region 1 Mock Variables
#-These are the variables\objects we use in the different tests
#***************************************
$CompSysobj = @{
  Domain       = 'ent.core.medtronic.com"'
  Manufacturer = 'Something Virtual'
  Model        = 'Random'
  Name         = $env:computername
}

$Biosobj = @{
  SMBIOSBIOSVersion = 'version'
  Manufacturer      = 'Manufacturer'
  Name              = 'Name'
  SerialNumber      = '123456'
  Version           = 'testVersion'
}

#***************************************
#endregion 1 Mock Variables
#***************************************

#***************************************
#region 1 Main
#***************************************
Write-MDT_LogMessage -message "Test Date:`t`t $(Get-Date)" -component $component -type 4
Write-MDT_LogMessage -message "Test System:`t $env:computername" -component $component -type 4
Write-MDT_LogMessage -message "Test User:`t`t $Env:UserName" -component $component -type 4
Describe  -Name 'Test-MDT_Virtual.ps1' -Fixture {
  #***************************************
  #region 2 ComputerName
  #***************************************
  Context -Name 'Computername Check' -Fixture {
    $Result = Test-MDT_Virtual -Verbose -VMNamingPattern $env:computername.Substring(2,3)
    
    It -name "Sub-String of computername Returned $True" -test {
      $Result | Should be $True
    }
  }
  #***************************************
  #endregion 2 ComputerName
  #***************************************

  #***************************************
  #region 2 ComputerName Wild
  #***************************************
  Context -Name 'Computername Wildcard Check' -Fixture {
    $Result = Test-MDT_Virtual -Verbose -VMNamingPattern '.*'
    
    It -name 'Wildcard regex match = true' -test {
      $Result | Should be $True
    }
  }
  #***************************************
  #endregion 2 ComputerName Wild
  #***************************************

  #***************************************
  #region 2 OU Path
  #***************************************
  Context -Name 'OU Path Check' -Fixture {
    $OUPath = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy\State\Machine' -Name 'Distinguished-Name' -ErrorAction SilentlyContinue).'Distinguished-Name'
    $Result = Test-MDT_Virtual -Verbose -VMOUPattern ($OUPath.split(',')[0])

    It -name 'Returned Last CN of OU' -test {
      $Result | Should be $True
    }
  }
  #***************************************
  #endregion 2  OU Path
  #***************************************
 
  #***************************************
  #region 2 OU Wild
  #***************************************
  Context -Name 'Computername Wildcard Check' -Fixture {
    $Result = Test-MDT_Virtual -Verbose -VMOUPattern '.*'
    
    It -name 'Wildcard regex match OU = true' -test {
      $Result | Should be $True
    }
  }
  #***************************************
  #endregion 2 OU Wild
  #***************************************
  
  #***************************************
  #region 2 Custom Model
  #***************************************
  Context -Name 'Custom Model Check' -Fixture {
    $model = Get-WmiObject -Class win32_computersystem
    $Result = Test-MDT_Virtual -Verbose -VirtualModelPattern $model.model
    
    It -name 'Returned True' -test {
      $Result | Should be $True
    }
  }
  #***************************************
  #endregion 2 Custom Model
  #***************************************
  
  #***************************************
  #region 2 VRTUAL test
  #***************************************
  Context -Name 'VRTUAL Check' -Fixture {
    Mock -CommandName Get-WMIObject -ParameterFilter {
      $Class -eq 'Win32_Bios'
    } -MockWith {
      $obj = New-Object -TypeName psobject -Property $Biosobj
      $obj.Version = 'VRTUAL machine'
      Return $obj
    }
    $Result = Test-MDT_Virtual -Verbose
    
    It -name 'WMI Was Mocked for Win32_Bios version = VRTUAL' -test {
      Assert-MockCalled -CommandName Get-WMIObject -Times 1 -ParameterFilter {
        $Class -eq 'Win32_Bios'
      }
    }
    It -name 'Returned $True' -test {
      $Result | Should be $True
    }
  }
  #***************************************
  #endregion 2 VRTUAL test
  #***************************************
  
  #***************************************
  #region 2 A M I test
  #***************************************
  Context -Name 'A M I Check' -Fixture {
    Mock -CommandName Get-WMIObject -ParameterFilter {
      $Class -eq 'Win32_Bios'
    } -MockWith {
      $obj = New-Object -TypeName psobject -Property $Biosobj
      $obj.Version = 'A M I machine'
      Return $obj
    }
    $Result = Test-MDT_Virtual -Verbose
    
    It -name 'WMI Was Mocked for Win32_Bios version = A M I' -test {
      Assert-MockCalled -CommandName Get-WMIObject -Times 1 -ParameterFilter {
        $Class -eq 'Win32_Bios'
      }
    }
    It -name 'Returned $True' -test {
      $Result | Should be $True
    }
  }
  #***************************************
  #endregion 2 A M I test
  #***************************************
  
  #***************************************
  #region 2 Xen test
  #***************************************
  Context -Name 'Xen Check' -Fixture {
    Mock -CommandName Get-WMIObject -ParameterFilter {
      $Class -eq 'Win32_Bios'
    } -MockWith {
      $obj = New-Object -TypeName psobject -Property $Biosobj
      $obj.Version = 'Xen machine'
      Return $obj
    }
    $Result = Test-MDT_Virtual -Verbose
    
    It -name 'WMI Was Mocked for Win32_Bios version = Xen' -test {
      Assert-MockCalled -CommandName Get-WMIObject -Times 1 -ParameterFilter {
        $Class -eq 'Win32_Bios'
      }
    }
    It -name 'Returned $True' -test {
      $Result | Should be $True
    }
  }
  #***************************************
  #endregion 2 Xen test
  #***************************************
  
  #***************************************
  #region 2 VMware SN test
  #***************************************
  Context -Name 'VMware SN Check' -Fixture {
    Mock -CommandName Get-WMIObject -ParameterFilter {
      $Class -eq 'Win32_Bios'
    } -MockWith {
      $obj = New-Object -TypeName psobject -Property $Biosobj
      $obj.SerialNumber = 'VMware 1 15 896 456'
      Return $obj
    }
    $Result = Test-MDT_Virtual -Verbose
    
    It -name 'WMI Was Mocked for Win32_Bios Sn = VMware' -test {
      Assert-MockCalled -CommandName Get-WMIObject -Times 1 -ParameterFilter {
        $Class -eq 'Win32_Bios'
      }
    }
    It -name 'Returned $True' -test {
      $Result | Should be $True
    }
  }
  #***************************************
  #endregion 2 VMware SN test
  #***************************************
  
  #***************************************
  #region 2 VMware MFG test
  #***************************************
  Context -Name 'VMware MFG Check' -Fixture {
    Mock -CommandName Get-WMIObject -ParameterFilter {
      $Class -eq 'Win32_ComputerSystem'
    } -MockWith {
      $obj = New-Object -TypeName psobject -Property $CompSysobj
      $obj.Manufacturer = 'VMware machine'
      Return $obj
    }
    $Result = Test-MDT_Virtual -Verbose
    
    It -name 'WMI Was Mocked for Win32_ComputerSystem' -test {
      Assert-MockCalled -CommandName Get-WMIObject -Times 1 -ParameterFilter {
        $Class -eq 'Win32_ComputerSystem'
      }
    }
    It -name 'Returned $True' -test {
      $Result | Should be $True
    }
  }
  #***************************************
  #endregion 2 VMware MFG test
  #***************************************
  
  #***************************************
  #region 2 Virtual test
  #***************************************
  Context -Name 'Virtual Check' -Fixture {
    Mock -CommandName Get-WMIObject -ParameterFilter {
      $Class -eq 'Win32_ComputerSystem'
    } -MockWith {
      $obj = New-Object -TypeName psobject -Property $CompSysobj
      $obj.Model = 'Virtual machine'
      $obj
      Return $obj
    }
    $Result = Test-MDT_Virtual -Verbose
    
    It -name 'WMI Was Mocked for Win32_ComputerSystem' -test {
      Assert-MockCalled -CommandName Get-WMIObject -Times 1 -ParameterFilter {
        $Class -eq 'Win32_ComputerSystem'
      }
    }
    It -name 'Returned $True' -test {
      $Result | Should be $True
    }
  }
  #***************************************
  #endregion 2 Virtual test
  #***************************************
}
#***************************************
#endregion 1 Main
#***************************************