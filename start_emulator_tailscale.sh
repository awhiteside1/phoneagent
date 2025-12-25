#!/bin/bash

###############################################################################
# Android Emulator + Tailscale Setup Script
# This script starts an Android emulator and makes it accessible via Tailscale
# VPN for secure remote access from Google Colab or other remote environments.
###############################################################################

set -e  # Exit on error

# Configuration
AVD_NAME="${AVD_NAME:-Pixel_7_API_33}"  # Default AVD name
ADB_PORT="5555"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Android Emulator + Tailscale VPN Setup                  ║${NC}"
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"

# Check if ADB is installed
if ! command -v adb &> /dev/null; then
    echo -e "${RED}❌ ADB not found. Installing...${NC}"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        brew install android-platform-tools
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        sudo apt-get update && sudo apt-get install -y adb
    fi
fi

# Check if emulator is installed
if ! command -v emulator &> /dev/null; then
    echo -e "${RED}❌ Android Emulator not found. Please install Android Studio.${NC}"
    echo "   Download from: https://developer.android.com/studio"
    exit 1
fi

# Check if Tailscale is installed
if ! command -v tailscale &> /dev/null; then
    echo -e "${YELLOW}⚠️  Tailscale not found. Installing...${NC}"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        brew install --cask tailscale
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        curl -fsSL https://tailscale.com/install.sh | sh
    fi
fi

# Check if Tailscale is running and authenticated
echo -e "\n${BLUE}🔐 Checking Tailscale status...${NC}"
if ! tailscale status &> /dev/null; then
    echo -e "${YELLOW}⚠️  Tailscale not running. Starting...${NC}"
    sudo tailscale up
    echo -e "${GREEN}✓ Tailscale started. Please authenticate in your browser.${NC}"
    echo "   Waiting for authentication..."
    sleep 5
fi

# Get Tailscale IP
TAILSCALE_IP=$(tailscale ip -4 2>/dev/null)
if [ -z "$TAILSCALE_IP" ]; then
    echo -e "${RED}❌ Could not get Tailscale IP. Please ensure Tailscale is running and authenticated.${NC}"
    echo "   Run: sudo tailscale up"
    exit 1
fi

echo -e "${GREEN}✓ Tailscale connected${NC}"
echo -e "   Your Tailscale IP: $TAILSCALE_IP"

# List available AVDs
echo -e "\n${BLUE}📱 Available Android Virtual Devices:${NC}"
emulator -list-avds

if ! emulator -list-avds | grep -q "$AVD_NAME"; then
    echo -e "${YELLOW}⚠️  AVD '$AVD_NAME' not found.${NC}"
    echo "Available AVDs:"
    emulator -list-avds
    read -p "Enter AVD name to use: " AVD_NAME
fi

# Kill any existing instances
echo -e "\n${BLUE}🧹 Cleaning up existing instances...${NC}"
adb kill-server 2>/dev/null || true
pkill -9 emulator 2>/dev/null || true
pkill -9 qemu-system 2>/dev/null || true
sleep 2

# Start ADB server
echo -e "\n${BLUE}🔄 Starting ADB server...${NC}"
adb start-server

# Start emulator
echo -e "\n${BLUE}🚀 Starting Android Emulator: $AVD_NAME${NC}"
echo "   This may take 30-60 seconds..."

# Start emulator in background
emulator -avd "$AVD_NAME" \
    -no-snapshot-load \
    -no-boot-anim \
    -gpu auto \
    -memory 4096 \
    > /tmp/emulator.log 2>&1 &

EMULATOR_PID=$!
echo -e "${GREEN}✓ Emulator started (PID: $EMULATOR_PID)${NC}"

# Wait for emulator to boot
echo -e "\n${BLUE}⏳ Waiting for emulator to boot...${NC}"
adb wait-for-device
echo -e "${GREEN}✓ Device detected${NC}"

