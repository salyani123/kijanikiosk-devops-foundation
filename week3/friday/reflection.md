### Reflection Questions

**1. Conflict Discovery:**
I discovered a conflict between systemd hardening and application functionality during Phase 4. Setting `ProtectSystem=strict` locked the entire file system to read-only, which immediately broke the application because it couldn't write to `/opt/kijanikiosk/shared/logs`. I learned that systemd security isn't just an "on/off" switch; I resolved it by using `ReadWritePaths=` to punch a highly specific, controlled hole through the read-only shield just for that directory.

**2. Translation for Tendo:**
*Nia's Version:* "If a malicious actor manages to find a vulnerability in our public-facing API, they will find themselves trapped in a restricted user account with no ability to navigate the wider server, view sensitive configuration files, or elevate their privileges."
*Tendo's Version:* "By enforcing `NoNewPrivileges=true`, dropping the `CapabilityBoundingSet`, and running the service via a `nologin` system account, we mitigate privilege escalation vectors via SUID binaries and sandbox the Node process."
*Trade-off:* Translating to Tendo's language loses the business context (the impact on the company's risk profile), but gains precise, auditable implementation details necessary for technical peer review.

**3. The Most Fragile Component:**
The single most fragile part of the script is the package version pinning (e.g., `NGINX_VERSION="1.18.0-6ubuntu14.21"`). In a real production environment, public apt repositories frequently rotate or drop older patch versions. If a new VM spins up and that exact string is no longer in the upstream mirror, the script will hard-fail. To make this robust, I would need to know if the target environment has a private, immutable artifact repository (like Artifactory) where we control the lifecycle of the packages, rather than relying on the public internet.
