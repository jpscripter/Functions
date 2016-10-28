#requires -Version 2
function Test-MDT_Ethernet 
{
  <#
      .Synopsis
      Checks if The current connection is eithernet and if wanted will make sure that nic can connect to a DC

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
  [OutputType([Boolean])]
  Param
  (
    # makes sure that the ethernet connection can contact the domain controller
    [Switch] $CheckDomain,
    
    # checks that it can query a DC
    [switch] $ForceDCTest,
    
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
    $ComputerSystem = Get-WmiObject -Class Win32_ComputerSystem
    $domain = $ComputerSystem.domain
    $EthernetNics = [System.Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces() 
    If ($blnLog) 
    {
      Write-Verbose -Message "$(Write-MDT_LogMessage -message "-Nubmer of Nics $($EthernetNics.count)" -component $component -type $loggingLevel)"
    }
    $EthernetNics = $EthernetNics | Where-Object -FilterScript{
      $PSItem.NetworkInterfaceType -EQ 'Ethernet' -and $PSItem.OperationalStatus -EQ 'Up'
    }
    If ($blnLog) 
    {
      Write-Verbose -Message "$(Write-MDT_LogMessage -message "-Nubmer of Ethernets $($EthernetNics.count)" -component $component -type $loggingLevel)"
    }    
    $IsEthernet = $False
  }
  Process
  {
    Foreach($EthernetNic in $EthernetNics)
    {
      If (-not $CheckDomain)
      {
        $IsEthernet = $true
        Break
      }
      Else
      {
        If ($blnLog) 
        {
          Write-Verbose -Message "$(Write-MDT_LogMessage -message "-Checking Domain: $($EthernetNic.GetIpProperties().DNSSuffix) -eq $domain" -component $component -type $loggingLevel)"
        }  
        If ($EthernetNic.GetIpProperties().DNSSuffix.ToLower() -eq $domain.ToLower().replace('stg','')) #[string]::Join('.',($domain.ToLower().split('.')[-2..-1]))
        {
          If (-Not $ForceDCTest)
          {
            $IsEthernet = $true
            Break
          }
          Else
          {
            $NetAdaptWMI = Get-WmiObject -Class win32_networkadapterconfiguration| Where-Object -FilterScript {
              $PSItem.SettingID -eq $EthernetNic.id
            }
            $Connected = $False   
            $SourceIP = [IPAddress]($NetAdaptWMI.ipaddress | Where-Object -FilterScript {
                $PSItem -match '(\d){1,3}(\.(\d){1,3}){3}'
            })
            # Local Ethernet IPv4
            $lastDC = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy\History' -Name 'DCname').dcname
            If ($blnLog) 
            {
              Write-Verbose -Message "$(Write-MDT_LogMessage -message "-DC to test Access - $lastDC" -component $component -type $loggingLevel)"
            }  
                        
            $Destination = [System.Net.Dns]::GetHostByName($lastDC.replace('\\','')).addresslist #Logon server
            $DestinationPort = 636 #Ldap port

            # get an unused local port, used in$env: local IP endpoint creation
            $UsedLocalPorts = ([System.Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties()).GetActiveTcpListeners() |
            Where-Object -FilterScript {
              $PSItem.AddressFamily -eq 'Internetwork'
            } |
            Select-Object -ExpandProperty Port
            do 
            {
              $localport = $(Get-Random -Minimum 49152 -Maximum 65535 )
            }
            until ( $UsedLocalPorts -notcontains $localport)

            # Create the local IP endpoint, this will bind to a specific N/W adapter for making the connection request 
            $LocalIPEndPoint = New-Object -TypeName System.Net.IPEndPoint -ArgumentList  $SourceIP, $localport

            # Create the TCP client and specify the local IP endpoint to be used.
            $TCPClient = New-Object -TypeName System.Net.Sockets.TcpClient -ArgumentList $LocaIPEndPoint # by default the proto used is TCP to connect 
            
            Try
            {
              # Connect to the Destination on the required port.
              $TCPClient.Connect($Destination, $DestinationPort)

              # Check the Connected property to see if the TCP connection succeeded. You can see netstat.exe output to verify the connection too
              $Connected = $TCPClient.Connected
              If ($blnLog) 
              {
                Write-Verbose -Message "$(Write-MDT_LogMessage -message "-TCPClient Status - $Connected" -component $component -type $loggingLevel)"
              }  
                            
              $TCPClient.Close()
            }
            Catch
            {
              If ($blnLog) 
              {
                Write-Verbose -Message "$(Write-MDT_LogMessage -message '-TCPClient Connect Failed' -component $component -type $loggingLevel)"
              }  
              Continue
            }
            If ($Connected -EQ $true)
            {
              $IsEthernet = $true
            }
          }
        }
      }
    }
  }

  End
  {
    If ($blnLog) 
    {
      Write-Verbose -Message "$(Write-MDT_LogMessage -message "-Return $IsEthernet" -component $component -type $loggingLevel)"
    }  
    Return $IsEthernet
  }
}

. Test-MDT_Ethernet -CheckDomain -ForceDCTest -NonverboseLogging -Verbose
