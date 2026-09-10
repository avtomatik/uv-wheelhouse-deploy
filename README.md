# uv-wheelhouse-deploy
Offline deployment bundles for Python applications.

Build on macOS/Linux.

Deploy to Windows machines without internet access.

Uses:
- uv, exists only on the build machine.
- pip wheelhouse
- Python venv

Features:

* uv-based dependency management
* requirements.txt export
* cross-platform wheel downloading
* offline Windows deployment
* automatic venv creation
* PowerShell and batch installers

Designed for:

* air-gapped machines
* remote Windows servers
* industrial PCs
* field deployments
* reproducible Python applications
