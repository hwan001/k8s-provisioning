- 노드 공통작업
    - swap 비활성화
        
        ```bash
        sudo swapoff -a
        sudo sed -i '/ swap / s/^/#/' /etc/fstab # 재부팅 시에도 swap off
        ```
        
    - 커널 모듈 및 sysctl 설정
        
        ```bash
        sudo modprobe overlay
        sudo modprobe br_netfilter
        
        sudo tee /etc/sysctl.d/k8s.conf <<EOF
        net.bridge.bridge-nf-call-iptables  = 1
        net.bridge.bridge-nf-call-ip6tables = 1
        net.ipv4.ip_forward                 = 1
        EOF
        
        sudo sysctl --system
        ```
        
    - 필요한 패키지 설치 및 containerd 설정
        
        ```bash
        sudo apt update
        sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
        
        # containerd 설치
        sudo apt install -y containerd
        
        # 기본 config 생성 및 systemd 사용 설정
        sudo mkdir -p /etc/containerd
        containerd config default | sudo tee /etc/containerd/config.toml > /dev/null
        sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
        
        sudo systemctl restart containerd
        sudo systemctl enable containerd
        ```
        
- k8s 설치 (모든 노드)
    - GPG 키, repo 추가
        
        ```bash
        sudo curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
        
        echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list
        
        sudo apt update
        ```
        
    - kubeadm, kubelet, kubectl 설치
        
        ```bash
        sudo apt install -y kubelet kubeadm kubectl
        sudo apt-mark hold kubelet kubeadm kubectl
        ```
        
- 재부팅 : `reboot`