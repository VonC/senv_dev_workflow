# senv_dev_workflow

A Git workflow automation tool for managing software versions between snapshots and releases, with integrated changelog generation.

## Disclaimer
This framework uses a framework named `senv` that is not yet public. 

## Overview

This tool automates the version management process between development (SNAPSHOT) and release versions, using a central `version.txt` file as the source of truth. It integrates with Maven projects and provides colored console output for better visibility.

## Features

- Automated version management between SNAPSHOT and release versions
- Integrated changelog generation using [git-cliff](https://git-cliff.org)
- Maven version synchronization
- Git tag management
- Colored console output for better readability
- Windows and Unix-compatible (requires Cygwin/bash)

## Prerequisites

- Git
- Windows environment 
- Maven (optional, for Java projects)
- [git-cliff](https://git-cliff.org) (for changelog generation)

## Getting Started

1. Add this repository as a submodule to your project:

```bash
git submodule add https://github.com/your-repo/senv_dev_workflow
git submodule update --init --recursive
```

2. Create a `version.txt` file in your project root with the format:

```text
0.1.0-SNAPSHOT -- Initial development version
Description line 1
Description line 2
```

## Usage

All the following commands should be triggered in the corresponding wrapper scripts (`build.bat`, `init.bat`, `senv.bat`)

### Managing Versions

To update versions:

```bat
update-version.bat           # Updates SNAPSHOT version
update-version.bat rel      # Creates a release version
```

### Building with Version Management

```bat
t_build.bat pre-processing          # Prepares version for build
t_build.bat pre-processing rel      # Prepares release version
t_build.bat post-processing         # Post-build processing
```

### Version File Format

The `version.txt` file follows this format:

```text
<version> -- <title>
<empty line>
<description line 1>
<description line 2>
...
```

- `version`: Current version (e.g., "1.0.0-SNAPSHOT" or "1.0.0")
- `title`: Release/version title
- `description`: Multi-line description used in changelog

It also interacts with `pom.xml` files when used in a maven project.

It will also interact with `package.json` soon.

### Environment Variables

- `PRJ_DIR`: Project directory path (required)
- `PRJ_DIR_NAME`: Project directory name (required)



