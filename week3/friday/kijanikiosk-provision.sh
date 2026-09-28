#!/bin/bash
# kijanikiosk-provision.sh
# Idempotent provisioning for KijaniKiosk application servers.

set -euo pipefail

readonly NGINX_VERSION="1.18.0-6ubuntu14.21"
readonly NODE_MAJOR_VERSION="20"
readonly NODE_VERSION="20.11.0-1nodesource1"
readonly APP_GROUP="kijanikiosk"
readonly APP_BASE="/opt/kijanikiosk"

log() { echo "[$(date +%FT%T)] INFO $*"; }
success() { echo "[$(date +%FT%T)] OK $*"; }
error() { echo "[$(date +%FT%T)] ERROR $*" >&2; exit 1; }

# Guard clauses to prevent running in the wrong environment
[[ $EUID -ne 0 ]] && error "Must run as root or with sudo"
grep -qi ubuntu /etc/os-release || error "Designed for Ubuntu only"

log "Starting KijaniKiosk provisioning..."

provision_packages() {
	log "=== Phase 1: Package Installation ==="

	export DEBIAN_FRONTEND=noninteractive

	log "Updating package index and installing prerequisites..."
	apt-get update -yq
	apt-get install -y --no-install-recommends curl gnupg acl ufw

	log "Adding NodeSource GPG key and repository..."
	curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /usr/share/keyrings/nodesource.gpg --yes

	echo "deb [signed-by=/usr/share/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_MAJOR_VERSION}.x nodistro main" > /etc/apt/sources.list.d/nodesource.list

	apt-get update -yq

	local current_nginx
	current_nginx=$(dpkg-query -W -f='${Version}' nginx 2>/dev/null || echo "none")

	if [[ "$current_nginx" == "$NGINX_VERSION" ]]; then
		log "Nginx is already at the pinned version ($NGINX_VERSION). Skipping install."
	else
		log "Installing/Downgrading Nginx to $NGINX_VERSION and Node.js to $NODE_VERSION..."
		apt-get install -y --allow-downgrades --no-install-recommends "nginx=${NGINX_VERSION}" "nodejs=${NODE_VERSION}"
	fi

	log "Holding packages to prevent version drift..."
	dpkg -l nginx 2>/dev/null | grep -q "^ii" && apt-mark hold nginx || true
	dpkg -l nodejs 2>/dev/null | grep -q "^ii" && apt-mark hold nodejs || true

	success "Packages provisioned and held."
}

provision_users() {
	log "=== Phase 2: Users and Groups ==="

	getent group "$APP_GROUP" >/dev/null || groupadd -r "$APP_GROUP"

	local accounts=("kk-api" "kk-payments" "kk-logs")

	for account in "${accounts[@]}"; do
		if getent passwd "$account" >/dev/null; then
			log "User $account exists. Enforcing strict system account settings..."
			usermod -s /usr/sbin/nologin -g "$APP_GROUP" "$account"
		else
			log "Creating system user $account..."
			useradd -r -M -s /usr/sbin/nologin -g "$APP_GROUP" "$account"
		fi
	done

	success "Users and groups provisioned."
}

provision_directories() {
	log "=== Phase 3: Directories and ACLs ==="

	log "Creating directory structure..."
	mkdir -p "${APP_BASE}/config" "${APP_BASE}/shared/logs" "${APP_BASE}/api" "${APP_BASE}/payments" "${APP_BASE}/health"
	log "Fixing dirty permissions and enforcing baseline ownership..."
	chown -R root:"$APP_GROUP" "$APP_BASE"
	find "$APP_BASE" -type d -exec chmod 750 {} \;

	log "Applying ACLs to shared logs..."
	setfacl -R -m u:kk-api:rwx,u:kk-payments:rwx,u:kk-logs:r-x "${APP_BASE}/shared/logs"
	setfacl -R -d -m u:kk-api:rwx,u:kk-payments:rwx,u:kk-logs:r-x "${APP_BASE}/shared/logs"

	success "Directories and ACLs provisioned."
}

