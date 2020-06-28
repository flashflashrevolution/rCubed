param (
	[switch]$fullPatch = $false
)

if ($fullPatch) {
	Start-Process powershell -ArgumentList "((Split-Path $MyInvocation.InvocationName) + '\\Updater.ps1') -fullPatch"
}
else {
	Start-Process powershell ((Split-Path $MyInvocation.InvocationName) + "\\Updater.ps1")
}
