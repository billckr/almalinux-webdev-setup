# AlmaLinux Web Development Environment Setup

A comprehensive automated setup script for configuring a complete web development environment on AlmaLinux 9.

## 🚀 Quick Start

### One-Line Installation
```bash
curl -sSL https://raw.githubusercontent.com/yourusername/almalinux-webdev-setup/main/setup.sh | sudo bash
```

### Manual Installation
```bash
# Download the script
curl -o setup.sh https://raw.githubusercontent.com/yourusername/almalinux-webdev-setup/main/setup.sh
chmod +x setup.sh

# Run the setup
sudo ./setup.sh
```

## 📋 What Gets Installed

### Web Servers
- **Apache HTTP Server** - Primary web server
- **Nginx** - Reverse proxy and alternative web server

### Databases
- **MySQL 8.0** - Relational database
- **PostgreSQL 16** - Advanced relational database
- **Redis** - In-memory data store
- **MongoDB 7.0** - NoSQL document database

### Programming Languages & Runtimes
- **PHP 8.2** - Server-side scripting with extensions
- **Python 3** - Programming language with pip
- **Node.js LTS** - JavaScript runtime with npm

### Development Tools
- **Git** - Version control with LFS support
- **GitHub CLI** - GitHub command-line tool
- **Docker** - Containerization platform
- **VS Code** - Code editor
- **Vim/Neovim** - Terminal editors

### Package Managers
- **npm** - Node.js package manager
- **yarn** - Alternative Node.js package manager
- **pnpm** - Fast Node.js package manager
- **Composer** - PHP dependency manager

### Global npm Packages
- Angular CLI
- Create React App
- Vue CLI
- TypeScript
- Nodemon
- PM2
- ESLint
- Prettier
- Webpack CLI
- Vite

### Security & Monitoring
- **Fail2ban** - Intrusion prevention
- **Certbot** - SSL certificate management
- **Firewall** - Configured with HTTP/HTTPS/SSH access

### System Utilities
- htop, curl, wget, zip, unzip, tree
- OpenSSL development libraries

## 📊 Installation Workflow

### Phase 1: System Update & Repository Setup
1. Update all system packages
2. Install EPEL repository
3. Add Remi repository (PHP)
4. Add PostgreSQL official repository
5. Add Node.js repository
6. Add Docker repository
7. Add VS Code repository
8. Add MongoDB repository

### Phase 2: Core Package Installation
1. System tools and utilities
2. Web servers (Apache, Nginx)
3. Database servers
4. Programming languages
5. Development tools
6. Security tools

### Phase 3: PHP Installation
1. Reset PHP module
2. Enable PHP 8.2 from Remi
3. Install PHP with all extensions

### Phase 4: Service Initialization
1. Initialize PostgreSQL database
2. Enable auto-start for all services
3. Start core services
4. Configure Docker permissions

### Phase 5: Firewall Configuration
1. Allow HTTP traffic
2. Allow HTTPS traffic
3. Allow SSH traffic
4. Reload firewall rules

### Phase 6: Database Configuration
1. Secure MySQL installation
2. Set MySQL root password
3. Remove anonymous users
4. Set PostgreSQL password

### Phase 7: Service Stabilization
1. Wait for services to fully start
2. Generate activity to create log files
3. Ensure service stability

### Phase 8: Security Configuration (Fail2ban)
1. Start Fail2ban service
2. Validate log file paths
3. Check available filters
4. Configure jails with validated paths
5. Test configuration

### Phase 9: Development Tools Installation
1. Install global npm packages
2. Install Composer for PHP
3. Configure package managers

### Phase 10: User Configuration
1. Configure Git settings
2. Set up Git LFS
3. User-specific configurations

### Phase 11: Web Server Content Setup
1. Create PHP info page
2. Set proper permissions
3. Create landing page

## 🔧 Configuration Requirements

The script will prompt you for the following information:

### Required Inputs
- **External IP Address** - Auto-detected, but confirmation required
- **MySQL Root Password** - Secure password for MySQL root user
- **PostgreSQL Password** - Password for postgres user
- **Git Username** - Your name for Git commits
- **Git Email** - Your email for Git commits

### Optional Inputs
- **Domain Name** - For SSL certificate configuration (optional)

## 🛡️ Security Features

### Fail2ban Protection
- **SSH Protection** - Monitors `/var/log/secure`
- **Apache Protection** - Monitors `/var/log/httpd/error_log`
- **MySQL Protection** - Monitors `/var/log/mysql/mysqld.log`

### IP Whitelisting
Your external IP is automatically whitelisted in Fail2ban to prevent lockouts.

