<#
    .Synopsis
    Runs test cases against Test-MDT_ACPower

    .DESCRIPTION
    Created: Jeff Scripter

    Version: 
    1.0.0 - 8/25/2016 - Jeff Scripter - Original


    Tests:
    1) Mocks Null return
    2) Mocks Battery Exists and is online
    3) Mocks battery exists but not online
    4) Mocks Battery Exists but not online with dialogs (Max retry reached)
    5) Mocks Battery Exists but not online with dialogs (Cancel)
    6) Mocks Battery Exists but not online with dialogs (Ignore)

      
    Return:
      Test results+

    .EXAMPLE
      invoke-pester -Script H:\scripts\functions\Test-MDT_ACPower.tests.ps1 -codecoverage H:\scripts\Functions\Test-MDT_ACPower.ps1

Test Date:		 08/29/2016 07:58:08
Test System:	 SCRIPJ1-L8
Test User:		 scripj1
Describing Test-MDT_ADPower
   Context No Battery Exists
VERBOSE: -Return True
    [+] WMI Was Mocked to Null 1.42s
    [+] Returned True 96ms
   Context Battery with PowerOnline = True
VERBOSE: -Batteries DischargeRate = 800
VERBOSE: 
VERBOSE: -Return True
    [+] WMI Was Mocked 350ms
    [+] Returned True 25ms
   Context Battery with PowerOnline = False
VERBOSE: -Batteries DischargeRate = 
VERBOSE: 
VERBOSE: -Return False
    [+] WMI Was Mocked 125ms
    [+] Returned False 11ms
   Context Prompt! (Press Retry Twice) - Battery with PowerOnline = False
VERBOSE: Created runspace pool
VERBOSE: ApartmentState: STA
VERBOSE: Runspace Pool Open
VERBOSE: Code invoked in runspace
VERBOSE: -Batteries DischargeRate = 
VERBOSE: 
VERBOSE: -User's responce to plugging in = Retry
VERBOSE: -User's responce to plugging in = Retry
VERBOSE: -Return False
    [+] WMI Was Mocked 2.62s
    [+] Returned False 18ms
   Context Prompt! (Press Abort) - Battery with PowerOnline = False
VERBOSE: Created runspace pool
VERBOSE: ApartmentState: STA
VERBOSE: Runspace Pool Open
VERBOSE: Code invoked in runspace
VERBOSE: -Batteries DischargeRate = 
VERBOSE: 
VERBOSE: -User's responce to plugging in = Abort
VERBOSE: -Return False
    [+] WMI Was Mocked 1.35s
    [+] Returned False 32ms
   Context Prompt! (Press Abort) - Battery with PowerOnline = False
VERBOSE: Created runspace pool
VERBOSE: ApartmentState: STA
VERBOSE: Runspace Pool Open
VERBOSE: Code invoked in runspace
VERBOSE: -Batteries DischargeRate = 
VERBOSE: 
VERBOSE: -User's responce to plugging in = Ignore
VERBOSE: -Return True
    [+] WMI Was Mocked 1.4s
    [+] Returned False 27ms
Tests completed in 7.47s
Passed: 12 Failed: 0 Skipped: 0 Pending: 0

Code coverage report:
Covered 100.00 % of 31 analyzed commands in 1 file.

#>
#***************************************
#region 1 sourcing Original File
#- Dot sources the script for functions (Shouldnt be done with scripts)
#***************************************
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).tolower().Replace(".tests.", ".")
. "$here\$sut"
#***************************************
#endregion 1 sourcing Original File
#***************************************

#***************************************
#region 1 Import\Load 
#- Load Runspaces to manage the Dialog testing by sending keys to the targeted window.
#***************************************
Import-module $here\Runspace.psm1
. $here\Write-MDT_LogMessage.ps1
#***************************************
#endregion 1 Import\Load 
#***************************************

#***************************************
#region 1 Standard Variables
#-These are variables I put in all of my scripts and are used for logging, location detection and other general detection.
#***************************************
$global:logFile = "$env:windir\temp\$(Split-Path -Leaf $MyInvocation.MyCommand.Path).log"
#***************************************
#endregion 1 Standard Variables
#***************************************

