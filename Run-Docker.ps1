# SPDX-License-Identifier: Apache-2.0
# Licensed to the Ed-Fi Alliance under one or more agreements.
# The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
# See the LICENSE and NOTICES files in the project root for more information.

<#
.SYNOPSIS
    Start and stop an MSSQL 2019 container.

.DESCRIPTION
    This is a quick-and-dirty helper primarily intended for script testing.
    Saves data to the .data directory. SA password is hard-coded to
    "super_strong_1".

.EXAMPLE
    ./Run-Docker.ps1 start

    Starts SQL Server running on the default port 1433.

.EXAMPLE
    ./Run-Docker.ps1 start 1434

    Starts SQL Server on an alternate port 1434.

.EXAMPLE
    ./Run-Docker.ps1 stop

    Stops SQL Server on any port.
#>
param(
    # The command "start" or "stop".
    [Parameter(Mandatory=$true)]
    [ValidateSet("start", "stop")]
    [string]
    $Command,

    # Alternative port number.
    [int]
    $Port = 1433
)

switch ($command) {
    start {
        Write-Host "Starting MSSQL container"
        $dataDir = "$($PsScriptRoot)/.data"

        New-Item -Path $dataDir -ItemType Directory -Force | Out-Null

        &docker run -p "$($Port):1433" -d -e 'ACCEPT_EULA=y' `
            -e 'SA_PASSWORD=super_strong_1' `
            -v "$($dataDir)/data:/var/opt/mssql/data" `
            -v "$($dataDir)/log:/var/opt/mssql/log" `
            -v "$($dataDir)/secrets:/var/opt/mssql/secrets" `
            --name edfi_sql_test `
            mcr.microsoft.com/mssql/server:2019-latest
    }
    stop {
        Write-Host "Stopping MSSQL container"
        &docker stop edfi_sql_test
        &docker rm edfi_sql_test
    }
}
