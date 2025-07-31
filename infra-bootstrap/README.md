# Infra

```sh
helmfile diff --selector tier=metallb --log-level=debug
helmfile apply --selector tier=metallb --log-level=debug

kubectl apply -n metallb-system -f config/metallb-config.yaml

```


- arc secretRef
```sh
kubectl create secret generic controller-manager \
  -n actions-runner-system \
  --from-literal=github_token=<YOUR_TOKEN>
```