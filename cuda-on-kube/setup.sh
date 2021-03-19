#!/usr/bin/bash

#
# Copyright (c) 2021 the original author or authors.
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS FILE HEADER.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
#
#

echo "Using: "
echo "Registry: $repository"
echo "Image Owner: $imageOwner"
echo "Base url: $base_url"

if [ -z $repository ] || [ -z $imageOwner ] || [ -z $base_url ]
then
  echo
  echo "Setup first: repository, imageOwner, base_url"
  echo
  exit 1
fi

echo "+--------------------------------------+"
echo "|                                      |"
echo "|                                      |"
echo "|    Welcome to the                    |"
echo "|                                      |"
echo "|    cuda-on-kube                      |"
echo "|                                      |"
echo "|    release deployment                |"
echo "|                                      |"
echo "|                                      |"
echo "+--------------------------------------+"

organization=""
function get_organization () {
  printf "\nOrganization: \n"
  echo "Examples:"
  printf "\t Group: aist, bin, … \n"
  printf "\t Department: mtd, mbi, dse, … \n"
  if [ ! -z $1 ]
  then
    echo "Current organization: $1 (enter to keep it)"
  fi
  read -p "Group/Department > " organization
  if [ -z $organization ]
  then
    organization=$1
  fi
}

owner=""
function get_owner() {
  printf "\nOwner: \n"
  echo "Examples"
  printf "\t Person: (first letter of first name)(full-lastname) == amustermann for Anton Mustermann \n"
  printf "\t Project: akfa, btastic, … \n"
  if [ ! -z $1 ]
  then
    echo "Current owner: $1 (enter to keep it)"
  fi
  read -p "Owner > " owner
  if [ -z $owner ]
  then
    owner=$1
  fi
}

ml_base=""
function get_ml_base() {
  printf "\nML base: \n"
  echo "Choose between:"
  printf "\t 1 for TensorFlow (default)\n"
  printf "\t 2 for PyTorch\n"
  if [ ! -z $1 ]
  then
    echo "Current ML base: $1 (enter to keep it)"
  fi
  read -p "ML base > " ml
  if [ -z $ml ]
  then
    ml_base=$1
  else
    if [ $ml -lt 2 ]
    then
      ml_base="tf"
    else
      ml_base="pytorch"
    fi
  fi
}

deploymentName=""
deploymentImage=""
function get_deployment_name_and_image() {
  while : ;
  do
    echo "+--------------------------------------+"
    echo "|                                      |"
    echo "|                                      |"
    echo "|   Setup release/deployment           |"
    echo "|                                      |"
    echo "|   information and base               |"
    echo "|                                      |"
    echo "|   ML library                         |"
    echo "|                                      |"
    echo "|                                      |"
    echo "+--------------------------------------+"

    get_organization $organization
    get_owner $owner
    get_ml_base $ml_base
    deploymentName="$organization-$owner-cuda-$ml_base"
    if [ -z $organization ] || [ -z $owner ]
    then
      printf "\n\n\t -->> Organization or owner not set \n\n"
      printf "\t Current: $deploymentName \n\n"
      printf "\t"
      read -p "Press enter to update the configuration " dummy
      printf "\n\n"
      continue
    fi
    if [[ $deploymentName =~ [A-Z] ]]
    then
      deploymentName="${deploymentName,,}"
    fi
    if [[ $deploymentName =~ [0-9] ]]
    then
      printf "\n\n\t -->> Only lowercase characters allowed \n\n"
      printf "\t Current: $deploymentName \n\n"
      printf "\t"
      read -p "Press enter to update the configuration " dummy
      printf "\n\n"
      continue
    fi
    deploymentImage="scipy-notebook-cuda-$ml_base:latest"
    break
  done
}
# get_deployment_name_and_image

password=""
function get_password() {
  while : ;
  do
    printf "\nBase deployment information set, next configuration: \n"
    echo "Password for jovyan user:"
    read -sp "1. Password > " password1
    printf "\nPassword second time:\n"
    read -sp "2. Password > " password2
    echo
    if [ -z $password1 ] || [ $password1 != $password2 ]
    then
      printf "\n\t --> Password do not match \n"
      printf "\t "
      read -p "Press enter to type the password again " dummy
      printf "\n\n"
      continue
    fi
    password=$password1
    break
  done
}
# get_password

ram=""
function get_ram() {
  printf "\nMaximum amount of memory (RAM) for the jupyter instance: \n"
  printf "Size parameters: Mi > Megabyte, Gi > Gigabyte, Ti > Terabyte \n"
  printf "\t Default if empty will be: 5Gi \n"
  read -p "RAM amount > " ram
  if [ -z $ram ]
  then
    ram="5Gi"
  fi
}
# get_ram

