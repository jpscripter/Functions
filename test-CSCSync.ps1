Function Test-MDT_CSCSync
{
  <#
      .Synopsis
      Checks the current user's cache for Dirty (Unsynchronized) files and checks sync time from other users. 
      .DESCRIPTION
      Author:    Jeff Scripter
      Modified:  Jeff Scripter

      2016_07_11 - Original - Jeff Scripter - NA

      Purpose:   This Function looks for dirty (Unsychronized) files in the Win32_OfflineFilesItem for the user runningthe process and (If Permissions permit) the 
      currently logged on user. Then it loops through the user profiles looking for last sync date. 


      Changes:	2016_07_11 - Original - Jeff Scripter - Original
      2016_07_20 - 1.0.1 - Jeff Scripter - filtered out users with no last sync date
      2016_07_21 - 1.0.2 - Jeff Scripter - Added Logging and fixed regload
      2016_07_28 - 1.0.3 - Jeff Scripter - Updated run as user section and added logging
      2016_08_01 - 1.0.4 - Jeff Scripter - Updated script location logic


      Comment:	
      Profileage - This variable is used to ignore profiles that are older than this number of days
      SyncPeriod - this is the number of days since the last loggon of the user that a sync must have occured.
					
 
      Assumptions:	- we have to run as system and RunAsCurrentUser utility need to be in the same directory as the script for the current user section to work.
      - This isnt a comprehensive check and is used as a best effort to find potentially lost files. 
    
      Return: - Null - No profiles have dirty info on this system
      FileList - UnsynchronizedFiles\profiles file were detected. 
    
      .EXAMPLE
      .\Test-CSCSync
  #>
  
  [CmdletBinding()]
  [Alias()]
  [OutputType([Array])]
  Param
  (
    # Checks only the CSC using the win32_offlinefilesitem to look for a successful sync
    [switch]$CurrentUserOnly,

    [Parameter(ValueFromPipelineByPropertyName = $true,
    Position = 0)] 
    # Number of days past which the profile wont be considered.
    [int]$ProfileAge = 30,
    
    # the difference the profile age and last sync time where
    [int]$Syncperiod = 2,
    
    #Logging to informational from Verbose
    [switch] $NonverboseLogging
  )
    

  Begin
  {

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
    $component = "$($MyInvocation.InvocationName)-1.0.3"
    $Return = @()
    $Date = (Get-Date -Format 'yyyyMMddhhmmss')
    If (Get-Variable -Name ScriptLocation -Scope global -ErrorAction Ignore)
    {
      $ScriptLocation = $global:ScriptLocation
    } Else {
      $ScriptLocation = (Get-Location).Path
    }
    
    $RunAsUserUtility = Join-Path -Path $ScriptLocation -ChildPath 'RunAsCurrentUser-2.0.3.1.exe'
    If ($blnLog) 
    {
      Write-MDT_LogMessage -message "-CUUtilityPath: $RunAsUserUtility = $ScriptLocation + 'RunAsCurrentUser-2.0.3.1.exe'" -component $component -type  $loggingLevel
    } 
        
    $RunAsUserParams = ' --w --q'
    $DirtyCachefilter = '([Boolean]$_.dirtyinfo.LocalDirtyByteCount) -ne $False'

    $XMLFilePath = "$env:windir\temp\UserOFC.xml"
    $PS1FilePath = "$env:windir\temp\UserOFC.PS1"
    $cmd = "Get-WMIObject -Class Win32_OfflineFilesItem | Where-Object -FilterScript {$DirtyCachefilter}| Select ItemPath |Export-clixml -Path $XMLFilePath"
    $RunAsUserCMD = "Powershell.exe -file $PS1FilePath"
  }
  Process
  {
    # looks at the process owner's CSC
    $CacheContent = Get-WmiObject -Class Win32_OfflineFilesItem | Where-Object -FilterScript ([Scriptblock]::Create($DirtyCachefilter))
    $ProcessUser = $env:username 
    If ($blnLog) 
    {
      Write-Verbose -Message "$(Write-MDT_LogMessage -message "-DirtyFiles ($ProcessUser): $($CacheContent.count)" -component $component -type  $loggingLevel)"
    }    
    If ($CacheContent)
    {
      $Return += $CacheContent.ItemPath + "`n"
    }
    If (($env:username -EQ 'nt authority\system' -or $env:username.ToLower() -eq ("$env:computername$").ToLower())-and (Test-Path -Path $RunAsUserUtility))
    { 
      If (Test-Path -Path $XMLFilePath) 
      {
        Remove-Item -Path $XMLFilePath
      }
      
      If ($blnLog) 
      {
        Write-Verbose -Message "$(Write-MDT_LogMessage -message "-CMD: $RunAsUserUtility $RunAsUserParams $RunAsUserCMD" -component $component -type  $loggingLevel)"
      }
      $currentUser = (query.exe User| Where-Object -FilterScript {
          $_ -match 'Active'
      })     
      $currentUser = $currentUser.tostring().split()|
      Where-Object -FilterScript {
        $_ -ne ''
      }|
      Select-Object -First 1
      IF ($currentUser -NE $Null)
      {
        Out-File -FilePath $PS1FilePath -InputObject $cmd -Force 
        $out = Invoke-MDT_CMDWithOutput -FilePath $RunAsUserUtility -Arguments "$RunAsUserParams $RunAsUserCMD" -NonverboseLogging 
        
        $Success = Test-Path -Path $XMLFilePath
        If ($blnLog) 
        {
          Write-Verbose -Message "$(Write-MDT_LogMessage -message "-CurrentUser - $currentUser : $Success" -component $component -type  $loggingLevel)"
        }       
        #runs process as user to export the Dirty Items in CSC

        If($Success)
        {
          $CurrentUserDirtyCache = Import-Clixml -Path $XMLFilePath
          If ([Boolean]$CurrentUserDirtyCache.ItemPath -NE $False)
          {
            $Return += $CurrentUserDirtyCache.ItemPath + "`n"
          }
          If ($blnLog) 
          {
            Write-Verbose -Message "$(Write-MDT_LogMessage -message "-Parsing ($currentUser) File Content $($CurrentUserDirtyCache.count)" -component $component -type  $loggingLevel)"
          } 
          Remove-Item -Path $XMLFilePath -Force       
          Remove-Item -Path $PS1FilePath -Force       
        }
      }Else
      {
        If ($blnLog) 
        {
          Write-Verbose -Message "$(Write-MDT_LogMessage -message "-No Detectable Current User: $(query.exe User)" -component $component -type  $loggingLevel)"
        }
      }
    }Else
    {
      If ($blnLog) 
      {
        Write-Verbose -Message "$(Write-MDT_LogMessage -message "-Not Running as system $env:username" -component $component -type  $loggingLevel)"
      }
    }
      
    #loops through users to look at their last sync  
    If (-not $CurrentUserOnly)
    {
      If(-not (Test-Path -Path HKU:\))
      {
        $Null = New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS
      }
      $os = Get-WmiObject -Class Win32_OperatingSystem
    
      Switch ($true){
        ($os.version -like '6.1*')
        {
          $HivePath = 'HKU\!!SID!!\Software\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\NetCache\SyncItemLog\!!HomeDir!!'
          $SyncProperty = 'LastSyncTime'
        }
        ($os.version -like '6.2*')
        {
          $HivePath = 'HKU\!!SID!!_Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\SyncMgr\HandlerInstances\{750FDF10-2A26-11D1-A3EA-080036587F03}'
          $SyncProperty = 'SyncTime'
        }
        ($os.version -like '6.3*')
        {
          $HivePath = 'HKU\!!SID!!_Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\SyncMgr\HandlerInstances\{750FDF10-2A26-11D1-A3EA-080036587F03}'
          $SyncProperty = 'SyncTime'
        }
        ($os.version -like '10.0*')
        {
          $HivePath = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\!!SID!!\SyncItemLog\!!HomeDir!!'
          $SyncProperty = 'LastSyncTime'
        }
      }

      $userlist = Get-WmiObject -Class win32_userprofile | Where-Object -FilterScript {
        $_.sid -match 'S-1-5-21-' -and (($_.LastUseTime.split('.')[0] - $Date) -lt (1000000*$ProfileAge)) -and $_.localPath -NotLike '*!'-and $_.localPath -NotLike '*SVC*'-and $_.localPath -NotLike '*sys.*'
      }
          
      Foreach ($user in $userlist) 
      {
        $LocalPath = $user.LocalPath
        If ($LocalPath -match $currentUser)
        {
          Continue
        }
        If ($LocalPath -match $ProcessUser)
        {
          Continue
        }
        If ($blnLog) 
        {
          Write-Verbose -Message "$(Write-MDT_LogMessage -message "-User: $($user.localpath) - $user" -component $component -type  $loggingLevel)"
        } 
        $sid = $user.sid
        $DidILoad = $False
        If (-not (Test-Path -Path "HKU:\$sid")) 
        {
          If (Test-Path -Path "$($user.LocalPath)\NTUser.dat")
          {
            Start-Process -FilePath $env:ComSpec -ArgumentList "/c reg load ""HKU\$sid"" ""$($user.LocalPath)\NTUser.dat""" -Wait -WindowStyle Hidden
            If (Test-Path -Path "HKU:\$sid")
            {
              $DidILoad = $true
              If ($blnLog) 
              {
                Write-Verbose -Message "$(Write-MDT_LogMessage -message "-Loaded: HKU\$sid - from - $($user.LocalPath)\NTUser.dat" -component $component -type  $loggingLevel)"
              } 
            }Else
            {
              If ($blnLog) 
              {
                Write-Verbose -Message "$(Write-MDT_LogMessage -message "-Failed Loaded: HKU\$sid - from - $($user.LocalPath)\NTUser.dat" -component $component -type  $loggingLevel)"
              }
            }
          }
        }
        If (Test-Path -Path "HKU:\$sid")
        {
          $HomeDrive = (Get-ItemProperty -Path "HKU:$sid\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name 'Personal' ).Personal
          IF ($HomeDrive -like '\\*')
          {
            If (-not(Test-Path -Path "registry::$($HivePath.replace('!!SID!!',$sid).replace('!!HomeDir!!',$HomeDrive))"))
            {
              $HomeDrive = [string]::Join('/', $HomeDrive.split('\')[0.0..3])
            }
            $SyncBin = (Get-Item -Path "registry::$($HivePath.replace('!!SID!!',$sid).replace('!!HomeDir!!',$HomeDrive))").getValue($SyncProperty)
            $syncTime = 0
            If ([boolean]( $SyncBin | Select-Object -Unique))
            {
              For ($I = 0; $I -lt 8; $I++)
              {
                $syncTime += $SyncBin[$I] * [Math]::Pow(2,(8*$I))
              }

              $syncTime = ([datetime]'01/01/1601 GMT').AddDays($syncTime / 864000000000)
              If ((Get-Date).Subtract($syncTime).days -GE $Syncperiod)
              {
                If ($blnLog) 
                {
                  Write-Verbose -Message "$(Write-MDT_LogMessage -message "-Profile Sync warning (MaxPeriod = $Syncperiod) - $LocalPath - Last Synced - $syncTime" -component $component -type  $loggingLevel)"
                } 
                $Return += $user.LocalPath 
              }
            }
          }
          If ($DidILoad)
          {
            Start-Process -FilePath $env:ComSpec -ArgumentList "/c reg Unload ""HKU\$sid""" -Wait -WindowStyle Hidden
            If (-Not (Test-Path -Path "HKU:\$sid"))
            {
              If ($blnLog) 
              {
                Write-Verbose -Message "$(Write-MDT_LogMessage -message "-UnLoaded: HKU\$sid - from - $($user.LocalPath)\NTUser.dat" -component $component -type  $loggingLevel)"
              }
            }Else
            {
              If ($blnLog) 
              {
                Write-Verbose -Message "$(Write-MDT_LogMessage -message "-Failed Unloaded: HKU\$sid - from - $($user.LocalPath)\NTUser.dat" -component $component -type  $loggingLevel)"
              }
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
      Write-Verbose -Message "$(Write-MDT_LogMessage -message "-Return Count - $($Return.count)" -component $component -type  $loggingLevel)"
    } 
    Return $Return
  }
}

. Test-MDT_CSCSync -NonverboseLogging -verbose

. Test-MDT_CSCSync 