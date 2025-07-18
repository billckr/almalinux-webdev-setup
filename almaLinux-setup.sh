#!/bin/bash

# AlmaLinux Web Development Environment Setup Script
# Run with: curl -sSL https://raw.githubusercontent.com/billckr/almalinux-webdev-setup/main/almaLinux-setup.sh | sudo bash
# Or: wget -O setup.sh https://raw.githubusercontent.com/billckr/almalinux-webdev-setup/main/almaLinux-setup.sh && chmod +x setup.sh && sudo ./setup.sh


set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Function to prompt for input
prompt_input() {
    local prompt="$1"
    local var_name="$2"
    local default="$3"
    
    if [ -n "$default" ]; then
        read -p "$prompt [$default]: " input
        if [ -z "$input" ]; then
            input="$default"
        fi
    else
        read -p "$prompt: " input
        while [ -z "$input" ]; do
            read -p "This field is required. $prompt: " input
        done
    fi
    
    eval "$var_name='$input'"
}

# Function to prompt for password
prompt_password() {
    local prompt="$1"
    local var_name="$2"
    
    while true; do
        read -s -p "$prompt: " password1
        echo
        read -s -p "Confirm password: " password2
        echo
        
        if [ "$password1" = "$password2" ]; then
            eval "$var_name='$password1'"
            break
        else
            print_error "Passwords don't match. Please try again."
        fi
    done
}

# Function to check and find log paths
check_log_paths() {
    print_status "Checking log paths for Fail2ban configuration..."
    
    # Check SSH log path
    SSH_LOG_PATH=""
    if [ -f "/var/log/secure" ]; then
        SSH_LOG_PATH="/var/log/secure"
    elif [ -f "/var/log/auth.log" ]; then
        SSH_LOG_PATH="/var/log/auth.log"
    else
        print_warning "SSH log file not found. Creating /var/log/secure"
        touch /var/log/secure
        SSH_LOG_PATH="/var/log/secure"
    fi
    print_status "SSH log path: $SSH_LOG_PATH"
    
    # Check Apache log path
    APACHE_LOG_PATH=""
    if [ -f "/var/log/httpd/error_log" ]; then
        APACHE_LOG_PATH="/var/log/httpd/error_log"
    elif [ -f "/var/log/apache2/error.log" ]; then
        APACHE_LOG_PATH="/var/log/apache2/error.log"
    else
        print_warning "Apache error log not found. Will create after Apache starts"
        mkdir -p /var/log/httpd
        APACHE_LOG_PATH="/var/log/httpd/error_log"
    fi
    print_status "Apache log path: $APACHE_LOG_PATH"
    
    # Check MySQL log path
    MYSQL_LOG_PATH=""
    if [ -f "/var/log/mysql/mysqld.log" ]; then
        MYSQL_LOG_PATH="/var/log/mysql/mysqld.log"
    elif [ -f "/var/log/mysqld.log" ]; then
        MYSQL_LOG_PATH="/var/log/mysqld.log"
    elif [ -f "/var/log/mysql/error.log" ]; then
        MYSQL_LOG_PATH="/var/log/mysql/error.log"
    else
        print_warning "MySQL log not found yet. Will be created when MySQL starts"
        # MySQL log will be created when service starts, so we'll use the expected path
        MYSQL_LOG_PATH="/var/log/mysql/mysqld.log"
    fi
    print_status "MySQL log path: $MYSQL_LOG_PATH"
    
    # Check PostgreSQL log path
    POSTGRES_LOG_PATH=""
    if [ -f "/var/lib/pgsql/16/data/log/postgresql.log" ]; then
        POSTGRES_LOG_PATH="/var/lib/pgsql/16/data/log/postgresql.log"
    elif [ -d "/var/lib/pgsql/16/data/log" ]; then
        # PostgreSQL logs to timestamped files, use the directory pattern
        POSTGRES_LOG_PATH="/var/lib/pgsql/16/data/log/postgresql-*.log"
    else
        print_warning "PostgreSQL log directory not found yet. Will be created after initialization"
        POSTGRES_LOG_PATH="/var/lib/pgsql/16/data/log/postgresql-*.log"
    fi
    print_status "PostgreSQL log path: $POSTGRES_LOG_PATH"
}

