### Fix CRI-O packaging error:

```bash
# cri-o-2:1.16.0-0.1.rc1.git6a4b481.module_f31+6837+7e34758d.x86_64
perl -p0e "s/\.module_f31/.alpha.0.31/g;s/\+6837/.6837/g;s/\+7e34758d/.7e34758d/g" -i /usr/bin/crio
```

```yaml
apiVersion: kubevirt.io/v1alpha3
kind: VirtualMachineInstance
metadata:
  name: myvmi
  labels:
    test: test
spec:
  terminationGracePeriodSeconds: 5
  domain:
    resources:
      requests:
        memory: 2G
    devices:
      disks:
      - name: containerdisk
        disk:
          bus: virtio
      - name: cloudinitdisk
        disk:
          bus: virtio
  volumes:
    - name: containerdisk
      containerDisk:
        image: quay.io/nschieder/fedora-cloud-disk:31
    - name: cloudinitdisk
      cloudInitNoCloud:
        userData: |
          #cloud-config
          password: fedora
          chpasswd: { expire: False }
          ssh_authorized_keys:
          - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIILXf3lXJioTlQu3GzMnZ8XiexTaNdCykstdF0EEAkg1 nschieder@notebook
          - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDA0a+76zqpLChaUE/pFq5Pnol4ZusIkLGmhBh8ou7tq nschieder@bigbox.home.nico-schieder.de
```
