#!/bin/bash
# ---------------------------------------
# VPN 인터페이스 → Istio LoadBalancer VIP 포워딩 설정 (kube-proxy safe)
# ---------------------------------------

set -e

# 🔧 설정값
VPN_IF="wt0"                     # VPN 인터페이스 이름
VPN_PORT=8080                     # VPN에서 수신할 포트
VIP_IP="192.168.11.241"          # MetalLB에서 할당한 VIP
LB_PORT=8080                     # LoadBalancer 서비스 포트
NODE_IF="ens18"                  # VIP가 붙는 실제 NIC
CHAIN_NAME="VPN-FORWARD"         # 커스텀 체인 이름

echo "[+] Setting up VPN port forwarding (chain: $CHAIN_NAME)"
echo "    VPN_IF=$VPN_IF, VPN_PORT=$VPN_PORT → VIP=$VIP_IP:$LB_PORT"

# ---------------------------------------
# 1️⃣ NAT 커스텀 체인 생성 및 연결
# ---------------------------------------

# 체인 생성 (이미 있으면 패스)
iptables -t nat -N $CHAIN_NAME 2>/dev/null || true

# PREROUTING → VPN-FORWARD 연결 (한 번만)
iptables -t nat -C PREROUTING -j $CHAIN_NAME 2>/dev/null \
  || iptables -t nat -A PREROUTING -j $CHAIN_NAME

# NAT 체인 내부 DNAT 규칙 추가
iptables -t nat -C $CHAIN_NAME -i $VPN_IF -p tcp --dport $VPN_PORT \
  -j DNAT --to-destination ${VIP_IP}:${LB_PORT} 2>/dev/null \
  || iptables -t nat -A $CHAIN_NAME -i $VPN_IF -p tcp --dport $VPN_PORT \
  -j DNAT --to-destination ${VIP_IP}:${LB_PORT}

# ---------------------------------------
# 2️⃣ FORWARD 체인 규칙 (양방향 허용)
# ---------------------------------------

iptables -C FORWARD -i $VPN_IF -o $NODE_IF -p tcp -d $VIP_IP --dport $LB_PORT -j ACCEPT 2>/dev/null \
  || iptables -A FORWARD -i $VPN_IF -o $NODE_IF -p tcp -d $VIP_IP --dport $LB_PORT -j ACCEPT

iptables -C FORWARD -o $VPN_IF -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT 2>/dev/null \
  || iptables -A FORWARD -o $VPN_IF -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# ---------------------------------------
# 3️⃣ POSTROUTING SNAT (응답 방향)
# ---------------------------------------

iptables -t nat -C POSTROUTING -o $NODE_IF -p tcp -d $VIP_IP --dport $LB_PORT -j MASQUERADE 2>/dev/null \
  || iptables -t nat -A POSTROUTING -o $NODE_IF -p tcp -d $VIP_IP --dport $LB_PORT -j MASQUERADE

# ---------------------------------------
# 4️⃣ INPUT 허용 (선택적)
# ---------------------------------------

iptables -C INPUT -i $VPN_IF -p tcp --dport $VPN_PORT -j ACCEPT 2>/dev/null \
  || iptables -A INPUT -i $VPN_IF -p tcp --dport $VPN_PORT -j ACCEPT

# ---------------------------------------
# ✅ 검증 출력
# ---------------------------------------

echo
echo "[+] Current rules summary:"
iptables -t nat -L $CHAIN_NAME -n -v
echo
iptables -t nat -L PREROUTING -n -v | grep $CHAIN_NAME || echo "Chain not linked to PREROUTING"
echo
iptables -t nat -L POSTROUTING -n -v | grep $VIP_IP || echo "No SNAT entries found"
echo
iptables -L FORWARD -n -v | egrep "$VPN_IF|$VIP_IP" || echo "No forward entries found"
echo
echo "[✓] VPN forwarding rule applied and isolated in chain '$CHAIN_NAME'."