```bash
# 설치
brew install kustomize  # 또는 wget 등

# 빌드된 최종 YAML 출력
kustomize build ./my-kustomize/

# kubectl과 연결해서 적용
kustomize build ./my-kustomize/ | kubectl apply -f -
```

```bash
# k 옵션
kubectl apply -k ./flux/kustomization-crds/

```

```bash
# ns 라벨링 체크
kubectl get ns --show-labels

# 수동 라벨링
kubectl label namespace n8n istio-injection=enabled --overwrite

# 라벨 체크
kubectl get pods -n n8n -o jsonpath='{range .items[*]}{.metadata.name} → {range .spec.containers[*]}{.name} {" "}{end}{"\n"}{end}'

# 예시 output ) n8n-xxxxxxxx → n8n istio-proxy

# 사이드카 자동 주입 유도 
kubectl rollout restart deployment -n n8n
```

```bash
# core dns 리스타트
kubectl rollout restart deployment coredns -n kube-system
```

```bash
# istio 인증서 발급 (istio-gw랑 같은 namespace)
kubectl -n istio-ingress get secret istio-ingress-avgmax-cert

# 인증서 생성
kubectl create -n istio-ingress secret tls istio-ingress-avgmax-cert \
  --cert=avgmax.pem \
  --key=avgmax.key

# 인증서 업데이트
kubectl -n istio-ingress create secret tls istio-ingress-avgmax-cert \
  --cert=your-updated-cert.pem \
  --key=your-updated-key.key \
  --dry-run=client -o yaml | kubectl apply -f -

# 재시작
kubectl rollout restart deployment ingress -n istio-ingress
```


### secret
```
# harbor-cred
kubectl -n testrtc create secret docker-registry harbor-creds \
  --docker-server=harbor.avgmax.team \
  --docker-username='admin' \
  --docker-password=PASSWORD'
```