#!/bin/bash

#This is a script that will boot up a VM and run a RStudio docker. It will print an external IP address to connect. 

#Configure the parameters below before running. 

#If a BUCKET_NAME is provided, the script will mount it in the VM so you can access the data in RStudio

#This assumes you have gcloud cli installed on the machine you are running this script, and you are authenticated (via gcloud auth login). 

#Hit ESC to delete the VM and clean up persistent disks.  

set -euo pipefail

# === CONFIGURE THESE ===
PROJECT_ID="sw-broad-epigenomics-igvf"
ZONE="us-east1-b"
VM_NAME="rstudio-tmp-vm"
MACHINE_TYPE="n2-standard-4"
DISK_SIZE="50GB"
IMAGE="rocker/rstudio:4.2.2"  # Or you can create custom docker and pass tag here like swekhande/sw-dockers:bp-cells
DOCKER_MEM='16g'
RSTUDIO_PASSWORD="password"
NETWORK="sw-broad-network" #find by running gcloud compute networks list
BUCKET_NAME=""  # Pass bucket name (optional). Pass "" if not needed. bucket name should not have gs://

echo "Creating VM: $VM_NAME in $ZONE (network: $NETWORK)"

# Create VM
gcloud compute instances create $VM_NAME \
  --project=$PROJECT_ID \
  --zone=$ZONE \
  --machine-type=$MACHINE_TYPE \
  --boot-disk-size=$DISK_SIZE \
  --image-family=ubuntu-2204-lts \
  --image-project=ubuntu-os-cloud \
  --network=$NETWORK \
  --tags=http-server,https-server 

echo "Waiting for VM to boot..."
sleep 30

gcloud compute ssh $VM_NAME --zone=$ZONE --project=$PROJECT_ID --command="sudo apt-get update -qq"
gcloud compute ssh $VM_NAME --zone=$ZONE --project=$PROJECT_ID --command="sudo apt-get install -y -qq docker.io curl gnupg apt-transport-https ca-certificates"

if [[ -n "$BUCKET_NAME" ]]; then

    gcloud compute ssh $VM_NAME --zone=$ZONE --project=$PROJECT_ID --command="export GCSFUSE_REPO=gcsfuse-jammy" 

    gcloud compute ssh $VM_NAME --zone=$ZONE --project=$PROJECT_ID --command="echo 'deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt gcsfuse-jammy main' | sudo tee /etc/apt/sources.list.d/gcsfuse.list"

    gcloud compute ssh $VM_NAME --zone=$ZONE --project=$PROJECT_ID --command="curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg |sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg"

    gcloud compute ssh $VM_NAME --zone=$ZONE --project=$PROJECT_ID --command="sudo apt-get update -qq"

    gcloud compute ssh $VM_NAME --zone=$ZONE --project=$PROJECT_ID --command="sudo apt-get install -y gcsfuse"

    gcloud compute ssh $VM_NAME --zone=$ZONE --project=$PROJECT_ID --command="sudo mkdir -p /mnt/data"  

    gcloud compute ssh $VM_NAME --zone=$ZONE --project=$PROJECT_ID --command="sudo gcloud auth application-default login"

    gcloud compute ssh $VM_NAME --zone=$ZONE --project=$PROJECT_ID --command="sudo gcsfuse --implicit-dirs $BUCKET_NAME /mnt/data"
    
else
  echo "No bucket specified — skipping gcsfuse mount"
fi

gcloud compute ssh $VM_NAME --zone=$ZONE --project=$PROJECT_ID --command="sudo docker pull $IMAGE"

gcloud compute ssh $VM_NAME --zone=$ZONE --project=$PROJECT_ID --command="sudo docker run -d -e PASSWORD=$RSTUDIO_PASSWORD -p 443:8787 --memory=$DOCKER_MEM --name rstudio $IMAGE"

EXTERNAL_IP=$(gcloud compute instances describe $VM_NAME --zone=$ZONE --project=$PROJECT_ID --format='get(networkInterfaces[0].accessConfigs[0].natIP)')

echo "==============================================="
echo "RStudio is available at: http://$EXTERNAL_IP:443"
echo "Username: rstudio"
echo "Password: $RSTUDIO_PASSWORD"
echo "Mounted Bucket: ${BUCKET_NAME:-None}"
echo "==============================================="
echo "Press ESC to delete the VM & cleanup"

while : ; do
    read -rsn1 key
    if [[ $key == $'\e' ]]; then
        echo "ESC pressed. Cleaning up..."
        break
    fi
done

echo "Deleting VM..."
gcloud compute instances delete $VM_NAME --zone=$ZONE --project=$PROJECT_ID --quiet

echo "Done!"