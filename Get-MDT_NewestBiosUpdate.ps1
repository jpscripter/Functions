#requires -Version 3.0 -Modules BitsTransfer
cd H:\Scripts\Functions
. .\Get-MDT_BiosUpdateVersion.ps1
. .\Write-MDT_LogMessage.ps1

Function Get-MDT_NewestBiosUpdate
{
  <#
      .Synopsis
    
      .DESCRIPTION
      Author:    Jeff Scripter
      Modified:  Jeff Scripter

      Purpose: 

      Return:


      Overview:


      .NOTES
      Comment:	
 
      Assumptions:	
    
    
      Changes:
      2016_06_07 - Original - Jeff Scripter - Original


      Test Script: 
      1) 

      .EXAMPLE

  #>

  [CmdletBinding()]
  [OutputType([Boolean])]
  Param
  (
    $ModelArray = (Get-WmiObject -Class win32_computersystem).model,
    $MinVersion = $Null,
    $MinDaysOld = 30,
    $Path = $env:temp,
    $WebTimeout = 15,
    [switch] $prompt
    
  )
    
  Begin
  {
    $component = "$($MyInvocation.InvocationName)-1.0.0"
    If (Get-Command -Name Write-MDT_LogMessage -ErrorAction Ignore) 
    {
      $blnLog = $true
    }
    $Return = @()
    $ExludedModelRegex = '-(atg|xfr|aio)'
    $DellDownloadRootURL = 'http://downloads.dell.com'
    $DellModelRootURL = 'http://downloads.dell.com/published/pages/'
    $DellCurrentModelDownloadJobArray = @()
    
  }
  Process
  {
    # Get landing page for all dell models
    $DellDellCurrentModelpage = Invoke-WebRequest -Uri $DellModelRootURL -UseBasicParsing -TimeoutSec $WebTimeout
    If ($blnLog) 
    {
      Write-MDT_LogMessage -message "-Dell Landing Page $($DellDellCurrentModelpage.BaseResponse.ResponseUri.AbsoluteUri) - $($DellDellCurrentModelpage.StatusDescription)" -component $component -type Debug
    }
    
    If($DellDellCurrentModelpage.StatusDescription -eq 'OK')
    {
      #Foreach Model passed into the function, look for their pages and get bios.
      Foreach($Model in $ModelArray.replace("`r",'').split("`n"))
      {
        If ($blnLog) 
        {
          Write-MDT_LogMessage -message "-Model = $Model" -component $component -type Debug
        }
        $DellCurrentModelURLArray = $Null
      
        #get any url that matches the Model
        $DellCurrentModelURLArray = $DellDellCurrentModelpage.Links|
        Where-Object -FilterScript {
          $_.href -match "$($Model.replace(' ','-'))(\.|-)"
        } |
        Select-Object -ExpandProperty href
        If ($blnLog) 
        {
          Write-MDT_LogMessage -message "-All Links Matching ($Model) - $DellCurrentModelURLArray" -component $component -type Debug
        }
      
        If ($Null -NE $DellCurrentModelURLArray)
        {
          $DellCurrentModelURLArray = $DellDellCurrentModelpage.Links|
          Where-Object -FilterScript {
            $_.outerhtml -match $Model
          }|
          Select-Object -ExpandProperty href
          If ($blnLog) 
          {
            Write-MDT_LogMessage -message "-All HTML Matching ($Model) - $DellCurrentModelURLArray" -component $component -type Debug
          }
        }
      
        If (([Array]$DellCurrentModelURLArray).count -NE 1)
        {
          $DellAfterExcludesModelURLArray = $DellCurrentModelURLArray | Where-Object -FilterScript {
            $_ -inotmatch $ExludedModelRegex
          }
          If ($Null -NE $DellAfterExcludesModelURLArray)
          {
            $DellCurrentModelURLArray = $DellAfterExcludesModelURLArray
            If ($blnLog) 
            {
              Write-MDT_LogMessage -message "-All HTML Without ($Model) - $DellCurrentModelURLArray" -component $component -type Debug
            }
          }
        } 

        If (([Array]$DellCurrentModelURLArray).count -NE 1)
        {
          :Segments Foreach ($Segment in $Model.split())
          {
            $DellPossibleModelURLArray += $DellDellCurrentModelpage.Links|
            Where-Object -FilterScript {
              $_.href -match "$($Segment.replace(' ','-'))(\.|-)"
            }
            If (([Array]$DellPossibleModelURLArray).count -eq 1 )
            {
              $DellCurrentModelURLArray = $DellPossibleModelURLArray.href
              If ($blnLog) 
              {
                Write-MDT_LogMessage -message "-All Single word ($Segment) - $DellCurrentModelURLArray" -component $component -type Debug
              }
              Break :Segments
            }
          }
          If (($DellPossibleModelURLArray).count -NE 1)
          {
            $ModelNumber = [regex]::Match($Model,'\d{2,}').value
            $DellCurrentModelURLArray = $DellPossibleModelURLArray.href |
            Where-Object -FilterScript {
              $_ -match $ModelNumber
            } |
            Group-Object |
            Sort-Object -Property Count -Descending 
            $DellCurrentModelURLArray = $DellCurrentModelURLArray.group[0]
            If ($blnLog) 
            {
              Write-MDT_LogMessage -message "-All matching model ($ModelNumber) - $DellCurrentModelURLArray" -component $component -type Debug
            }
          }
        }
        
        If (([Array]$DellCurrentModelURLArray).count -NE 1)
        {
          If ($prompt)
          {
            $ModelNumber = [regex]::Match($Model,'\d{2,}').value
            $DellCurrentModelURLArray = $DellPossibleModelURLArray.href |
            Where-Object -FilterScript {
              $_ -match $ModelNumber
            } 
            $DellCurrentModelURLArray = Out-GridView -InputObject $DellCurrentModelURLArray -PassThru -Title 'Select Correct Model'
            $DellCurrentModelURLArray = $DellCurrentModelURLArray| Select-Object -First 1
            If ($blnLog) 
            {
              Write-MDT_LogMessage -message "-User Selected - $DellCurrentModelURLArray" -component $component -type Debug
            }
          }
          Else
          {
            If ($blnLog) 
            {
              Write-MDT_LogMessage -message "-Cannot identify link for $M"  -component $component -type Debug
            }
            Continue
          }
        }
       
        #Use the identified model to get the model's page
        $DellCurrentModelurl = $DellModelRootURL + $DellCurrentModelURLArray
        $DellCurrentModelpage = Invoke-WebRequest -Uri $DellCurrentModelurl -UseBasicParsing -TimeoutSec $WebTimeout
        IF ($blnLog) 
        {
          Write-MDT_LogMessage -message "-$Model Landing Page $($DellCurrentModelpage.BaseResponse.ResponseUri.AbsoluteUri) - $($DellCurrentModelpage.StatusDescription)" -component $component -type Verbose
        }

        #If we can connect to the page, identify latest bios that has the min age and version
        IF ($DellCurrentModelpage.StatusDescription -eq 'OK')
        {
          #Get all listed bios for model
          $DellCurrentModelBiosDownloadURLArray = $DellCurrentModelpage.Links| Where-Object -FilterScript {
            $_.outerhtml -match 'BIOS' -and $_.href -match '.exe'
          }
          If ($blnLog) 
          {
            Write-MDT_LogMessage -message "-Bios for $Model - $($DellCurrentModelBiosDownloadURLArray.HREF)" -component $component -type Debug
          }

          If ($Null -NE $DellCurrentModelBiosDownloadURLArray )
          {
            $DellCurrentModelUpdateVersions = @()
          
            #Get Versions
            Foreach ($DellCurrentModelBiosUpdateURL in $DellCurrentModelBiosDownloadURLArray.href)
            {
              $CurrentBiosUpdateVersion = Get-MDT_BiosUpdateVersion -String $DellCurrentModelBiosUpdateURL

            
              If ($blnLog) 
              {
                Write-MDT_LogMessage -message "-Bios for $Model - $DellCurrentModelBiosUpdateURL - $($CurrentBiosUpdateVersion.Version)" -component $component -type Debug
              }

              #Exe update time string
              $FileData = Invoke-WebRequest -Uri "$DellDownloadRootURL$DellCurrentModelBiosUpdateURL" -UseBasicParsing -TimeoutSec $WebTimeout -Method Head
              $ExeupdateLine = $FileData.RawContent.split("`n") | Where-Object -FilterScript {
                $_ -match 'last-modified'
              } 
              $exeTimestamp = [datetime]$ExeupdateLine.replace('Last-Modified: ','')
              Add-Member -InputObject $CurrentBiosUpdateVersion -NotePropertyName 'ExeTimestamp' -NotePropertyValue $exeTimestamp -Force
              If ($blnLog) 
              {
                Write-MDT_LogMessage -message "-Bios for $M - exe Date - $($exeTimestamp)" -component $component -type Debug
              }
            
              #>
              If ($CurrentBiosUpdateVersion.version -match '^[0-9]{1,4}(\.[0-9]{1,4}){1,3}$')
              {         
                #MinVersion
                If (([version]$CurrentBiosUpdateVersion.version).CompareTo([version]$MinVersion) -eq 1)
                {
                  $DellCurrentModelUpdateVersions += $CurrentBiosUpdateVersion
                }
              }
              ElseIf(([String]$CurrentBiosUpdateVersion.version).CompareTo([String]$MinVersion) -eq 1)
              {
                $DellCurrentModelUpdateVersions += $CurrentBiosUpdateVersion
              }
            }
          
            #Is update old enough
            $DellCurrentModelOrderedUpdateArray = $DellCurrentModelUpdateVersions |
            Where-Object -FilterScript {
              $_.version.compareto([string]$MinVersion) -NE -1
            }|
            Group-Object -Property version |
            Sort-Object -Property name -Descending
            Foreach ($DellCurrentUpdate in $DellCurrentModelOrderedUpdateArray)
            {
              $DellCurrentModelOrderedIndex = $DellCurrentModelOrderedUpdateArray.IndexOf($Update)
              If ($DellCurrentUpdate -NE $DellCurrentModelOrderedUpdateArray[0])
              {
                If ((New-TimeSpan -Start $DellCurrentUpdate.Group[0].ExeTimestamp -End $OrderedUpdates[$DellCurrentModelOrderedIndex - 1].Group[0].ExeTimestamp) -gt $MinDaysOld)
                {
                  Continue
                }
              }
              If ((Get-Date).AddDays(- $MinDaysOld).CompareTo($pageLastUpdate) -NE 1)
              {
                Continue
              }
              $DellCurrentModelSelectedUpdate = $DellCurrentUpdate.group | Select-Object -First 1
              Break
            }
            
            #start download process
            $DellCurrentModelDownloadRoot = Join-Path -Path $Path  -ChildPath $Model
            $DellCurrentModelDownloadPath = Join-Path -Path $DellCurrentModelDownloadRoot  -ChildPath $DellCurrentModelSelectedUpdate.UpdateFile.split('/')[-1]
            IF (-not (Test-Path $DellCurrentModelDownloadPath))
            {
              If (-not (Test-Path $DellCurrentModelDownloadRoot)) 
              {
                $Null = New-Item -Path $DellCurrentModelDownloadRoot -Type Directory -Force
              }
              
              #Download Main Update
              $DellCurrentModelBiosUpdateURL = $DellCurrentModelSelectedUpdate.UpdateFile
              $DellCurrentModelBiosDownloadURL = $DellDownloadRootURL + $DellCurrentModelSelectedUpdate.UpdateFile
              $DellCurrentModelDownloadJobArray += Start-BitsTransfer -Source $DellCurrentModelBiosDownloadURL -Destination $DellCurrentModelDownloadPath -Priority Normal -DisplayName $DellCurrentModelSelectedUpdate.UpdateFile.split('/')[-1] -Asynchronous
              
              #Get Help Info
              $DellCurrentModelhelpURL = $DellCurrentModelpage.Links.href[$DellCurrentModelpage.Links.href.IndexOf($DellCurrentModelBiosUpdateURL)-1]
              $DellCurrentModelhelppage = Invoke-WebRequest -Uri $DellCurrentModelhelpURL -OutFile $DellCurrentModelDownloadPath.replace('.exe','.html') -TimeoutSec $WebTimeout -PassThru
              If ($DellCurrentModelhelppage.StatusDescription -eq 'OK')
              {
                $DellCurrentModelLastUpdatedArray = ($DellCurrentModelhelppage.ParsedHtml.getElementsByTagName('div') | Where-Object -FilterScript {
                    $_.innertext -Match '^Last Updated'
                }) 
                $DellCurrentModelPageLastUpdate = [datetime] $DellCurrentModelLastUpdatedArray.innertext.split(([char]10))[2]
                Add-Member -InputObject $DellCurrentModelSelectedUpdate -NotePropertyName 'PageLastUpdate' -NotePropertyValue $DellCurrentModelPageLastUpdate -Force 

                If ($blnLog) 
                {
                  Write-MDT_LogMessage -message "-Bios for $Model - Update Date - $($pageLastUpdate)" -component $component -type Debug
                }
                
                $DellCurrentModelBiosimportantInfo = $DellCurrentModelhelppage.ParsedHtml.all.tags('div') | Where-Object -FilterScript {
                  $_.innerhtml -Match 'Important Information'
                }
                If ($DellCurrentModelBiosimportantInfo -ne $Null)
                {
                  $DellCurrentModelBiosimportantText = $DellCurrentModelBiosimportantInfo[-1].innertext
                  #Commenting this out disables the prereq download
                  #$DellCurrentModelBiosprereqURlArray = $DellCurrentModelBiosimportantText.split() | Select-String  -Pattern '(?i)http://www.dell.com/support/drivers/.*/DriverDetails.driverid=*'
                  ForEach ($DellCurrentModelBiosPrereqURl in $DellCurrentModelBiosprereqURlArray)
                  {
                    If ($blnLog) 
                    {
                      Write-MDT_LogMessage -message "-Extra download: $DellCurrentModelBiosPrereqURl" -component $component -type Debug
                    }
                    $DellCurrentModelBiosPrereqURlpage = Invoke-WebRequest -Uri $DellCurrentModelBiosPrereqURl.tostring()  -TimeoutSec $WebTimeout -UseBasicParsing
                    If ($DellCurrentModelBiosPrereqURlpage.StatusDescription -NE 'OK'){Continue}
                    $DellCurrentModelBiosPrereqDL = $DellCurrentModelBiosPrereqURlpage.Links| Where-Object -FilterScript {
                      $_.href -match '.exe'
                    }
                    If ($DellCurrentModelBiosPrereqDL.count -ne $Null) 
                    {
                      $DellCurrentModelBiosPrereqDL = $DellCurrentModelBiosPrereqDL[0]
                    }Elseif($DellCurrentModelBiosPrereqDL -eq $Null){
                      If ($blnLog) 
                      {
                        Write-MDT_LogMessage -message  "-Can't find Exe for $DellCurrentModelBiosPrereqURl" -component $component -type warning
                      }
                      Continue
                    }
                    $DellCurrentModelBiosPrereqDLVersion = Get-MDT_BiosUpdateVersion -string $DellCurrentModelBiosPrereqDL
                    $DellCurrentModelDownloadPath = Join-Path -Path $DellCurrentModelDownloadRoot  -ChildPath $DellCurrentModelBiosPrereqDL.href.split('/')[-1]
                    If ($blnLog) 
                    {
                      Write-MDT_LogMessage -message  "-Downloading - $DellCurrentModelBiosPrereqDLVersion - $DellCurrentModelBiosPrereqDL" -component $component -type Debug
                    }
                    $DellCurrentModelDownloadJobArray += Start-BitsTransfer -Source $DellCurrentModelBiosPrereqDL.href -Destination $DellCurrentModelDownloadPath -Priority Normal -DisplayName $localModelName -Asynchronous
                  }
                  Add-Content -Path ($DellCurrentModelDownloadRoot + '\biosPrereqs.txt') -Value "`n`n$Model `n $DellCurrentModelBiosimportantInfo"
                }
              }
              $Return += $DellCurrentModelSelectedUpdate
            }
          }
        }

        If ($DellCurrentModelDownloadJobArray.JobState -contains 'Transferred')
        {
          $DellCurrentModelDownloadJobTransfered = $DellCurrentModelDownloadJobArray | Where-Object -FilterScript {
            $_.JobState -eq 'Transferred'
          }
          If ($blnLog) 
          {
            Write-MDT_LogMessage -message "-Completing Bits Job = $($DellCurrentModelDownloadJobTransfered.displayname)" -component $component -type Debug
          }
          $Null = Complete-BitsTransfer -BitsJob $DellCurrentModelDownloadJobTransfered
        }
      }
    } 

  }
  End
  {
    While ($DellCurrentModelDownloadJobArray.JobState -NE $Null )
    {
      $DellCurrentModelDownloadJobTransfered = $DellCurrentModelDownloadJobArray | Where-Object -FilterScript {
        $_.JobState -eq 'Transferred'
      }
      If ($blnLog) 
      {
        Write-MDT_LogMessage -message "-Completing Bits Job = $($DellCurrentModelDownloadJobTransfered.displayname)" -component $component -type Debug
      }
      If ($DellCurrentModelDownloadJobTransfered -NE $Null)
      {
        $Null = Complete-BitsTransfer -BitsJob $DellCurrentModelDownloadJobTransfered
      }
      Else
      {
        Start-Sleep -Seconds 5
      }
    }
    If ($blnLog) 
    {
      Write-MDT_LogMessage -message "-Return = $($Return.UpdateFile)" -component $component -type 4
    }
    Return $Return
  }
}