# Wait for boot to complete
while [ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" != "1" ]; do
    echo -n "."
    sleep 2
done
echo -e "\n${GREEN}✓ Boot completed${NC}"

# Get emulator serial
EMULATOR_SERIAL=$(adb devices | grep emulator | awk '{print $1}' | head -1)
echo -e "${BLUE}📱 Emulator serial: $EMULATOR_SERIAL${NC}"

# Enable TCP/IP mode
echo -e "\n${BLUE}🔧 Enabling ADB over TCP/IP on port $ADB_PORT...${NC}"
adb -s "$EMULATOR_SERIAL" tcpip "$ADB_PORT"
sleep 2

# Connect to emulator via TCP on all interfaces
echo -e "${BLUE}🔗 Connecting to 127.0.0.1:$ADB_PORT...${NC}"
adb connect "127.0.0.1:$ADB_PORT"
sleep 1

# Verify connection
echo -e "\n${GREEN}✓ Connected devices:${NC}"
adb devices -l

# Display success information
echo -e "\n${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                   🎉 SETUP COMPLETE! 🎉                    ║${NC}"
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"

echo -e "\n${BLUE}📱 Emulator Information:${NC}"
echo -e "   Serial:       $EMULATOR_SERIAL"
echo -e "   Local Port:   127.0.0.1:$ADB_PORT"
echo -e "   Status:       Running (PID: $EMULATOR_PID)"

echo -e "\n${BLUE}🔐 Tailscale VPN Information:${NC}"
echo -e "   Your IP:      $TAILSCALE_IP"
echo -e "   ADB Port:     $ADB_PORT"
echo -e "   Full Address: $TAILSCALE_IP:$ADB_PORT"
echo -e "   Status:       Connected"

echo -e "\n${YELLOW}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}║          Copy this for Google Colab:                       ║${NC}"
echo -e "${YELLOW}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}"
cat << EOF

# Step 1: Install Tailscale in Colab
!curl -fsSL https://tailscale.com/install.sh | sh

# Step 2: Authenticate Tailscale (get auth key from https://login.tailscale.com/admin/settings/keys)
# Create a reusable auth key with "Ephemeral" enabled
!tailscale up --authkey=tskey-auth-XXXXXXXXX

# Step 3: Connect to your emulator
TAILSCALE_IP = "$TAILSCALE_IP"
ADB_PORT = "$ADB_PORT"

!adb connect {TAILSCALE_IP}:{ADB_PORT}
!adb devices -l

# Step 4: Test connection
!adb shell getprop ro.build.version.release

EOF
echo -e "${NC}"

# Create a status file
cat > /tmp/emulator_tailscale_status.txt << EOF
Emulator Status
================
AVD Name:      $AVD_NAME
Serial:        $EMULATOR_SERIAL
PID:           $EMULATOR_PID
Local Port:    127.0.0.1:$ADB_PORT

Tailscale VPN
=============
Your IP:       $TAILSCALE_IP
ADB Address:   $TAILSCALE_IP:$ADB_PORT

Connection Command for Colab:
adb connect $TAILSCALE_IP:$ADB_PORT

Auth Key Setup:
1. Go to: https://login.tailscale.com/admin/settings/keys
2. Generate a new auth key with "Ephemeral" and "Reusable" enabled
3. Use in Colab: tailscale up --authkey=YOUR_KEY

Started:       $(date)
EOF

echo -e "${BLUE}📄 Status file saved: /tmp/emulator_tailscale_status.txt${NC}"

echo -e "\n${YELLOW}⚠️  IMPORTANT NOTES:${NC}"
echo -e "   1. Your Tailscale network is private - only your devices can connect"
echo -e "   2. Generate an ephemeral auth key for Colab at:"
echo -e "      https://login.tailscale.com/admin/settings/keys"
echo -e "   3. The emulator must stay running for remote access"
echo -e "   4. Your local machine must stay online"

# Monitor function
echo -e "\n${BLUE}📊 Monitoring emulator...${NC}"
echo -e "${YELLOW}Press Ctrl+C to stop and cleanup${NC}\n"

# Trap Ctrl+C
cleanup() {
    echo -e "\n\n${YELLOW}🛑 Shutting down...${NC}"

    echo -e "${BLUE}Stopping emulator (PID: $EMULATOR_PID)...${NC}"
    kill $EMULATOR_PID 2>/dev/null || true

    echo -e "${BLUE}Killing ADB server...${NC}"
    adb kill-server

    echo -e "${GREEN}✓ Cleanup complete${NC}"
    echo -e "${BLUE}ℹ️  Tailscale is still running in the background${NC}"
    exit 0
}

trap cleanup SIGINT SIGTERM

# Monitor loop
while true; do
    # Check if emulator is still running
    if ! ps -p $EMULATOR_PID > /dev/null 2>&1; then
        echo -e "${RED}❌ Emulator process died${NC}"
        cleanup
    fi

    # Show stats
    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} Status: Emulator ✓ | Tailscale IP: $TAILSCALE_IP"
    sleep 30
done
