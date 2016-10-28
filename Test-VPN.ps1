function Test-MDT_VPN
{
  <#
      .Synopsis
      Looks for Network adapter Service names associated with VPN
      .DESCRIPTION
      Author:    Jeff Scripter
      Modified:  Jeff Scripter

      2016_05_13 - Original - Jeff Scripter - NA

      Purpose:   This is used to identify VPN status but can be used to identify status of any network adapter
      based on the service name


      Changes:	2016_07_28 - 1.0.1 - Jeff Scripter - Added logging
      2016_05_14 - Original - Jeff Scripter - Original

      Comment:	NA

      Assumptions:	Pulls data from WMI Win32_NetworkAdapter

      Returns: $True  - we are Configured ( Connected if -online param is used)
      $False - we are not Configured
    
      .EXAMPLE
      PS C:\WINDOWS\system32> test-vpn 
      True

      .EXAMPLE
      PS C:\WINDOWS\system32> test-vpn -VirtualAdapterNames "test","jn*" -online
      True

  #>
  [CmdletBinding()]
  [OutputType([int])]
  Param
  (
    # List of network adapter service names
    [Parameter(ValueFromPipelineByPropertyName=$true,
    Position=0)]
    [string[]]$VirtualAdapterNames = @('dsNcAdpt','jnprva','JnprVaMgr'),

    # Force the check for NetEnabled = True on the adapter
    [Switch]
    $Online
  )

  Begin
  {
    $component = "$($MyInvocation.InvocationName)-1.0.1"
    $loggingLevel = 4
    If (Get-Command -Name Write-MDT_LogMessage -ErrorAction Ignore) {$blnLog = $true}
    $Return = $False
    $NicAdapters = Get-WmiObject -Class Win32_NetworkAdapter
  }
  Process
  {
    Foreach ($nic in $NicAdapters){
      Foreach ($sn in $VirtualAdapterNames) {
        If ($nic.servicename -like $sn){
          If ($blnLog) {Write-MDT_LogMessage -message "-$($nic.Description)(Netenabled $($nic.netenabled)) - $($nic.servicename) -like $sn" -component $component -type $loggingLevel}
          If (($nic.netenabled -eq $true) -or -not $online){$Return = $True}
        }
      }
    }
  }
  End
  {
    If ($blnLog) {Write-MDT_LogMessage -message "`-Return - $Return" -component $component -type $loggingLevel}
    Return $Return
  }
}

Test-MDT_VPN

Test-MDT_VPN -Verbose 
Test-MDT_VPN -Verbose -Online
Test-MDT_VPN -Verbose -VirtualAdapterNames 'test' -Online
