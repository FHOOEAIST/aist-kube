![logo](images/logo.svg)

# aistKube | aist K8s Utility Build Essentials

## Getting Started

* Install **kubectl** and **helm**, for more details have a look at *Prerequisites*
* Get a kubernetes access to your instance.
* Check out the [aistKube Stacks repository](https://github.com/FHOOEAIST/aist-kube-stacks) and build 
  and provide the images from there. 
* Install the **local-dynamic-storage** provisioner with **helm**.
* Deploy new gpu accelerated jupyter instances with **helm** or with the **setup.sh** script.

## Prerequisites

* [kubectl](https://kubernetes.io/de/docs/tasks/tools/install-kubectl/)
* [kubectl config](https://kubernetes.io/docs/tasks/access-application-cluster/access-cluster/)
* [helm.sh](https://helm.sh/)

If no kubernetes (K8s) setup is available then have a look at:

* Your windows/mac [docker](https://kubernetes.io/blog/2020/05/21/wsl-docker-kubernetes-on-the-windows-desktop/) installation (there should be a mini setup available)
* On Ubuntu use [microk8s](https://microk8s.io/) via snap

## Available helm charts in this repository

* `cuda-on-kube` Jupyter Notebook system with cuda gpu support for TensorFlow
    and PyTorch and webdav service for remote data file system access
* `local-dynamic-storage` Kubernetes dynamic custom local host path volume provisioning
* `dynamic-storage-test` Webdav service for testing the local-dynamic-storage

## How to use helm.sh

### Make DRY-RUN

Execution pattern to make a dry-run against an existing k8s cluster.

`helm install --debug --dry-run <release name> ./<chart>`

Example execution:
`helm install --debug --dry-run aist-amustermann-cuda-tf ./cuda-tf-on-kube`

Check the output. If some errors occur fix it otherwise it cannot be deployed.

### Install a chart

Execution pattern to install an existing chart into an existing k8s cluster.

`helm install <release name> ./<chart>`

Example execution:
`helm install aist-amustermann-cuda-tf ./cuda-tf-on-kube`

### Remove a chart

Execution pattern to remove an existing chart from an existing k8s cluster.
This chart has to be deployed with helm otherwise it will do nothing.

`helm uninstall <release name>`

## How to use K8s - STATUS

Basic K8s handling stuff

### Show all deployed stuff

Show all element that are deployed inside a K8s cluster. 
`kubectl get all --all-namespaces` 
The output is huge depending on the amount of deployed elements. 

### Show deployed stuff in one namespace

Namespaces separate deployments from each other and to schedule replaces better.
Also, the selector is more efficient since fewer elements have to be checked.

`kubectl get all --namespace <release name>`

Namespace is in case of the `cuda-tf-on-kube` chart equal to the `<release name>`.

### Show ingress deployment in one namespace

Get all deployed ingress elements: `kubectl get ingress --all-namespaces`

Show configuration from one deployed ingress element: 
`kubectl describe ingress <ingress deployment> --namespace <release name>`

## How to use K8s - DEPLOY ELEMENTS

`kubectl` can directly deploy and remove elements into a configured K8s cluster.

### Deploy directly with kubectl

`kubectl apply -f <some yaml file or directory with yaml files>`

The `yaml file` must contain a deployable K8s definition or a directory 
containing deployable K8s definitions.

**Use --dry-run=client** to test the deployment and if some errors occur in 
the definition.

**Important:** keep the definition files, otherwise it is painful to remove
them later.

> Be aware that this way of deployment can create additional elements.
> Those will not be removed automatically with running the delete step. 

### Remove some deployed elements

To remove a deployed element the **original** definition file **is required**.

To actually remove deployment use `delete`: 
`kubectl delete -f <some yaml file or directory with yaml files>`.

> Some errors may occur because of some automatically deployed elements. 
> If this is the case, then may God have mercy with you and 
> ask someone to help you. 

## FAQ

Nothing for the moment

## Contributing

**First make sure to read our [general contribution guidelines](https://fhooeaist.github.io/CONTRIBUTING.html).**
   
## Licence

Copyright (c) 2020 the original author or authors.
DO NOT ALTER OR REMOVE COPYRIGHT NOTICES.

This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at https://mozilla.org/MPL/2.0/.
