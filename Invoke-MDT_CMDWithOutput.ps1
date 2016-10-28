Function Invoke-MDT_CMDWithOutput
{
  <#
      .Synopsis
      Runs a command with arguments and returns the output and exitcode

      .DESCRIPTION
      Created: Jeff Scripter

      Version:  1.0.2 - 08/04/2016 - Jeff Scripter - Removed extra code for new Log function
      1.0.1 - 7/28/2016 - Jeff Scripter - Added logging
      1.0.0 - Jeff Scripter - Original
   
      Details: 
      Uses the ProcessStartInfo Class-https://msdn.microsoft.com/en-us/library/system.diagnostics.processstartinfo(v=vs.110).aspx

      Assumptions:
        


      .EXAMPLE
      PS C:\WINDOWS\system32> Invoke-MDT_CMDWithOutput -FilePath C:\Windows\System32\cmd.exe -Arguments "/c echo Output & exit 10"
      10
      Output 

  #>

  [CmdletBinding()]
  [OutputType([Array])]
  Param
  (
    # Path to executable
    [Parameter(Mandatory = $true,
        ValueFromPipelineByPropertyName = $true,
    Position = 0)]
    $FilePath,
    
    # Arguments to use with Executable
    [String]
    $Arguments = '',

    # Suppress window
    [Switch] $CreateNoWindow,

    #Run command in shell
    [Switch] $UseShellExecute,
    
    #Log Level 
    [String] $loglevel = 4
  

  )
    
  Begin
  {
    $component = "$($MyInvocation.InvocationName)-1.0.1"
    $psi = New-Object -TypeName System.Diagnostics.ProcessStartInfo 
    $psi.CreateNoWindow = $CreateNoWindow 
    $psi.UseShellExecute = $UseShellExecute 
    $psi.RedirectStandardOutput = $true 
    $psi.RedirectStandardError = $true 
    $psi.FileName = $FilePath
    $psi.Arguments = $Arguments
    $Return = @('', '')

    If (Get-Command -Name Write-MDT_LogMessage -ErrorAction Ignore) 
    {
      $blnLog = $true
    }
  }
  Process
  {
    If ($blnLog) 
    {
      Write-MDT_LogMessage -message "-CMD(Win - $CreateNoWindow ;Shell - $UseShellExecute): $FilePath $Arguments" -component $component -type $loglevel
    }
    $process = New-Object -TypeName System.Diagnostics.Process 
    $process.StartInfo = $psi 
    $null = $process.Start()
    $output = $process.StandardOutput.ReadToEnd() 
    $null = $process.WaitForExit()
    If ($blnLog) 
    {
      Write-MDT_LogMessage -message "-Return $($process.ExitCode) - $output" -component $component -type $loglevel
    }
  }
  End
  {
    $Return[0] = $process.ExitCode
    $Return[1] = $output    
    Return $Return
  }
}

#Invoke-MDT_CMDWithOutput -FilePath $env:ComSpec -Arguments "/c dir $env:systemroot" -CreateNoWindow -Verbose
#Invoke-MDT_CMDWithOutput -FilePath $env:ComSpec -Arguments "/c dir $env:systemroot" -CreateNoWindow  