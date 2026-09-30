# Cloud Service Model Justification

For the KijaniKiosk platform, we ate utlizing an IaaS model.

## Why Iaas?
-> In our cuurent architecture, we need control over the opearing systema and server environment. By using IaaS, we get direct root access. This is exactly ehat allowed us to write custom bash scripts to provision the sever, install specific package versions, and manually manage systemd services for kk-api and kk-payments.

## Why not Paas or Saas?
**PaaS** -> If we used PaaS, the cloud provider would manage the underlying Linux OS and runtime. While this is easier, it isolates you from the server. We wouldnt be able to perform extremem systemd  security hardeing or write custom rules fot the security requirements for our system
**SaaS** -> SaaS does nto apply here because we are developing a custom, proprietary application for KijaniKiosk, not subscribing to an existing third party softwar product.

Ultimately, IaaS gives us the exact OS level control required to securely isolate and harden out platforms underlying services.