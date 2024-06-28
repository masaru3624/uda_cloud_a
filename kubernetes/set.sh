#!/bin/bash

# Vagrant環境の初期化と起動
vagrant up --provider=virtualbox

# VagrantボックスへのSSH接続
vagrant ssh << EOF

# ルートユーザーに切り替え
sudo su -

# k3sのインストール
curl -sfL https://get.k3s.io | sh -

# ノードの確認
kubectl get nodes

# ディレクトリの作成
mkdir -p .vagrant/kubernetes
mkdir -p .vagrant/screenshots

# namespace.yamlの作成
cat << 'EOT' > .vagrant/kubernetes/namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: sandbox
EOT

# deploy.yamlの作成
cat << 'EOT' > .vagrant/kubernetes/deploy.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: techtrends
  namespace: sandbox
spec:
  replicas: 1
  selector:
    matchLabels:
      app: techtrends
  template:
    metadata:
      labels:
        app: techtrends
    spec:
      containers:
      - name: techtrends
        image: techtrends:latest
        ports:
        - containerPort: 3111
        resources:
          requests:
            memory: "64Mi"
            cpu: "250m"
          limits:
            memory: "128Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /healthz
            port: 3111
        readinessProbe:
          httpGet:
            path: /healthz
            port: 3111
EOT

# service.yamlの作成
cat << 'EOT' > .vagrant/kubernetes/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: techtrends
  namespace: sandbox
spec:
  selector:
    app: techtrends
  ports:
    - protocol: TCP
      port: 4111
      targetPort: 3111
  type: ClusterIP
EOT

# Namespaceの作成
kubectl apply -f .vagrant/kubernetes/namespace.yaml

# Deploymentの作成
kubectl apply -f .vagrant/kubernetes/deploy.yaml

# Serviceの作成
kubectl apply -f .vagrant/kubernetes/service.yaml

# sandboxネームスペース内のすべてのリソースを確認
kubectl get all -n sandbox

EOF

echo "Setup complete."
