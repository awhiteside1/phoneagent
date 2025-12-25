#!/bin/bash

###############################################################################
# Android Emulator + ngrok Tunnel Setup Script
# This script starts an Android emulator and exposes it via ngrok for remote
# access from Google Colab or other remote environments.
###############################################################################

set -e  # Exit on error

# Configuration
AVD_NAME="${AVD_NAME:-Pixel_7_API_33}"  # Default AVD name, override with env var
ADB_PORT="5555"
NGROK_REGION="${NGROK_REGION:-us}"  # us, eu, ap, au, sa, jp, in

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Android Emulator + ngrok Tunnel Setup                   ║${NC}"
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"

# Check if ADB is installed
if ! command -v adb &> /dev/null; then
    echo -e "${RED}❌ ADB not found. Please install Android SDK Platform-Tools.${NC}"
    echo "   macOS: brew install android-platform-tools"
    echo "   Linux: sudo apt-get install adb"
    exit 1
fi

# Check if emulator is installed
if ! command -v emulator &> /dev/null; then
    echo -e "${RED}❌ Android Emulator not found. Please install Android Studio.${NC}"
    echo "   Download from: https://developer.android.com/studio"
    exit 1
fi

# Check if ngrok is installed
if ! command -v ngrok &> /dev/null; then
    echo -e "${RED}❌ ngrok not found. Installing...${NC}"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        brew install ngrok
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "Please install ngrok manually: https://ngrok.com/download"
        exit 1
    fi
fi

# Check if ngrok is authenticated
if ! ngrok config check &> /dev/null; then
    echo -e "${YELLOW}⚠️  ngrok not authenticated.${NC}"
    echo "Get your auth token from: https://dashboard.ngrok.com/get-started/your-authtoken"
    read -p "Enter your ngrok auth token: " NGROK_TOKEN
    ngrok config add-authtoken "$NGROK_TOKEN"
fi

# List available AVDs
echo -e "\n${BLUE}📱 Available Android Virtual Devices:${NC}"
emulator -list-avds

if ! emulator -list-avds | grep -q "$AVD_NAME"; then
    echo -e "${YELLOW}⚠️  AVD '$AVD_NAME' not found.${NC}"
    echo "Available AVDs:"
    emulator -list-avds
    read -p "Enter AVD name to use: " AVD_NAME
fi

# Kill any existing emulator instances
echo -e "\n${BLUE}🧹 Cleaning up existing instances...${NC}"
adb kill-server 2>/dev/null || true
pkill -9 emulator 2>/dev/null || true
pkill -9 qemu-system 2>/dev/null || true
pkill -9 ngrok 2>/dev/null || true
sleep 2

# Start ADB server
echo -e "\n${BLUE}🔄 Starting ADB server...${NC}"
adb start-server

# Start emulator
echo -e "\n${BLUE}🚀 Starting Android Emulator: $AVD_NAME${NC}"
echo "   This may take 30-60 seconds..."

# Start emulator in background with optimized settings
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

# Connect to emulator via TCP
echo -e "${BLUE}🔗 Connecting to 127.0.0.1:$ADB_PORT...${NC}"
adb connect "127.0.0.1:$ADB_PORT"
sleep 1

# Verify connection
echo -e "\n${GREEN}✓ Connected devices:${NC}"
adb devices -l

# Start ngrok tunnel
echo -e "\n${BLUE}🌐 Starting ngrok tunnel on port $ADB_PORT...${NC}"
ngrok tcp "$ADB_PORT" --region="$NGROK_REGION" > /tmp/ngrok.log 2>&1 &
NGROK_PID=$!
echo -e "${GREEN}✓ ngrok started (PID: $NGROK_PID)${NC}"

# Wait for ngrok to start
sleep 3

# Get ngrok public URL
echo -e "\n${BLUE}🔍 Retrieving ngrok public URL...${NC}"
NGROK_URL=$(curl -s http://localhost:4040/api/tunnels | grep -o '"public_url":"tcp://[^"]*' | cut -d'"' -f4 | head -1)

if [ -z "$NGROK_URL" ]; then
    echo -e "${RED}❌ Failed to get ngrok URL. Check logs: /tmp/ngrok.log${NC}"
    exit 1
fi

# Parse host and port
NGROK_HOST=$(echo "$NGROK_URL" | sed 's|tcp://||' | cut -d: -f1)
NGROK_PORT=$(echo "$NGROK_URL" | sed 's|tcp://||' | cut -d: -f2)

# Display success information
echo -e "\n${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                   🎉 SETUP COMPLETE! 🎉                    ║${NC}"
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "\n${BLUE}📱 Emulator Information:${NC}"
echo -e "   Serial:       $EMULATOR_SERIAL"
echo -e "   Local Port:   127.0.0.1:$ADB_PORT"
echo -e "   Status:       Running (PID: $EMULATOR_PID)"

echo -e "\n${BLUE}🌐 ngrok Tunnel Information:${NC}"
echo -e "   Public URL:   $NGROK_URL"
echo -e "   Host:         $NGROK_HOST"
echo -e "   Port:         $NGROK_PORT"
echo -e "   Status:       Running (PID: $NGROK_PID)"
echo -e "   Dashboard:    http://localhost:4040"

echo -e "\n${YELLOW}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}║          Copy this for Google Colab:                       ║${NC}"
echo -e "${YELLOW}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}"
cat << EOF

# Paste this in your Google Colab notebook:
NGROK_HOST = "$NGROK_HOST"
NGROK_PORT = "$NGROK_PORT"

!adb connect {NGROK_HOST}:{NGROK_PORT}
!adb devices -l

EOF
echo -e "${NC}"

# Create a status file
cat > /tmp/emulator_tunnel_status.txt << EOF
Emulator Status
================
AVD Name:      $AVD_NAME
Serial:        $EMULATOR_SERIAL
PID:           $EMULATOR_PID
Local Port:    127.0.0.1:$ADB_PORT

ngrok Tunnel
============
Public URL:    $NGROK_URL
Host:          $NGROK_HOST
Port:          $NGROK_PORT
PID:           $NGROK_PID
Dashboard:     http://localhost:4040

Connection Command for Colab:
adb connect $NGROK_HOST:$NGROK_PORT

Started:       $(date)
EOF

echo -e "${BLUE}📄 Status file saved: /tmp/emulator_tunnel_status.txt${NC}"

# Monitor function
echo -e "\n${BLUE}📊 Monitoring emulator and tunnel...${NC}"
echo -e "${YELLOW}Press Ctrl+C to stop and cleanup${NC}\n"

# Trap Ctrl+C
cleanup() {
    echo -e "\n\n${YELLOW}🛑 Shutting down...${NC}"

    echo -e "${BLUE}Stopping ngrok (PID: $NGROK_PID)...${NC}"
    kill $NGROK_PID 2>/dev/null || true

    echo -e "${BLUE}Stopping emulator (PID: $EMULATOR_PID)...${NC}"
    kill $EMULATOR_PID 2>/dev/null || true

    echo -e "${BLUE}Killing ADB server...${NC}"
    adb kill-server

    echo -e "${GREEN}✓ Cleanup complete${NC}"
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

    # Check if ngrok is still running
    if ! ps -p $NGROK_PID > /dev/null 2>&1; then
        echo -e "${RED}❌ ngrok process died${NC}"
        cleanup
    fi

    # Show stats every 30 seconds
    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} Status: Emulator ✓ | ngrok ✓ | Dashboard: http://localhost:4040"
    sleep 30
done
