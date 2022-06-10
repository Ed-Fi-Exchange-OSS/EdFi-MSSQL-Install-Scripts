# EdFi-MSSQL-Install-Scripts

| :exclamation: **Experimental** :exclamation: |
| -------------------------------------------- |

This repo has a small collection of PowerShell 7 scripts for installing the
Ed-Fi databases into Microsoft SQL Server. The motivating goal is to install the
EdFi_Admin, EdFi_ODS, and EdFi_Security databases into SQL Server, whether
running in a cloud service, in Docker, or traditional hosting, without the need
to run the full ODS/API source code build and deploy processes. In addition to
installing the core Ed-Fi ODS/API tables, these scripts also install the Admin
App tables.

## Usage Notes

* These scripts will only create bare databases, with no descriptors, sample
  data, or extensions.
* The install process must download and unzip a few NuGet packages. These will
  be placed in a local directory called `.packages`.

## Examples

Sample script to demonstrate use of the modules. Please see the comments in
[Install-EdFiDatabases.psm1](Install-EdFiDatabases.psm1) for more information
about alternate configuration options.

Install the Admin and Security databases:

```pwsh
Import-Module ./Install-EdFiDatabases.psm1 -Force


Install-AdminDatabase -OdsApiVersion 5.3 -Username sa -Password super_strong_1
Install-AdminAppTables -AdminAppVersion 2.3 -Username sa -Password super_strong_1

Install-SecurityDatabase -OdsApiVersion 5.3 -Username sa -Password super_strong_1
```

Install a single ODS for use in Shared Instance mode:

```pwsh
Install-OdsDatabase -OdsApiVersion 5.3 -Username sa -Password super_strong_1
```

Install two ODS databases for use in Year-Specific mode.

```pwsh
Install-OdsDatabase -OdsApiVersion 5.3 -Username sa -Password super_strong_1 -DatabaseName EdFi_Ods_2022
Install-OdsDatabase -OdsApiVersion 5.3 -Username sa -Password super_strong_1 -DatabaseName EdFi_Ods_2023
```

Install two ODS databases for use in District-Specific mode

```pwsh
Install-OdsDatabase -OdsApiVersion 5.3 -Username sa -Password super_strong_1 -DatabaseName EdFi_Ods_255901
Install-OdsDatabase -OdsApiVersion 5.3 -Username sa -Password super_strong_1 -DatabaseName EdFi_Ods_255902
```

Switch to pre-release of ODS/API 6.0 and Admin App 2.4, connecting with
integrated security and using alternate database names.

```pwsh
Install-AdminDatabase -OdsApiVersion 6.0 -PreRelease -UseIntegratedSecurity -DatabaseName "EdFi_Admin_Pre"
Install-AdminAppTables -AdminAppVersion 2.4 -PreRelease -UseIntegratedSecurity -DatabaseName "EdFi_Admin_Pre"
Install-SecurityDatabase -OdsApiVersion 6.0 -PreRelease -UseIntegratedSecurity -DatabaseName "EdFi_Security_Pre"
Install-OdsDatabase -OdsApiVersion 6.0 -PreRelease -UseIntegratedSecurity -DatabaseName "EdFi_ODS_Pre"
```

## Legal Information

Copyright (c) 2022 Ed-Fi Alliance, LLC and contributors.

Licensed under the [Apache License, Version 2.0](LICENSE) (the "License").

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied. See the License for the
specific language governing permissions and limitations under the License.

See [NOTICES](NOTICES.md) for additional copyright and license notifications.
