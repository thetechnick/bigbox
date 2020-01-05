```yaml
apiVersion: v1
kind: Service
metadata:
  name: gitea-web
  namespace: gitea
  labels:
    app: gitea
spec:
  ports:
  - port: 80
    name: http
    targetPort: http
  selector:
    app: gitea
---
apiVersion: v1
kind: Service
metadata:
  name: gitea-ssh
  namespace: gitea
  labels:
    app: gitea
spec:
  ports:
  - port: 22
    name: ssh
  selector:
    app: gitea
  type: LoadBalancer
---
apiVersion: v1
kind: Service
metadata:
  name: gitea-headless
  namespace: gitea
  labels:
    app: gitea
spec:
  ports:
  - port: 80
    name: http
  - port: 22
    name: ssh
  clusterIP: None
  selector:
    app: gitea
---
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: gitea
  namespace: gitea
spec:
  tls:
  - hosts:
    - gitea.home.nico-schieder.de
    secretName: gitea-tls
  rules:
  - host: gitea.home.nico-schieder.de
    http:
      paths:
      - path: /
        backend:
          serviceName: gitea-web
          servicePort: http
---
apiVersion: cert-manager.io/v1alpha2
kind: Certificate
metadata:
  name: gitea
  namespace: gitea
spec:
  secretName: gitea-tls
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  dnsNames:
  - gitea.home.nico-schieder.de
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: gitea
  namespace: gitea
spec:
  selector:
    matchLabels:
      app: gitea
  serviceName: gitea-headless
  replicas: 1
  template:
    metadata:
      labels:
        app: gitea
    spec:
      terminationGracePeriodSeconds: 10
      containers:
      - name: gitea
        image: gitea/gitea:1.10.2
        env:
        - name: RUN_MODE
          value: prod
        - name: DISABLE_REGISTRATION
          value: 'true'
        - name: DB_TYPE
          value: postgres
        - name: DB_HOST
          value: 127.0.0.1:5432
        - name: DB_NAME
          value: gitea
        - name: DB_USER
          value: gitea
        - name: DB_PASSWD
          value: gitea
        ports:
        - containerPort: 3000
          name: http
        - containerPort: 22
          name: ssh
        volumeMounts:
        - name: gitea-data
          mountPath: /data
      - name: postgres
        image: postgres:12
        env:
        - name: POSTGRES_USER
          value: gitea
        - name: POSTGRES_PASSWORD
          value: gitea
        - name: POSTGRES_DB
          value: gitea
        volumeMounts:
        - name: postgres-data
          mountPath: /var/lib/postgresql/data
  volumeClaimTemplates:
  - metadata:
      name: gitea-data
    spec:
      accessModes: [ "ReadWriteOnce" ]
      storageClassName: fast-disks
      resources:
        requests:
          storage: 10000Mi
  - metadata:
      name: postgres-data
    spec:
      accessModes: [ "ReadWriteOnce" ]
      storageClassName: fast-disks
      resources:
        requests:
          storage: 5000Mi
```
