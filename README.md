# AmneziaWG 3.1 Installer & Configurator

### Automated VPN Deployment with Docker, Web UI, HTTPS and Server Hardening

An interactive Bash installer to deploy and configure **[AmneziaWG](https://github.com/amnezia-vpn/amneziawg-go)** on Debian 11+ and Ubuntu 20.04+.

The installer automates the deployment of an AmneziaWG VPN server using the **[myceliummesh/amneziawg-ui](https://github.com/myceliummesh/amneziawg-ui)** Docker image, with Nginx reverse proxy, Let's Encrypt SSL certificates, UFW firewall, Fail2Ban, SSH hardening, optional Brazil-only SSH access, and scheduled maintenance.

Designed to simplify deployment while providing configurable security controls and maintenance features.

## ⚡ Quick Start

Connect to your VPS via SSH as `root` and run:

```bash
# 1. Download the installer
wget https://raw.githubusercontent.com/Kurumim3/amneziawg-setup/main/amneziawg-setup.sh

# 2. Make it executable
chmod +x amneziawg-setup.sh

# 3. Launch the interactive menu
bash amneziawg-setup.sh
```

Select:

**Option 2 — FULL INSTALL**

The guided installation will configure the system, firewall, Docker, AmneziaWG, Nginx, SSL, Fail2Ban, scheduled maintenance, and SSH hardening.

Alternatively, launch the guided installation directly:

```bash
bash amneziawg-setup.sh --full
```

Display the installer version:

```bash
bash amneziawg-setup.sh --version
```

> **Important:** Configure your domain's DNS A record to point to your VPS public IPv4 address before installing. If using IPv6, ensure the AAAA record also points to the correct server address.

## 🚀 Features

### VPN Deployment
- Automated AmneziaWG 3.1 deployment using Docker Compose.
- Integrated `myceliummesh/amneziawg-ui` Web UI.
- Persistent VPN configuration and data storage.
- Configurable VPN UDP port.
- Automatic container restart policy.
- Web panel exposed only on localhost, accessed externally through Nginx.

### Web Interface & SSL
- Nginx reverse proxy.
- Automatic Let's Encrypt certificate issuance using Certbot.
- HTTPS redirection.
- TLS 1.2 and TLS 1.3.
- HTTP/2 support based on the installed Nginx version.
- Security-related HTTP headers.
- Basic request rate limiting.
- WebSocket proxy support.

### Server Security
- UFW firewall with default-deny incoming policy.
- Explicit SSH, HTTP, HTTPS and VPN firewall rules.
- Fail2Ban protection for SSH and Nginx.
- Additional Nginx filters for suspicious requests, authentication failures and common exploit attempts.
- Recidive jail for repeat offenders.
- SSH port customization.
- SSH authentication hardening.
- Optional Brazil-only SSH access using ipset and iptables.
- Automatic daily Brazilian IP list updates.

### System Optimization
- Docker installation and configuration.
- IPv4 and IPv6 forwarding.
- TCP SYN cookies.
- Reverse-path filtering configuration.
- BBR congestion control when supported by the kernel.
- Network buffer tuning.
- Additional network hardening through sysctl.

### Automated Maintenance
- Scheduled weekly maintenance (Sunday at 04:00).
- Optional automatic Docker image updates.
- Docker image cleanup.
- APT package cleanup.
- System journal cleanup.
- Optional unattended security updates.
- Maintenance logs with log rotation.
- Systemd timers for scheduled tasks.

### AmneziaWG Obfuscation Guide
- Generates suggested values for Jc, Jmin, Jmax and S1/S2.
- Generates suggested H1-H4 ranges.
- Explains important parameter restrictions.
- Provides guidance for changing the I1 packet signature.
- Helps maintain consistent obfuscation parameters across server and clients.

### Additional Features
- Interactive menu with 9 main options.
- Portuguese and English interface.
- Persistent configuration.
- Input validation before saving settings.
- Password hashing for Web UI configuration.
- Installation status and service verification.
- Guided cleanup and uninstall functionality.

## 📋 Requirements

| Requirement | Description |
|---|---|
| Operating System | Debian 11+ or Ubuntu 20.04+ |
| Access | Root privileges |
| Domain | Public domain or subdomain pointing to the VPS |
| Network | Publicly reachable VPS |
| HTTP | TCP 80 |
| HTTPS | TCP 443 |
| VPN | Configurable UDP port |
| SSH | Configurable TCP port |
| Docker | Automatically installed if missing |
| Docker Compose | Plugin or compatible standalone command |

### SSH Access Requirement

Before enabling SSH hardening, ensure you have a working SSH public key configured.

The installer can configure:

- Custom SSH port.
- Root login restricted to public-key authentication.
- Password authentication settings.
- Authentication attempt limits.
- Connection timeout settings.

**Keep your existing SSH session open until you have successfully tested a new connection using the configured port.**

Without a working SSH key, root access may become unavailable after hardening.

## 📖 Interactive Menu

The installer provides nine main options:

| Option | Description |
|---|---|
| 1. Configure | Domain, email, SSH/VPN/panel ports, panel credentials and administrator IP. |
| 2. Full Install | Guided deployment of the complete VPN environment. |
| 3. System + Firewall | Docker, system preparation, sysctl and UFW configuration. |
| 4. Deploy AmneziaWG | Deploys or updates the Docker container and Web UI. |
| 5. Nginx + SSL + Fail2Ban | Configures reverse proxy, HTTPS certificates and intrusion prevention. |
| 6. SSH | Changes SSH port, applies hardening and manages optional Brazil geo-blocking. |
| 7. Maintenance + Status | Configures scheduled maintenance and displays service status. |
| 8. Advanced Options | Language selection, cleanup and AmneziaWG obfuscation guide. |
| 9. Exit | Closes the installer. |

### Installation Dependencies

Some options require previous configuration:

- **Option 4:** Requires Docker, Docker Compose, `/dev/net/tun` and a configured panel password.
- **Option 5:** Requires a configured domain and publicly reachable HTTP/HTTPS ports.
- **Option 6:** Requires particular attention to SSH key availability and firewall rules.
- **Option 7:** Requires an existing installation configuration.

The Full Install option runs the main installation sequence automatically. Nginx, Fail2Ban, maintenance and SSH configuration failures are reported, but some failures do not automatically abort the entire sequence.

## 🌎 Optional Brazil SSH Geo-Blocking

The installer includes an optional feature to restrict new SSH connections to Brazilian IPv4 networks.

It uses:

- `ipset` for network set management.
- `iptables` for connection filtering.
- [ipdeny.com](https://www.ipdeny.com/) for Brazilian IP ranges.
- Systemd timers for automatic daily updates.
- An administrator IP whitelist.

The update process validates downloaded network entries before replacing the active IP set.

**Important:** Geo-blocking is optional and can cause SSH lockouts if your IP is outside Brazil or missing from the whitelist.

Keep an alternative access method available and test the configuration before closing your current SSH session.

## 🔄 Maintenance & Updates

The installer can configure scheduled maintenance through systemd.

Default maintenance schedule:

- Every Sunday at 04:00.
- Docker image cleanup.
- APT cleanup.
- System journal vacuum (14 days).
- Maintenance logging and rotation.

Optional features:

- Automatic weekly Docker image updates using the `latest` image tag.
- Automatic security updates using `unattended-upgrades`.
- No automatic system reboot configured by the installer.

> **Note:** Automatic image updates can introduce upstream changes. Review the application logs and service status after updates.

## 🛠️ AmneziaWG Configuration

After installation:

1. Open the Web UI using your configured HTTPS domain.
2. Log in with your configured panel credentials.
3. Create your VPN server and client configurations.
4. Review the AmneziaWG obfuscation parameters.
5. Import the generated client configuration into the AmneziaVPN application.

Use the AmneziaVPN/AmneziaWG-compatible client rather than the standard WireGuard application.

The installer includes an additional obfuscation guide with suggested values and parameter restrictions.

**Important:** The server and all clients must use matching obfuscation parameters.

## 🧹 Uninstall & Cleanup

To remove the AmneziaWG deployment:

1. Run the installer:

```bash
bash amneziawg-setup.sh
```

2. Select **Option 8 — Advanced Options**.
3. Select **Option 2 — Remove container + cleanup**.

The removal procedure requires confirmation and a second explicit confirmation:

- `APAGAR` (Portuguese)
- `DELETE` (English)

The installer can remove:

- AmneziaWG Docker container.
- Associated Docker image.
- Docker Compose deployment file.
- VPN panel data (optional confirmation).
- Nginx site configuration.
- Fail2Ban configuration and custom filters.
- Geo-blocking rules and IP sets.
- Systemd maintenance and geo-block timers.
- Installer configuration and generated maintenance files.
- Let's Encrypt certificate (optional confirmation).

The following system components are intentionally retained:

- Docker packages.
- Nginx packages.
- UFW.
- Fail2Ban packages.
- Existing SSH keys.
- System-wide sysctl configuration.

> **Important:** The cleanup operation does not perform a complete server rollback. Review firewall rules and system-wide configuration separately if you intend to return the VPS to its original state.

## ⚠️ Security Disclaimer

This installer modifies system-level configuration, including:

- SSH configuration.
- UFW firewall rules.
- iptables and ipset rules.
- sysctl network parameters.
- Nginx configuration.
- Fail2Ban configuration.
- Docker services and containers.

Recommendations:

- Start with a fresh VPS whenever possible.
- Maintain an alternative recovery method.
- Keep a working SSH session open during configuration.
- Verify firewall rules before disconnecting.
- Keep backups of important configurations.
- Review upstream Docker image updates before deploying them in production.

This project automates configuration but does not guarantee anonymity, uninterrupted connectivity, or protection against every security threat.

## 📚 Dependencies & Credits

- **[AmneziaWG](https://github.com/amnezia-vpn/amneziawg-go)** — Obfuscated WireGuard protocol implementation.
- **[myceliummesh/amneziawg-ui](https://github.com/myceliummesh/amneziawg-ui)** — Docker-based AmneziaWG Web UI.
- **[Docker](https://www.docker.com/)** — Container platform.
- **[Nginx](https://nginx.org/)** — Reverse proxy and web server.
- **[Let's Encrypt](https://letsencrypt.org/)** — Free SSL/TLS certificates.
- **[Certbot](https://certbot.eff.org/)** — Certificate management.
- **[Fail2Ban](https://github.com/fail2ban/fail2ban)** — Intrusion prevention.
- **[ipdeny.com](https://www.ipdeny.com/)** — Country IP address ranges.

## 📄 License

This project is licensed under the Apache License 2.0.

See the [LICENSE](LICENSE) file for details.

---

**AmneziaWG 3.1 Installer & Configurator**  
*Automated deployment. Configurable security. Simplified VPN management.*