cpu=""
function get_cpu() {
  printf "\nMaximum amount of CPUs for the jupyter instance: \n"
  printf "Size defined in number of cores: 0.5 (50% of one core), 1 (one core), 2 (two cors), … \n"
  printf "\t Default if empty will be: 1 \n"
  read -p "CPU amount > " cpu
  if [ -z $cpu ]
  then
    cpu="1"
  fi
}
# get_cpu

gpu=""
function get_gpu() {
  printf "\nMaximum amount of GPUs for the jupyter instance: \n"
  printf "\t Default if empty will be: 1 \n"
  read -p "GPU amount > " gpu
  if [ -z $gpu ]
  then
    gpu="1"
  fi
}
# get_cpu

ssd=""
function get_ssd_space() {
  printf "\nMaximum amount of storage space (SSD) for the shared data folder: \n"
  printf "Size parameters: Mi > Megabyte, Gi > Gigabyte, Ti > Terabyte \n"
  printf "\t Default if empty will be: 10Gi \n"
  read -p "Storage space > " ssd
  if [ -z $ssd ]
  then
    ssd="10Gi"
  fi
}
# get_ssd_space

while : ;
do
  get_deployment_name_and_image
  get_password

  echo
  echo "+--------------------------------------+"
  echo "|                                      |"
  echo "|                                      |"
  echo "|   Setup resource limits              |"
  echo "|                                      |"
  echo "|   and login information              |"
  echo "|                                      |"
  echo "|                                      |"
  echo "+--------------------------------------+"

  get_ram
  get_cpu
  get_gpu
  get_ssd_space

  echo
  echo "+--------------------------------------+"
  echo "|                                      |"
  echo "|  Current configuration               |"
  echo "|                                      |"
  echo "|  Overview:                           |"
  echo "|                                      |"
  echo "+--------------------------------------+"
  printf "\n\t DeploymentName: $deploymentName \n"
  printf "\t DeploymentImage: $imageOwner/$deploymentImage \n"
  printf "\t Password: *********** \n"
  printf "\t Jupyter RAM limit: $ram \n"
  printf "\t Jupyter CPU limit $cpu \n"
  printf "\t GPU claims: $gpu \n"
  printf "\t SSD storage claim: $ssd"
  printf "\n\n\t "
  read -p "Is this configuration correct (yes/no) > " correct

  if [ $correct != "yes" ]
  then
    continue
  fi

  echo 
  echo "+--------------------------------------+"
  echo "|                                      |"
  echo "|  Preparing setup                     |"
  echo "|                                      |"
  echo "+--------------------------------------+"
  echo

  new_deployment="./releases/$deploymentName.yaml"
  cpu="$(($cpu * 1000))m"

  if [ -f "$new_deployment" ]
  then
    printf "\n\n\t -->> Deployment $FILE exists \n\n"
    printf "\t"
    read -p "Override existing !! (yes/no) " override
    if [ $override != "yes" ]
    then
      exit 0
    fi
  fi

  cp ./releases/auto_template.yaml $new_deployment

  sed -i "s?<url>?$base_url?g" "$new_deployment"
  sed -i "s/<repo>/$repository/g" "$new_deployment"
  sed -i "s/<imgOwner>/$imageOwner/g" "$new_deployment"
  sed -i "s/<deName>/$deploymentName/g" "$new_deployment"
  sed -i "s?<deImage>?$deploymentImage?g" "$new_deployment"
  sed -i "s/<store>/$ssd/g" "$new_deployment"
  sed -i "s/<ram>/$ram/g" "$new_deployment"
  sed -i "s/<cpu>/$cpu/g" "$new_deployment"
  sed -i "s/<gpu>/$gpu/g" "$new_deployment"

  while : ;
  do
    echo
    echo "+--------------------------------------+"
    echo "|                                      |"
    echo "|  Helm dry run                        |"
    echo "|                                      |"
    echo "+--------------------------------------+"
    echo
    read -p "Make helm debug and dry run (yes/no) > " correct

    if [ $correct == "yes" ]
    then
      helm install --debug --dry-run --set-string setup.jovyanPassword=$password -f $new_deployment $deploymentName .
    fi

    echo
    echo "+--------------------------------------+"
    echo "|                                      |"
    echo "|  Helm run install                    |"
    echo "|                                      |"
    if [ $correct != "yes" ]
    then
      echo "|  NO DEBUG / DRY RUN WAS EXECUTED     |"
      echo "|                                      |"
      echo "|  ARE YOU SURE TO INSTALL IT          |"
      echo "|                                      |"
    fi
    echo "+--------------------------------------+"
    echo
    read -p "Make helm install (yes/no/dry) > " correct

    if [ $correct == "dry" ]
    then
      continue
    elif [ $correct == "no" ]
    then
      exit 0
    else
      echo
      echo "+--------------------------------------+"
      echo "|                                      |"
      echo "|  Start deployment of release         |"
      echo "|                                      |"
      echo "+--------------------------------------+"
      echo
      helm install --set-string setup.jovyanPassword=$password -f $new_deployment $deploymentName .
      exit 0
    fi
  done
done
