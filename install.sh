#!/bin/bash
set -e

echo "=========================================="
echo "🚀 Installing Docker and Trivy (latest versions)"
echo "=========================================="

# Update system
sudo apt-get update -y

# -------------------------------
# 🐳 Install Docker
# -------------------------------
if ! command -v docker &> /dev/null; then
    echo "🔧 Installing Docker..."
    sudo apt-get install -y ca-certificates curl gnupg lsb-release

    # Add Docker's official GPG key
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

    # Add Docker repository
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
      https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Install Docker engine
    sudo apt-get update -y
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Enable & start Docker
    sudo systemctl enable docker
    sudo systemctl start docker

    echo "✅ Docker installation complete!"
else
    echo "✅ Docker is already installed."
fi

# -------------------------------
# 🔍 Install Trivy
# -------------------------------
if ! command -v trivy &> /dev/null; then
    echo "🔧 Installing Trivy..."
    sudo apt-get install -y wget apt-transport-https gnupg lsb-release

    wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
    echo deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main | sudo tee /etc/apt/sources.list.d/trivy.list

    sudo apt-get update -y
    sudo apt-get install -y trivy

    echo "✅ Trivy installation complete!"
else
    echo "✅ Trivy is already installed."
fi

# -------------------------------
# 🔢 Version Checks
# -------------------------------
echo
echo "=========================================="
echo "📦 Installed Versions"
echo "=========================================="
docker --version
trivy --version

# -------------------------------
# 🧾 File System Scan
# -------------------------------
echo
echo "=========================================="
echo "🕵️ Running Trivy File System Scan in Current Directory"
echo "=========================================="

trivy fs .

echo
echo "✅ Installation and file scan completed successfully!"
echo "=========================================="
# now update its