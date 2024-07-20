@{
    # Version number of this module.
    ModuleVersion        = '2.0.0'

    # ID used to uniquely identify this module
    GUID                 = '6c9fe2f4-8af9-4bad-bd95-5909188c0f0a'

    # Author of this module
    Author               = 'DSC Community'

    # Company or vendor of this module
    CompanyName          = 'DSC Community'

    # Copyright statement for this module
    Copyright            = 'Copyright the DSC Community contributors. All rights reserved.'

    # Description of the functionality provided by this module
    Description          = 'DSC resources for for manipulating the content of text files.'

    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion    = '4.0'

    # Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
    CLRVersion           = '4.0'

    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport    = @()

    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport      = @()

    # Variables to export from this module
    VariablesToExport    = @()

    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport      = @()

    # DSC resources to export from this module
    DscResourcesToExport = @('ReplaceText','KeyValuePairFile','IniSettingsFile')

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData          = @{
        PSData = @{
            # Set to a prerelease string value if the release should be a prerelease.
            Prerelease   = 'preview0005'

            # Tags applied to this module. These help with module discovery in online galleries.
            Tags         = @('DesiredStateConfiguration', 'DSC', 'DSCResource', 'FileContent')

            # A URL to the license for this module.
            LicenseUri   = 'https://github.com/dsccommunity/FileContentDsc/blob/main/LICENSE'

            # A URL to the main website for this project.
            ProjectUri   = 'https://github.com/dsccommunity/FileContentDsc'

            # A URL to an icon representing this module.
            IconUri      = 'https://dsccommunity.org/images/DSC_Logo_300p.png'

            # ReleaseNotes of this module
            ReleaseNotes = '## [2.0.0-preview0005] - 2024-06-12

### Changed

- Transferred ownership to DSCCommunity.org -
  fixes [Issue #31](https://github.com/dsccommunity/FileContentDsc/issues/39).
- BREAKING CHANGE: Changed resource prefix from MSFT to DSC.
- Updated to use continuous delivery pattern using Azure DevOps - fixes
  [Issue #41](https://github.com/dsccommunity/FileContentDsc/issues/41).
- Updated build badges in README.MD.
- Change Azure DevOps Pipeline definition to include `source/*` - Fixes [Issue #45](https://github.com/dsccommunity/FileContentDsc/issues/45).
- Updated pipeline to use `latest` version of `ModuleBuilder` - Fixes [Issue #45](https://github.com/dsccommunity/FileContentDsc/issues/45).
- Merge `HISTORIC_CHANGELOG.md` into `CHANGELOG.md` - Fixes [Issue #46](https://github.com/dsccommunity/FileContentDsc/issues/46).
- Fixed build failures caused by changes in `ModuleBuilder` module v1.7.0
  by changing `CopyDirectories` to `CopyPaths` - Fixes [Issue #49](https://github.com/dsccommunity/FileContentDsc/issues/49).
- Updated to use the common module _DscResource.Common_ - Fixes [Issue #48](https://github.com/dsccommunity/FileContentDsc/issues/48).
- Pin `Pester` module to 4.10.1 because Pester 5.0 is missing code
  coverage - Fixes [Issue #50](https://github.com/dsccommunity/FileContentDsc/issues/50).
- Automatically publish documentation to GitHub Wiki - Fixes [Issue #51](https://github.com/dsccommunity/FileContentDsc/issues/51).
- Renamed `master` branch to `main` - Fixes [Issue #53](https://github.com/dsccommunity/FileContentDsc/issues/53).
- Updated `GitVersion.yml` to latest pattern - Fixes [Issue #57](https://github.com/dsccommunity/FileContentDsc/issues/57).
- Updated build to use `Sampler.GitHubTasks` - Fixes [Issue #60](https://github.com/dsccommunity/FileContentDsc/issues/60).
- Added support for publishing code coverage to `CodeCov.io` and
  Azure Pipelines - Fixes [Issue #61](https://github.com/dsccommunity/FileContentDsc/issues/61).
- Updated .github issue templates to standard - Fixes [Issue #64](https://github.com/dsccommunity/FileContentDsc/issues/64).
- Added Create_ChangeLog_GitHub_PR task to publish stage of build pipeline.
- Added SECURITY.md.
- Updated pipeline Deploy_Module anb Code_Coverage jobs to use ubuntu-latest
  images - Fixes [Issue #63](https://github.com/dsccommunity/FileContentDsc/issues/63).
- Updated pipeline unit tests and integration tests to use Windows Server 2019 and
  Windows Server 2022 images - Fixes [Issue #63](https://github.com/dsccommunity/FileContentDsc/issues/63).
- CI Pipeline
  - Updated pipeline files to match current DSC Community patterns - fixes [Issue #71](https://github.com/dsccommunity/FileContentDsc/issues/71).
  - Updated HQRM and build steps to use windows-latest image.

### Fixed

- Fixed pipeline by replacing the GitVersion task in the `azure-pipelines.yml`
  with a script.

'
        } # End of PSData hashtable
    } # End of PrivateData hashtable
}
