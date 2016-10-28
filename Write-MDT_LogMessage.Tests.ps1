<#
    .Synopsis
    Runs test cases against Write-MDT_LogMessage

    .DESCRIPTION
    Created: Jeff Scripter

    Version: 
    1.0.0 - 8/25/2016 - Jeff Scripter - Original


    Tests:
    1) Write-MDT_LogMessage -message 'Test: 1' -component $component -type 1  # Log info
    2) Write-MDT_LogMessage -message 'Test: 2' -component $component -type 2  # Log warning
    3) Write-MDT_LogMessage -message 'Test: 3' -component $component -type 3  # Log Error
    4) Write-MDT_LogMessage -message 'Test: 4' -component $component -type 4  # No log
    5) Write-MDT_LogMessage -message 'Test: 5' -component $component -type 4 -Verbose  #  Log Verbose With Verbose
    6) Write-MDT_LogMessage -message 'Test: 6' -component $component -type 5 -Verbose  # No Log
    7) Write-MDT_LogMessage -message 'Test: 7' -component $component -type 5 -Debug  #log Debug with Debug Switch
    8) Write-MDT_LogMessage -message 'Test: 8' -component $component -type debug -Debug # Log Debug
    9) Write-MDT_LogMessage -message 'Test: 9' -component $component -type error # log error
    10) Write-MDT_LogMessage -message 'Test: 10' -component $component -type $env:Computername # log with custom prefix
    11) Write-MDT_LogMessage -message 'Test: 11' -component $component -type warning # log warning

      
    Return:
      Test results+

    .EXAMPLE
      PS H:\> Invoke-Pester -script H:\Scripts\Functions\Write-MDT_LogMessage.Tests.ps1

        Test Date:		 08/26/2016 16:12:48
        Test System:	 SCRIPJ1-L8
        Test User:		 scripj1
        Describing Write-MDT_LogMessage
           Context Test Information output
            [+] Returned Output - Test: Info 199ms
            [+] Creates New Log 9ms
            [+] Wrote Log 10ms
           Context Test Warning Output
        WARNING: Test: Warning
            [+] Returned Output - Test: Warning 25ms
            [+] Wrote Log 16ms
           Context Test Error output
        Write-MDT_LogMessage : Test: Error
        At H:\Scripts\Functions\Write-MDT_LogMessage.Tests.ps1:176 char:5
        +     Write-MDT_LogMessage -message $message -component $component -typ ...
        +     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            + CategoryInfo          : NotSpecified: (:) [Write-Error], WriteErrorException
            + FullyQualifiedErrorId : Microsoft.PowerShell.Commands.WriteErrorException,Write-MDT_LogMessage
 
            [+] Returned Output - Test: Error 35ms
            [+] Wrote Log 11ms
           Context Test Verbose output
            [+] Returned Output - Test: Verbose 37ms
            [+] Returned Output - Test: Verbose 11ms
            [+] Wrote Log 7ms
           Context Test Verbose output
            [+] Returned Output - Test: Verbose 41ms
            [+] Returned Output - Test: Verbose 8ms
            [+] Wrote Log 11ms
           Context Test Verbose output
            [+] Returned Output - Test: Debug 31ms
            [+] Returned Output - Test: Debug 7ms
            [+] Wrote Log 12ms
           Context Test Verbose output
            [+] Returned Output - Test: Debug 33ms
            [+] Returned Output - Test: Debug 7ms
            [+] Wrote Log 8ms
           Context Test Verbose output
            [+] Returned Output - Test: Debug 29ms
            [+] Returned Output - Test: Debug 6ms
            [+] Wrote Log 12ms
           Context Test Warning Output
        WARNING: Test: Warning
            [+] Returned Output - Test: Warning 23ms
            [+] Wrote Log 10ms
           Context Test Error output
        Write-MDT_LogMessage : Test: Error
        At H:\Scripts\Functions\Write-MDT_LogMessage.Tests.ps1:399 char:5
        +     Write-MDT_LogMessage -message $message -component $component -typ ...
        +     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            + CategoryInfo          : NotSpecified: (:) [Write-Error], WriteErrorException
            + FullyQualifiedErrorId : Microsoft.PowerShell.Commands.WriteErrorException,Write-MDT_LogMessage
 
            [+] Returned Output - Test: Error 81ms
            [+] Wrote Log 10ms
            [+] Creates New Log 7ms
        Tests completed in 707ms
        Passed: 27 Failed: 0 Skipped: 0 Pending: 0

