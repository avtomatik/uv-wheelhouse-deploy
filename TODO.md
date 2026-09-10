# TODO — `uv-wheelhouse-deploy`

## Current state

The repository already has the basic deployment skeleton:

```text
.
├── LICENSE.md
├── README.md
├── examples
│   └── sample_project
├── scripts
│   ├── build_requirements.sh
│   ├── build_wheelhouse.sh
│   ├── package.sh
│   └── windows
│       ├── install.bat
│       ├── install.ps1
│       ├── run.bat
│       └── run.ps1
└── templates
    └── deploy_config.yaml
```

The intended architecture is:

```text
POSIX development machine
        |
        | uv
        v
requirements.txt
        |
        v
Windows-compatible wheelhouse
        |
        v
hashes + build metadata
        |
        v
deployment ZIP
        |
        v
remote Windows machine
        |
        +-- create .venv
        +-- verify wheel hashes
        +-- install wheels offline with pip
        +-- verify installed dependencies
        |
        v
run application
```

Important design decision:

> `uv` is a build-time dependency only. The target Windows machine does NOT need `uv`.

---

# TODO 1 — Create the single POSIX build entry point

Create:

```text
deploy-build.sh
```

Target usage:

```bash
./deploy-build.sh /path/to/project
```

or, preferably, eventually:

```bash
./deploy-build.sh myproject
```

The script should orchestrate the existing individual steps:

```text
build requirements
        ↓
build Windows wheelhouse
        ↓
create hashes
        ↓
create build metadata
        ↓
package ZIP
```

The existing scripts should remain independently usable; `deploy-build.sh` is the convenient top-level entry point.

---

# TODO 2 — Make the build scripts operate on an explicit project

Currently the scripts assume the current working directory is the project.

Make the interface consistent so that the top-level script can invoke them against a project directory.

For example:

```bash
./scripts/build_requirements.sh /path/to/project
./scripts/build_wheelhouse.sh /path/to/project
./scripts/package.sh /path/to/project
```

Avoid relying on the caller having first done:

```bash
cd project
```

The project directory should be an explicit input.

---

# TODO 3 — Remove hard-coded deployment values

Current wheelhouse script contains:

```text
--python-version 3.12.4
--platform win_amd64
```

Current Windows batch installer contains:

```text
py -3.12.4
```

Make these values come from the project's generated:

```text
deploy_config.yaml
```

The template remains:

```text
templates/deploy_config.yaml
```

Each project gets its own generated/configured copy:

```text
my_project/deploy_config.yaml
```

At minimum the configuration should describe:

```yaml
python:
  version: "3.12.4"

application:
  entrypoint: "src/main.py"

platform:
  os: windows
  architecture: amd64
```

The build and Windows installation processes should use this configuration rather than duplicating the values in several scripts.

---

# TODO 4 — Establish project configuration generation

The template:

```text
templates/deploy_config.yaml
```

is the basis for a project's configuration.

Create a mechanism to initialize/configure:

```text
deploy_config.yaml
```

for each project.

The generated configuration should be project-specific.

Do not expect users to modify the repository-wide template directly for every deployment.

---

# TODO 5 — Add SHA-256 hashes for the wheelhouse

Generate a hash manifest during the build.

For example:

```text
wheels/SHA256SUMS
```

containing hashes for every downloaded wheel.

The build pipeline should automatically generate this file after the wheelhouse is populated.

Example conceptual contents:

```text
<sha256>  numpy-....whl
<sha256>  pandas-....whl
...
```

---

# TODO 6 — Verify wheel hashes on Windows before installation

The Windows installer should verify the wheelhouse before installing anything.

Desired sequence:

```text
create .venv
      ↓
verify wheel hashes
      ↓
install wheels
      ↓
dependency verification
```

A corrupted or unexpectedly modified wheel should cause installation to fail.

Prefer a standard PowerShell implementation rather than introducing another dependency.

---

# TODO 7 — Add build metadata

Generate:

```text
deploy-info.json
```

during the build.

At minimum, capture things such as:

```json
{
  "created": "...",
  "python": "3.12.4",
  "platform": "win_amd64",
  "builder": "uv-wheelhouse-deploy",
  "uv_version": "..."
}
```

This should describe the deployment artifact that was actually produced.

The metadata should be included in the final ZIP.

Potential later additions:

* source project version
* git commit
* git branch/tag
* operating system of build host
* package/tool versions

Do not overcomplicate this initially.

---

# TODO 8 — Make the Windows installer fully offline

Current PowerShell installer contains:

```powershell
.\.venv\Scripts\python.exe -m pip install `
    --upgrade pip
```

This conflicts with the offline deployment model.

Remove any installation step that requires Internet access.

The target Windows machine should need no network access and no `uv`.

The installer should install exclusively from:

```text
wheels/
```

using:

```text
--no-index
--find-links wheels
```

---

# TODO 9 — Make PowerShell and BAT installers equivalent

The following should expose the same logical behavior:

```text
scripts/windows/install.ps1
scripts/windows/install.bat
```

Both should:

```text
1. detect/use the configured Python version
2. create .venv
3. verify wheel hashes
4. install requirements from wheels/
5. run dependency verification
6. fail on errors
7. report success clearly
```

Likewise:

```text
scripts/windows/run.ps1
scripts/windows/run.bat
```

should both invoke the configured application entrypoint.

---

# TODO 10 — Stop hard-coding `main.py` in run scripts

Current:

```text
.venv\Scripts\python.exe main.py
```

The actual project entrypoint is already represented in:

```yaml
application:
  entrypoint: "src/main.py"
