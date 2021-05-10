![logo](images/logo.svg)

# aistKube | aist k8s Utility Build Essentials

## Getting Started

* Install **kubectl** and **helm**, for more details have a look at the *Prerequisites*
* Get a kubernetes admin access to your instance.
* Check out the [aistKube Stacks repository](https://github.com/FHOOEAIST/aist-kube-stacks) and build the images and
  further provide the images via an image registry.
* Install the **local-dynamic-storage** provisioner with **helm** which needs the aistKube Stacks repository.
* Deploy new gpu accelerated jupyter instances with **helm** or with the **setup.sh** script.

## Prerequisites

* [kubectl](https://kubernetes.io/de/docs/tasks/tools/install-kubectl/)
* [kubectl config](https://kubernetes.io/docs/tasks/access-application-cluster/access-cluster/)
* [helm.sh](https://helm.sh/)

If no kubernetes (k8s) setup is available then have a look at:

* Your windows/mac [docker](https://kubernetes.io/blog/2020/05/21/wsl-docker-kubernetes-on-the-windows-desktop/)
  installation (there should be a mini setup available)
* On Ubuntu use [microk8s](https://microk8s.io/) via snap

## Available helm charts in this repository

* `cuda-on-kube` Jupyter Notebook system with cuda gpu support for the machine learning libraries TensorFlow and
  PyTorch. Furthermore, a webdav service for remote data file system access is deployed with the bundle.
* `local-dynamic-storage` Kubernetes dynamic custom local host path volume provisioning via a customized hostpath
  provisioner.
* `dynamic-storage-test` Webdav service for testing the local-dynamic-storage with the custom hostpath provisioner.

## How to use helm.sh

### Make DRY-RUN

Use the dry-run and debug functionality to test your chart against an existing k8s cluster.

`helm install --debug --dry-run <release name> ./<chart>`

Example execution:
`helm install --debug --dry-run aist-amustermann-cuda-tf ./cuda-tf-on-kube`

Check the output. If some errors occur fix it otherwise it cannot be deployed.

### Install a chart

Use the same functionality without the dry-run and debug flags to install the chart into an existing k8s cluster.

`helm install <release name> ./<chart>`

Example execution:
`helm install aist-amustermann-cuda-tf ./cuda-tf-on-kube`

### Remove a chart

To remove an existing chart from an existing k8s cluster use the `uninstall`. This chart has to be deployed with helm
otherwise it will do nothing.

`helm uninstall <release name>`

## How to use k8s - STATUS

k8s status can be checked with the commandline tool `kubectl`. It needs access to the api-service of k8s as admin. 
Have a look the kubectl setup guidelines.

### Show all deployed stuff

Show all element that are deployed inside a k8s cluster. `kubectl get all --all-namespaces` The output is huge depending
on the amount of deployed/installed elements.

### Show deployed stuff in one namespace

Namespaces separate deployments from each other and to schedule replaces better. Also, the selector is more efficient
since fewer elements have to be checked.

`kubectl get all --namespace <release name>`

Namespace is in case of the `cuda-on-kube` chart equal to the `<release name>`.

### Show ingress deployment in one namespace

Get all deployed ingress elements: `kubectl get ingress --all-namespaces`

Show configuration from one deployed ingress element:
`kubectl describe ingress <ingress deployment> --namespace <release name>`

## How to use k8s - DEPLOY ELEMENTS

`kubectl` can directly deploy and remove elements into a configured k8s cluster.

### Deploy directly with kubectl

`kubectl apply -f <some yaml file or directory with yaml files>`

The `yaml file` must contain a deployable k8s manifest or a directory containing deployable k8s manifests.

Use **--dry-run=client** to test the deployment and if some errors occur in the manifest.

**Important:** keep the manifest files, otherwise it is painful to remove them later.

> Be aware that this way of deployment can create additional elements.
> Those will not be removed automatically with running the delete step.

### Remove some deployed elements

To remove a deployed element the **original** manifest file **is required**.

To actually remove a deployment use `delete`:
`kubectl delete -f <some yaml file or directory with yaml files>`.

> Some errors may occur because of some automatically deployed elements.
> Or the original manifest is not available. In this case get 
> the current manifest state via `kubectl get … -o=yaml` for each element
> or remove it via `kubectl delete …` manually.
> In any case, may God have mercy with you and
> ask someone to help you. 

## Contributing

**First make sure to read our [general contribution guidelines](https://fhooeaist.github.io/CONTRIBUTING.html).**

## Licence

Copyright (c) 2020 the original author or authors. DO NOT ALTER OR REMOVE COPYRIGHT NOTICES.

This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not
distributed with this file, You can obtain one at https://mozilla.org/MPL/2.0/.
