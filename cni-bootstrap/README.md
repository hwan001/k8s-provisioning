# CNI

## calico
- 최소 옵션으로 helm 설치 후 calicoctl로 제어
- calico-node 로그 확인
```sh
kubectl logs -n calico-system calico-node-xxx
```
- XDP/bPF 옵션 끄기
```sh
kubectl patch felixconfiguration default \
  --type merge \
  -p '{"spec": {"bpfEnabled": false, "xdpEnabled": false}}'

kubectl rollout restart daemonset calico-node -n calico-system
```
```sh
calicoctl patch felixconfiguration default \
  -p '{"spec": {"bpfEnabled": false, "xdpEnabled": false}}'
```


## cilium 

### tunnel 방식
- 설치 시 kube-apiserver 연결 실패 문제

### native 방식
- 설치 시 kube-apiserver 연결 실패하고, 클러스터가 고립되는 문제 발생