Function New-MDT_RandomPassword
{
  <#
      .Synopsis
      Randomly generates a password of a certain length

      .DESCRIPTION
      Created: Mike Clemson

      Version:  1.0.1 - 08/04/2016 - Jeff Scripter - Formatted
      1.0.0 - Mike Clemson - original

   
      Details: 

      Assumptions:

      .EXAMPLE
      PS C:\WINDOWS\system32> Invoke-MDT_CMDWithOutput -FilePath C:\Windows\System32\cmd.exe -Arguments "/c echo Output & exit 10"
      10
      Output 

  #>
  [CmdletBinding()]
  [OutputType([String])]
  Param (
    [int]$Length
  )
  
  $Set = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'.ToCharArray()
  For ($i = 0; $i -lt $Length; $i++) {
    $Result += Get-Random -inputobject $set
  }
  Write-MDT_LogMessage -message "-Password Created = $Result" -component $component -type Debug
    
  Return $Result
}