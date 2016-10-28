function New-RunspacePool{
    <#
        .SYNOPSIS
            Create a new runspace pool
        .DESCRIPTION
            This function creates a new runspace pool. This is needed to be able to run code multi-threaded.
        .EXAMPLE
            $pool = New-RunspacePool
            Description
            -----------
            Create a new runspace pool with default settings, and store it in the pool variable.
        .EXAMPLE
            $pool = New-RunspacePool -Snapins 'vmware.vimautomation.core'
            Description
            -----------
            Create a new runspace pool with the VMWare PowerCli snapin added, and store it in the pool variable.
        .NOTES
            Name: New-RunspacePool
            Author: Øyvind Kallstad
            Date: 10.02.2014
            Version: 1.0
    #>
    [CmdletBinding()]
    param(
        # The minimun number of concurrent threads to be handled by the runspace pool. The default is 1.
        [Parameter(HelpMessage='Minimum number of concurrent threads')]
        [ValidateRange(1,65535)]
        [int32]$minRunspaces = 1,
 
        # The maximum number of concurrent threads to be handled by the runspace pool. The default is 15.
        [Parameter(HelpMessage='Maximum number of concurrent threads')]
        [ValidateRange(1,65535)]
        [int32]$maxRunspaces = 15,
 
        # Using this switch will set the apartment state to MTA.
        [Parameter()]
        [switch]$MTA,
 
        # Array of snapins to be added to the initial session state of the runspace object.
        [Parameter(HelpMessage='Array of SnapIns you want available for the runspace pool')]
        [string[]]$Snapins,
 
        # Array of modules to be added to the initial session state of the runspace object.
        [Parameter(HelpMessage='Array of Modules you want available for the runspace pool')]
        [string[]]$Modules,
 
        # Array of functions to be added to the initial session state of the runspace object.
        [Parameter(HelpMessage='Array of Functions that you want available for the runspace pool')]
        [string[]]$Functions,
 
        # Array of variables to be added to the initial session state of the runspace object.
        [Parameter(HelpMessage='Array of Variables you want available for the runspace pool')]
        [string[]]$Variables
    )
 
    # if global runspace array is not present, create it
    if(-not $global:runspaces){
        $global:runspaces = New-Object System.Collections.ArrayList
    }
    # if global runspace counter is not present, create it
    if(-not $global:runspaceCounter){
        $global:runspaceCounter = 0
    }
 
    # create the initial session state
    $iss = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
 
    # add any snapins to the session state object
    if($Snapins){
        foreach ($snapName in $Snapins){
            try{
                $iss.ImportPSSnapIn($snapName,[ref]'') | Out-Null
                Write-Verbose "Imported $snapName to Initial Session State"
            }
            catch{
                Write-Warning $_.Exception.Message
            }
        }
    }
 
    # add any modules to the session state object
    if($Modules){
        foreach($module in $Modules){
            try{
                $iss.ImportPSModule($module) | Out-Null
                Write-Verbose "Imported $module to Initial Session State"
            }
            catch{
                Write-Warning $_.Exception.Message
            }
        }
    }
 
    # add any functions to the session state object
    if($Functions){
        foreach($func in $Functions){
            try{
                $thisFunction = Get-Item -LiteralPath "function:$func"
                [String]$functionName = $thisFunction.Name
                [ScriptBlock]$functionCode = $thisFunction.ScriptBlock
                $iss.Commands.Add((New-Object -TypeName System.Management.Automation.Runspaces.SessionStateFunctionEntry -ArgumentList $functionName,$functionCode))
                Write-Verbose "Imported $func to Initial Session State"
                Remove-Variable thisFunction, functionName, functionCode
            }
            catch{
                Write-Warning $_.Exception.Message
            }
        }
    }
 
    # add any variables to the session state object
    if($Variables){
        foreach($var in $Variables){
            try{
                $thisVariable = Get-Variable $var
                $iss.Variables.Add((New-Object -TypeName System.Management.Automation.Runspaces.SessionStateVariableEntry -ArgumentList $thisVariable.Name, $thisVariable.Value, ''))
                Write-Verbose "Imported $var to Initial Session State"
            }
            catch{
                Write-Warning $_.Exception.Message
            }
        }
    }
 
    # create the runspace pool
    $runspacePool = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspacePool($minRunspaces, $maxRunspaces, $iss, $Host)
    Write-Verbose 'Created runspace pool'
 
    # set apartmentstate to MTA if MTA switch is used
    if($MTA){
        $runspacePool.ApartmentState = 'MTA'
        Write-Verbose 'ApartmentState: MTA'
    }
    else {
        Write-Verbose 'ApartmentState: STA'
    }
 
    # open the runspace pool
    $runspacePool.Open()
    Write-Verbose 'Runspace Pool Open'
 
    # return the runspace pool object
    Write-Output $runspacePool
}
 
