<#
    .Synopsis
    Runs test cases against <Script>

    .DESCRIPTION
    Created: Jeff Scripter

    Version: 
    1.0.0 - 8/25/2016 - Jeff Scripter - Original


    Tests:
    1) Test1
    2) Test2

      
    Return:
      Test results+

    .EXAMPLE
      invoke-pester -Script H:\scripts\functions\Test-MDT_ACPower.tests.ps1

    Describing Test-MDT_ADPower
    Context No Battery Exists
    VERBOSE: -Return True
    [+] WMI Was Mocked to Null 3s
    [+] Returned True 18ms
    Context Battery with PowerOnline = True
    VERBOSE: -Batteries DischargeRate = 800
    VERBOSE: 
    VERBOSE: -Return True
    [+] WMI Was Mocked 140ms
    [+] Returned True 14ms
    Context Battery with PowerOnline = False
    VERBOSE: -Batteries DischargeRate = 
    VERBOSE: 
    VERBOSE: -Return False
    [+] WMI Was Mocked 91ms
    [+] Returned False 7ms
    Context Prompt! (Press Retry Twice) - Battery with PowerOnline = False
    VERBOSE: -Batteries DischargeRate = 
    VERBOSE: 
    VERBOSE: -User's responce to plugging in = Retry
    VERBOSE: -User's responce to plugging in = Retry
    VERBOSE: -Return False
    [+] WMI Was Mocked 3.13s
    [+] Returned False 27ms
    Context Prompt! (Press Abort) - Battery with PowerOnline = False
    VERBOSE: -Batteries DischargeRate = 
    VERBOSE: 
    VERBOSE: -User's responce to plugging in = Abort
    VERBOSE: -Return False
    [+] WMI Was Mocked 2.25s
    [+] Returned False 26ms
    Tests completed in 8.7s
    Passed: 10 Failed: 0 Skipped: 0 Pending: 0

#>
#***************************************
#region 1 sourcing Original File
#- Dot sources the script for functions (Shouldnt be done with scripts)
#***************************************
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).tolower().Replace(".tests.", ".")
#. "$here\$sut"
#***************************************
#endregion 1 sourcing Original File
#***************************************

#***************************************
#region 1 Import\Load 
#***************************************

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

#***************************************
#endregion 1 Mock Variables
#***************************************

#***************************************
#region 1 Main
#***************************************
Write-Output -InputObject "Test Date:`t`t $(Get-Date)"
Write-Output -InputObject "Test System:`t $Env:ComputerName"
Write-Output -InputObject "Test User:`t`t $Env:UserName"
Describe  "<Script>"{

  #***************************************
  #region 2 No Battery
  #***************************************
  Context "Test Description"{
    Mock -CommandName Get-WMIObject -ParameterFilter { $true} -MockWith {Return $Null}
    $Result = <Script> -verbose
    
    It "WMI Was Mocked to <Value>"{
      Assert-MockCalled -CommandName Get-WMIObject -Times 1
    }
    It "Returned <Return>"{
        $Result | Should be $TRUE
    }
  }
  #***************************************
  #endregion 2 No Battery
  #***************************************
  
}
#***************************************
#endregion 1 Main
#***************************************