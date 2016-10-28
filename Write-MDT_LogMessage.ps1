#requires -Version 3.0
Function Write-MDT_LogMessage
{
  <#
      .Synopsis
      Logs in the CM Format and writes output to the screen.

      .DESCRIPTION
      Created: Some Online source I forgot

      Version:  1.0.0 - Jeff Scripter - Original
      1.0.1 - Jeff Scripter - Replaced write-host, corrected some minor syntax
      1.0.2 - Jeff Scripter - added some autodetection for global variables
      1.0.3 - Jeff Scripter - added Debug
      1.0.4 - 2016-08-04 -Jeff Scripter - Fixed script name check
      1.0.5 - 2016-08-05 -Jeff Scripter - Fixed logfile order because the test-path failed
      1.0.6 - 2016-08-09 -Jeff Scripter - Fixed log file creation issue and variable exists = Null
      1.0.7 - 2016-08-16 -Jeff Scripter - Prevented verbose and debug from writing to the log if Pref variables not set.
      1.0.8 - 2016-08-29 -Jeff Scripter - Added Parameter help, types and updated some positional params
   
      Details: 
      Designed to create a log and communicate in the console

      Assumptions:
      $Global:ScriptName is Setup.

      .Examples
      Write-MDT_LogMessage -message "PS Host Version: $($host.Version.ToString())" -component $component -type 1

      .Examples
      Write-MDT_LogMessage -message "PS Host Version: $($host.Version.ToString())" -component $component -type 1

      .Examples
      Write-MDT_LogMessage -message "PS Host Version: $($host.Version.ToString())" -component $component -type 1
  #>

  Param (
    # This is the text that will appear in the message and log.
    [Parameter(Mandatory,HelpMessage='Message to appear in output stream and Log.')]
    [String]$message,
    
    # this updates the Component in the CMTrace format. <Scriptname>:<This Parameter>
    [string]$component = '',
    
    # This is the type of message. (1=into,2=Warning,3=Error,4=verbose,5=Debug, <custom> = Any text you want to group your message with)
    [string]$type = '1' )
  
  IF (Get-Variable -Name scriptName -Scope global -ErrorAction Ignore) 
  {
    $scriptName = $Global:ScriptName
  }
  Else
  {
    If ($Global:PSISE.CurrentFile.FullPath -NE $Null)
    {
      $scriptName = Split-Path -Leaf -Path $Global:PSISE.CurrentFile.FullPath
    }
    ElseIf($Global:MyInvocation.InvocationName -NE '')
    {
      $scriptName = Split-Path -Leaf -Path $Global:MyInvocation.InvocationName
    }
  }
  If ([string]$scriptName -eq '')
  {
    $scriptName = 'Powershell_MDTLOG'
  }
  If (([string](Get-Variable -Name LogFile -Scope Global -ErrorAction Ignore)) -EQ $Null)
  {
    $Global:LogFile = "$env:WINDIR\temp\$scriptName.log"
  }
  If (-not (Test-Path -Path $Global:LogFile -ErrorAction Ignore)) 
  {
    $Null = New-Item -Path $Global:LogFile -ItemType File
  }
  If (-Not (Get-Variable -Name MaxLogSizeInKB -Scope Global -ErrorAction Ignore) )
  {
    $Global:MaxLogSizeInKB = 5000
  }


  Switch ($type)
  {
    1 
    {
      $type = 'Info' 
    }
    2 
    {
      $type = 'Warning' 
    }
    3 
    {
      $type = 'Error' 
    }
    4 
    {
      $type = 'Verbose'
    }
    5 
    {
      $type = 'Debug'
    }
  }

  If ($type -eq 'Verbose')
  {
    If ($VerbosePreference -notin 'SilentlyContinue','Ignore'){
      $toLog = "{0} `$$<{1}><{2} {3}><thread={4}>" -f ($type + ':' + $message), ($Global:ScriptName + ':' + $component), (Get-Date -Format 'MM-dd-yyyy'), (Get-Date -Format 'HH:mm:ss.ffffff'), $pid
      $Null = $toLog | Out-File -Append -Encoding UTF8 -FilePath ('filesystem::{0}' -f $Global:LogFile)
      Write-Verbose -Message $message
    }
  }
  ElseIf ($type -eq 'Debug' )
  {
    If ($DebugPreference -notin 'SilentlyContinue','Ignore'){
      $toLog = "{0} `$$<{1}><{2} {3}><thread={4}>" -f ($type + ':' + $message), ($Global:ScriptName + ':' + $component), (Get-Date -Format 'MM-dd-yyyy'), (Get-Date -Format 'HH:mm:ss.ffffff'), $pid
      $Null = $toLog | Out-File -Append -Encoding UTF8 -FilePath ('filesystem::{0}' -f $Global:LogFile)
      Write-Debug -Message $message 
    }
  }
  ElseIf ($type -eq 'Error')
  {
    $toLog = "{0} `$$<{1}><{2} {3}><thread={4}>" -f ($type + ':' + $message), ($Global:ScriptName + ':' + $component), (Get-Date -Format 'MM-dd-yyyy'), (Get-Date -Format 'HH:mm:ss.ffffff'), $pid
    $Null = $toLog | Out-File -Append -Encoding UTF8 -FilePath ('filesystem::{0}' -f $Global:LogFile)
    Write-Error -Message $message 
  }
  ElseIf ($type -eq 'Warning')
  {
    $toLog = "{0} `$$<{1}><{2} {3}><thread={4}>" -f ($type + ':' + $message), ($Global:ScriptName + ':' + $component), (Get-Date -Format 'MM-dd-yyyy'), (Get-Date -Format 'HH:mm:ss.ffffff'), $pid
    $Null = $toLog | Out-File -Append -Encoding UTF8 -FilePath ('filesystem::{0}' -f $Global:LogFile)
    Write-Warning -Message $message 
  }
  Else
  {
    $toLog = "{0} `$$<{1}><{2} {3}><thread={4}>" -f ($type + ':' + $message), ($Global:ScriptName + ':' + $component), (Get-Date -Format 'MM-dd-yyyy'), (Get-Date -Format 'HH:mm:ss.ffffff'), $pid
    $Null = $toLog | Out-File -Append -Encoding UTF8 -FilePath ('filesystem::{0}' -f $Global:LogFile)
    Write-Output -InputObject $message
  }

  If ((Get-Item -Path $Global:LogFile).Length/1KB -gt $Global:MaxLogSizeInKB)
  {
    $log = $Global:LogFile
    $Null = Remove-Item -Path ($log.Replace('.log', '.lo_')) -Force -ErrorAction Ignore
    $Null = Rename-Item -Path $Global:LogFile -NewName ($log.Replace('.log', '.lo_')) -Force
  }
}

 
<#
$component = 'Test'
Write-MDT_LogMessage -message 'Test: 1' -component $component -type 1
Write-MDT_LogMessage -message 'Test: 2' -component $component -type 2
Write-MDT_LogMessage -message 'Test: 3' -component $component -type 3
Write-MDT_LogMessage -message 'Test: 4' -component $component -type 4 
Write-MDT_LogMessage -message 'Test: 5' -component $component -type 4 -Verbose
Write-MDT_LogMessage -message 'Test: 6' -component $component -type 5 -Verbose
Write-MDT_LogMessage -message 'Test: 7' -component $component -type 5
Write-MDT_LogMessage -message 'Test: 8' -component $component -type 5 -Debug
Write-MDT_LogMessage -message 'Test: 9' -component $component -type 5 
Write-MDT_LogMessage -message 'Test: 10' -component $component -type debug -Debug
Write-MDT_LogMessage -message 'Test: 11' -component $component -type error
Write-MDT_LogMessage -message 'Test: 12' -component $component -type warning
#>