### Firewall Configuration
- HTTP (port 80) - Enabled
- HTTPS (port 443) - Enabled
- SSH (port 22) - Enabled
- All other ports - Blocked by default

### Database Security
- MySQL anonymous users removed
- Test databases removed
- Root password required
- PostgreSQL password authentication

## 📁 File Locations

### Web Root
```
/var/www/html/
├── index.html          # Landing page
└── info.php           # PHP info page
```

### Configuration Files
```
/etc/fail2ban/jail.local       # Fail2ban configuration
/etc/httpd/conf/httpd.conf     # Apache configuration
/etc/nginx/nginx.conf          # Nginx configuration
/etc/my.cnf                    # MySQL configuration
```

### Log Files
```
/var/log/httpd/error_log       # Apache errors
/var/log/secure                # SSH authentication
/var/log/mysql/mysqld.log      # MySQL logs
/var/lib/pgsql/16/data/log/    # PostgreSQL logs
```

## 🔍 Post-Installation Verification

### Check Service Status
```bash
# All services status
sudo systemctl status httpd mysqld postgresql-16 redis nginx

# Fail2ban status
sudo fail2ban-client status

# Active jails
sudo fail2ban-client status sshd
```

### Database Connections
```bash
# MySQL
mysql -u root -p

# PostgreSQL
sudo -u postgres psql

# Redis
redis-cli ping

# MongoDB
mongosh
```

### Web Server Tests
```bash
# Local access
curl http://localhost
curl http://localhost/info.php

# External access
curl http://YOUR_SERVER_IP
```

## 🌐 Accessing Your Server

### Web Interface
- **Main page**: `http://YOUR_SERVER_IP`
- **PHP Info**: `http://YOUR_SERVER_IP/info.php`

### Database Access
- **MySQL**: Port 3306 (local only)
- **PostgreSQL**: Port 5432 (local only)
- **Redis**: Port 6379 (local only)
- **MongoDB**: Port 27017 (local only)

## 🔧 Common Commands

### Service Management
```bash
# Restart web servers
sudo systemctl restart httpd nginx

# Restart databases
sudo systemctl restart mysqld postgresql-16 redis mongod

# View logs
sudo journalctl -u httpd -f
sudo journalctl -u mysqld -f
```

### Fail2ban Management
```bash
# Check status
sudo fail2ban-client status

# Unban an IP
sudo fail2ban-client set sshd unbanip IP_ADDRESS

# Add IP to whitelist
sudo fail2ban-client set sshd addignoreip IP_ADDRESS
```

### SSL Certificate Setup
```bash
# Apache
sudo certbot --apache -d yourdomain.com

# Nginx
sudo certbot --nginx -d yourdomain.com
```

## 🚨 Troubleshooting

### Common Issues

#### Fail2ban Not Starting
```bash
# Check configuration
sudo fail2ban-client -t

# View detailed logs
sudo journalctl -u fail2ban -f
```

#### Database Connection Issues
```bash
# MySQL
sudo systemctl status mysqld
sudo journalctl -u mysqld -f

# PostgreSQL
sudo systemctl status postgresql-16
sudo journalctl -u postgresql-16 -f
```

#### Permission Issues
```bash
# Reset web directory permissions
sudo chown -R apache:apache /var/www/html/
sudo chmod -R 755 /var/www/html/
```

### Log Locations for Debugging
- **Script execution**: `/var/log/setup-YYYYMMDD-HHMMSS.log`
- **System messages**: `/var/log/messages`
- **Security events**: `/var/log/secure`
- **Service logs**: `sudo journalctl -u SERVICE_NAME`

## 🔄 Updates and Maintenance

### Regular Updates
```bash
# System updates
sudo dnf update

# npm packages
sudo npm update -g

# Composer
sudo composer self-update
```

### Security Updates
```bash
# Update Fail2ban rules
sudo fail2ban-client reload

# Update SSL certificates
sudo certbot renew
```

## 📝 Customization

### Adding More Services
Edit the script to include additional packages in Phase 2:
```bash
dnf install -y your-additional-package
```

### Custom Fail2ban Rules
Add custom jails to `/etc/fail2ban/jail.local`:
```ini
[custom-service]
enabled = true
filter = custom-filter
logpath = /var/log/custom.log
maxretry = 3
```

### PHP Configuration
Modify PHP settings in `/etc/php.ini` or `/etc/php-fpm.d/www.conf`

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

- **Issues**: Report bugs and request features via GitHub Issues
- **Documentation**: Check this README for common solutions
- **Community**: Join discussions in GitHub Discussions

---

**Note**: This script is designed for fresh AlmaLinux 9 installations. Running on systems with existing configurations may cause conflicts. Always test in a development environment first.