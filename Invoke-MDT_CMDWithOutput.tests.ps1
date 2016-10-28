<#
    .Synopsis
    Runs test cases against Invoke-MDT_CMDWithOutput

    .DESCRIPTION
    Created: Jeff Scripter

    Version: 
    1.0.0 - 8/26/2016 - Jeff Scripter - Original


    Tests:
    1) Mock Diagnostic Process Object With Hide Window
      - Should change the 
    2) Test2

      
    Return:
      Test results

    .EXAMPLE
      invoke-pester -Script 

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
#***************************************
. "$here\Write-MDT_logMessage.ps1"
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

$StandardOutputObject = New-Object psobject -Property @{}
Add-Member -InputObject $StandardOutputObject -MemberType ScriptMethod -Name ReadToEnd -Value {
    return $Global:MockedReturn
}

$MockedPSI =  New-Object psobject -Property @{
        CreateNoWindow = $FALSE 
        UseShellExecute = $FALSE 
        RedirectStandardOutput = $FALSE 
        RedirectStandardError = $FALSE 
        FileName = ''
        Arguments = ''

    }

$Mockprocess = New-Object  psobject -Property @{
  StartInfo = ''
  StandardOutput = $StandardOutputObject 
  ExitCode = $Global:MockedExitCode
}
Add-Member -InputObject $Mockprocess -MemberType ScriptMethod -Name Start -Value {
    return $Null
}
Add-Member -InputObject $Mockprocess -MemberType ScriptMethod -Name WaitForExit -Value {
    return $Null
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

Describe  "Invoke-MDT_CMDWithOutput" {

  #***************************************
  #region 2 Test 1 Mock Diagnostic Process Object
  #***************************************
  Context "Mock Diagnostic Process Object"{
    $Global:MockedReturn = "test output"
    $Global:MockedExitCode = 3010
    Mock -CommandName New-Object -ParameterFilter { $TypeName -ilike 'System.Diagnostics.ProcessStartInfo' } -MockWith {
      Return $MockedPSI
    }
    Mock -CommandName New-Object -ParameterFilter { $TypeName -ilike 'System.Diagnostics.Process' } -MockWith {
      Return $Mockprocess
    }
    
    $Result = Invoke-MDT_CMDWithOutput -FilePath 'Test' -Arguments "Args" -loglevel 2 -warningVariable logging
    
    #- Test Mock of start info
    It "Process start info Was Mocked to Custom Object"{
      Assert-MockCalled -CommandName New-Object -Times 1 -ParameterFilter { $TypeName -ilike 'System.Diagnostics.ProcessStartInfo' } 
    }
    
    #- Test Mock of Process
    It "Process Was Mocked to Custom Object"{
      Assert-MockCalled -CommandName New-Object -Times 1 -ParameterFilter { $TypeName -ilike 'System.Diagnostics.Process' }
    }
    
    #- Did it return Correctly
    It "Returned ExitCode"{
        $Result[0] | Should be $Global:MockedExitCode
    }
    
    #Did the output return
    It "Returned Output"{
        $Result[1] | Should be $Global:MockedReturn
    }
    
    #Did logging match Filename
    It "Returned Output"{
        $logging[-1] | Should match $Global:MockedReturn
    }
    
  }
  #***************************************
  #endregion 2 No Battery
  #***************************************
  
}
#***************************************
#endregion 1 Main
#***************************************