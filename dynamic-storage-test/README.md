# AIST dynamic host storage class test

This helm chart allows to test the local-dynamic-storage chart that provides the
`aist.science/hostpath` provisioner.

It consists of a webdav service that claims a persistence volume via the 
`aist.science/hostpath` provisioner. The webdav service is then exposed via 
a service and ingress rule to the sub path `/webdav/test` on the node ip.
Access the storage via webdav protocol and use the username `jovyan` and 
password `test`. 

# Getting Started

## Deployment of this storage chart

This chart requires that the `aist.science/hostpath` provisioner is deployed into the
kubernetes system.

Install this chart via helm with the command and don't forget to test with `--debug --dry-run`:
```bash
# if you are in the main directory of the project
helm install --set-string webdavAndRegistry=docker.io/aist storage-test ./dynamic-storage-test
# if you are in the dynamic-storage-test
helm install --set-string webdavAndRegistry=docker.io/aist storage-test .
```

## Remove the deployment

The local-dynamic-storage chart can be removed at anytime but with the risk of side effects.
If persistence volume claims via this storage class exist then they will
never be cleaned up because the provisioning system which does also the 
cleanup does not exist anymore. Other side effect may occur.

So first uninstall all deployment that rely on `aist.science/hostpath` provisioner (chart).

```bash
helm uninstall storage-test
```


