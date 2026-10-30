# AmneziaWG 3.1 — VPN Server Installer with Xray

Automated AmneziaWG and Xray VPN installation and management for Debian and Ubuntu servers. Features Docker deployment, VLESS + REALITY support, web panel, firewall configuration and server hardening.

## Features

- Automated AmneziaWG deployment using Docker.
- Xray integration with VLESS + REALITY.
- Web panel with Nginx and SSL.
- Firewall configuration with UFW.
- SSH hardening and Fail2Ban protection.
- Optional Brazil-only SSH access restriction.
- Network and system optimizations.
- Scheduled maintenance and Docker cleanup.
- Configuration and obfuscation management.
- AmneziaWG and Xray status monitoring.

## Requirements

- Debian 11+ or Ubuntu 20.04+
- Root or sudo access
- Internet connection

## Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/Kurumim3/amneziawg-xray-setup.git

# 2. Enter the project directory
cd amneziawg-xray-setup

# 3. Make the script executable
chmod +x amneziawg-setup.sh

# 4. Run the interactive menu
sudo bash amneziawg-setup.sh
```

## Installation Menu

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
- Journal log cleanup.
- Optional unattended security updates.

Scheduled maintenance runs weekly.

## Security Notes

- Keep your SSH session open while changing SSH settings.
- Test a new SSH connection before closing the current session.
- Configure the administrator IP whitelist before enabling geographic restrictions.
- Review firewall and access rules before deployment.

## License

Apache License 2.0 — see [LICENSE](LICENSE).
