
Function Test-MDT_OS
{

  <#
      .Synopsis
      Preforms basic validation of the operating systems

      .DESCRIPTION
      Created: Jeff Scripter

      Version: 1.0.0 - Jeff Scripter - Original
   
      Details: 
      Test the os object to make sure it is Compliant with caption, version and architectures passed in

      Assumptions:
      Use win32_OperatingSystem


      .EXAMPLE
      PS C:\WINDOWS\system32> Test-OS -ValidOSCaptions '6' -Workstation -Architecture "64"
      True

      .EXAMPLE
      PS C:\WINDOWS\system32> Test-OS -ValidOSCaptions '6' -Workstation -Architecture "32"
      False

      .EXAMPLE
      PS C:\WINDOWS\system32> Test-OS -ValidOSCaptions '6' -server -Architecture "64"
      False


  #>

  [CmdletBinding()]
  [OutputType([int])]
  Param
  (
    # List of Valid OS Names
    [Parameter(ValueFromPipelineByPropertyName=$true,
    Position=0)]
    [String[]]$ValidOSCaptions,
         
    # List of Valid OS versions
    [Parameter(ValueFromPipelineByPropertyName=$true,
    Position=0)]
    [String[]]$ValidOSVersions,

    # Checks win32_operatingsystem product type for 3
    [Switch]$Server,

    # Checks win32_operatingsystem product type for 1
    [Switch]$Workstation,

    # Arch check 
    [string] $Architecture
  )

  Begin
  {
    $component = "$($MyInvocation.InvocationName)-1.0.0"
    $loggingLevel = 4
    If (Get-Command -Name Write-MDT_LogMessage -ErrorAction Ignore) {$blnLog = $true}
    $Return = $False
        
    $OSObject = Get-WmiObject -Namespace root/cimv2 -Class Win32_OperatingSystem
    $BlnValidOS = $False
    $BlnCap = $False
    $BlnVer = $False
    $Blnproducttype = $False
    $ProductType = ''
    Switch ($TRUE){
      $server {
        $productType = 3
        Break
      }
      $workstation{
        $productType = 1
        Break
      }
      Default{
        $productType = $OSObject.producttype
        Break
      }

    }
  }
  Process
  {
    # Captions 
    If($ValidOSCaptions -NE $null){
      Foreach ($Caption in $ValidOSCaptions){
        If ($OSObject.caption -Match $Caption){
          $BlnCap = $True                       
        }
      }
    }Else{
      $BlnCap = $True
    }
    If ($blnLog) {Write-MDT_LogMessage -message "-Result - $BlnCap - $Caption in - $($OSObject.caption)" -component $component -type $loggingLevel}   
    
    #versions
    If($ValidOSVersions -NE $null){
      Foreach ($Version in $ValidOSVersions){
        If ($OSObject.Version -Match $Version){
          $BlnVer = $True
        }
      }
    }Else{
      $BlnVer = $True
    }
    If ($blnLog) {Write-MDT_LogMessage -message "-Result - $BlnVer - $Version in - $($OSObject.Version)" -component $component -type $loggingLevel}
        

    #arch
    If ($OSObject.OSArchitecture -match $Architecture -or $Architecture -eq $Null){
      $BlnArch = $True
    }
    If ($blnLog) {Write-MDT_LogMessage -message "-Result - $BlnArch -  $Architecture - $($OSObject.OSArchitecture)" -component $component -type $loggingLevel}             
        
    If ($OSObject.producttype -eq $producttype){
      $Blnproducttype = $True
    } 
    If ($blnLog) {Write-MDT_LogMessage -message "-Result - $Blnproducttype -  $producttype - $($OSObject.producttype)" -component $component -type $loggingLevel}                   
    
    #bring it all together
    If ($BlnArch -and $BlnVer -and $BlnCap -and $Blnproducttype){
      $BlnValidOS = $True
    }
  }
  End
  {
    If ($blnLog) {Write-MDT_LogMessage -message "-Returning - $blnValidOS" -component $component -type $loggingLevel}  
    Return $BlnValidOS
  }
}


. Test-MDT_OS -ValidOSCaptions '10' -Architecture '64'  -verbose
Test-MDT_OS -ValidOSVersions '6.1' -Workstation -Architecture '64'  -verbose
Test-MDT_OS -ValidOSCaptions '6' -Workstation -Architecture '64'  -verbose
Test-MDT_OS -ValidOSCaptions '10' -Workstation -Architecture '32'
Test-MDT_OS -ValidOSCaptions '10' -server -Architecture '64'  -verbose
