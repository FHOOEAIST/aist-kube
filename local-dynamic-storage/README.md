# AIST dynamic host storage class

This helm chart is required if an additional storage should be dynamically provisioned.

This dynamic storage class only allows to provide dynamic storage from a local host path.
In a multi node set up a more sophisticated storage solution such as cephfs should be used.

# Important read this FIRST!!!

**This chart can only be deployed one time!!!**

The host path provisioning can only be deployed one time.
This is because of the restriction that the storage class needs a named provisioner.
That provisioner used in the deployment registers itself with a name into the 
kubernetes system. This name is unique and can not be deployed multiple times. 
(It can but without any effect)

# Getting Started

## How to use this storage class

First prepare a directory in the host system that should be used for storing 
the persistence volume claim. Have a look at **LVM Volume Group**.

Next open the *values.yaml* and change the `hostMainPath: …` value to the path
that from the first step. Now deploy the chart with `helm`, see the deployment step.

Now create in your chart a persistence volume claim that uses as `storageClassName` this
chart named as `aist-hostpath`. The storage class is based on the `aist/hostpath-provisioner` 
located in the [aistKube Stacks repository](https://github.com/FHOOEAIST/aist-kube-stacks) images.

Example persistence volume claim:
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: task-pv-claim
  namespace: my-namespace
spec:
  storageClassName: aist-hostpath
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 3Gi
```

## Deployment of this storage chart

This storage class and required deployment is integrated into the `kube-system` namespace which
is the main namespaces of kubernetes.

Install this chart via helm with the command and providing the image to
the prepared hostpath-provisioner and don't forget to test with `--debug --dry-run`:
```bash
# if you are in the main directory of the project
helm install --set-string provisioner=someOwner/hostpath-provisioner local-dynamic-storage ./local-dynamic-storage
# if you are in the local-dynamic-storage directory
helm install --set-string provisioner=someOwner/hostpath-provisioner local-dynamic-storage .
```

## Remove the deployment

The chart can be removed at anytime but with a lot of side effects.
If persistence volume claims via this storage class exist then they will
never be cleaned up because the provisioning system which is responsible 
for the cleanup does not exist anymore. 

So first uninstall all deployment that rely on this storage class (chart)
and then uninstall this chart.

```bash
helm uninstall local-dynamic-storage
```

# LVM volume group

This guide is based on the content of 
[tecmint.com](https://www.tecmint.com/add-new-disks-using-lvm-to-linux/) and 
[ubuntuuseres.de](https://wiki.ubuntuusers.de/Logical_Volume_Manager/).

## Why LVM

1. Easy to create a pool of storage that can be scattered across multiple disks or
    available partitions.
1. LVM logical volumes can be easily be extended and reduces with additional 
   storage dynamically.
1. New disks can be added and removed dynamically

## Setup LVM storage

First prepare the disks that should be used for storing.
1. Get an overview of the disks that are available with `fdisk -l`
1. Unmount all mounted disk that should be used with `umount <path to mount>` 
   such as `umount /mnt/318bfe6c-cb0d-47be-9fc9-fab80d23cac0`.
1. For each disk that should be used do the following steps:
    1. **Important** 
       > The disk should be clean or should not contain any production data.
       > After the following steps everything that was stored on that disk is not 
       > accessible anymore. Don't use the /dev/sda devices if it is mounted to `/`
       > or any other disk that is mounted to `/`!!!
    1. Use `fdisk /dev/{disk}` to start to repartition the disk. `{disk}` can 
    therefore be `sda` or else shown by the command `fdisk -l`.
    1. Now create a new partition table py pressing `g`.
    1. Now create a new partition with pressing `n`.
    1. Next the question arises of the number of the new partition. Use the default
        which is `1` and is equal to pressing `enter`. If the question of the 
        partition type shows up the use the default that is `p` as primary.
    1. Next comes the question about the start sector. Use the default and press 
        `enter` again. (Should be around 2048)
    1. Next the final question about the size of the partition. If the full disk should
        be used then press `enter` or type the size in gigabytes such as `+19G` for 
        19 GB of disk space.
    1. Finish the creation of the partition by typing `w`. 
       > **Important** by typing `w` the new partition schema is written to 
       > disk and everything on it will be unreadable.
1. Get an overview of the created partitions with `fdisk -l`.
1. Now create physical volume (PV) managed by LVM.
    ```bash
    # for one physical volume
    pvcreate /dev/sda1
    # for multiple physical volumes
    pvcreate /dev/sda1 /dev/sda2
    ```
    The output should look similar to this:
    ```bash
    root@localhost:/mnt# pvcreate /dev/sda1 /dev/sdb1 /dev/sdc1 /dev/sdd1 
      Physical volume "/dev/sda1" successfully created.
      Physical volume "/dev/sdb1" successfully created.
      Physical volume "/dev/sdc1" successfully created.
      Physical volume "/dev/sdd1" successfully created.
    ```
1. Next create a volume group (vg) that changes the physical volumes into one managed
    group. In the example the volume group has the name `main-vg`.
   ```bash
   root@localhost:/mnt# vgcreate main-vg /dev/sda1 /dev/sdb1 /dev/sdc1 /dev/sdd1
     Volume group "main-vg" successfully created
   ```
1. Now you can look with volume groups are available by using `vgdisplay`. It shows 
   how much storage is available for example 14.55 TiB:
   ```bash
   root@localhost:/mnt# vgdisplay 
      --- Volume group ---
      VG Name               main-vg
      System ID             
      Format                lvm2
      Metadata Areas        4
      Metadata Sequence No  1
      VG Access             read/write
      VG Status             resizable
      MAX LV                0
      Cur LV                0
      Open LV               0
      Max PV                0
      Cur PV                4
      Act PV                4
      VG Size               14,55 TiB
      PE Size               4,00 MiB
      Total PE              3815444
      Alloc PE / Size       0 / 0   
      Free  PE / Size       3815444 / 14,55 TiB
      VG UUID               iuduj2-VJx6-8UFr-l9J3-QkVt-jMcs-uQadCI
   ```
1. Now create as many local volumes as you need by calling `lvcreate`, such as:
    ```bash
   root@localhost:/mnt# lvcreate -n kube_data --size 13T main-vg
     Logical volume "kube_data" created. 
   ```
   This creates a new virtual block disk based on the managed space available over 
   all grouped physical disks. In this case with the name `kube_data` the amount of
   `13 TiB` of space and in the volume group `main-vg`.
1. Get en overview of the logical volumes with `lvdisplay`.
1. Next format the logical volume with the wanted filesystem for example `ext4`.
   The virtual disk is located under the volume group dev name. In this example
   it is `/dev/main-vg/kube_data`.
    ```bash
   root@localhost:/mnt# mkfs.ext4 /dev/main-vg/kube_data 
        mke2fs 1.44.1 (24-Mar-2018)
        Creating filesystem with 3489660928 4k blocks and 436207616 inodes
        Filesystem UUID: d0fb4416-3add-4e6f-b4f7-86e4b5df73a8
        Superblock backups stored on blocks: 
                32768, 98304, 163840, 229376, 294912, 819200, 884736, 1605632, 2654208, 
                4096000, 7962624, 11239424, 20480000, 23887872, 71663616, 78675968, 
                102400000, 214990848, 512000000, 550731776, 644972544, 1934917632, 
                2560000000
        
        Allocating group tables: done                            
        Writing inode tables: done                            
        Creating journal (262144 blocks): done
        Writing superblocks and filesystem accounting information: done    
    ```
1. Execute `blkid` to get the UUID of the new virtual disk or copy the UUID from the
    `mkfs` that also prints out the UUID.
   ```bash
   root@cad660853:/# blkid
        /dev/nvme0n1p2: UUID="eacb0763-0848-48be-a99b-a7880d2191b5" TYPE="ext4" PARTUUID="98777602-a8e9-45b7-b1ea-335f535f09da"
        /dev/nvme0n1p1: UUID="EDA3-9AD3" TYPE="vfat" PARTLABEL="EFI System Partition" PARTUUID="59baa0d8-a347-4950-903b-dddb78edbc77"
        /dev/sdb1: UUID="veYczN-O8iJ-0BZR-btU1-yE3h-iM3v-oRSXSj" TYPE="LVM2_member" PARTUUID="0d3673e0-c96b-8b4e-86e1-d26a5b5de4bb"
        /dev/sda1: UUID="ESGBWV-mUTJ-br9O-jMvM-6n4m-6K71-pjZgAy" TYPE="LVM2_member" PARTUUID="9095262a-25c4-6b45-8dba-33f1b8a76924"
        /dev/sdd1: UUID="cKrfmM-c0qK-1ETf-xmsG-yI1q-wjxA-0ZMmSC" TYPE="LVM2_member" PARTUUID="fd004c36-8027-9640-81c5-9d1573571791"
        /dev/sdc1: UUID="eIVLcA-Dd45-7Mn3-SRpo-lFC4-z3jx-KL1Gqe" TYPE="LVM2_member" PARTUUID="8bbd1d8b-c356-ba45-b959-147934744339"
   -->  /dev/mapper/main--vg-kube_data: UUID="d0fb4416-3add-4e6f-b4f7-86e4b5df73a8" TYPE="ext4"
        /dev/nvme0n1: PTUUID="17899ec1-1fc8-428e-8c4e-ac354865755a" PTTYPE="gpt"
   ```
   Look for some device named `/dev/mapper/…` and copy the value of the UUID.
1. Create some path to mount the new disk, such as `/kube_data/`.
1. Finally, open the `/etc/fstab` to automatically mount the new disk also after a 
   restart. In the fstab add the following line updated to your UUID and mount path:
   ```bash
   UUID=d0fb4416-3add-4e6f-b4f7-86e4b5df73a8       /kube_data      ext4    defaults        0       2
   ```
1. Apply the changes in the fstab without a reboot by executing `mount -a`. 
   This mounts all defined mounts in the fstab.
