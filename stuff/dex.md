```yaml
apiVersion: cert-manager.io/v1alpha2
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    email: nico.schieder@gmail.com
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: acme-staging-account
    solvers:
    - selector:
        dnsZones:
        - "home.nico-schieder.de"
      dns01:
        route53:
          region: eu-central-1
          accessKeyID: AKIAWTRPSKEP2UWQJDON
          secretAccessKeySecretRef:
            name: prod-route53-credentials
            key: secret-access-key

---
apiVersion: cert-manager.io/v1alpha2
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    email: nico.schieder@gmail.com
    # server: https://acme-staging-v02.api.letsencrypt.org/directory
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: acme-prod-account
    solvers:
    - selector:
        dnsZones:
        - "home.nico-schieder.de"
      dns01:
        route53:
          region: eu-central-1
          accessKeyID: AKIAWTRPSKEP2UWQJDON
          secretAccessKeySecretRef:
            name: prod-route53-credentials
            key: secret-access-key

---
apiVersion: cert-manager.io/v1alpha2
kind: Certificate
metadata:
  name: dex
  namespace: auth
spec:
  secretName: dex-tls
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  dnsNames:
  - dex.home.nico-schieder.de
```

```yaml
config:
  issuer: https://dex.home.nico-schieder.de/dex

  staticClients:
  - id: example-app
    redirectURIs:
    - 'http://127.0.0.1:5555/callback'
    - 'https://bigbox-k8s-login.home.nico-schieder.de/callback'
    name: 'Example App'
    secret: ZXhhbXBsZS1hcHAtc2VjcmV0

  - id: gitea
    name: 'Gitea'
    secret: sOpeVC83iDCtBcMIlqEu
    redirectURIs:
    - 'https://gitea.home.nico-schieder.de/user/oauth2/dex/callback'

  - id: concourse
    name: Concourse
    secret: vPE3SCAlHnvkxftJPCuV
    redirectURIs:
    - 'https://ci.home.nico-schieder.de/sky/issuer/callback'

  - id: harbor
    name: Harbor
    secret: tJeJkxKcwnCWiCmsS95Q
    redirectURIs:
    - 'https://ci.home.nico-schieder.de/sky/issuer/callback'

  # - id: bigbox-k8s
  #   name: 'Bigbox Kubernetes'
  #   secret: vPE3SCAlHnvkxftJPCuV
  #   redirectURIs: []
  connectors:
  - type: ldap
    id: ldap
    name: LDAP
    config:
      host: ldap-openldap.auth.svc.cluster.local:636
      insecureSkipVerify: true
      
      bindDN: cn=dex,ou=users,dc=nico-schieder,dc=de
      bindPW: .48fr#"v6~W34iVH7ZS`Fm$Y.Adn72/t

      userSearch:
        baseDN: ou=users,dc=nico-schieder,dc=de
        username: cn
        idAttr: cn
        emailAttr: mail
        nameAttr: displayName

      groupSearch:
        baseDN: ou=groups,dc=nico-schieder,dc=de
        userAttr: dn
        groupAttr: member
        nameAttr: cn

  enablePasswordDB: false

```

```
helm install dex --namespace auth -f dex-values.yaml - stable/dex
```

```yaml
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: dex
  namespace: auth
spec:
  tls:
  - hosts:
    - dex.home.nico-schieder.de
    secretName: dex-tls
  rules:
  - host: dex.home.nico-schieder.de
    http:
      paths:
      - path: /
        backend:
          serviceName: dex
          servicePort: 32000
```

```yaml
oidc-issuer-url: https://dex.home.nico-schieder.de/dex
oidc-client-id: example-app
oidc-username-claim: email
oidc-groups-claim: groups
```

# Login App
```yaml
apiVersion: v1
kind: Service
metadata:
  name: loginapp
  namespace: auth
spec:
  type: ClusterIP
  ports:
  - name: loginapp
    port: 80
    protocol: TCP
    targetPort: 5555
  selector:
    app: loginapp
---
apiVersion: cert-manager.io/v1alpha2
kind: Certificate
metadata:
  name: bigbox-k8s-login
  namespace: auth
spec:
  secretName: bigbox-k8s-login-tls
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  dnsNames:
  - bigbox-k8s-login.home.nico-schieder.de
---
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: bigbox-k8s-login
  namespace: auth
spec:
  tls:
  - hosts:
    - bigbox-k8s-login.home.nico-schieder.de
    secretName: bigbox-k8s-login-tls
  rules:
  - host: bigbox-k8s-login.home.nico-schieder.de
    http:
      paths:
      - path: /
        backend:
          serviceName: loginapp
          servicePort: 80
---
kind: ConfigMap
apiVersion: v1
metadata:
  name: loginapp
  namespace: auth
