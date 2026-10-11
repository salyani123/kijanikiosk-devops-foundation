#!/bin/bash
set -e

echo "Creating custom Docker network..."
docker network create kijani-net || true

echo "Starting Nexus registry..."
docker run -d -p 8081:8081 --name nexus --network kijani-net sonatype/nexus3

echo "Starting Jenkins..."
docker run -d -p 8080:8080 --name jenkins \
  --network kijani-net \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v jenkins_home:/var/jenkins_home \
  jenkins/jenkins:lts

echo "Waiting for Jenkins container to initialize..."
sleep 30

echo "Installing Docker CLI inside Jenkins container..."
docker exec -u 0 jenkins apt-get update 
docker exec -u 0 jenkins apt-get install -y docker.io
docker exec -u 0 jenkins chmod 666 /var/run/docker.sock

echo "Docker CLI installed inside Jenkins container."
echo "Setup complete."