#***************************************
#region 1 Mock Variables
#-These are the variables\objects we use in the different tests
#***************************************
$OnlineBatteryWMIObject =  New-Object psobject -Property @{
    __GENUS            = 2
    __CLASS            = 'BatteryStatus'
    __SUPERCLASS       = 'MSBatteryClass'
    __DYNASTY          = 'CIM_StatisticalInformation'
    __RELPATH          = 'BatteryStatus.InstanceName="ACPI\\PNP0C0A\\1_0"'
    __PROPERTY_COUNT   = 20
    __DERIVATION       = '{MSBatteryClass, Win32_PerfRawData, Win32_Perf, CIM_StatisticalInformation}'
    __SERVER           = $env:Computername
    __NAMESPACE        = 'root\WMI'
    __PATH             = "\\$env:Computername\root\WMI=BatteryStatus.InstanceName=""ACPI\\PNP0C0A\\1_0"""
    Active             = $True
    Caption            = ''
    ChargeRate         = 3744
    Charging           = $True
    Critical           = $False
    Description        = ''
    DischargeRate      = 800
    Discharging        = $False
    Frequency_Object   = ''
    Frequency_PerfTime = ''
    Frequency_Sys100NS = ''
    InstanceName       = 'ACPI\PNP0C0A\1_0'
    Name               = ''
    PowerOnline        = $True
    RemainingCapacity  = 53643
    Tag                = 1
    Timestamp_Object   = ''
    Timestamp_PerfTime = ''
    Timestamp_Sys100NS = ''
    Voltage            = 8772
    PSComputerName     = $env:Computername
}
#***************************************
#endregion 1 Mock Variables
#***************************************

