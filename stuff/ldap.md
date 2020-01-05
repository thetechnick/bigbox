
```yaml
apiVersion: cert-manager.io/v1alpha2
kind: Issuer
metadata:
  name: selfsigned
  namespace: auth
spec:
  selfSigned: {}
---
apiVersion: cert-manager.io/v1alpha2
kind: Certificate
metadata:
  name: ldap
  namespace: auth
spec:
  secretName: ldap
  duration: 2160h # 90d
  renewBefore: 360h # 15d
  organization:
  - nico
  keySize: 2048
  keyAlgorithm: rsa
  keyEncoding: pkcs1
  usages:
  - server auth
  - client auth
  dnsNames:
  - ldap.home.nico-schieder.de

  issuerRef:
    name: selfsigned
    kind: Issuer
```

```yaml
persistence:
  enabled: true
  storageClass: fast-disks
  size: 5000Mi
tls:
  enabled: true
  secret: ldap
```

helm install --name ldap --namespace auth -f ldap-values.yaml stable/openldap

Patch
```yaml
        - name: LDAP_TLS_VERIFY_CLIENT
          value: try
```

`{1} to dn.subtree="dc=nico-schieder,dc=de" by dn="cn=dex,ou=users,dc=nico-schieder,dc=de" read`