data:
  ca.pem: |
    -----BEGIN CERTIFICATE-----
    MIIFjTCCA3WgAwIBAgIRANOxciY0IzLc9AUoUSrsnGowDQYJKoZIhvcNAQELBQAw
    TzELMAkGA1UEBhMCVVMxKTAnBgNVBAoTIEludGVybmV0IFNlY3VyaXR5IFJlc2Vh
    cmNoIEdyb3VwMRUwEwYDVQQDEwxJU1JHIFJvb3QgWDEwHhcNMTYxMDA2MTU0MzU1
    WhcNMjExMDA2MTU0MzU1WjBKMQswCQYDVQQGEwJVUzEWMBQGA1UEChMNTGV0J3Mg
    RW5jcnlwdDEjMCEGA1UEAxMaTGV0J3MgRW5jcnlwdCBBdXRob3JpdHkgWDMwggEi
    MA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCc0wzwWuUuR7dyXTeDs2hjMOrX
    NSYZJeG9vjXxcJIvt7hLQQWrqZ41CFjssSrEaIcLo+N15Obzp2JxunmBYB/XkZqf
    89B4Z3HIaQ6Vkc/+5pnpYDxIzH7KTXcSJJ1HG1rrueweNwAcnKx7pwXqzkrrvUHl
    Npi5y/1tPJZo3yMqQpAMhnRnyH+lmrhSYRQTP2XpgofL2/oOVvaGifOFP5eGr7Dc
    Gu9rDZUWfcQroGWymQQ2dYBrrErzG5BJeC+ilk8qICUpBMZ0wNAxzY8xOJUWuqgz
    uEPxsR/DMH+ieTETPS02+OP88jNquTkxxa/EjQ0dZBYzqvqEKbbUC8DYfcOTAgMB
    AAGjggFnMIIBYzAOBgNVHQ8BAf8EBAMCAYYwEgYDVR0TAQH/BAgwBgEB/wIBADBU
    BgNVHSAETTBLMAgGBmeBDAECATA/BgsrBgEEAYLfEwEBATAwMC4GCCsGAQUFBwIB
    FiJodHRwOi8vY3BzLnJvb3QteDEubGV0c2VuY3J5cHQub3JnMB0GA1UdDgQWBBSo
    SmpjBH3duubRObemRWXv86jsoTAzBgNVHR8ELDAqMCigJqAkhiJodHRwOi8vY3Js
    LnJvb3QteDEubGV0c2VuY3J5cHQub3JnMHIGCCsGAQUFBwEBBGYwZDAwBggrBgEF
    BQcwAYYkaHR0cDovL29jc3Aucm9vdC14MS5sZXRzZW5jcnlwdC5vcmcvMDAGCCsG
    AQUFBzAChiRodHRwOi8vY2VydC5yb290LXgxLmxldHNlbmNyeXB0Lm9yZy8wHwYD
    VR0jBBgwFoAUebRZ5nu25eQBc4AIiMgaWPbpm24wDQYJKoZIhvcNAQELBQADggIB
    ABnPdSA0LTqmRf/Q1eaM2jLonG4bQdEnqOJQ8nCqxOeTRrToEKtwT++36gTSlBGx
    A/5dut82jJQ2jxN8RI8L9QFXrWi4xXnA2EqA10yjHiR6H9cj6MFiOnb5In1eWsRM
    UM2v3e9tNsCAgBukPHAg1lQh07rvFKm/Bz9BCjaxorALINUfZ9DD64j2igLIxle2
    DPxW8dI/F2loHMjXZjqG8RkqZUdoxtID5+90FgsGIfkMpqgRS05f4zPbCEHqCXl1
    eO5HyELTgcVlLXXQDgAWnRzut1hFJeczY1tjQQno6f6s+nMydLN26WuU4s3UYvOu
    OsUxRlJu7TSRHqDC3lSE5XggVkzdaPkuKGQbGpny+01/47hfXXNB7HntWNZ6N2Vw
    p7G6OfY+YQrZwIaQmhrIqJZuigsrbe3W+gdn5ykE9+Ky0VgVUsfxo52mwFYs1JKY
    2PGDuWx8M6DlS6qQkvHaRUo0FMd8TsSlbF0/v965qGFKhSDeQoMpYnwcmQilRh/0
    ayLThlHLN81gSkJjVrPI0Y8xCVPB4twb1PFUd2fPM3sA1tJ83sZ5v8vgFv2yofKR
    PB0t6JzUA81mSqM3kxl5e+IZwhYAyO0OTg3/fs8HqGTNKd9BqoUwSRBzp06JMg5b
    rUCGwbCUDI0mxadJ3Bz4WxR6fyNpBK2yAinWEsikxqEt
    -----END CERTIFICATE-----
  config.yaml: |
    name: Bigbox Kubernetes
    listen: 0.0.0.0:5555
    oidc:
      client:
        id: example-app
        secret: ZXhhbXBsZS1hcHAtc2VjcmV0
        redirect_url: https://bigbox-k8s-login.home.nico-schieder.de/callback
      
      issuer:
        url: https://dex.home.nico-schieder.de/dex
        root_ca: "/config/ca.pem"

      extra_scopes:
      - groups

      extra_auth_code_opts:
        resource: XXXXX

      offline_as_scope: true

    web_output:
      main_username_claim: email
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: loginapp
  namespace: auth
spec:
  replicas: 1
  selector:
    matchLabels:
      app: loginapp
  template:
    metadata:
      labels:
        app: loginapp
    spec:
      containers:
      - image: quay.io/fydrah/loginapp:2.7.0
        name: loginapp
        args:
        - serve
        - /config/config.yaml
        ports:
        - name: http
          containerPort: 5555
        volumeMounts:
        - name: config
          mountPath: /config/
      volumes:
      - name: config
        configMap:
          name: loginapp
```
