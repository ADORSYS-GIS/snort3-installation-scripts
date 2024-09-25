[![Snort 3 Installation and Uninstallation Test](https://github.com/bengo237/snort3-intall-script/actions/workflows/snort-test.yaml/badge.svg)](https://github.com/bengo237/snort3-intall-script/actions/workflows/snort-test.yaml)
# Snort3 Installation and Uninstallation Script for Linux

This repository contains a Bash script that automates the process of installing, configuring, and uninstalling Snort3 on a Linux system. Snort is an open-source network intrusion prevention system (NIPS) and network intrusion detection system (NIDS) capable of performing real-time traffic analysis and packet logging.

## Features

- **Installation Script**: Installs all necessary dependencies and downloads/compiles Snort3 from source.
- **Uninstallation Script**: Completely removes Snort3 and its dependencies, along with system configurations.
- **Automated Testing Workflow**: Includes GitHub Actions workflow for testing the installation and uninstallation scripts on Ubuntu and Debian.
- **Systemd Service**: Configures Snort3 as a `systemd` service for easy management and ensures it runs at system boot.

## Prerequisites

Before running the installation script, ensure that `git` is installed on your system. Other necessary tools and libraries, such as `wget`, `gcc`, `cmake`, `libpcap-dev`, and additional dependencies required by Snort3, will be automatically installed by the script.

## Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/bengo237/snort3-install-script.git
   cd snort3-install-script
   ```

2. Make the installation script executable and run it:

   ```bash
   chmod +x ./install-snort3.sh
   sudo ./install-snort3.sh
   ```

   This script will:
   - Download and compile Snort3 from source.
   - Install all necessary dependencies such as `libpcap`, `libdaq`, `pcre`, `zlib`, and more.
   - Set up Snort as a `systemd` service for easy management.

3. Once the installation is complete, verify the installation by running:

   ```bash
   snort -V
   ```

## Uninstallation

To completely uninstall Snort3 and remove all configurations, you can run the uninstallation script:

1. Make the uninstallation script executable and run it:

   ```bash
   chmod +x ./uninstall-snort3.sh
   sudo ./uninstall-snort3.sh
   ```

   This script will:
   - Stop and disable the Snort service.
   - Remove all Snort binaries, dependencies, and system configurations.
   - Remove the Snort user and associated directories.

2. After uninstallation, you can verify that Snort has been removed by checking:

   ```bash
   if command -v snort &> /dev/null; then
       echo "Snort is still installed"
   else
       echo "Snort has been successfully uninstalled"
   fi
   ```

## Automated Testing with GitHub Actions

This repository also includes a GitHub Actions workflow to automatically test the installation and uninstallation scripts on different operating systems (Ubuntu and Debian). The workflow is triggered on `push` and `pull_request` events.

### Workflow: Snort 3 Installation and Uninstallation Test

The workflow performs the following steps:

1. **Checkout Repository**: Checks out the repository where the scripts are stored.
2. **Set Up Python**: Sets up Python 3.x environment (if needed for other processes).
3. **Install Dependencies**: Installs essential dependencies, like `libpcap-dev`.
4. **Run Installation Script**: Runs the `install-snort3.sh` script to install Snort3.
5. **Verify Snort Installation**: Runs `snort -V` to ensure Snort has been successfully installed.
6. **Run Uninstallation Script**: Executes `uninstall-snort3.sh` to completely remove Snort3.
7. **Verify Snort Uninstallation**: Ensures that Snort has been fully removed by checking if the `snort` command is no longer available.

## Notes

- Ensure that you run the scripts as `root` or with `sudo` privileges to avoid permission issues.
- The scripts are tested on the latest versions of Ubuntu and Debian. Compatibility with other Linux distributions may vary.
- If you encounter any issues during installation or uninstallation, feel free to open an issue on the repository.

## License

This project is licensed under the MIT License. See the `LICENSE` file for details.

## Support

If you find this project helpful, please consider giving it a star on GitHub! ⭐
If you reuse or fork this repository, kindly mention the original repository to give credit. Thank you for your support!

