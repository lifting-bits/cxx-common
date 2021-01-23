[CmdletBinding()]
param(
    $badParam,
    [Parameter(Mandatory=$False)][switch]$disableMetrics = $false,
    [Parameter(Mandatory=$False)][switch]$win64 = $false,
    [Parameter(Mandatory=$False)][string]$withVSPath = "",
    [Parameter(Mandatory=$False)][string]$withWinSDK = ""
)
Set-StrictMode -Version Latest