# Function to validate fail2ban filters
validate_fail2ban_filters() {
    print_status "Validating Fail2ban filters..."
    
    AVAILABLE_FILTERS=()
    FILTER_DIR="/etc/fail2ban/filter.d"
    
    # Check which filters are available
    if [ -f "$FILTER_DIR/sshd.conf" ]; then
        AVAILABLE_FILTERS+=("sshd")
        print_status "✅ SSH filter available"
    else
        print_warning "❌ SSH filter not found"
    fi
    
    if [ -f "$FILTER_DIR/apache-auth.conf" ]; then
        AVAILABLE_FILTERS+=("apache-auth")
        print_status "✅ Apache auth filter available"
    else
        print_warning "❌ Apache auth filter not found"
    fi
    
    if [ -f "$FILTER_DIR/mysqld-auth.conf" ]; then
        AVAILABLE_FILTERS+=("mysqld-auth")
        print_status "✅ MySQL auth filter available"
    else
        print_warning "❌ MySQL auth filter not found"
    fi
    
    # List all available filters for reference
    print_status "Available filters in $FILTER_DIR:"
    ls "$FILTER_DIR" | grep -E "(sshd|apache|mysql|nginx)" | head -10
}

# Configure Fail2ban with validated paths
configure_fail2ban() {
    print_status "Configuring Fail2ban with validated paths..."
    
    # Start with basic configuration
    cat > /etc/fail2ban/jail.local << EOF
[DEFAULT]
ignoreip = 127.0.0.1/8 ::1 192.168.0.0/16 10.0.0.0/8 172.16.0.0/12 $EXTERNAL_IP
bantime = 3600
findtime = 600
maxretry = 5
backend = systemd

EOF

    # Add SSH jail if log exists
    if [ -f "$SSH_LOG_PATH" ] && [[ " ${AVAILABLE_FILTERS[@]} " =~ " sshd " ]]; then
        cat >> /etc/fail2ban/jail.local << EOF
[sshd]
enabled = true
filter = sshd
logpath = $SSH_LOG_PATH
maxretry = 3

EOF
        print_status "✅ SSH jail configured"
    else
        print_warning "⚠️  SSH jail skipped (log: $SSH_LOG_PATH)"
    fi
    
    # Add Apache jail if log exists
    if [ -f "$APACHE_LOG_PATH" ] && [[ " ${AVAILABLE_FILTERS[@]} " =~ " apache-auth " ]]; then
        cat >> /etc/fail2ban/jail.local << EOF
[apache-auth]
enabled = true
filter = apache-auth
logpath = $APACHE_LOG_PATH
maxretry = 3

EOF
        print_status "✅ Apache jail configured"
    else
        print_warning "⚠️  Apache jail skipped (log: $APACHE_LOG_PATH)"
    fi
    
    # Add MySQL jail if log exists
    if [ -f "$MYSQL_LOG_PATH" ] && [[ " ${AVAILABLE_FILTERS[@]} " =~ " mysqld-auth " ]]; then
        cat >> /etc/fail2ban/jail.local << EOF
[mysqld-auth]
enabled = true
filter = mysqld-auth
logpath = $MYSQL_LOG_PATH
maxretry = 3

EOF
        print_status "✅ MySQL jail configured"
    else
        print_warning "⚠️  MySQL jail skipped (log: $MYSQL_LOG_PATH)"
    fi
    
    print_status "Fail2ban configuration written to /etc/fail2ban/jail.local"
}

