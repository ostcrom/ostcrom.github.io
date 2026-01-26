#!/usr/bin/env bash

set -e

CONFIG_FILE="/etc/rancher/k3s/registries.yaml"
ALIAS_NAME="registry.local"

echo "=== k3s Registry Alias Configuration ==="
echo

read -rp "Enter REAL registry hostname (e.g. registry.internal.local): " REAL_HOST

if [[ -z "$REAL_HOST" ]]; then
  echo "❌ Hostname cannot be empty"
  exit 1
fi

echo
echo "This will map:"
echo "  $ALIAS_NAME  ➜  https://$REAL_HOST"
echo

read -rp "Continue? (y/N): " CONFIRM
[[ "$CONFIRM" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }

echo
echo "📄 Writing config to $CONFIG_FILE"

sudo mkdir -p /etc/rancher/k3s

sudo tee "$CONFIG_FILE" > /dev/null <<EOF
mirrors:
  "$ALIAS_NAME":
    endpoint:
      - "https://$REAL_HOST"

configs:
  "$REAL_HOST":
    tls:
      insecure_skip_verify: true
EOF

echo "✅ Config written."

echo
echo "🔄 Restarting k3s service..."

if systemctl list-units --full -all | grep -Fq 'k3s.service'; then
  sudo systemctl restart k3s
elif systemctl list-units --full -all | grep -Fq 'k3s-agent.service'; then
  sudo systemctl restart k3s-agent
else
  echo "⚠️ Could not detect k3s service name. Restart manually."
  exit 1
fi

echo
echo "🎉 Done!"
echo
echo "You can now use this image name in Jenkins:"
echo
echo "  image: $ALIAS_NAME/your-builder:latest"
echo
echo "Test with:"
echo "  kubectl run test --rm -it --image=$ALIAS_NAME/your-builder:latest -- sh"

