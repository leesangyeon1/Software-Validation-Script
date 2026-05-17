# Software-Validation-Script
 software and environment validation automation script designed to ensure the stability and consistency of compute environments before production use.

The system performs a comprehensive pre-deployment check across all compute nodes, verifying:

Linux distribution and kernel version

Slurm version and cluster connectivity

Loaded environment modules

Active software test outputs from OnDemand GUI applications (Jupyter, RStudio, VS Code, PyCharm, etc)
The automation collects metadata such as timestamps, node information, and software versions, then generates a consolidated report (General_test/) to document system readiness before cluster-wide deployment.

This validation framework improves reproducibility, ensures consistent software configurations across GUI and shell environments, and supports long-term maintainability for HPC users and administrators.
