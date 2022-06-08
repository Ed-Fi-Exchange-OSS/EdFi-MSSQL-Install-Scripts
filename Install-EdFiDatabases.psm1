# SPDX-License-Identifier: Apache-2.0
# Licensed to the Ed-Fi Alliance under one or more agreements.
# The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
# See the LICENSE and NOTICES files in the project root for more information.

#Requires -Version 7
$ErrorActionPreference = "Stop"

Import-Module ./Package-Management.psm1 -Force
Import-Module ./Database-Management.psm1 -Force

<#
.SYNOPSIS
    Installs the Admin App support tables into an MSSQL database.

.DESCRIPTION
    Runs the same SQL script installation as used by the full-blown Admin App
    installation process. It requires the .NET Core 3.1 SDK and PowerShell 7,
    and it downloads pre-requisites NuGet packages on your behalf in to a
    `.packages` directory.

.OUTPUTS
    1) Detailed console logs of the install process
    2) Tables in the `adminapp` and `adminapp_Hangfire` schemas.

.EXAMPLE
    Invoke-DbDeploy -FilePaths "c:/Ed-Fi-ODS","c:/Ed-Fi-ODS-Implementation" -Port 1434 `
        -Username sa -Password super_strong_1 -DatabaseType Security

.EXAMPLE
    Invoke-DbDeploy -FilePaths "c:/Ed-Fi-ODS","c:/Ed-Fi-ODS-Implementation" -Port 1434 `
        -UseIntegratedSecurity -DatabaseType Admin