provision_systemd() {
	log "=== Phase 4: Systemd Units ==="

	log "Generating kk-api.service..."
	cat << 'EOF' > /etc/systemd/system/kk-api.service
[Unit]
Description=KijaniKiosk API Service
After=network.target

[Service]
User=kk-api
Group=kijanikiosk
ExecStart=/usr/bin/node /opt/kijanikiosk/api/app.js
Restart=on-failure

# Hardening (Targeting < 3.5)
ProtectSystem=strict
ReadWritePaths=/opt/kijanikiosk/shared/logs
PrivateTmp=true
NoNewPrivileges=true
ProtectHome=true
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectControlGroups=true
RestrictNamespaces=true
PrivateDevices=true
PrivateUsers=true
ProtectHostname=true
ProtectClock=true
ProtectKernelLogs=true
RestrictSUIDSGID=true
CapabilityBoundingSet=
# Extra tweaks to get under 3.5
LockPersonality=true
ProtectProc=invisible
UMask=0027

[Install]
WantedBy=multi-user.target
EOF

	log "Generating kk-payments.service (High Security)..."
	cat << 'EOF' > /etc/systemd/system/kk-payments.service
[Unit]
Description=KijaniKiosk Payments Service
After=network.target

[Service]
User=kk-payments
Group=kijanikiosk
ExecStart=/usr/bin/node /opt/kijanikiosk/payments/app.js
Restart=on-failure

ProtectSystem=strict
ReadWritePaths=/opt/kijanikiosk/shared/logs
PrivateTmp=true
NoNewPrivileges=true
ProtectHome=true
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectControlGroups=true
RestrictAddressFamilies=AF_INET AF_INET6
RestrictNamespaces=true
LockPersonality=true
MemoryDenyWriteExecute=true
CapabilityBoundingSet=
PrivateDevices=true
PrivateUsers=true
ProtectClock=true
ProtectKernelLogs=true
ProtectHostname=true
ProtectProc=invisible
RestrictSUIDSGID=true
RestrictRealtime=true
SystemCallFilter=@system-service
UMask=0077

[Install]
WantedBy=multi-user.target
EOF

	log "Generating kk-logs.service..."
	cat << 'EOF' > /etc/systemd/system/kk-logs.service
[Unit]
Description=KijaniKiosk Logging Service
After=network.target

[Service]
User=kk-logs
Group=kijanikiosk
ExecStart=/usr/bin/tail -f /opt/kijanikiosk/shared/logs/app.log
Restart=on-failure

# Hardening (Targeting < 3.5)
ProtectSystem=strict
ReadWritePaths=/opt/kijanikiosk/shared/logs
PrivateTmp=true
NoNewPrivileges=true
ProtectHome=true
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectControlGroups=true
RestrictNamespaces=true
PrivateDevices=true
PrivateUsers=true
ProtectHostname=true
ProtectClock=true
ProtectKernelLogs=true
RestrictSUIDSGID=true
CapabilityBoundingSet=
# Extra tweaks to get under 3.5
LockPersonality=true
ProtectProc=invisible
UMask=0027

[Install]
WantedBy=multi-user.target
EOF

    log "Reloading systemd daemon..."
    systemctl daemon-reload
    log "Starting and enabling services..."
    systemctl enable --now kk-api kk-payments kk-logs || true
    success "Systemd units generated."
}

provision_firewall() {
	log "=== Phase 5: Firewall ==="

	log "Resetting UFW to a clean baseline..."
	ufw --force reset >/dev/null

	log "Setting default policies..."
	ufw default deny incoming >/dev/null
	ufw default allow outgoing >/dev/null

	log "Allowing SSH, HTTP, and internal health checks..."
	ufw allow 22/tcp comment 'Allow SSH for administrators' >/dev/null
	ufw allow 80/tcp comment 'Allow HTTP traffic' >/dev/null
	ufw allow from 127.0.0.1 to any port 3001 proto tcp comment 'Allow local health checks' >/dev/null

	log "Enabling UFW..."
	ufw --force enable >/dev/null

	success "Firewall provisioned and enabled."
}

provision_logging() {
	log "=== Phase 6: Logging and Journald ==="

	log "Enforcing persistent journald storage..."
	mkdir -p /var/log/journal
	# This command forces systemd to create the necessary directory structures
	systemd-tmpfiles --create --prefix /var/log/journal
	systemctl restart systemd-journald

	    log "Configuring logrotate (Challenge C)..."
	    cat << 'EOF' > /etc/logrotate.d/kijanikiosk
	/opt/kijanikiosk/shared/logs/*.log {
	su root kijanikiosk
	daily
	missingok
	rotate 14
	compress
	notifempty
	create 0640 kk-api kijanikiosk
	# Challenge C resolution: copytruncate prevents the need to reload the isolated systemd service
	copytruncate
}
EOF
    	success "Logging configured."
}

provision_health_checks() {
	log "=== Phase 7: Health Checks ==="

	local health_file="${APP_BASE}/health/last-provision.json"

	log "Generating health check JSON..."
	cat << EOF > "$health_file"
{
	"status": "hardened",
	"version": "$NODE_VERSION",
	"timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF

	chown root:"$APP_GROUP" "$health_file"
	chmod 640 "$health_file"

	# Challenge B resolution: Read-only ACL for the monitoring account
	log "Applying read-only ACL for monitoring..."
	setfacl -m u:kk-logs:r-- "$health_file"

	success "Health checks provisioned."
}

verify_provisioning() {
	log "=== Phase 8: Verification ==="

	dpkg -s nginx >/dev/null 2>&1 || error "Verification failed: Nginx not installed"
	getent passwd kk-payments >/dev/null || error "Verification failed: kk-payments user missing"

	log "Verifying UFW rules..."
	ufw status | grep -q "22/tcp.*ALLOW" && log "PASS: SSH port 22 allowed" || error "FAIL: SSH rule missing"
	ufw status | grep -q "80/tcp.*ALLOW" && log "PASS: HTTP port 80 allowed" || error "FAIL: HTTP rule missing"
	ufw status | grep -q "3001/tcp.*ALLOW.*127.0.0.1" && log "PASS: Internal port 3001 allowed" || error "FAIL: Health check rule missing"

	[ -f "${APP_BASE}/health/last-provision.json" ] || error "Verification failed: Health file missing"

	success "All verifications passed. Server is hardened and ready."
}


main() {
    	provision_packages
    	provision_users
    	provision_directories
    	provision_systemd
    	provision_firewall
	provision_logging
	provision_health_checks
	verify_provisioning
}

main "$@"
