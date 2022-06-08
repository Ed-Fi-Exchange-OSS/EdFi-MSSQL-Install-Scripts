# SPDX-License-Identifier: Apache-2.0
# Licensed to the Ed-Fi Alliance under one or more agreements.
# The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
# See the LICENSE and NOTICES files in the project root for more information.


<#
.DESCRIPTION
    Sample script to demonstrate use of the modules. Please see the comments in
    Install-EdFiDatabases.psm1 for more information about alternate
    configuration options.
#>

Import-Module ./Install-EdFiDatabases.psm1 -Force


Install-AdminDatabase -OdsApiVersion 5.3 -Port 1434 -Username sa -Password super_strong_1
Install-AdminAppTables -AdminAppVersion 2.3 -Port 1434 -Username sa -Password super_strong_1

Install-SecurityDatabase -OdsApiVersion 5.3 -Port 1434 -Username sa -Password super_strong_1

# Shared Instance
Install-OdsDatabase -OdsApiVersion 5.3 -Port 1434 -Username sa -Password super_strong_1

# Year Specific
Install-OdsDatabase -OdsApiVersion 5.3 -Port 1434 -Username sa -Password super_strong_1 -DatabaseName EdFi_Ods_2022
Install-OdsDatabase -OdsApiVersion 5.3 -Port 1434 -Username sa -Password super_strong_1 -DatabaseName EdFi_Ods_2023

# District Specific
Install-OdsDatabase -OdsApiVersion 5.3 -Port 1434 -Username sa -Password super_strong_1 -DatabaseName EdFi_Ods_255901
Install-OdsDatabase -OdsApiVersion 5.3 -Port 1434 -Username sa -Password super_strong_1 -DatabaseName EdFi_Ods_255902
