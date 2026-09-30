# Region and Availability Zone Strategy

To ensure high availabiliity and low latency for the KijaniKioskk platform, we must carefully design out deployment geography.

## Region Selection
The platform will be deployed in a region closest to our primary user base. Because KijaniKiosk serves customers locally in Kenya and the East African marekt, deploying to a region like AWS af-south-1 minimizes network latency compared to routing traffic to Europe or the US. This ensures that kiosk transactions, especially the kk payments service processes as quickly as possible.

## Multi Availability Zone Reliability
Within out chosen region, we will distribute our infrastructure across at least two avalability zones 
**Fault Tolerance** -> An AZ is basically an isolated data center with its own independent power, cooling, and networking. If one AZ experiences a power outage or hardware failure, the other AZ remains online.
**Traffic Routing** -> By placing our backend our backend services behind a load balancer that covers multiple AZs, traffic will automatically reroute to the healthy AZ is a failure occurs.