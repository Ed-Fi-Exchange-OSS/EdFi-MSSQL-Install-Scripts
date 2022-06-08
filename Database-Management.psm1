# SPDX-License-Identifier: Apache-2.0
# Licensed to the Ed-Fi Alliance under one or more agreements.
# The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
# See the LICENSE and NOTICES files in the project root for more information.

#Requires -Version 7

Import-Module SqlServer
Import-Module ./Package-Management.psm1 -Force

<#
.SYNOPSIS
    Builds a connection string for Microsoft SQL Server.

.EXAMPLE
    New-SqlServerConnectionString -Server localhost -DatabaseName master -Port 1456 -UseIntegratedSecurity

    "Data Source=localhost,1456;Initial Catalog=master;Integrated Security=true"

.EXAMPLE
    New-SqlServerConnectionString -Server localhost -DatabaseName master -Port 1456 -Username sa -Password super_strong_1

    Data Source=localhost,1456;Initial Catalog=master;User Id=sa;Password=super_strong_1
#>
function New-SqlServerConnectionString {
    param (
        [string]
        $Server,

        [string]
        $DatabaseName,

        [int]
        $Port = 1433,

        [switch]
        $UseIntegratedSecurity,

        [string]
        $Username,

        [string]
        $Password
    )

    # Only use port if non-standard, so that developers don't need
    # to manually enable TCP/IP on their local SQL Server instances
    if (1433 -ne $Port) {
        $connectionString = "Data Source=$Server,$Port;Initial Catalog=$DatabaseName;"
    }
    else {
        $connectionString = "Data Source=$Server;Initial Catalog=$DatabaseName;"
    }

    if ($UseIntegratedSecurity) {
        return $connectionString + "Integrated Security=true"
    }

    return $connectionString + "User Id=$Username;Password=$Password"
}

<#
.SYNOPSIS
    Creates a database if it does not exist yet

.EXAMPLE
    New-Database -server localhost -port 1434 -username sa -password "super_strong_1" -DatabaseName whatever

.EXAMPLE
    New-Database -server localhost -port 1434 -UseIntegratedSecurity -DatabaseName whatever
#>
function New-Database {
    param(
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

    $query = @"
IF NOT EXISTS(SELECT * FROM sys.databases WHERE name = '$DatabaseName')
BEGIN
    CREATE DATABASE [$DatabaseName]
END
"@

    $arguments = @{
        Query = "$query"
        Database = "master"
        ServerInstance = "$($Server),$($Port)"
    }

    if (-not $UseIntegratedSecurity) {
        $arguments.Username = "$Username"
        $arguments.Password = "$Password"
    }

    Invoke-SqlCmd @arguments
}

<#
.SYNOPSIS
    Download and extract the current version (2.x.y) of the Db Deploy tool.
#>
function Get-DbDeploy {
    Get-NugetPackage -PackageName "EdFi.Suite3.Db.Deploy" -PackageVersion "2" | Out-String
}

Export-ModuleMember -Function New-SqlServerConnectionString, New-Database, Get-DbDeploy
