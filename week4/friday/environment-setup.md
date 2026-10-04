# Environment Setup and Tool Stack

To ensure this Infrastructure as Code (IaC) pipeline is fully reproducible by other engineers on the team, the following tool stack and host environment were used during development and execution. 

### Host Operating System
* **OS:** Fedora Linux (KDE Plasma)

### Core DevOps Tools
* **Terraform:** v1.16.4
* **Ansible:** core 2.20.7
* **Python:** 3.14.7

### Cloud Provider & Backend
* **Cloud Platform:** Amazon Web Services (AWS)
* **Remote State Backend:** AWS S3 
* **State Locking:** Handled natively via S3 (`use_lockfile = true`)

### Authentication
* **SSH Key Management:** Standard RSA key pairs (`~/.ssh/kijani-key.pem`)