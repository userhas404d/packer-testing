#!/bin/bash

# packer build \
#   -var 'aws_access_key=<AWS_ACCESS_KEY>' \
#   -var 'aws_secret_key=<AWS_SECRET_KEY>' \
#   example.json


# delete the image

# get the caller's account id
export aws_account_id=$(aws sts get-caller-identity | jq '.["Account"]' --raw-output)

# get the ami id from the manifest
export ami_id=$(cat manifest.json | jq -r '.builds[-1].artifact_id' |  cut -d':' -f2)

# check if the ami actually exists
if [ $(aws ec2 describe-images --filters Name=image-id,Values=$ami_id | jq .Images[0]) == "null" ]
then
  echo "AMI not found and may already have been deleted." && exit 1
fi

# deregister the ami
aws ec2 deregister-image --image-id $ami_id && echo "Deregistered AMI $ami_id"

# get the snapshot id from the packer manifest
# https://gist.github.com/danrigsby/11354917#gistcomment-2613880
export snapshot_id=$( aws ec2 describe-snapshots --owner-ids $aws_account_id --filters Name=description,Values=*$ami_id* | jq '.Snapshots[0].SnapshotId' -r)

# delete the snapshot
aws ec2 delete-snapshot --snapshot-id $snapshot_id && echo "deleted snapshot $snapshot_id"