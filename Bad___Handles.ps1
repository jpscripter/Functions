Add-Type "
using System;
using System.Runtime.InteropServices;

    public static class NtDll
    {
        [DllImport(`"ntdll.dll`")]
        public static extern NT_STATUS NtQueryObject(
            [In] IntPtr Handle,
            [In] OBJECT_INFORMATION_CLASS ObjectInformationClass,
            [In] IntPtr ObjectInformation,
            [In] int ObjectInformationLength,
            [Out] out int ReturnLength);

        [DllImport(`"ntdll.dll`")]
        public static extern NT_STATUS NtQuerySystemInformation(
            [In] SYSTEM_INFORMATION_CLASS SystemInformationClass,
            [In] IntPtr SystemInformation,
            [In] int SystemInformationLength,
            [Out] out int ReturnLength);
    }

	public static class Kernel32
	{
	        [DllImport(`"kernel32.dll`", SetLastError = true)]
			public static extern IntPtr OpenProcess(
            [In] int dwDesiredAccess,
            [In, MarshalAs(UnmanagedType.Bool)] bool bInheritHandle,
            [In] int dwProcessId);

        [DllImport(`"kernel32.dll`", SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool DuplicateHandle(
            [In] IntPtr hSourceProcessHandle,
            [In] IntPtr hSourceHandle,
            [In] IntPtr hTargetProcessHandle,
            [Out] out IntPtr lpTargetHandle,
            [In] int dwDesiredAccess,
            [In, MarshalAs(UnmanagedType.Bool)] bool bInheritHandle,
            [In] int dwOptions);

		[DllImport(`"kernel32.dll`", SetLastError = true)]
			public static extern uint QueryDosDevice(string lpDeviceName, System.Text.StringBuilder lpTargetPath, int ucchMax);
	}

	[StructLayout(LayoutKind.Sequential)]
    public struct SystemHandleEntry
    {
        public int OwnerProcessId;
        public byte ObjectTypeNumber;
        public byte Flags;
        public ushort Handle;
        public IntPtr Object;
        public int GrantedAccess;
    }

	public enum SYSTEM_INFORMATION_CLASS
    {
        SystemBasicInformation = 0,
        SystemPerformanceInformation = 2,
        SystemTimeOfDayInformation = 3,
        SystemProcessInformation = 5,
        SystemProcessorPerformanceInformation = 8,
        SystemHandleInformation = 16,
        SystemInterruptInformation = 23,
        SystemExceptionInformation = 33,
        SystemRegistryQuotaInformation = 37,
        SystemLookasideInformation = 45
    }

	public enum OBJECT_INFORMATION_CLASS
    {
        ObjectBasicInformation = 0,
        ObjectNameInformation = 1,
        ObjectTypeInformation = 2,
        ObjectAllTypesInformation = 3,
        ObjectHandleInformation = 4
    }

	public enum NT_STATUS
    {
        STATUS_SUCCESS = 0x00000000,
        STATUS_BUFFER_OVERFLOW = unchecked((int)0x80000005L),
        STATUS_INFO_LENGTH_MISMATCH = unchecked((int)0xC0000004L)
    }
"

<#
.SYNOPSIS

Converts a DOS-style file name into a regular Windows file name.
.DESCRIPTION



This function can convert a DOS-style (\Device\HarddiskVolume1\MyFile.txt) file name into a regular Windows (C:\MyFile.txt)
file name. 

.PARAMETER RawFileName

The DOS-style file name.

.EXAMPLE

ConvertTo-RegularFileName -RawFileName "\Device\HarddiskVolume1\MyFile.txt"

#>
function ConvertTo-RegularFileName
{
	param($RawFileName)

    foreach ($logicalDrive in [Environment]::GetLogicalDrives())
    {
        $targetPath = New-Object System.Text.StringBuilder 256
        if ([Kernel32]::QueryDosDevice($logicalDrive.Substring(0, 2), $targetPath, 256) -eq 0)
        {
            return $targetPath
        }
        $targetPathString = $targetPath.ToString()
        if ($RawFileName.StartsWith($targetPathString))
        {
            $RawFileName = $RawFileName.Replace($targetPathString, $logicalDrive.Substring(0, 2))
            break
        }
    }
    $RawFileName
}

<#
.SYNOPSIS

Converts a SystemHandleEntry into a PSCustomObject.
.DESCRIPTION

This function is intended to convert a SystemHandleEntry returned by
Get-FileHandle into a PSCustomObject that exposes a Process property and a
file name. 

.PARAMETER HandleEntry

The SystemHandleEntry as returned by Get-FileHandle

.EXAMPLE

Get-FileHandle | ConvertTo-HandleHashTable
#>
function ConvertTo-HandleHashTable
{
	[CmdletBinding()]
	param(
		[Parameter(Mandatory, ValueFromPipeline=$true)]
		[SystemHandleEntry]$HandleEntry
	)

	Process {
		if ($HandleEntry.GrantedAccess -eq 0x0012019f -or $HandleEntry.GrantedAccess -eq 0x00120189 -or $HandleEntry.GrantedAccess -eq 0x120089)
		{
			return
		}

		$sourceProcessHandle = [IntPtr]::Zero
        $handleDuplicate = [IntPtr]::Zero
        $sourceProcessHandle = [Kernel32]::OpenProcess(0x40, $true, $HandleEntry.OwnerProcessId)

        if (-not [Kernel32]::DuplicateHandle($sourceProcessHandle, [IntPtr]$HandleEntry.Handle, (Get-Process -Id $Pid).Handle, [ref]$handleDuplicate, 0, $false, 2))
		{
            return
		}

        $length = 0
        [NtDll]::NtQueryObject($handleDuplicate, [OBJECT_INFORMATION_CLASS]::ObjectNameInformation, [IntPtr]::Zero, 0, [ref]$length) | Out-Null
        $ptr = [IntPtr]::Zero

        $ptr = [System.Runtime.InteropServices.Marshal]::AllocHGlobal($length)
        if ([NtDll]::NtQueryObject($handleDuplicate, [OBJECT_INFORMATION_CLASS]::ObjectNameInformation, $ptr, $length, [ref]$length) -ne [NT_STATUS]::STATUS_SUCCESS)
		{
            return;
		}
        $Path = [System.Runtime.InteropServices.Marshal]::PtrToStringUni([IntPtr]([long]$ptr+ 2 * [IntPtr]::Size))

		[PSCustomObject]@{
			ObjectTypeNumber=$HandleEntry.ObjectTypeNumber;
			Path=(ConvertTo-RegularFileName $Path);
			Process=(Get-Process -Id $HandleEntry.OwnerProcessId);
		}

        [System.Runtime.InteropServices.Marshal]::FreeHGlobal($ptr)

		}
}

<#
.SYNOPSIS

Returns open file handles found on the system. 
.DESCRIPTION

This function returns all open file handles found on the system. In its current state
this cmdlet will only work on a Windows 8 machine.

.EXAMPLE

Get-FileHandle
#>
function Get-FileHandle
{
    $length = 0x10000
    $ptr = [IntPtr]::Zero
    try
    {
        while ($true)
        {
            $ptr = [System.Runtime.InteropServices.Marshal]::AllocHGlobal($length)
            $wantedLength = 0
			$SystemHandleInformation = 16
            $result = [NtDll]::NtQuerySystemInformation($SystemHandleInformation, $ptr, $length, [ref] $wantedLength)
            if ($result -eq [NT_STATUS]::STATUS_INFO_LENGTH_MISMATCH)
            {
                $length = [Math]::Max($length, $wantedLength)
                [System.Runtime.InteropServices.Marshal]::FreeHGlobal($ptr)
                $ptr = [IntPtr]::Zero
            }
            elseif ($result -eq [NT_STATUS]::STATUS_SUCCESS)
			{
                break
			}
            else
			{
                throw (New-Object System.ComponentModel.Win32Exception)
			}
        }

		if ([IntPtr]::Size -eq 4)
		{
			$handleCount = [System.Runtime.InteropServices.Marshal]::ReadInt32($ptr)
		}
		else
		{
			$handleCount = [System.Runtime.InteropServices.Marshal]::ReadInt64($ptr)
		}

		$offset = [IntPtr]::Size
		$She = New-Object -TypeName SystemHandleEntry
        $size = [System.Runtime.InteropServices.Marshal]::SizeOf($She)
        for ($i = 0; $i -lt $handleCount; $i++)
        {
            $FileHandle = [SystemHandleEntry][System.Runtime.InteropServices.Marshal]::PtrToStructure([IntPtr]([long]$ptr + $offset),[Type]$She.GetType())

			#Note that 31 is only applicable to Windows 8
			#It is possible to make this more dynamic but this 
			#was removed for brevity.
			if ($FileHandle.ObjectTypeNumber -eq 31)
			{
				$FileHandle | ConvertTo-HandleHashTable
			}
            $offset += $size
        }
    }
    finally
    {
        if ($ptr -ne [IntPtr]::Zero)
		{
            [System.Runtime.InteropServices.Marshal]::FreeHGlobal($ptr)
		}
    }
    
}

<#
.SYNOPSIS

Finds the locking process for the specified file or files. 
.DESCRIPTION

This function locates processes that have open handles to the file or files specified. They may or may not be the files 
that are currently locking the file but a process must have a handle in order to lock it. 
.PARAMETER InputObject

A System.IO.FileInfo object. This is likely returned from Get-ChildItem.
.PARAMETER Path

The path to a file. 
.EXAMPLE

Find-LockingProcess -Path "E:\Program Files (x86)\Steam\steam.log"
#>
function Find-LockingProcess
{
	[CmdletBinding()]
	param(
	[Parameter(ValueFromPipeline=$true,ParameterSetName="Pipeline",Mandatory)]
	[System.IO.FileInfo]$InputObject,
	[Parameter(ValueFromPipeline=$true,ParameterSetName="Path",Mandatory)]
	[String]$Path
	)

	Begin {
	$Handles = Get-FileHandle
	}

	Process
	{
		if ($InputObject)
		{
			$Handles | Where-Object { $_.Path -eq $InputObject.FullName } | Select-Object -ExpandProperty Process
		}

		if ($Path)
		{
			$Handles| Where-Object { $_.Path -contains $Path } | Select-Object -ExpandProperty Process
		}
	}
}

#Find-LockingProcess -Path "E:\Program Files (x86)\Steam\steam.log"
#Get-FileHandle