```

Use that configuration.

The Windows run scripts should not independently hard-code a different entrypoint.

---

# TODO 11 — Add dependency/environment verification

Create a verification script, likely:

```text
scripts/windows/verify.py
```

or a generated/project-specific equivalent.

Purpose:

> Confirm that the deployed environment actually contains the dependencies required by the application.

The dependency information should be derived from the project's:

```text
pyproject.toml
```

rather than maintaining a second manually duplicated dependency list.

Important caveat:

A Python distribution name is not always the same as its import name.

Examples include packages where:

```text
distribution name != import name
```

Therefore do not rely blindly on transforming package names into imports.

The verification design should explicitly account for this.

Potential mechanism:

```toml
[tool.deploy]
verify_imports = [
    "numpy",
    "pandas",
    "sklearn"
]
```

This is optional metadata specifically for verification, while the actual dependency source remains `pyproject.toml`.

---

# TODO 12 — Make packaging produce the complete deployment artifact

The final ZIP should contain everything required by the target Windows machine.

Conceptually:

```text
my_project.zip
│
├── src/
├── requirements.txt
├── wheels/
│   ├── *.whl
│   └── SHA256SUMS
├── deploy_config.yaml
├── deploy-info.json
├── verify.py
├── install.ps1
├── install.bat
├── run.ps1
└── run.bat
```

The target machine should not need to fetch anything else.

---

# TODO 13 — Clean up generated artifact naming

Current:

```bash
zip -r "../${PROJECT}.zip"
```

is based directly on the input path/name.

Define a consistent artifact naming convention.

For example:

```text
my_project-2026-09-10.zip
```

or:

```text
my_project-<version>-win_amd64-py3.12.zip
```

Keep the first implementation simple.

---

# TODO 14 — Add a sample project that actually exercises the workflow

Populate:

```text
examples/sample_project
```

with a real minimal Python project containing:

```text
pyproject.toml
uv.lock
src/
deploy_config.yaml
```

The sample should have at least one nontrivial third-party dependency so that the wheelhouse functionality is genuinely tested.

The sample should be usable as an end-to-end demonstration.

---

# TODO 15 — Test the complete workflow end-to-end

Test from a POSIX machine:

```text
sample project
   ↓
deploy-build.sh
   ↓
deployment ZIP
```

Then move the ZIP to Windows and test:

```text
install.ps1
   ↓
.venv
   ↓
offline installation
   ↓
verify.py
   ↓
run.ps1
```

Also test the BAT equivalents.

The most important acceptance criterion:

> Once the deployment ZIP has been created, the Windows installation succeeds with Internet access disabled.

---

# TODO 16 — Test failure cases

Explicitly test:

```text
missing wheel
corrupted wheel
incorrect SHA-256
missing requirements.txt
wrong Python version
missing Python executable
invalid deploy_config.yaml
dependency unavailable for win_amd64
```

Installation should fail clearly rather than leaving a misleading "successful" environment.

---

# TODO 17 — Improve error handling in Windows scripts

The current PowerShell and BAT scripts continue fairly optimistically.

Make failures propagate properly.

PowerShell should use appropriate error handling so a failed command aborts the installation.

BAT should check `ERRORLEVEL` after important operations.

The user should get an obvious final result:

```text
DEPLOYMENT SUCCESSFUL
```

or:

```text
DEPLOYMENT FAILED
```

---

# TODO 18 — Add README documentation for the actual workflow

Document the complete intended workflow:

```text
1. Develop normally with uv.
2. Create/configure deploy_config.yaml.
3. Run deploy-build.sh.
4. Copy ZIP to Windows.
5. Extract ZIP.
6. Run install.ps1 (or install.bat).
7. Run application with run.ps1 (or run.bat).
```

Also explicitly state:

> The target Windows machine does not require `uv`.

Document prerequisites separately for:

```text
build machine
target machine
```

---

# TODO 19 — Document the platform assumptions

Initially define the supported target clearly.

Current intended target:

```text
Windows
CPython 3.12.4
x86-64 / win_amd64
```

Do not imply broader cross-platform support until it is actually implemented and tested.

Later the configuration can naturally grow to support other targets.

---

# TODO 20 — Keep the repository deliberately simple

Do not add a Python-based orchestration framework unless the shell/PowerShell solution genuinely becomes insufficient.

The intended philosophy is:

```text
simple scripts
+
uv on build machine
+
pip + venv on target
+
self-contained wheelhouse
```

The tool should remain easy to understand and easy to debug.

---

# Possible later enhancements

These are intentionally deferred until the core workflow works:

```text
- support Linux deployment targets
- support multiple Windows architectures
- support multiple Python versions
- reproducible build timestamps
- richer deployment manifests
- artifact versioning
- signed manifests/artifacts
- automatic Git commit/version information
- optional archive compression choices
- CI testing on GitHub Actions
- automated release artifacts
```

Do not let these delay the initial usable workflow.

---

# Definition of "1.0-ish"

The project has achieved its original goal when this works:

```bash
./deploy-build.sh ~/projects/my_project
```

produces:

```text
my_project-....zip
```

and, on a clean Windows machine with the required Python version but no `uv` and no Internet:

```powershell
.\install.ps1
```

creates:

```text
.venv/
```

verifies the wheelhouse, installs the project dependencies entirely offline, verifies the resulting environment, and then:

```powershell
.\run.ps1
```

successfully runs the application.
