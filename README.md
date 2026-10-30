# AmneziaWG 3.1

Automated AmneziaWG VPN installation and management for Debian and Ubuntu servers.

## Features

- Automated AmneziaWG deployment using Docker.
- Web panel with Nginx and SSL.
- Firewall configuration with UFW.
- SSH hardening and Fail2Ban protection.
- Optional Brazil-only SSH access restriction.
- Network and system optimizations.
- Scheduled maintenance and Docker cleanup.
- Configuration and obfuscation management.
- Status monitoring and uninstall options.

## Requirements

- Debian 11+ or Ubuntu 20.04+
- Root or sudo access
- Internet connection
- Docker and Docker Compose (installed automatically if needed)

## Quick Start

Clone the repository:

```bash
git clone https://github.com/USER/REPOSITORY.git
cd REPOSITORY
```

Make the script executable and run it:

```bash
chmod +x amneziawg-setup.sh
sudo ./amneziawg-setup.sh
```

Follow the interactive menu to configure or install the services.

## Installation Options

The menu provides:

1. Configure installation
2. Full installation
3. System and firewall setup
4. AmneziaWG deployment
5. Nginx, SSL and Fail2Ban
6. SSH configuration
7. Maintenance and status
8. Advanced options
9. Exit

## Maintenance

Automatic maintenance can include:

- Docker image updates.
- Unused image and package cleanup.
- Journal log rotation.
- Optional unattended security updates.

Scheduled maintenance runs weekly.

## Security Notes

- Keep your SSH session open while changing SSH settings.
- Test a new SSH connection before closing the current session.
- Configure the administrator IP whitelist before enabling geographic restrictions.
- Review firewall and access rules before deployment.

## License

Apache License 2.0 — see [LICENSE](LICENSE).
