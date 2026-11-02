#!/bin/bash
# 1. Compute the version from package.json and the 7 character Git SHA
VERSION=$(node -p "require(\"./package.json\").version")
GITSHA=$(git rev-parse --short=7 HEAD)
TAG="${VERSION}-${GITSHA}"
FULL_IMAGE="salyani123/kk-payments:${TAG}"

# 2. Start recording to the evidence file
echo "Computed Tag: ${TAG}" > week8/friday/registry-push.txt
echo "Target Image: ${FULL_IMAGE}" >> week8/friday/registry-push.txt
echo -e "\n--- PUSHING TO REGISTRY ---" >> week8/friday/registry-push.txt

# 3. Tag the image
docker tag kk-payments:latest ${FULL_IMAGE}

# 4. Push the image and record output
docker push ${FULL_IMAGE} 2>&1 | tee -a week8/friday/registry-push.txt

# 5. Delete the local images to simulate a cold start
docker rmi kk-payments:latest ${FULL_IMAGE}

# 6. Pull the image from the registry to prove it works
echo -e "\n--- PULLING FROM REGISTRY ---" >> week8/friday/registry-push.txt
docker pull ${FULL_IMAGE} 2>&1 | tee -a week8/friday/registry-push.txt
