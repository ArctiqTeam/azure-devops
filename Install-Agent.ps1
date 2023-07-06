param (
    [Parameter(Mandatory=$true)][string]$URL,
    [Parameter(Mandatory=$true)][string]$PAT,
    [Parameter(Mandatory=$true)][string]$POOL,
    [Parameter(Mandatory=$true)][string]$AGENT
)

# set a variable to the path of the installation
$installPath = "c:\agent"

# set a variable to the path of the parent folder of the script
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition

Write-Host "Start installation of Azure DevOps agent"

# test if the installation folder already exists and delete if it does
if (test-path $installPath)
{
    Remove-Item -Path $installPath -Force -Confirm:$false -Recurse
}
New-Item -ItemType Directory -Force -Path $installPath

# save the current working directory
Push-Location
Set-Location $installPath

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$wr = Invoke-WebRequest https://api.github.com/repos/Microsoft/azure-pipelines-agent/releases/latest
$tag = ($wr | ConvertFrom-Json)[0].tag_name
$tag = $tag.Substring(1)

write-host "$tag is the latest version"
$packageURL = "https://vstsagentpackage.azureedge.net/agent/$tag/vsts-agent-win-x64-$tag.zip"

# set a variable to the path of the zip file in the same folder as the script
$packageFile = Join-Path $scriptPath "vsts-agent-win-x64-$tag.zip"

# test if the output file already exists and download the file if it doesn't
if (!(Test-Path $packageFile))
{
    Write-Host "Downloading $packageURL to $packageFile"
    Invoke-WebRequest $packageURL -OutFile $packageFile
}

Expand-Archive -Path $packageFile -DestinationPath $PWD
.\config.cmd --unattended --url $URL --auth pat --token $PAT --pool $POOL --agent $AGENT --runAsService

Write-Host "Installation succeeded and agent configured as a service"
Pop-Location

exit 0