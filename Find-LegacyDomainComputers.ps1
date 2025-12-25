[CmdletBinding()]
param(
  [string] $SearchBase,
  [switch] $IncludeDisabled,
  [switch] $IncludeWindows10,
  [switch] $ExportCsv,
  [string] $ExportPath = ("os_inventory_{0}.csv" -f (Get-Date -Format "yyyyMMdd_HHmmss"))
)

function Get-BuildNumberFromOSVersion([string]$osVersion) {
  if ([string]::IsNullOrWhiteSpace($osVersion)) { return $null }

  $m = [regex]::Match($osVersion, '(?<build>\d{5})')
  if ($m.Success) { return [int]$m.Groups['build'].Value }

  return $null
}

function Get-Win10Release([int]$build) {
  switch ($build) {
    19045 { "22H2" }
    19044 { "21H2" }
    19043 { "21H1" }
    19042 { "20H2" }
    19041 { "2004" }
    18363 { "1909" }
    18362 { "1903" }
    17763 { "1809" }
    17134 { "1803" }
    16299 { "1709" }
    15063 { "1703" }
    14393 { "1607" }
    10586 { "1511" }
    10240 { "1507" }
    default { if ($build) { "Unknown" } else { $null } }
  }
}

try {
  Import-Module ActiveDirectory -ErrorAction Stop

  $props = @(
    "Name","DNSHostName","OperatingSystem","OperatingSystemVersion",
    "LastLogonDate","Enabled","DistinguishedName"
  )

  $params = @{
    Filter      = "OperatingSystem -like '*Windows*'"
    Properties  = $props
    ErrorAction = "Stop"
  }
  if ($SearchBase) { $params.SearchBase = $SearchBase }

  $computers = Get-ADComputer @params
  if (-not $IncludeDisabled) {
    $computers = $computers | Where-Object { $_.Enabled -eq $true }
  }

  $results = $computers | ForEach-Object {
    $os = $_.OperatingSystem
    $osVer = $_.OperatingSystemVersion
    $build = Get-BuildNumberFromOSVersion $osVer

    $family = $null
    $release = $null
    $support = $null
    $isInteresting = $false

    if ($os -match "Windows 7") {
      $family = "Windows 7"; $support = "Legacy / EOL"; $isInteresting = $true
    }
    elseif ($os -match "Windows 8\.1") {
      $family = "Windows 8.1"; $support = "Legacy / EOL"; $isInteresting = $true
    }
    elseif ($os -match "Windows 8") {
      $family = "Windows 8"; $support = "Legacy / EOL"; $isInteresting = $true
    }
    elseif ($os -match "Windows 10") {
      $family = "Windows 10"
      $release = if ($build) { Get-Win10Release $build } else { $null }

      # 2025-10-14 itibarıyla Windows 10 genel destek bitti (22H2 de dahil)
      $support = if ($release -eq "21H2") {
        "Out of servicing (21H2) + Windows 10 EOL"
      } elseif ($release) {
        "Windows 10 EOL (consider Win11 / ESU)"
      } else {
        "Windows 10 (unclassified) - verify"
      }

      $isInteresting = $IncludeWindows10  # Win10'ları istersen listele
    }

    if ($isInteresting) {
      [PSCustomObject]@{
        Name              = $_.Name
        DNSHostName       = $_.DNSHostName
        OperatingSystem   = $os
        OSVersionRaw      = $osVer
        BuildNumber       = $build
        OSFamily          = $family
        Release           = $release
        SupportStatus     = $support
        Enabled           = $_.Enabled
        LastLogonDate     = $_.LastLogonDate
        DistinguishedName = $_.DistinguishedName
      }
    }
  } | Where-Object { $_ -ne $null } | Sort-Object OSFamily, Release, Name

  if ($results.Count -eq 0) {
    Write-Host "No matching machines found in the given scope." -ForegroundColor Green
    return
  }

  $results | Format-Table Name, OSFamily, Release, BuildNumber, SupportStatus, LastLogonDate -AutoSize -Wrap

  Write-Host ""
  Write-Host "Summary:"
  $results | Group-Object OSFamily | Sort-Object Name | ForEach-Object {
    Write-Host ("- {0}: {1}" -f $_.Name, $_.Count)
  }

  if ($ExportCsv) {
    Write-Host ("CSV exported: {0}" -f $ExportPath) -ForegroundColor Cyan
  }
}
catch {
  Write-Error $_.Exception.Message
  exit 1
}
