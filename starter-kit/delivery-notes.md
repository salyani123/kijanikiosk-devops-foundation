# Devops Delivery Notes

To ensure a reliable and maintainable infrastructure for the KijaniKiosk platform, our engineering team adheres to the three core ways of DevOps

## 1. Flow
-> Flow is about accelerating the delivery of work from Development to Operations. In our workflow, we achieve this through:
**Version Control and Branching** -> We use a strict Git workflow (main, develop, and feature branches) to ensure code is organized and integrated smoothly without disrupting prodcution.
**Infrastructure as Code (IAC)** - > By using automated bash provisioning scripts instead of manual server configurations, we eliminate bottlenecks and ensure that server setups are repeatable, idempotent, and fast.
**Small Batch Sizes** -> Work is broken down into specific feature branches, allowing us to merger small, manageable changes rather than massice, risky updates

## 2. Feedback
-> Feedback ensures we catch and fix issues as quickly as posssible. We build feedback loops into our pipelines by:
**Pull Requests and Code Review** -> All feature branches must be merged into develop via a pull request. This acts as a quality gate, allowing us to review infrastructure changes before they go live.
**System Service Monitoring** -> During provisioning, we rely heavily on systemctl status and journalctl logs. If a service like kk-payments fails to start or hits a perimission error, the system immediatley provides diagnostic feedback so we can fix it.

## 3. Continuous learning
Learning is about creating a culture of improvement and sharing knowledge. We demonstrate this through:
**Iterative Security Hardening** -> After intitially configuring the services, we used systemd-analyze security to measure our exposure, learned about linux capability bounding, and iteratively dialed our security scores down to meet prodcution standards.
**Documentation** -> All architectural decisions, service constraints, and post remediation steps are documented. This ensures that when we solve a complex issue, the knowledge is retained in the repository for the future.