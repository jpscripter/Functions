function Test-MDT_DomainConnected 
{
  <#
      .Synopsis
      Checks if The local system can connect to the domain

      .DESCRIPTION
      Created: Jeff Scripter

      Version: 1.0.0 - Jeff Scripter - Original

      Assumptions:
      NA

      Return
      True - Can connect and query AD
      False - Not able to connect and query AD

      .EXAMPLE
      Test-MDT_DomainConnected
      > False


  #>

  [CmdletBinding()]
  [OutputType([Boolean])]
  Param
  (
    # time in seconds to wait for the network conenction to be extablished 
    [int] $WaitTime = 25
  )

  Begin
  {
    $component = "$($MyInvocation.InvocationName)-1.0.0"
    If (Get-Command -Name Write-MDT_LogMessage -ErrorAction Ignore) {$blnLog = $true}
    $Return = $False
    
    $ComputerName = $env:computername
    $Filter = "(&(objectCategory=Computer)(Name=$ComputerName))"
    $NicFilter = 'IPEnabled=True'
    
  }
  Process
  {
    For ($I = 0; $I -LT $WaitTime; $I++)
    {
      $AvailableNics = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter $NicFilter -ErrorAction Ignore
      If ($AvailableNics)
      {
        If ($blnLog) {Write-MDT_LogMessage -message "-NIC Available $($AvailableNics.Description)" -component $component -type 4}
        $I = $WaitTime
      }
      Start-Sleep -Seconds 1
    }
    
    Try
    {
      $DirectorySearcher = New-Object -TypeName System.DirectoryServices.DirectorySearcher
      $DirectorySearcher.Filter = $Filter
      $SearcherPath = $DirectorySearcher.FindOne()
      $OUPath = $SearcherPath.GetDirectoryEntry().DistinguishedName
      If ($blnLog) {Write-MDT_LogMessage -message "-Query AD ($($DirectorySearcher.SearchRoot.path)) - $oupath" -component $component -type 4} 
    }
    Catch
    {

    }
    If ($OUPath)
    {
      $Return = $true
      If ($blnLog) {Write-MDT_LogMessage -message "-Return = $Return" -component $component -type 4}       
    }

  }
  End
  {
    Return $Return
  }
}

Test-MDT_DomainConnected 
[boolean] (Test-MDT_DomainConnected -verbose)