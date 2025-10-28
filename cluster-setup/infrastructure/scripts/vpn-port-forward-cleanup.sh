#!/bin/bash
# ---------------------------------------
# VPN → Istio LoadBalancer VIP iptables 규칙 제거 (kube-proxy-safe)
# ---------------------------------------

set -e

VPN_IF="wt0"
VPN_PORT=8080
VIP_IP="192.168.11.241"   # MetalLB VIP
LB_PORT=8080
NODE_IF="ens18"           # 실제 NIC
CHAIN_NAME="VPN-FORWARD"

echo "[x] Removing VPN port forwarding rules (chain: $CHAIN_NAME)"
echo "    VPN_IF=$VPN_IF, VPN_PORT=$VPN_PORT → VIP=$VIP_IP:$LB_PORT"

# ---------------------------------------
# 1️⃣ NAT 커스텀 체인 규칙 제거
# ---------------------------------------

if iptables -t nat -L $CHAIN_NAME -n &>/dev/null; then
  # DNAT 룰 제거
  iptables -t nat -D $CHAIN_NAME -i $VPN_IF -p tcp --dport $VPN_PORT \
    -j DNAT --to-destination ${VIP_IP}:${LB_PORT} 2>/dev/null || true

  # 체인이 비었으면 삭제
  RULE_COUNT=$(iptables -t nat -L $CHAIN_NAME -n | grep -vE 'Chain|target' | wc -l)
  if [ "$RULE_COUNT" -eq 0 ]; then
    echo "[x] Chain $CHAIN_NAME empty, deleting..."
    iptables -t nat -D PREROUTING -j $CHAIN_NAME 2>/dev/null || true
    iptables -t nat -F $CHAIN_NAME 2>/dev/null || true
    iptables -t nat -X $CHAIN_NAME 2>/dev/null || true
  fi
else
  echo "[i] Chain $CHAIN_NAME does not exist, skipping."
fi

# ---------------------------------------
# 2️⃣ SNAT (POSTROUTING)
# ---------------------------------------

iptables -t nat -D POSTROUTING -o $NODE_IF -p tcp -d $VIP_IP --dport $LB_PORT \
  -j MASQUERADE 2>/dev/null || true

# ---------------------------------------
# 3️⃣ FORWARD (요청/응답)
# ---------------------------------------

iptables -D FORWARD -i $VPN_IF -o $NODE_IF -p tcp -d $VIP_IP --dport $LB_PORT \
  -j ACCEPT 2>/dev/null || true

iptables -D FORWARD -o $VPN_IF -m conntrack --ctstate ESTABLISHED,RELATED \
  -j ACCEPT 2>/dev/null || true

# ---------------------------------------
# 4️⃣ INPUT (optional)
# ---------------------------------------

iptables -D INPUT -i $VPN_IF -p tcp --dport $VPN_PORT -j ACCEPT 2>/dev/null || true

# ---------------------------------------
# ✅ 검증 출력
# ---------------------------------------

echo
echo "[x] Cleanup complete. Current iptables state:"
iptables -t nat -L PREROUTING -n -v | grep $CHAIN_NAME || echo "No PREROUTING chain link found"
iptables -t nat -L POSTROUTING -n -v | grep $VIP_IP || echo "No POSTROUTING entries found"
iptables -L FORWARD -n -v | grep $VPN_IF || echo "No FORWARD entries found"
echo
echo "[✓] VPN forwarding rules fully removed."