.EXAMPLE
    Invoke-DbDeploy -FilePaths "c:/Ed-Fi-ODS","c:/Ed-Fi-ODS-Implementation" -Port 1434 `
        -UseIntegratedSecurity -DatabaseName EdFi_Ods_District10 -DatabaseType Ods
#>
function Invoke-DbDeploy {
    param (
        # Array of file paths containing an Artifacts directory
        [Parameter(Mandatory=$true)]
        [string[]]
        $FilePaths,

        # Microsoft SQL Server domain / host name.
        [string]
        $Server = "localhost",

        # Port number, optional.
        [int]
        $Port = 1433,

        # Database name.
        [Parameter(Mandatory=$true)]
        [string]
        $DatabaseName,

        # Ed-Fi database type.
        [Parameter(Mandatory=$true)]
        [ValidateSet("Admin", "ODS", "Security")]
        [string]
        $DatabaseType,

        # Indicates that integrated security should be used instead of username and password.
        [switch]
        $UseIntegratedSecurity,

        # Database username if not using integrated security.
        [string]
        $Username,

        # Database password if not using integrated security.
        [string]
        $Password
    )

    # Ending up with a spurious newline at the end of the string. Trim() fixes that.
    $dbDeployDir = (Get-DbDeploy).Trim()

    $arguments = @{
        Server = $Server
        DatabaseName = $DatabaseName
        Port = $Port
        UseIntegratedSecurity = $UseIntegratedSecurity
        Username = $UserName
        Password = $Password
    }

    New-Database @arguments

    $arguments = @(
        "deploy",
        "-d", $DatabaseType,
        "-e", "SqlServer",
        "-c", (New-SqlServerConnectionString @arguments),
        "-p", ($FilePaths -Join ",")
    )

    &dotnet "$($dbDeployDir)/tools/netcoreapp3.1/any/EdFi.Db.Deploy.dll" $arguments

    if ($LASTEXITCODE -ne 0) {
        throw "Execution of EdFi.Db.Deploy failed."
    }
}

<#
.SYNOPSIS
    Installs the Admin App support tables into an MSSQL database.

.DESCRIPTION
    Runs the same SQL script installation as used by the full-blown Admin App
    installation process. It requires the .NET Core 3.1 SDK and PowerShell 7,
    and it downloads pre-requisites NuGet packages on your behalf in to a
    `.packages` directory.

.OUTPUTS
    1) Detailed console logs of the install process
    2) Tables in the `adminapp` and `adminapp_Hangfire` schemas.

.EXAMPLE
    Install-AdminAppTables -AdminAppVersion 2.3 -Port 1434 -Username sa -Password super_strong_1

.EXAMPLE
    Install-AdminAppTables -AdminAppVersion 2.3 -Port 1434 -UseIntegratedSecurity

.EXAMPLE
    Install-AdminAppTables -AdminAppVersion 5 -Port 1434 -UseIntegratedSecurity -DatabaseName EdFi_Admin_District10
#>
function Install-AdminAppTables {
    param (
        # Requested version, example: "2" (latest 2.x.y), "2.4" (latest 2.4.y), "2.4.10" (exact 2.4.10).
        [Parameter(Mandatory=$true)]
        [string]
        $AdminAppVersion,

        # Microsoft SQL Server domain / host name.
        [string]
        $Server = "localhost",

        # Database name.
        [string]
        $DatabaseName = "EdFi_Admin",

        # Port number, optional.
        [int]
        $Port = 1433,

        # Indicates that integrated security should be used instead of username and password.
        [switch]
        $UseIntegratedSecurity,

        # Database username if not using integrated security.
        [string]
        $Username,

        # Database password if not using integrated security.
        [string]
        $Password
    )

    $adminAppDir = (Get-AdminAppPackage $AdminAppVersion).Trim()

    $arguments = @{
        Server = $Server
        DatabaseName = $DatabaseName
        Port = $Port
        UseIntegratedSecurity = $UseIntegratedSecurity
        Username = $UserName
        Password = $Password
        FilePaths = @(Resolve-Path $adminAppDir)
        DatabaseType = "Admin"
    }

    Invoke-DbDeploy @arguments
}

<#
.SYNOPSIS
    Installs the EdFi_Admin tables into an MSSQL database.

.DESCRIPTION
    Runs the same SQL script installation as used by the full-blown ODS/API
    installation process. It requires the .NET Core 3.1 SDK and PowerShell 7,
    and it downloads pre-requisites NuGet packages on your behalf in to a
    `.packages` directory.

.OUTPUTS
    1) Detailed console logs of the install process
    2) Tables in the `dbo` schema.

.EXAMPLE
    Install-AdminDatabase -OdsApiVersion 5.3 -Port 1434 -Username sa -Password super_strong_1

.EXAMPLE
    Install-AdminDatabase -OdsApiVersion 5 -Port 1434 -UseIntegratedSecurity

.EXAMPLE
    Install-AdminDatabase -OdsApiVersion 5 -Port 1434 -UseIntegratedSecurity -DatabaseName EdFi_Admin_District10
#>
function Install-AdminDatabase {
    param(
        # Requested version, example: "5" (latest 5.x.y), "5.3" (latest 5.3.y), "5.3.1146" (exact).
        [Parameter(Mandatory=$true)]
        [string]
        $OdsApiVersion,

        # Microsoft SQL Server domain / host name.
        [string]
        $Server = "localhost",

        # Database name.
        [string]
        $DatabaseName = "EdFi_Admin",

        # Port number, optional.
        [int]
        $Port = 1433,

        # Indicates that integrated security should be used instead of username and password.
        [switch]
        $UseIntegratedSecurity,

        # Database username if not using integrated security.
        [string]
        $Username,

        # Database password if not using integrated security.
        [string]
        $Password
    )

    $restApiDbDir = (Get-RestApiPackage $OdsApiVersion).Trim()

    $arguments = @{
        Server = $Server
        DatabaseName = $DatabaseName
        Port = $Port
        UseIntegratedSecurity = $UseIntegratedSecurity
        Username = $UserName
        Password = $Password
        FilePaths = @(
            (Resolve-Path "$($restApiDbDir)/Ed-Fi-ODS"),
            (Resolve-Path "$($restApiDbDir)/Ed-Fi-ODS-Implementation")
        )
        DatabaseType = "Admin"
    }

    Invoke-DbDeploy @arguments
}

<#
.SYNOPSIS
    Installs the EdFi_Security tables into an MSSQL database.

.DESCRIPTION
    Runs the same SQL script installation as used by the full-blown ODS/API
    installation process. It requires the .NET Core 3.1 SDK and PowerShell 7,
    and it downloads pre-requisites NuGet packages on your behalf in to a
    `.packages` directory.

.OUTPUTS
    1) Detailed console logs of the install process
    2) Tables in the `dbo` schema.

.EXAMPLE
    Install-SecurityDatabase -OdsApiVersion 5.3 -Port 1434 -Username sa -Password super_strong_1

.EXAMPLE
    Install-SecurityDatabase -OdsApiVersion 5 -Port 1434 -UseIntegratedSecurity

.EXAMPLE
    Install-SecurityDatabase -OdsApiVersion 5 -Port 1434 -UseIntegratedSecurity -DatabaseName EdFi_Security_District10
#>
function Install-SecurityDatabase {
    param(
        # Requested version, example: "5" (latest 5.x.y), "5.3" (latest 5.3.y), "5.3.1146" (exact).
        [Parameter(Mandatory=$true)]
        [string]
        $OdsApiVersion,

        # Microsoft SQL Server domain / host name.
        [string]
        $Server = "localhost",

        # Database name.
        [string]
        $DatabaseName = "EdFi_Security",

        # Port number, optional.
        [int]
        $Port = 1433,

        # Indicates that integrated security should be used instead of username and password.
        [switch]
        $UseIntegratedSecurity,

        # Database username if not using integrated security.
        [string]
        $Username,

        # Database password if not using integrated security.
        [string]
        $Password
    )

    $restApiDbDir = (Get-RestApiPackage $OdsApiVersion).Trim()

    $arguments = @{
        Server = $Server
        DatabaseName = $DatabaseName
        Port = $Port
        UseIntegratedSecurity = $UseIntegratedSecurity
        Username = $UserName
        Password = $Password
        FilePaths = @(
            (Resolve-Path "$($restApiDbDir)/Ed-Fi-ODS"),
            (Resolve-Path "$($restApiDbDir)/Ed-Fi-ODS-Implementation")
        )
        DatabaseType = "Security"
    }

    Invoke-DbDeploy @arguments
}

<#
.SYNOPSIS
    Installs the EdFi_ODS tables into an MSSQL database.

.DESCRIPTION
    Runs the same SQL script installation as used by the full-blown ODS/API
    installation process. It requires the .NET Core 3.1 SDK and PowerShell 7,
    and it downloads pre-requisites NuGet packages on your behalf in to a
    `.packages` directory.

.OUTPUTS
    1) Detailed console logs of the install process
    2) Tables in the `edfi` schema.

.EXAMPLE
    Install-OdsDatabase -OdsApiVersion 5.3 -Port 1434 -Username sa -Password super_strong_1

.EXAMPLE
    Install-OdsDatabase -OdsApiVersion 5 -Port 1434 -UseIntegratedSecurity

.EXAMPLE
    Install-OdsDatabase -OdsApiVersion 5 -Port 1434 -UseIntegratedSecurity -DatabaseName EdFi_ODS_District10
#>
function Install-OdsDatabase {
    param(
        # Requested version, example: "5" (latest 5.x.y), "5.3" (latest 5.3.y), "5.3.1146" (exact).
        [Parameter(Mandatory=$true)]
        [string]
        $OdsApiVersion,

        # Microsoft SQL Server domain / host name.
        [string]
        $Server = "localhost",

        # Database name.
        [string]
        $DatabaseName = "EdFi_Ods",

        # Port number, optional.
        [int]
        $Port = 1433,

        # Indicates that integrated security should be used instead of username and password.
        [switch]
        $UseIntegratedSecurity,

        # Database username if not using integrated security.
        [string]
        $Username,

        # Database password if not using integrated security.
        [string]
        $Password
    )

    $restApiDbDir = (Get-RestApiPackage $OdsApiVersion).Trim()

    $arguments = @{
        Server = $Server
        DatabaseName = $DatabaseName
        Port = $Port
        UseIntegratedSecurity = $UseIntegratedSecurity
        Username = $UserName
        Password = $Password
        FilePaths = @(
            (Resolve-Path "$($restApiDbDir)/Ed-Fi-ODS"),
            (Resolve-Path "$($restApiDbDir)/Ed-Fi-ODS-Implementation"),
            (Resolve-Path "$($restApiDbDir)/Ed-Fi-ODS/Application/EdFi.Ods.Standard")
        )
        DatabaseType = "Ods"
    }

    Invoke-DbDeploy @arguments
}

Export-ModuleMember -Function Install-AdminAppTables, Install-AdminDatabase, Install-SecurityDatabase, Install-OdsDatabase
