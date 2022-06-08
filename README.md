# EdFi-MSSQL-Install-Scripts

This repo has a small collection of PowerShell 7 scripts for installing the
Ed-Fi databases into Microsoft SQL Server. The motivating goal is to install the
EdFi_Admin, EdFi_ODS, and EdFi_Security databases into SQL Server, whether
running in a cloud service, in Docker, or traditional hosting, without the need
to run the full ODS/API source code build and deploy processes. In addition to
installing the core Ed-Fi ODS/API tables, these scripts also install the Admin
App tables.

Please note that these scripts will only create a bare database, with no
descriptors or sample data.

See [run.ps1](run.ps1) for a sample script to run these installations.

## Legal Information

Copyright (c) 2022 Ed-Fi Alliance, LLC and contributors.

Licensed under the [Apache License, Version 2.0](LICENSE) (the "License").

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied. See the License for the
specific language governing permissions and limitations under the License.

See [NOTICES](NOTICES.md) for additional copyright and license notifications.
