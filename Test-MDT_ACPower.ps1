#requires -Version 3
Function Test-MDT_ACPower 
{
  <#
      .Synopsis
      Checks if The local system has a battery and if it does, it checks that it is plugged in

      .DESCRIPTION
      Created: Jeff Scripter

      Version:  1.0.1 - 7/29/2016 - Jeff Scripter - Added logging
      1.0.0 - 7/13/2016 - Jeff Scripter - Original


      Assumptions: NA
      
      Return:
      True - If there is no battery or if the Battery is online for power. 
      $False - If there is a battery and it isnt online power.

      .EXAMPLE
      PS H:\> . 'H:\Scripts\Functions\Test-ACPower.ps1'
      True


  #>

  [CmdletBinding()]
  [OutputType([int])]
  Param
  (
    # IF switch is present, we will ask the user if they want to connect the power and retry.
    [Switch] $Prompt,
    
    # If we are prompting, this is the max number of times we prompt. 
    [int] $MaxCount = 5 
    
  )

  Begin
  {
    $component = "$($MyInvocation.InvocationName)-1.0.1"
    $loggingLevel = 4
    If (Get-Command -Name Write-MDT_LogMessage -ErrorAction Ignore) 
    {
      $blnLog = $true
    }
    $Return = $False
    $BatteryStatus = Get-WmiObject -Namespace root/WMI -List BatteryStatus
    $IsACPower = $true
  }
  Process
  {


    IF ($BatteryStatus -NE $Null)
    {
      $Counter = 0
      $BatteryStatus = Get-WmiObject -Namespace root/WMI -Class BatteryStatus -Filter 'poweronline = True'
      If ($blnLog) 
      {
        Write-Verbose -Message "$(Write-MDT_LogMessage  -message "-Batteries DischargeRate = $($BatteryStatus.DischargeRate)" -component $component -type $loggingLevel)"
      }      
      While ($BatteryStatus -EQ $Null -and $Return -NE 'Ignore')
      {
        $BatteryStatus = Get-WmiObject -Namespace root/WMI -Class BatteryStatus  -Filter 'poweronline = True'
        IF ($BatteryStatus -EQ $Null)
        {
          $Counter++
          If( $Prompt)
          {
            $Null = [reflection.assembly]::loadwithpartialname('System.Windows.Forms')
            $Return = [Windows.Forms.MessageBox]::Show("Power adapter is not plugged in. `nPlease plug in the system then click retry to continue or click cancel to Exit.",'AC Power Warning',2)
            If ($blnLog) 
            {
              Write-MDT_LogMessage  -message "-User's responce to plugging in = $Return" -component $component -type $loggingLevel
            }
          }
          If ($Return -EQ 'Cancel' -or $Return -EQ 'Abort' -or $Counter -eq $MaxCount -or (-Not $Prompt))
          {
            $Return = 'Ignore'
            $IsACPower = $False
          }
        }
      }
    }
  }
  End
  {
    If ($blnLog) 
    {
      Write-MDT_LogMessage  -message "-Return $IsACPower" -component $component -type $loggingLevel
    }    
    Return $IsACPower
  }
}


#Test-MDT_ACPower -verbose 