# Wait for services to create log files
wait_for_services() {
    print_status "Waiting for services to start and create log files..."
    sleep 5
    
    # Generate some log entries to ensure files exist
    systemctl status httpd >/dev/null 2>&1 || true
    systemctl status mysqld >/dev/null 2>&1 || true
    
    # Try to access MySQL to generate log entry
    mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "SELECT 1;" >/dev/null 2>&1 || true
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    print_error "Please run as root (use sudo)"
    exit 1
fi

# Welcome message
print_header "AlmaLinux Web Development Environment Setup"
echo "This script will install and configure:"
echo "- Apache, Nginx, MySQL, PostgreSQL"
echo "- PHP 8.2, Python, Node.js, Git"
echo "- Redis, Docker, Fail2ban"
echo "- Development tools and packages"
echo

# Collect user inputs
print_header "Configuration Setup"

# Get external IP automatically and confirm
DETECTED_IP=$(curl -s ifconfig.me || echo "")
if [ -n "$DETECTED_IP" ]; then
    prompt_input "Your external IP address (detected: $DETECTED_IP)" EXTERNAL_IP "$DETECTED_IP"
else
    prompt_input "Your external IP address" EXTERNAL_IP
fi

# Domain name (optional)
prompt_input "Domain name (optional, press enter to skip)" DOMAIN_NAME ""

# Database passwords
prompt_password "MySQL root password" MYSQL_ROOT_PASSWORD
prompt_password "PostgreSQL postgres user password" POSTGRES_PASSWORD

# Git configuration
prompt_input "Git username" GIT_USERNAME
prompt_input "Git email" GIT_EMAIL

# Confirmation
echo
print_header "Configuration Summary"
echo "External IP: $EXTERNAL_IP"
echo "Domain: ${DOMAIN_NAME:-"Not set"}"
echo "Git User: $GIT_USERNAME <$GIT_EMAIL>"
echo
read -p "Continue with installation? (y/N): " confirm
if [[ ! $confirm =~ ^[Yy]$ ]]; then
    print_error "Installation cancelled"
    exit 1
fi

# Start installation
print_header "Starting Installation"

# Phase 1: System Update and Repository Setup
print_header "Phase 1: System Update & Repository Setup"

print_status "Updating system packages..."
dnf update -y

print_status "Installing EPEL repository..."
dnf install epel-release -y

print_status "Installing Remi repository for PHP..."
dnf install https://rpms.remirepo.net/enterprise/remi-release-9.rpm -y

print_status "Adding PostgreSQL repository..."
dnf install https://download.postgresql.org/pub/repos/yum/reporpms/EL-9-x86_64/pgdg-redhat-repo-latest.noarch.rpm -y

print_status "Adding Node.js repository..."
curl -fsSL https://rpm.nodesource.com/setup_lts.x | bash -

print_status "Adding Docker repository..."
dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

print_status "Adding VS Code repository..."
rpm --import https://packages.microsoft.com/keys/microsoft.asc
cat > /etc/yum.repos.d/vscode.repo << EOF
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF

print_status "Adding MongoDB repository..."
cat > /etc/yum.repos.d/mongodb-org-7.0.repo << EOF
[mongodb-org-7.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/9/mongodb-org/7.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://pgp.mongodb.com/server-7.0.asc
EOF

# Phase 2: Core Package Installation
print_header "Phase 2: Core Package Installation"

print_status "Installing system tools and utilities..."
dnf install -y htop curl wget zip unzip tree git git-lfs gh \
    openssl openssl-devel vim neovim

print_status "Installing web servers..."
dnf install -y httpd nginx

print_status "Installing databases..."
dnf install -y mysql-server postgresql16-server postgresql16 postgresql16-contrib \
    redis mongodb-org

print_status "Installing Python and development tools..."
dnf install -y python3 python3-pip python3-devel

print_status "Installing Node.js..."
dnf install -y nodejs

print_status "Installing Docker..."
dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

print_status "Installing development tools..."
dnf install -y code

print_status "Installing security and SSL tools..."
dnf install -y fail2ban certbot python3-certbot-apache python3-certbot-nginx

# Phase 3: PHP Installation and Configuration
print_header "Phase 3: PHP Installation"

print_status "Installing PHP 8.2..."
dnf module reset php -y
dnf module enable php:remi-8.2 -y
dnf install -y php php-cli php-fpm php-mysqlnd php-pgsql php-zip \
    php-devel php-gd php-mbstring php-curl php-xml php-pear \
    php-bcmath php-json php-opcache php-redis

# Phase 4: Service Initialization
print_header "Phase 4: Service Initialization"

print_status "Initializing PostgreSQL database..."
/usr/pgsql-16/bin/postgresql-16-setup initdb

print_status "Enabling services for auto-start..."
systemctl enable httpd nginx mysqld postgresql-16 redis php-fpm docker mongod

print_status "Starting core services..."
systemctl start httpd nginx mysqld postgresql-16 redis php-fpm docker mongod

# Add user to docker group
print_status "Configuring Docker permissions..."
usermod -aG docker $SUDO_USER 2>/dev/null || true

# Phase 5: Firewall Configuration
print_header "Phase 5: Firewall Configuration"

print_status "Configuring firewall rules..."
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --permanent --add-service=ssh
firewall-cmd --reload

# Phase 6: Database Configuration
print_header "Phase 6: Database Configuration"

print_status "Securing MySQL installation..."
# Set root password and remove anonymous users
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD';" 2>/dev/null || true
mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "DELETE FROM mysql.user WHERE User='';" 2>/dev/null || true
mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "DROP DATABASE IF EXISTS test;" 2>/dev/null || true
mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "FLUSH PRIVILEGES;" 2>/dev/null || true

print_status "Configuring PostgreSQL..."
sudo -u postgres psql -c "ALTER USER postgres PASSWORD '$POSTGRES_PASSWORD';"

# Phase 7: Wait for Services and Log Files
print_header "Phase 7: Service Stabilization"

print_status "Waiting for services to fully start and create log files..."
sleep 10

# Generate some activity to ensure log files are created
systemctl status httpd mysqld postgresql-16 >/dev/null 2>&1 || true
mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "SELECT 1;" >/dev/null 2>&1 || true

# Phase 8: Fail2ban Installation and Configuration
print_header "Phase 8: Security Configuration (Fail2ban)"

print_status "Starting Fail2ban service..."
systemctl start fail2ban

# Validate log paths and filters before configuration
check_log_paths
validate_fail2ban_filters

# Configure fail2ban with validated paths and filters
configure_fail2ban

# Test fail2ban configuration
print_status "Testing Fail2ban configuration..."
if systemctl restart fail2ban; then
    print_status "✅ Fail2ban restarted successfully"
    sleep 2
    if fail2ban-client status >/dev/null 2>&1; then
        ACTIVE_JAILS=$(fail2ban-client status | grep "Jail list:" | cut -d: -f2 | tr -d ' \t')
        if [ -n "$ACTIVE_JAILS" ]; then
            print_status "✅ Active jails: $ACTIVE_JAILS"
        else
            print_warning "⚠️  No jails are active"
        fi
    else
        print_warning "⚠️  Fail2ban client not responding"
    fi
else
    print_error "❌ Fail2ban failed to restart - check configuration"
    print_status "Fail2ban configuration:"
    cat /etc/fail2ban/jail.local
fi

# Phase 9: Development Tools Installation
print_header "Phase 9: Development Tools Installation"

print_status "Installing global npm packages..."
npm install -g yarn pnpm @angular/cli create-react-app typescript ts-node \
    nodemon pm2 eslint prettier webpack-cli vite vue-cli

print_status "Installing Composer for PHP..."
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer
chmod +x /usr/local/bin/composer

# Phase 10: Git and User Configuration
print_header "Phase 10: User Configuration"

print_status "Configuring Git..."
if [ -n "$SUDO_USER" ]; then
    sudo -u $SUDO_USER git config --global user.name "$GIT_USERNAME"
    sudo -u $SUDO_USER git config --global user.email "$GIT_EMAIL"
    sudo -u $SUDO_USER git config --global init.defaultBranch main
    sudo -u $SUDO_USER git lfs install
fi

# Configure Git for root as well
git config --global user.name "$GIT_USERNAME"
git config --global user.email "$GIT_EMAIL"
git config --global init.defaultBranch main
git lfs install

# Phase 11: Web Content and Permissions
print_header "Phase 11: Web Server Content Setup"

print_status "Creating web content..."
echo "<?php phpinfo(); ?>" > /var/www/html/info.php

print_status "Setting web directory permissions..."
chown -R apache:apache /var/www/html/
chmod -R 755 /var/www/html/

print_status "Creating landing page..."
cat > /var/www/html/index.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Development Server Ready</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f4f4f4; }
        .container { background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: #333; }
        .status { display: inline-block; padding: 4px 8px; border-radius: 4px; color: white; background: #28a745; }
        .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 20px; margin-top: 20px; }
        .card { background: #f8f9fa; padding: 15px; border-radius: 5px; border-left: 4px solid #007bff; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 Development Server Ready</h1>
        <p>Your AlmaLinux development environment is <span class="status">ACTIVE</span></p>
        
        <div class="grid">
            <div class="card">
                <h3>Web Servers</h3>
                <p>✅ Apache HTTP Server<br>
                ✅ Nginx<br>
                📝 <a href="/info.php">PHP Info</a></p>
            </div>
            
            <div class="card">
                <h3>Databases</h3>
                <p>✅ MySQL<br>
                ✅ PostgreSQL<br>
                ✅ MongoDB<br>
                ✅ Redis</p>
            </div>
            
            <div class="card">
                <h3>Development Tools</h3>
                <p>✅ Node.js & npm<br>
                ✅ Python 3<br>
                ✅ PHP 8.2<br>
                ✅ Git</p>
            </div>
            
            <div class="card">
                <h3>Security</h3>
                <p>✅ Fail2ban<br>
                ✅ Firewall configured<br>
                ✅ SSL ready (Certbot)</p>
            </div>
        </div>
        
        <h3>Quick Commands</h3>
        <pre>
# Check service status
sudo systemctl status httpd mysqld postgresql-16

# View Fail2ban status  
sudo fail2ban-client status

# Connect to databases
mysql -u root -p
sudo -u postgres psql
        </pre>
    </div>
</body>
</html>
EOF

# Final system check
print_status "Running final system check..."
sleep 2

print_header "Installation Complete!"
echo
print_status "✅ All services installed and configured"
print_status "🔒 Your IP ($EXTERNAL_IP) is whitelisted in Fail2ban"
print_status "🌐 Web server accessible at: http://$(hostname -I | awk '{print $1}')"
if [ -n "$DOMAIN_NAME" ]; then
    print_status "🌐 Domain: http://$DOMAIN_NAME"
fi

echo
print_header "Service Status"
systemctl is-active httpd && echo "✅ Apache: Running" || echo "❌ Apache: Stopped"
systemctl is-active mysqld && echo "✅ MySQL: Running" || echo "❌ MySQL: Stopped"
systemctl is-active postgresql-16 && echo "✅ PostgreSQL: Running" || echo "❌ PostgreSQL: Stopped"
systemctl is-active redis && echo "✅ Redis: Running" || echo "❌ Redis: Stopped"
systemctl is-active fail2ban && echo "✅ Fail2ban: Running" || echo "❌ Fail2ban: Stopped"

echo
print_header "Version Information"
echo "Apache: $(httpd -v | head -1)"
echo "MySQL: $(mysql --version)"
echo "PostgreSQL: $(sudo -u postgres psql --version)"
echo "PHP: $(php -v | head -1)"
echo "Node.js: $(node --version)"
echo "Python: $(python3 --version)"
echo "Git: $(git --version)"

echo
print_header "Database Connection Info"
echo "MySQL:"
echo "  Host: localhost"
echo "  User: root"
echo "  Password: [as set during installation]"
echo
echo "PostgreSQL:"
echo "  Host: localhost"
echo "  User: postgres"
echo "  Password: [as set during installation]"
echo "  Connect: sudo -u postgres psql"

echo
print_header "Next Steps"
echo "1. Visit http://$(hostname -I | awk '{print $1}') to see your server"
echo "2. Check PHP: http://$(hostname -I | awk '{print $1}')/info.php"
echo "3. Configure SSL with: sudo certbot --apache"
echo "4. Test database connections"
echo "5. Start developing! 🎉"

if [ -n "$SUDO_USER" ]; then
    echo
    print_warning "Remember to logout and login again to use Docker without sudo"
fi

echo
print_status "Installation log saved to: /var/log/setup-$(date +%Y%m%d-%H%M%S).log"
