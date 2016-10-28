Function Test-MDT_UEFIBoot
{
  <#
      .Synopsis
      Runs a preflight check for OSD task sequence to make sure the system is 

      .DESCRIPTION
      Created: was requested by Bob Underwood for Windows 10 project to look for the EFI boot loader.

      Version:  1.0.1 - 7/29/2016 - Jeff Scripter - Added logging
      1.0.0 - Jeff Scripter - Original
   
      Details: 
     

      Assumptions:
      we are looking for the \EFI\Microsoft\Boot\bootmgfw.efi bootloader

  #>
  [CmdletBinding()]
  [OutputType([Boolean])]
  Param
  (
    #Logging to informational from Verbose
    [switch] $NonverboseLogging
  )
  
  Begin
  {
    $component = "$($MyInvocation.InvocationName)-1.0.1"
    If ($NonverboseLogging)
    {
      $loggingLevel = 1
    }
    Else
    {
      $loggingLevel = 4
    }
    If (Get-Command -Name Write-MDT_LogMessage -ErrorAction Ignore) 
    {
      $blnLog = $true
    }
    $Return = $False
  }

  Process
  {
    $Output = Invoke-MDT_CMDWithOutput -FilePath $env:comspec -Arguments '/c bcdedit.exe' -CreateNoWindow
    If ($blnLog) 
    {
      Write-Verbose -Message "$( Write-MDT_LogMessage -message "- EFI loaders - $($Output  -match '\\EFI\\Microsoft\\Boot\\bootmgfw.efi')" -component $component -type $loggingLevel)"
    }
    
    If ($Output[1]  -match '\\EFI\\Microsoft\\Boot\\bootmgfw.efi')
    {
      $Return = $true
    }
  }
  END{
    If ($blnLog) 
    {
      Write-Verbose -Message "$( Write-MDT_LogMessage -message "Return $Return" -component $component -type $loggingLevel)"
    }
    Return $Return 
  }
}



Test-MDT_UEFIBoot

Test-MDT_UEFIBoot -NonverboseLogging -verbose