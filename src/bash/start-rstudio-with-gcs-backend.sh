#!/bin/bash

#This is a script that will boot up a VM and run a RStudio docker. It will print an external IP address to connect. 

#Configure the parameters below before running. 

#If a BUCKET_NAME is provided, the script will mount the bucket via gcsfuse in the VM so you can access the data in RStudio

#This assumes you have gcloud cli installed on the machine you are running this script, and you are authenticated (via gcloud auth login). 

#Hit ESC to delete the VM and clean up persistent disks.  

set -euo pipefail

# === CONFIGURE THESE ===
#name of google project (this is the project with linked billing account)
PROJECT_ID="sw-broad-epigenomics-igvf"

#name of zone you want to create VM in. you can find zones here https://cloud.google.com/compute/docs/regions-zones. Closer zones should be cheaper. 
ZONE="us-east1-b"

#name of the VM the script will create. 
VM_NAME="rstudio-tmp-vm"

#name of the machine type. Google has preconfigured VMs here https://cloud.google.com/compute/docs/general-purpose-machines#n4-standard. This decides the cores and memory of the VM
MACHINE_TYPE="e2-standard-4"

#disk space to request on VM
DISK_SIZE="50GB"

# Or you can create custom docker and pass tag here like swekhande/sw-dockers:bp-cells
IMAGE="rocker/rstudio:4.2.2"

#how much RAM you want to give the Rstudio.
DOCKER_MEM='16g' 

RSTUDIO_PASSWORD="password"

#find by running gcloud compute networks list
NETWORK="sw-broad-network"

# Pass bucket name (optional). This will be mounted at /mnt/data. Pass "" if not needed. bucket name should not have gs://
BUCKET_NAME="sw-igvf-submission"

# Pass folder name (optional). Your Rstudio docker will have read/write permissions to this folder only. If you try to give 
#read/write permissions to the whole bucket, it will take a really long time. Pass "" if not needed. folder name should not have gs://
FOLDER_NAME="seqspecs"

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

    gcloud compute ssh $VM_NAME --zone=$ZONE --project=$PROJECT_ID --command="mkdir -p ~/data"  

    gcloud compute ssh $VM_NAME --zone=$ZONE --project=$PROJECT_ID --command="sudo gcloud auth application-default login --no-launch-browser"

    gcloud compute ssh $VM_NAME --zone=$ZONE --project=$PROJECT_ID --command="sudo chmod 777 -R ~/data"

    gcloud compute ssh $VM_NAME --zone=$ZONE --project=$PROJECT_ID --command="sudo sed -i '/^# *user_allow_other/s/^# *//' /etc/fuse.conf || echo 'user_allow_other' | sudo tee -a /etc/fuse.conf"

    gcloud compute ssh $VM_NAME --zone=$ZONE --project=$PROJECT_ID --command="gcsfuse --implicit-dirs -o allow_other --only-dir $FOLDER_NAME $BUCKET_NAME ~/data"
    
else
  echo "No bucket specified — skipping gcsfuse mount"
fi

gcloud compute ssh $VM_NAME --zone=$ZONE --project=$PROJECT_ID --command="sudo docker pull $IMAGE"
gcloud compute ssh $VM_NAME --zone=$ZONE --project=$PROJECT_ID --command="sudo docker run -d --mount type=bind,source=\$(pwd)/data,target=/home/rstudio/data --privileged -e PASSWORD=$RSTUDIO_PASSWORD -p 443:8787 --memory=$DOCKER_MEM --name rstudio $IMAGE"

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