function New-RunspaceJob{
    <#
        .SYNOPSIS
            Create a new runspace job.
        .DESCRIPTION
            This function creates a new runspace job, executed in it's own runspace (thread).
        .EXAMPLE
            New-RunspaceJob -JobName 'Inventory' -ScriptBlock $code -Parameters $parameters
            Description
            -----------
            Execute code in $code with parameters from $parameters in a new runspace (thread).
        .NOTES
            Name: New-RunspaceJob
            Author: Øyvind Kallstad
            Date: 10.02.2014
            Version: 1.0
    #>
    [CmdletBinding()]
    param(
        # Optionally give the job a name.
        [Parameter()]
        [string]$JobName,
 
        # The code you want to execute.
        [Parameter(Mandatory = $true)]
        [ScriptBlock]$ScriptBlock,
 
        # A working runspace pool object to handle the runspace job.
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Runspaces.RunspacePool]$RunspacePool,
 
        # Hashtable of parameters to add to the runspace scriptblock.
        [Parameter()]
        [HashTable]$Parameters
    )
 
    # increment the runspace counter
    $global:runspaceCounter++
 
    # create a new runspace and set it to use the runspace pool object
    $runspace = [System.Management.Automation.PowerShell]::Create()
    $runspace.RunspacePool = $RunspacePool
 
    # add the scriptblock to the runspace
    $runspace.AddScript($ScriptBlock) | Out-Null
 
    # if any parameters are given, add them into the runspace
    if($parameters){
        foreach ($parameter in ($Parameters.GetEnumerator())){
            $runspace.AddParameter("$($parameter.Key)", $parameter.Value) | Out-Null
        }
    }
 
    # invoke the runspace and store in the global runspaces variable
    [void]$runspaces.Add(@{
        JobName = $JobName
        InvokeHandle = $runspace.BeginInvoke()
        Runspace = $runspace
        ID = $global:runspaceCounter
    })
    
    Write-Verbose 'Code invoked in runspace' 
}
 
function Receive-RunspaceJob{
    <#
        .SYNOPSIS
            Receive data back from a runspace job.
        .DESCRIPTION
            This function checks for completed runspace jobs, and retrieves the return data.
        .EXAMPLE
            Receive-RunspaceJob -Wait
            Description
            -----------
            Will wait until all runspace jobs are complete and retrieve data back from all of them.
        .EXAMPLE
            Receive-RunspaceJob -JobName 'Inventory'
            Description
            -----------
            Will get data from all completed jobs with the JobName 'Inventory'.
        .NOTES
            Name: Receive-RunspaceJob
            Author: Øyvind Kallstad
            Date: 10.02.2014
            Version: 1.0
    #>
    [CmdletBinding()]
    param(
        # Only get results from named job.
        [Parameter()]
        [string]$JobName,

        # Only get the results from job with this ID.
        [Parameter()]
        [int] $ID,
 
        # Wait for all jobs to finish.
        [Parameter(HelpMessage='Using this switch will wait until all jobs are finished')]
        [switch]$Wait,

        # Timeout in seconds until breaking free of the wait loop.
        [Parameter()]
        [int] $TimeOut = 60,
 
        # Not implemented yet!
        [Parameter(HelpMessage='Not implemented yet!')]
        [switch]$ShowProgress
    )

    $startTime = Get-Date
 
    do{
        $more = $false
 
        # handle filtering of runspaces
        $filteredRunspaces = $global:runspaces.Clone()
        		
        if($JobName){
            $filteredRunspaces = $filteredRunspaces | Where-Object {$_.JobName -eq $JobName}
        }

        if ($ID) {
            $filteredRunspaces = $filteredRunspaces | Where-Object {$_.ID -eq $ID}
        }
 
        # iterate through the runspaces
        foreach ($runspace in $filteredRunspaces){
            # If job is finished, write the result to the pipeline and dispose of the runspace.
            if ($runspace.InvokeHandle.isCompleted){
                Write-Output $runspace.Runspace.EndInvoke($runspace.InvokeHandle)
                $runspace.Runspace.Dispose()
                $runspace.Runspace = $null
                $runspace.InvokeHandle = $null
                $runspaces.Remove($runspace)
                Write-Verbose 'Job received'
            }
 
            # If invoke handle is still in place, the job is not finished.
            elseif ($runspace.InvokeHandle -ne $null){
                $more = $true
            }
        }

        # break free of wait loop if timeout is exceeded
        if ((New-TimeSpan -Start $startTime).TotalSeconds -ge $TimeOut) {
            Write-Verbose 'Timeout exceeded - breaking out of loop'
            $more = $false
        }
 
    }
    while ($more -and $PSBoundParameters['Wait'])
}
 
function Show-RunspaceJob{
    <#
        .SYNOPSIS
            Show info about current runspace jobs.
        .DESCRIPTION
            This function will show you information about current (non-received) runspace jobs.
        .EXAMPLE
            Show-RunspaceJob
            Description
            -----------
            Will list all current (non-received) runspace jobs.
        .EXAMPLE
            Show-RunspaceJob -JobName 'Inventory'
            Description
            -----------
            Will list all jobs with the name 'Inventory' that are not received yet.
        .NOTES
            Name: Show-RunspaceJob
            Author: Øyvind Kallstad
            Date: 10.02.2014
            Version: 1.0
    #>
    [CmdletBinding()]
    param(
        # Use the JobName parameter to optionally filter on the name of the job.
        [Parameter()]
        [string]$JobName
    )
 
    # if JobName parameter is used filter the runspaces
    if($JobName){
        $filteredRunspaces = $global:runspaces | Where-Object {$_.JobName -eq $JobName}
    }
    # else use all runspaces
    else{
        $filteredRunspaces = $global:runspaces
    }
 
    # iterate through all runspaces
    foreach ($runspace in $filteredRunspaces){
        # and create and output object for each job
        Write-Output (,([PSCustomObject] [Ordered] @{
            JobName = $runspace.JobName
            ID = $runspace.ID
            InstanceId = $runspace.Runspace.InstanceId
            Status = $runspace.Runspace.InvocationStateInfo.State
            Reason = $runspace.Runspace.InvocationStateInfo.Reason
            Completed = $runspace.InvokeHandle.IsCompleted
            HadErrors = $runspace.Runspace.HadErrors
        }))
    }
}

function Clear-RunspaceJobs {
    Remove-Variable -Name 'Runspaces' -Scope 'Global'
}