#>
#***************************************
#region 1 sourcing Original File
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
#-None
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
Describe  'Write-MDT_LogMessage'{

  #***************************************
  #region 2 Test 1 Create File and Log information to file and Output stream
  #-Should write to log
  #***************************************
  Context "Test Information output"{
    If (Test-Path -Path $global:logfile)
    {
      Remove-Item -Path $global:logfile -Force
    }
    $component = "Test1"
    $message = 'Test: Info'
    
    $Result = Write-MDT_LogMessage -message $message -component $component -type 1 
    
    #- Catch output and match to what was logging
    It "Returned Output - $message"{
        $Result | Should be $message
    }

    #- Does log exist
    It "Creates New Log"{
        Test-Path -Path $global:logfile| Should be $true
    }
    
    #- Did it log correctly
    It "Wrote Log"{
        Get-content -Path $global:logfile -Tail 1| Should match $message
    }
  }
  #***************************************
  #endregion 2 Test 1 Create File and Log information to file and Output stream
  #***************************************

  #***************************************
  #region 2 Test 2 Warning with number
  #- Should write warning
  #***************************************
  Context "Test Warning Output"{
    $component = "Test2"
    $message = 'Test: Warning'
    
    Remove-Variable -name LogFile -scope global -ErrorAction Ignore
    Remove-Variable -name ScriptName -scope global -ErrorAction Ignore
    Remove-Variable -name MaxLogSizeInKB -scope global -ErrorAction Ignore
    
    Write-MDT_LogMessage -message $message -component $component -type 2 -WarningVariable result
    
    #- Catch output and match to what was logging
    It "Returned Output - $message"{
      $Result | Should be $message
    }

    #- Did it log correctly
    It "Wrote Log"{
      Get-content -Path $global:logfile -Tail 1| Should match $message
    }
  }
  #***************************************
  #endregion 2 Test 2 Warning with number
  #***************************************

  #***************************************
  #region 2 Test 3 Error with number
  #- should write Error
  #***************************************
  Context "Test Error output"{
    $component = "Test3"
    $message = 'Test: Error'
    
    Write-MDT_LogMessage -message $message -component $component -type 3 -ErrorVariable result
    $error.remove($error[0])
    
    #- Catch output and match to what was logging
    It "Returned Output - $message"{
        $Result | Should be $message
    }

    #- Did it log correctly
    It "Wrote Log"{
        Get-content -Path $global:logfile -Tail 1| Should match $message
    }
  }
  #***************************************
  #endregion 2 Test 3 Error with number
  #***************************************
  
  #***************************************
  #region 2 Test 4 Verbose with number and not Verbose flag
  #-Should NOT Write verbose
  #***************************************
  Context "Test Verbose output"{
    Mock -CommandName Write-Verbose -MockWith {Write-Output -InputObject $message}
    $component = "Test4"
    $message = 'Test: Verbose'
    $oldVerboseSetting = $verbosePreference
    $verbosePreference = "SilentlyContinue"
    $result = Write-MDT_LogMessage -message $message -component $component -type 4 
    $verbosePreference = $oldVerboseSetting

    #- Make sure Mock wasnt called
    It "Returned Output - $message"{
        Assert-MockCalled -CommandName  Write-Verbose -Exactly 0
    }
    
    #- Catch output and Make sure it didnt log
    It "Returned Output - $message"{
        $Result | Should not be $message
    }
    
    #- Did it log correctly
    It "Wrote Log"{
        Get-content -Path $global:logfile -Tail 1| Should not match $message
    }
  }
  #***************************************
  #endregion 2 Test 4 Verbose with number and not Verbose flag
  #***************************************
  
  #***************************************
  #region 2 Test 5 Verbose with number and with Verbose flag
  #- Should write Verbose
  #***************************************
  Context "Test Verbose output"{
    Mock -CommandName Write-Verbose -MockWith {Write-Output -InputObject $message}
    $component = "Test5"
    $message = 'Test: Verbose'
    $oldVerboseSetting = $verbosePreference
    $verbosePreference = "SilentlyContinue"
    $result = Write-MDT_LogMessage -message $message -component $component -type 4 -Verbose
    $verbosePreference = $oldVerboseSetting

    #- Make sure Mock was called
    It "Returned Output - $message"{
        Assert-MockCalled -CommandName  Write-Verbose -Exactly 1
    }
    
    #- Catch output and match to what was logging
    It "Returned Output - $message"{
        $Result | Should be $message
    }
    
    #- Did it log correctly
    It "Wrote Log"{
        Get-content -Path $global:logfile -Tail 1| Should match $message
    }
  }
  #***************************************
  #endregion 2 Test 5 Verbose with number and with Verbose flag
  #***************************************
  
  #***************************************
  #region 2 Test 6 Debug with number and with Verbose flag
  #-Should Not Write Debug or Verbose
  #***************************************
  Context "Test Verbose output"{
    Mock -CommandName Write-Debug -MockWith {Write-Output -InputObject $message}
    $component = "Test6"
    $message = 'Test: Debug'
    $oldVerboseSetting = $verbosePreference
    $verbosePreference = "SilentlyContinue"
    $oldDebugSetting = $DebugPreference
    $DebugPreference = "SilentlyContinue"
    $result = Write-MDT_LogMessage -message $message -component $component -type 5 -Verbose
    $verbosePreference = $oldVerboseSetting
    $DebugPreference = $oldDebugSetting

    #- Make sure Mock wasnt called
    It "Returned Output - $message"{
      Assert-MockCalled -CommandName  Write-Debug -Exactly 0
    }
    
    #- Catch output and make sure it didnt write
    It "Returned Output - $message"{
      $Result | Should not be $message
    }
    
    #- Did it Not Log
    It "Wrote Log"{
      Get-content -Path $global:logfile -Tail 1| Should not match $message
    }
  }
  #***************************************
  #endregion 2 Test 6 Debug with number and with Verbose flag
  #***************************************
 
  #***************************************
  #region 2 Test 7 Debug with number and with Debug 
  #-Should Write Debug
  #***************************************
  Context "Test Verbose output"{
    Mock -CommandName Write-Debug -MockWith {Write-Output -InputObject $message}
    $component = "Test7"
    $message = 'Test: Debug'
    $oldVerboseSetting = $verbosePreference
    $verbosePreference = "SilentlyContinue"
    $oldDebugSetting = $DebugPreference
    $DebugPreference = "Continue"
    $result = Write-MDT_LogMessage -message $message -component $component -type 5  -debug
    $verbosePreference = $oldVerboseSetting
    $DebugPreference = $oldDebugSetting

    #- Make sure Mock was called
    It "Returned Output - $message"{
      Assert-MockCalled -CommandName  Write-Debug -Exactly 1
    }
    
    #- Catch output and match to what was logging
    It "Returned Output - $message"{
      $Result | Should be $message
    }
    
    #- Did it log correctly
    It "Wrote Log"{
      Get-content -Path $global:logfile -Tail 1| Should match $message
    }
  }
  #***************************************
  #endregion 2 Test 7 Debug with number and with Debug 
  #***************************************
  
  #***************************************
  #region 2 Test 8 Debug with Word and with Debug flag
  #- Should write Debug
  #***************************************
  Context "Test Verbose output"{
    Mock -CommandName Write-Debug -MockWith {Write-Output -InputObject $message}
    $component = "Test8"
    $message = 'Test: Debug'
    $oldVerboseSetting = $verbosePreference
    $verbosePreference = "SilentlyContinue"
    $oldDebugSetting = $DebugPreference
    $DebugPreference = "Continue"
    $result = Write-MDT_LogMessage -message $message -component $component -type Debug -debug
    $verbosePreference = $oldVerboseSetting
    $DebugPreference = $oldDebugSetting

    #- Make sure Mock wasnt called
    It "Returned Output - $message"{
      Assert-MockCalled -CommandName  Write-Debug -Exactly 1
    }
    
    #- Catch output and match to what was logging
    It "Returned Output - $message"{
      $Result | Should be $message
    }
    
    #- Did it log correctly
    It "Wrote Log"{
      Get-content -Path $global:logfile -Tail 1| Should match $message
    }
  }
  #***************************************
  #endregion 2 Test 8 Debug with Word and without Debug flag
  #***************************************
  
  #***************************************
  #region 2 Test 9 Warning with Word
  #-Should write warning
  #***************************************
  Context "Test Warning Output"{
    $component = "Test9"
    $message = 'Test: Warning'
    
    Write-MDT_LogMessage -message $message -component $component -type Warning -WarningVariable result
    
    #- Catch output and match to what was logging
    It "Returned Output - $message"{
        $Result | Should be $message
    }

    #- Did it log correctly
    It "Wrote Log"{
        Get-content -Path $global:logfile -Tail 1| Should match $message
    }
  }
  #***************************************
  #endregion 2 Test 9 Warning with Word
  #***************************************
  
  #***************************************
  #region 2 Test 10 Custom with Word
  #-Should write custom prefix
  #***************************************
  Context "Test Warning Output"{
    $component = "Test10"
    $message = 'Test: Warning'
    
    Write-MDT_LogMessage -message $message -component $component -type $env:computername

    #- Did it log correctly
    It "Wrote Log"{
        Get-content -Path $global:logfile -Tail 1| Should match "$env:computername:$message"
    }
    
  }
  #***************************************
  #endregion 2 Test 10 Warning with Word
  #***************************************
  
  #***************************************
  #region 2 Test 11 Error with Word
  #-Should Write Error
  #***************************************
  Context "Test Error output"{
    If (Test-Path -Path $Global:LogFile.Replace('.log', '.lo_'))
    { 
      Remove-Item -path $Global:LogFile.Replace('.log', '.lo_') -force 
    }
    $global:MaxLogSizeInKB = 0.5
    $component = "Test11"
    $message = 'Test: Error'
    
    Write-MDT_LogMessage -message $message -component $component -type Error -ErrorVariable result
    $error.remove($error[0])
    
    #- Catch output and match to what was logging
    It "Returned Output - $message"{
        $Result | Should be $message
    }

    #- Did it log correctly
    It "Wrote Log"{
        Get-content -Path $Global:LogFile.Replace('.log', '.lo_') -Tail 1| Should match $message
    }
    
     #- Does log backup exist
    It "Creates New Log"{
        Test-Path -Path $Global:LogFile.Replace('.log', '.lo_')| Should be $true
    }
  }
  #***************************************
  #endregion 2 Test 11 Error with Word
  #***************************************
}
#***************************************
#endregion 1 Main
#***************************************
& cmtrace $Global:LogFile.Replace('.log', '.lo_')

