# SPDX-License-Identifier: Apache-2.0
# Licensed to the Ed-Fi Alliance under one or more agreements.
# The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
# See the LICENSE and NOTICES files in the project root for more information.

#Requires -Version 7

<#
.SYNOPSIS
    Sorts versions semantically.

.DESCRIPTION
    Semantic Version sorting means that "5.3.111" comes before "5.3.2", despite
    2 being greater than 1.

.EXAMPLE
    Invoke-SemanticSort @("5.1.1", "5.1.11", "5.2.9")

    Output: @("5.2.9", "5.1.11", "5.1.1")
#>
function Invoke-SemanticSort {
    param(
        [Parameter(Mandatory=$true)]
        [string[]]
        $Versions
    )

    $Versions `
        | Select-Object {$_.Split(".")} `
        | Sort-Object {$_.'$_.Split(".")'[0], $_.'$_.Split(".")'[1], $_.'$_.Split(".")'[2]} -Descending `
        | ForEach-Object { $_.'$_.Split(".")' -Join "." }
}

<#
.SYNOPSIS
    Downloads and extracts the latest compatible version of a NuGet package.

.DESCRIPTION
    Uses the [NuGet Server API](https://docs.microsoft.com/en-us/nuget/api/overview)
    to look for the latest compatible version of a NuGet package, where version is
    all or part of a Semantic Version. For example, if $PackageVersion = "5", this
    will download the most recent 5.minor.patch version. If $PackageVersion = "5.3",
    then it download the most recent 5.3.patch version. And if $PackageVersion = "5.3.1",
    then it will look for the exact version 5.3.1 and fail if it does not exist.

.OUTPUTS
    Directory name containing the downloaded files.

.EXAMPLE
    Get-NugetPackage -PackageName "EdFi.Suite3.RestApi.Databases" -PackageVersion "5.3"
#>
function Get-NugetPackage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $PackageName,

        [Parameter(Mandatory=$true)]
        [string]
        $PackageVersion,

        # URL for the pre-release package feed
        [string]
        $PreReleaseServiceIndex = "https://pkgs.dev.azure.com/ed-fi-alliance/Ed-Fi-Alliance-OSS/_packaging/EdFi/nuget/v3/index.json",

        # URL for the release package feed
        [string]
        $ReleaseServiceIndex = "https://pkgs.dev.azure.com/ed-fi-alliance/Ed-Fi-Alliance-OSS/_packaging/EdFi%40Release/nuget/v3/index.json",

        # Enable usage of prereleases
        [Switch]
        $PreRelease
    )

    # Pre-releases
    $nugetServicesURL = $ReleaseServiceIndex
    if ($PreRelease) {
        $nugetServicesURL = $PreReleaseServiceIndex
    }

    # The first URL just contains metadata for looking up more useful services
    $nugetServices = Invoke-RestMethod $nugetServicesURL

    $packageService = $nugetServices.resources `
                        | Where-Object { $_."@type" -like "PackageBaseAddress*" } `
                        | Select-Object -Property "@id" -ExpandProperty "@id"

    # pad this out to three part semver
    $versionSearch
    switch ($PackageVersion.split(".").length) {
        1 { $versionSearch = "$PackageVersion.*.*"}
        2 { $versionSearch = "$PackageVersion.*" }
        3 { $versionSearch = $PackageVersion }
        default: { throw @"
Invalid version string ``$($PackageVersion)``. Should be one, two, or three components from a Semantic Version"
"@.Trim()
}
    }
    $lowerId = $PackageName.ToLower()

    # Lookup available packages
    $package = Invoke-RestMethod "$($packageService)$($lowerId)/index.json"

    # Sort by SemVer
    $versions = Invoke-SemanticSort $package.versions

    # Find the first available version that matches the requested version
    $version = $versions | Where-Object { $_ -like $versionSearch } | Select-Object -First 1

    if ($null -eq $version) {
        throw "Version ``$($PackageVersion)`` does not exist yet."
    }

    $file = "$($lowerId).$($version)"
    $zip = "$($file).zip"
    $packagesDir = ".packages"
    New-Item -Path $packagesDir -Force -ItemType Directory | Out-Null

    Push-Location $packagesDir

    if ($null -ne (Get-ChildItem $file -ErrorAction SilentlyContinue)) {
        # Already exists, don't re-download
        Pop-Location
        return "$($packagesDir)/$($file)"
    }

    try {
        Invoke-RestMethod "$($packageService)$($lowerId)/$($version)/$($file).nupkg" -OutFile $zip

        Expand-Archive $zip -Force

        Remove-Item $zip
    }
    catch {
        throw $_
    }
    finally {
        Pop-Location
    }

    "$($packagesDir)/$($file)"
}

<#
.SYNOPSIS
    Download and extract the ODS/API databases package.

.OUTPUTS
    String containing the name of the created directory, e.g.
    "edfi.suite3.restapi.databases.5.3.1146".

.EXAMPLE
    Get-AdminAppPackage -PackageVersion 5.3
#>
function Get-RestApiPackage {
    param (
        # Requested version, example: "5" (latest 5.x.y), "5.1" (latest 5.1.y), "5.1.2" (exact 5.1.2)
        [Parameter(Mandatory=$true)]
        [string]
        $PackageVersion
    )

    Get-NugetPackage -PackageName "EdFi.Suite3.RestApi.Databases" -PackageVersion $PackageVersion | Out-String
}


<#
.SYNOPSIS
    Download and extract the Admin App installer package.

.OUTPUTS
    String containing the name of the created directory, e.g.
    "edfi.suite3.installer.adminapp.2.4.10".

.EXAMPLE
    Get-AdminAppPackage -PackageVersion 2.4.10
#>
function Get-AdminAppPackage {
    param (
        # Requested version, example: "2" (latest 2.x.y), "2.4" (latest 2.4.y), "2.4.10" (exact 2.4.10)
        [Parameter(Mandatory=$true)]
        [string]
        $PackageVersion
    )

    # Without the pipe to Out-String, the return value was being treated as an
    # object instead of a string, leading to strange behavior.
    Get-NugetPackage -PackageName "EdFi.Suite3.Ods.AdminApp.Web" -PackageVersion $PackageVersion | Out-String
}

Export-ModuleMember -Function Get-RestApiPackage, Get-NugetPackage, Get-AdminAppPackage
