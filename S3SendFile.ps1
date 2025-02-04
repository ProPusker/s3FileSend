# Author: Pusker 
# Email: propuskerworks@gmail.com
# Date: 2022-10-22
# Version: 1.0.0


$ScriptName = [io.path]::GetFileNameWithoutExtension($(Get-ChildItem $PSCommandPath | Select-Object -Expand Name))
$ScriptBuild = "211214"
$ScriptPath = Split-Path -Path $PSCommandPath

$LogHeader = "HEADER"
$LogInfo = "INFO"
$LogWarning = "WARNING"
$LogError = "ERROR"

$ScriptsDir = $ScriptPath
$LogsDir = $ScriptPath

$LogPath = $ScriptPath
$LogFileName = "$LogPath\$ScriptName.txt"
$LogSize = 64 * 1024
$LogCount = 5

function Write-NoPrefixLog {
    [CmdletBinding()]
    Param (
        [parameter(Mandatory = $True)]
        $Message
    )

    $Message | Out-File -Append -Encoding utf8 -FilePath ('FileSystem::' + $LogFileName);
}

function Write-Log {
    [CmdletBinding()]
    Param (
        [parameter(Mandatory = $True)]
        $Message
    )
    
    $LogLine = `
        "$(Get-Date -Format "MM/dd/yyyy HH:mm:ss.fff")|" + `
        "$($MyInvocation.ScriptLineNumber)|" + `
        $Message;

    Write-NoPrefixLog $LogLine
    Write-Host $Message
}

function Init-LogFile {
    if (!(Test-Path $LogFileName)) {
        if (!(Test-Path $LogPath)) {
            New-Item -Path $LogPath -ItemType Directory | Out-Null
        }

        New-Item -Path $LogFileName -ItemType File | Out-Null
    } 
    else {
        if ((Get-Item $LogFileName).Length -gt $LogSize) {
            Move-Item -Path $LogFileName -Destination "$LogPath\$ScriptName-$(Get-Date -format yyyyMMdd)-$(Get-Date -Format HHmmss).bak"
            New-Item -Path $LogFileName -ItemType File | Out-Null
        }
    }
    
    While ((Get-ChildItem "$LogPath\$ScriptName-*.bak").count -gt $LogCount) {
        Get-ChildItem "$LogPath\$ScriptName-*.bak" | Sort ModifiedTime | Select -First 1 | Remove-Item | Out-Null
    }

    $Hostname = $(Get-WmiObject Win32_ComputerSystem).Name
    $PSVersion = $PSVersionTable.PSVersion
    Write-Log "$LogHeader|"
    Write-Log "$LogInfo|Script: $ScriptName build $ScriptBuild"
    Write-Log "$LogInfo|PS Version: $PSVersion"
    Write-Log "$LogInfo|Computer: $Hostname"
    Write-Log "$LogInfo|User: $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)"
}

function Decode64 {
    [CmdletBinding()]
    Param (
        [parameter(Mandatory = $True)]
        [string]$EncodedPassword  
    )
    $password = [System.Text.Encoding]::ASCII.GetString([System.Convert]::FromBase64String($EncodedPassword))
    return $password
}

function S3-SafeUpload {
    [CmdletBinding()]
    Param (
        [parameter(Mandatory = $True)]
        [string]$BucketName,

        [parameter(Mandatory = $True)]
        [string]$FileName,

        [parameter(Mandatory = $True)]
        [string]$Destination,

        [parameter(Mandatory = $True)]
        [string]$StorageClass
    )

    $locahhash = EtagHashForFile -FileName $FileName 
    $transfercount = 1
    while ($true) {
        try {
            Write-Log "$LogInfo|Upload $FileName to bucket $BucketName as $Destination (try $transfercount)"
            Write-S3Object -BucketName $BucketName -File $FileName -Key $Destination -StorageClass $StorageClass
            return
        }
        catch {
            $errormessage = "$($Error[0].ToString())$($Error[0].InvocationInfo.PositionMessage)"
            if ($transfercount -ge 10) {
                throw "$LogError|$errormessage"
            }
            else {
                Write-Log "$LogInfo|Transfer error: $errormessage"
                $transfercount += 1
                if ($testtransfer -or $testtransferfail) {
                    Write-Log "$LogInfo|Pause 1 second (test mode)"
                    Start-Sleep -s 1
                }
                else {
                    Write-Log "$LogInfo|Pause 300 seconds"
                    Start-Sleep -s 300
                }
            }
        }
    }
}

function Process-Command {
    [CmdletBinding()]
    Param (
        [parameter(Mandatory = $True)]
        $Command
    )

    Write-Log "$LogInfo|Looking for $($Command.SourceFolder)\$($Command.FileFormat)..."
    $files = Get-ChildItem -Path $Command.SourceFolder -Filter $Command.FileFormat -Force -File | ? {$_.LastWriteTime -gt (Get-Date).AddDays(-$($Command.Age))}
    if ($files.Count -gt 0) {
        Write-Log "$LogInfo|Sign in to S3 with $($Command.S3RegionEndpoint)/$($Command.S3BucketName)"
        $s3password = Decode64($Command.S3SecretAccessKey)
        Set-AWSCredentials -AccessKey $Command.S3AccessKeyID -SecretKey $s3password
        Set-DefaultAWSRegion -Region $Command.S3RegionEndpoint     
        foreach ($f in $files) {
            try {
                $destination = "$($Command.DestinationFolder)$($f.FullName.Substring($Command.SourceFolder.Length).Replace('\', '/'))"
                Write-Log "$LogInfo|  COPY $($f.FullName) to $destination"
                Write-S3Object -BucketName $Command.S3BucketName -File $f.FullName -Key $destination
                if ($Command.Move -like "true") {
                    Write-Log "$LogInfo|  DELETE $($f.FullName)"
                    Remove-Item -Path $f.FullName -Force | Out-Null
                }
            }
            catch {
                $errormessage = $($Error[0].ToString())
                $WarningsCounter += 1
                Write-Log "$LogWarning|$errormessage"
            }
        }        
    }
}

# script starts here

try {
    $StopWatch = [System.Diagnostics.Stopwatch]::StartNew()
    $WarningsCounter = 0

    Init-LogFile

    # find all .xml files in script's folder

    $InputPath = Split-Path -Path $PSCommandPath
    $inputfiles = Get-ChildItem -Path "$InputPath/*.xml"
    if ($inputfiles.Count -eq 0) {
        Write-Log "$LogError|No .xml file found in $InputPath"
        exit 1        
    }

    foreach ($inputfile in $inputfiles) {
        Write-Log "$LogInfo|Read input data from $($inputfile.FullName)"
        [xml]$Config = Get-Content -Path $inputfile.FullName

        foreach ($e in $Config.ABC.Commands.Command) {
            Process-Command -Command $e
        }
    }
}
catch {
    $errormessage = "$($Error[0].ToString())`n$($Error[0].InvocationInfo.PositionMessage)"
    Write-Log "$LogError|$errormessage"
    exit 1
}

# finalizing the log

$totalseconds = [Math]::Round($StopWatch.Elapsed.TotalSeconds, 0)
if ($WarningsCounter -eq 0) {
    Write-Log "$LogInfo|Script completed successfully. Elapsed $totalseconds seconds."
}
else {
    $errormessage = "Script completed with $WarningsCounter warning(s). Elapsed $totalseconds seconds."
    Write-Log "$LogInfo|$errormessage"
}

# script ends here

exit 0
