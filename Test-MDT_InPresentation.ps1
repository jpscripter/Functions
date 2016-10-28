#requires -Version 2
function Test-MDT_InPresentation
{
  <#
      .Synopsis
      Looks for a current Presentation on the computer. 

      .DESCRIPTION
      Created: Jeff Scripter

      Version: 1.0.0 - 7/20/2016 - Jeff Scripter - Original


      Assumptions: NA
      
      Return:
      True - If there is no battery or if the Battery is online for power. 
      $False - If there is a battery and it isnt online power.

      .EXAMPLE
      PS H:\> . 'H:\Scripts\Functions\Test-MDT_IsPresenting.ps1'
      False

      .EXAMPLE
      PS H:\> . 'H:\Scripts\Functions\Test-MDT_IsPresenting.ps1' -verbose
      VERBOSE: The object written to the pipeline is an instance of the type "Microsoft.Office.Interop.PowerPoint.ApplicationClass" 
      from the component's primary interoperability assembly. If this type exposes different members than the IDispatch members, scr
      ipts that are written to work with this object might not work if the primary interoperability assembly is not installed.
      VERBOSE: -Powerpoint Com Object Check = 
      VERBOSE: -PowerPoint Presentation Window found: PowerPoint Slide Show - [Presentation1]
      VERBOSE: -Return - True
      True

  #>

  [CmdletBinding()]
  [OutputType([Boolean])]
  Param
  (
 
  )

  Begin
  {
    $component = "$($MyInvocation.InvocationName)-1.0.0"
    If (Get-Command -Name Write-MDT_LogMessage -ErrorAction Ignore) {$blnLog = $true}
    $Return = $False
  }
  Process
  {
        
    # Com Object Check (PowerPoint)
    $PPT = New-Object -ComObject powerpoint.application 
    $ComReturn = $PPT.SlideShowWindows -NE $Null
    Write-MDT_LogMessage -message "-Powerpoint Com Object Check = $ComReturn" -component $component -type 4
    
    #Window Check (PowerPoint)
    $presentations = Get-Process | Where-Object -FilterScript {
       $_.MainWindowTitle -like 'PowerPoint Slide Show*'
    } 
    If ($presentations.MainWindowTitle -NE $NUll){Write-MDT_LogMessage -message "-PowerPoint Presentation Window found: $($presentations.MainWindowTitle)" -component $component -type 4}
  }

  End
  {
    $return = $ComReturn -or ($presentations -NE $NUll)
    Write-MDT_LogMessage -message "-Return - $return" -component $component -type 4 
    Return [boolean]$Return
  }
}

Test-MDT_InPresentation 
. Test-MDT_InPresentation -Verbose




