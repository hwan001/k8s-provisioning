# Infra

```sh
helmfile diff --selector app=metallb --log-level=debug
helmfile apply --selector app=metallb --log-level=debug
helmfile apply --selector app=n8n --log-level=debug

kubectl apply -n metallb-system -f config/metallb-config.yaml

```


- arc secretRef
```sh
kubectl create secret generic controller-manager \
  -n actions-runner-system \
  --from-literal=github_token=<YOUR_TOKEN>
```

- cert-manager CRD 수동 설치
```sh
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.3/cert-manager.crds.yaml
```