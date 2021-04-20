# cuda-on-kube Chart

This **helm** chart exists to deploy a jupyter notebook with cuda support.
Look up helm charts if you don't know it. Links: 
* [helm.sh - base](https://helm.sh)
* [helm chart creation guide](https://helm.sh/docs/chart_template_guide/)
* [helm existing charts how-to](https://helm.sh/docs/howto/)

## IMPORTANT

> Never use helm to deploy or remove plain k8s manifests and vise versa.

## Base 

This helm chart is based on the resulting image from the jupyter docker-stack images available 
on the docker hub but with different base images to allow cuda (RTX3090) access.

# Getting Started

## Use Setup.sh

1. Navigate with a bash into the folder `cuda-on-kube`.
2. Open the `setup.sh` file and customize the first three variables to your needs
   * `repository` points to a private repository or `docker.io`
   * `imageOwner` states the owner of the published images
   * `base_url` the ip or dns name of the node hosting the microk8s system
3. Run the setup script `./setup.sh` or `bash setup.sh`

## Manual

1. Navigate to the releases directory and copy the `example.yaml`.
2. Replace the following value:
   * `nodeUrl` with the ip or domain of your microk8s setup.
   * `repository` with the ip or name of the docker registry, if it is docker hub then 
     it would be `docker.io`.
   * `imageOwner` with the name of the image owner. All images (jupyter notebook and webdav) 
      must have the owner in common.
3. Define the `deploymentName` as given in the following pattern and set 
   it in the copied configuration:
   ```
   pattern: (group|department)-((first letter of first name)(full-lastname)|project name)-cuda-(tf|pytorch)
   example person Anton Mustermann: aist-amustermann-cuda-tf
   example project AKFA: aist-akfa-cuda-tf 
   ```
4. Create a copy of the `example.yaml` file and name it like the `deploymentName` with `.yaml` as extension.
5. Set the `deploymentImage` by choosing between a TensorFlow or PyTorch
    base image:
    * TensorFlow: `<registry>/<owner>/scipy-notebook-cuda-tf:latest`
    * PyTorch: `<registry>/<owner>/scipy-notebook-cuda-pytorch:latest`
6. Make a **dry run** and check if any error occur. Use as release name
   the defined `deploymentName`. Provide the password as parameter 
   defined by `--set-string setup.jovyanPassword=XYZ` and reference 
   the created configuration with `-f cuda-on-kube/releases/<deploymentName>.yaml`
   Example:
   ```bash
   helm install \
      --debug --dry-run \ 
      --set-string setup.jovyanPassword=thisIsAVewwySecurePassword \ 
      -f cuda-on-kube/releases/aist-amustermann-cuda-tf.yaml \ 
      aist-amustermann-cuda-tf \
      ./cuda-on-kube
   ```
7. If no errors occur run the same command without the `--debug --dry-run` 
   flags. Example: 
   ```bash
   helm install \
      --set-string setup.jovyanPassword=thisIsAVewwySecurePassword \ 
      -f cuda-on-kube/releases/aist-amustermann-cuda-tf.yaml \ 
      aist-amustermann-cuda-tf \
      ./cuda-on-kube
   ```

Now your chart is deployed, and a note similar to the following should 
show up:
```
NOTES:
--------------------------------------------------------------------------------------------------

The chart cuda-on-kube is deployed successfully into the namespace aist-amustermann-cuda-tf.
The chart is based on: scipy-notebook-cuda-tf:latest

Please visit http://<ip/domain>/notebook/aist-amustermann-cuda-tf
Login:
    Token: thisIsAVewwySecurePassword

Please visit on of the following depending on your system:
- Windows: http://<ip/domain>/webdav/aist-amustermann-cuda-tf
- Linux Dolphin: webdavs://<ip/domain>/webdav/aist-amustermann-cuda-tf
- Linux Nautilus: davs://<ip/domain>/webdav/aist-amustermann-cuda-tf
Login:
    User: jovyan
    Password: thisIsAVewwySecurePassword

--------------------------------------------------------------------------------------------------

See release status run:

  $ helm status aist-amustermann-cuda-tf
  $ helm get all aist-amustermann-cuda-tf
```

Send the first lines between the ascii-lines to the person how requested the notebook.


# How to remove a deployed chart

This is done by using the `uninstall` argument of the helm system.

* If the name of the release is unknown then check the output of 
   `kubectl get namespaces` and choose the right name. The namespace should be equal to the 
   release name of each deployment.
* If the release was deployed with the current machine than a deployment information is located
   in the directory releases. Open the correct `*.yaml` and lookup the `deploymentName` you want to remove.

1. Now run `helm uninstall <deploymentName>` to remove the deployment. Example: 
   `helm uninstall aist-amustermann-cuda-tf`
2. Now remove the configuration from the `releases` directory or add some information 
   that this notebook is no longer deployed.
   
> If errors occur then may God have mercy with you and ask someone to help you. 
> (If there is none, then ask someone to help you)

# cuda-on-kube structure

## values.yaml

This contains the requited information/parameters to deploy this chart. 
Only the `setup` tag has to be extended to deploy new notebooks.

## releases directory

This directory contains releases configuration's that are currently deployed
or are tagged to be not deployed.

## templates/namespace.yaml

It represents the namespace that will be created on deployment time and
where all elements from this chart belong to.

## templates/persistent-volume-claim.yaml

This manifest defines a storage that is claimed at creation time.
This storage is used and mounted by the notebook and webdav service.
Both deployments can read and write into it.

## deployment

### templates/notebook.yaml

This manifest defines the pod and how it is deployed. It is the core of this chart 
and host the jupyter notebook and has access to one or more gpus. To avoid url rewriting 
in the reverse proxy it already listens on a sub path such as `/notebook/<deploymentName>`.
Further the base port with `8888` is used. The provided password in jovyanPassword is applied.

### templates/webdav.yaml

This manifest defines the webdav pod, to access the data directory from your local pc via webdav.

## service

### templates/service-notebook.yaml

This manifest allows to access the notebook deployment on a certain port.
It is basically a k8s internal port-mapping that allows to access the
jupyter notebook port `8888` on port `80`.

### templates/service-webdav.yaml

This manifest allows to access the webdav deployment on port `80`.

## ingress

### templates/ingress-notebook.yaml

This manifest allows to access the notebook from the outside such as your PC.
It creates new reverse proxy rules in the deployed ingress controller / reverse proxy 
to access internally services. In the case of this chart the rule is as follows:
`/notebook/<deploymentName>` such as `/notebook/aist-amustermann-cuda-tf`. The complete 
url would be `http://<ip/domain>/notebook/aist-amustermann-cuda-tf`.

### templates/ingress-webdav.yaml

This manifest allows to access the notebook from the outside such as your PC.
It creates new reverse proxy rules in the deployed ingress controller / reverse proxy 
to access internally export services. In the case of this chart the rule is as follows:
`/webdav/<deploymentName>` such as `/webdav/aist-amustermann-cuda-tf`. The complete 
url would be `http://<ip/domain>/webdav/aist-amustermann-cuda-tf`.
