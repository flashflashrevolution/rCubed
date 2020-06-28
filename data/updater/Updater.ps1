param (
	[switch]$fullPatch = $false
)

$url = "http://www.flashflashrevolution.com/~velocity/Q/R3Air.Release.zip"
$output = "R3Air.Release.zip"
$start_time = Get-Date
$exe_name = "R3Air"

"Stopping R3 if running."
Stop-Process -processname $exe_name -ErrorAction SilentlyContinue

if ($fullpatch) {
	"Downloading new version of R3."
	Import-Module BitsTransfer
	Start-BitsTransfer -Source $url -Destination $output

	"Installing R3"
	Expand-Archive $output -DestinationPath $PSScriptRoot\\.. -Force
	Remove-Item $output

	Write-Output "Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"
}

Set-Location $PSScriptRoot\\..

Start-Process -FilePath $exe_name
