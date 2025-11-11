
### 노드 연결
- 노드 구성
    - k8sm1 : 제어 노드
    - k8sw1 : 데이터 노드

- kubeadm 초기화
    
    ```bash
    sudo kubeadm init --pod-network-cidr=10.0.0.0/16
    ```
    
- kubeadm init 결과로 나온 join 명령어 복사 (k8sw1)
    
    ```bash
    [addons] Applied essential addon: CoreDNS
    [addons] Applied essential addon: kube-proxy
    
    Your Kubernetes control-plane has initialized successfully!
    
    To start using your cluster, you need to run the following as a regular user:
    
        mkdir -p $HOME/.kube
        sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
        sudo chown $(id -u):$(id -g) $HOME/.kube/config
    
    Alternatively, if you are the root user, you can run:
    
        export KUBECONFIG=/etc/kubernetes/admin.conf
    
    You should now deploy a pod network to the cluster.
    Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
        https://kubernetes.io/docs/concepts/cluster-administration/addons/
    
    Then you can join any number of worker nodes by running the following on each as root:
    
    kubeadm join <Control-Plane IP>:6443 --token <Token> --discovery-token-ca-cert-hash <Hash>
    ```
    
- kubeconfig 설정
    
    ```bash
    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config
    ```
    
- join 명령어 다시 확인하기 (k8sm1)

    ```bash
    kubeadm token create --print-join-command
    ```

- 워커 노드 조인 (k8sw1)
    - k8sm1에서 출력한 join 명령어 입력 (k8sw1)
        
        ```bash
        # kubelet 실행 에러(swapoff 관련)로 -> 클린업 후 다시 조인
        sudo kubeadm reset -f # 클러스터 리셋 (이미 모든 kubeadm 관련 파일 지움)
        sudo systemctl stop kubelet
        sudo systemctl stop containerd
        
        # 아래 디렉토리 정리
        sudo rm -rf /etc/kubernetes/
        sudo rm -rf /var/lib/kubelet/
        sudo rm -rf /etc/cni/net.d/
        
        sudo iptables -F
        sudo ipvsadm --clear 2>/dev/null
        
        # containerd 재시작
        sudo systemctl start containerd
        
        ```
        
    - `k get nodes -o wide` (k8sm1)


### 추가 작업
- openlens 연결 중 도메인 문제로 연결이 안됨 (인증서에 Extra-SAN 추가해서 해결)
    
    ```bash
    # /etc/kubernetes/kubeadm-config-san.yaml
    apiVersion: kubeadm.k8s.io/v1beta3
    kind: ClusterConfiguration
    kubernetesVersion: v1.30.14
    controlPlaneEndpoint: "<Cluster IP>:6443"
    apiServer:
        certSANs:
        - <Domain1>
        - <IP1>
    ```
    
    ```bash
    sudo kubeadm init phase certs apiserver --config kubeadm-config-san.yaml
    ```
    
    - [https://blusky10.tistory.com/entry/K8S-api-server-연결시-IP-추가](https://blusky10.tistory.com/entry/K8S-api-server-%EC%97%B0%EA%B2%B0%EC%8B%9C-IP-%EC%B6%94%EA%B0%80) **참고**