#***************************************
#region 1 Main
#***************************************
Write-Output -InputObject "Test Date:`t`t $(Get-Date)"
Write-Output -InputObject "Test System:`t $Env:ComputerName"
Write-Output -InputObject "Test User:`t`t $Env:UserName"
Describe  "Test-MDT_ADPower"{

  #***************************************
  #region 2 No Battery
  #***************************************
  Context "No Battery Exists"{
    Mock -CommandName Get-WMIObject -ParameterFilter { $Namespace -ieq 'root/WMI' -and $Class -ieq 'BatteryStatus'} -MockWith {Return $Null}
    $Result = Test-MDT_ACPower -verbose
    
    It "WMI Was Mocked to Null"{
      Assert-MockCalled -CommandName Get-WMIObject -Times 1
    }
    It "Returned True"{
        $Result | Should be $TRUE
    }
  }
  #***************************************
  #endregion 2 No Battery
  #***************************************
  
  #***************************************
  #region 2 Battery is plugged in
  #***************************************
  Context "Battery with PowerOnline = $true"{
    Mock -CommandName Get-WMIObject -ParameterFilter {$Namespace -eq 'root/WMI' -and $Class -eq 'BatteryStatus' -and $Filter -ieq 'poweronline = True'} -MockWith {
      return $OnlineBatteryWMIObject
    }
   
    $wmi = Get-WmiObject -Namespace root/WMI -ClassName BatteryStatus -Filter 'poweronline = True'
    $Result = Test-MDT_ACPower -verbose

    It "WMI Was Mocked"{
      Assert-MockCalled -CommandName Get-WMIObject -Times 1
    }
    It "Returned True"{
        $Result | Should be $True
    }
  }
  #***************************************
  #endregion 2 No Battery
  #*************************************** 

  #***************************************
  #region 2 Battery not plugged in (No Prompt)
  #***************************************
  Context "Battery with PowerOnline = $False"{
    Mock -CommandName Get-WMIObject -ParameterFilter {$Namespace -eq 'root/WMI' -and $Class -eq 'BatteryStatus' -and $Filter -ieq 'poweronline = True'} -MockWith {return $Null}
    Mock -CommandName Get-WMIObject -ParameterFilter {$Namespace -eq 'root/WMI' -and $List -eq 'BatteryStatus'} -MockWith {Return $True }
   
    $wmi = Get-WmiObject -Namespace root/WMI -ClassName BatteryStatus -Filter 'poweronline = True'
    $Result = Test-MDT_ACPower -verbose

    It "WMI Was Mocked"{
      Assert-MockCalled -CommandName Get-WMIObject -Times 1
    }
    It "Returned False"{
        $Result | Should be $False
    }

  }
  #***************************************
  #endregion 2 Battery not plugged in in (No Prompt)
  #***************************************
  
  #***************************************
  #region 2 Battery not plugged in (Retry twice)
  #***************************************
  
  Context "Prompt! (Press Retry Twice) - Battery with PowerOnline = $False"{
    Mock -CommandName Get-WMIObject -ParameterFilter {$Namespace -eq 'root/WMI' -and $Class -eq 'BatteryStatus' -and $Filter -ieq 'poweronline = True'} -MockWith {return $Null}
    Mock -CommandName Get-WMIObject -ParameterFilter {$Namespace -eq 'root/WMI' -and $List -eq 'BatteryStatus'} -MockWith {Return $True }
   
    $wmi = Get-WmiObject -Namespace root/WMI -ClassName BatteryStatus -Filter 'poweronline = True'

    $DialogRunSpacePool = New-RunspacePool  
    $RetryDialogRS = New-RunspaceJob -JobName RetryDialog -RunspacePool $DialogRunSpacePool  -ScriptBlock {
        $Count = 0
        $Null = Add-Type -AssemblyName Microsoft.VisualBasic
        While ($Count -LT 2){
        Try
        {
          $WindowSelected = $true
          [Microsoft.VisualBasic.Interaction]::AppActivate("AC Power Warning")
        }
        Catch
        {
          $WindowSelected = $False
        }
        If($WindowSelected)
        {
          [Windows.Forms.SendKeys]::SendWait('{Tab}')
          [Windows.Forms.SendKeys]::SendWait('{Enter}')
          $Count++
        }
        Start-Sleep -Seconds 1
        }
    }

    $Result = Test-MDT_ACPower -verbose -prompt -MaxCount 2

    It "WMI Was Mocked"{
      Assert-MockCalled -CommandName Get-WMIObject -Times 1
    }
    It "Returned False"{
        $Result | Should be $False
    }
  }
  #***************************************
  #region 2 Battery not plugged in (Retry twice)
  #***************************************
  
  #***************************************
  #region 2 Battery not plugged in (Abort)
  #***************************************
    Context "Prompt! (Press Abort) - Battery with PowerOnline = $False"{
      Mock -CommandName Get-WMIObject -ParameterFilter {$Namespace -eq 'root/WMI' -and $Class -eq 'BatteryStatus' -and $Filter -ieq 'poweronline = True'} -MockWith {return $Null}
      Mock -CommandName Get-WMIObject -ParameterFilter {$Namespace -eq 'root/WMI' -and $List -eq 'BatteryStatus'} -MockWith {Return $True }
   
      $wmi = Get-WmiObject -Namespace root/WMI -ClassName BatteryStatus -Filter 'poweronline = True'
      
      $DialogRunSpacePool = New-RunspacePool 
      $CancelDialogRS = New-RunspaceJob -JobName CancelDialog -RunspacePool $DialogRunSpacePool -ScriptBlock {
          $Count = 0
          $Null = Add-Type -AssemblyName Microsoft.VisualBasic
          While ($Count -eq 0){
          Try
          {
            $WindowSelected = $true
            [Microsoft.VisualBasic.Interaction]::AppActivate("AC Power Warning")
          }
          Catch
          {
            $WindowSelected = $False
          }
          If($WindowSelected)
          {
            [Windows.Forms.SendKeys]::SendWait('{Enter}')
            $Count++
          }
          Start-Sleep -Seconds 1
          }
      }
      
      $Result = Test-MDT_ACPower -verbose -prompt -MaxCount 2

      It "WMI Was Mocked"{
        Assert-MockCalled -CommandName Get-WMIObject -Times 1
      }
      It "Returned False"{
        $Result | Should be $False
      }
    }
  #***************************************
  #region 2 Battery not plugged in (Abort)
  #***************************************
  
  #***************************************
  #region 2 Battery not plugged in (Ignore)
  #***************************************
    Context "Prompt! (Press Abort) - Battery with PowerOnline = $False"{
      Mock -CommandName Get-WMIObject -ParameterFilter {$Namespace -eq 'root/WMI' -and $Class -eq 'BatteryStatus' -and $Filter -ieq 'poweronline = True'} -MockWith {return $Null}
      Mock -CommandName Get-WMIObject -ParameterFilter {$Namespace -eq 'root/WMI' -and $List -eq 'BatteryStatus'} -MockWith {Return $True }
   
      $wmi = Get-WmiObject -Namespace root/WMI -ClassName BatteryStatus -Filter 'poweronline = True'
      
      $DialogRunSpacePool = New-RunspacePool 
      $CancelDialogRS = New-RunspaceJob -JobName CancelDialog -RunspacePool $DialogRunSpacePool -ScriptBlock {
          $Count = 0
          $Null = Add-Type -AssemblyName Microsoft.VisualBasic
          While ($Count -eq 0){
          Try
          {
            $WindowSelected = $true
            [Microsoft.VisualBasic.Interaction]::AppActivate("AC Power Warning")
          }
          Catch
          {
            $WindowSelected = $False
          }
          If($WindowSelected)
          {
            [Windows.Forms.SendKeys]::SendWait('{Tab}')
            [Windows.Forms.SendKeys]::SendWait('{Tab}')
            [Windows.Forms.SendKeys]::SendWait('{Enter}')
            $Count++
          }
          Start-Sleep -Seconds 1
          }
      }
      
      $Result = Test-MDT_ACPower -verbose -prompt -MaxCount 2

      It "WMI Was Mocked"{
        Assert-MockCalled -CommandName Get-WMIObject -Times 1
      }
      It "Returned False"{
        $Result | Should be $True
      }
    }
  #***************************************
  #region 2 Battery not plugged in (Ignore)
  #***************************************
  
}
#***************************************
#endregion 1 Main
#***************************************