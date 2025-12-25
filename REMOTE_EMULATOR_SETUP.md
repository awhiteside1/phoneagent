# Running Android Emulator Locally with Colab via Network Tunnel

This guide explains how to run an Android emulator on your local machine and connect to it from Google Colab using ngrok or Tailscale.

## Overview

```
┌─────────────────────┐         ┌──────────────┐         ┌─────────────────┐
│  Your Local Machine │────────▶│ ngrok/       │────────▶│  Google Colab   │
│                     │         │ Tailscale    │         │                 │
│  - Android Emulator │         │  (Tunnel)    │         │  - AutoGLM      │
│  - ADB Server       │         │              │         │  - ADB Client   │
└─────────────────────┘         └──────────────┘         └─────────────────┘
```

## Why This Works

- ADB supports **TCP/IP connections** (not just USB)
- ngrok/Tailscale can **tunnel TCP ports** over the internet
- Colab can **connect to remote ADB servers** using `adb connect`

## Prerequisites

### On Your Local Machine:
- Android Studio (includes emulator and ADB)
- ngrok account (free tier works) OR Tailscale account
- Terminal access

### On Google Colab:
- The enhanced AutoGLM notebook
- Internet connection (obviously!)

---

## Method 1: Using ngrok (Easier, Free Tier Available)

### Pros:
✅ Simple setup
✅ Free tier available
✅ Works through firewalls
✅ No VPN configuration needed

### Cons:
❌ URL changes each restart (on free tier)
❌ Slight latency
❌ Public endpoint (use authentication)

### Step-by-Step Setup

#### Part A: Local Machine Setup

**1. Install Android Studio and Emulator**

```bash
# macOS (using Homebrew)
brew install --cask android-studio

# Or download from: https://developer.android.com/studio
```

**2. Create and Start an Android Emulator**

```bash
# List available emulators
emulator -list-avds

# If none exist, create one via Android Studio:
# Tools → Device Manager → Create Device → Pixel 7 → Download System Image (API 33) → Finish

# Start emulator (replace with your AVD name)
emulator -avd Pixel_7_API_33 &

# Wait for it to boot (30-60 seconds)
adb wait-for-device
echo "Emulator is ready!"
```

**3. Enable ADB over TCP/IP**

```bash
# Find the emulator device
adb devices

# You should see something like:
# emulator-5554   device

# Enable TCP/IP on port 5555
adb -s emulator-5554 tcpip 5555

# Verify it's listening
adb connect 127.0.0.1:5555
adb devices

# You should now see:
# 127.0.0.1:5555  device
```

**4. Install and Configure ngrok**

```bash
# Install ngrok
# macOS
brew install ngrok

# Linux
curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | \
  sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null && \
  echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | \
  sudo tee /etc/apt/sources.list.d/ngrok.list && \
  sudo apt update && sudo apt install ngrok

# Windows (using Chocolatey)
choco install ngrok

# Or download from: https://ngrok.com/download
```

**5. Authenticate ngrok** (get your token from https://dashboard.ngrok.com/get-started/your-authtoken)

```bash
ngrok config add-authtoken YOUR_AUTH_TOKEN
```

**6. Start ngrok tunnel**

```bash
# Expose ADB port 5555
ngrok tcp 5555
```

**You'll see output like:**
```
Session Status                online
Account                       your@email.com
Version                       3.x.x
Region                        United States (us)
Forwarding                    tcp://0.tcp.ngrok.io:12345 -> localhost:5555
```

**📝 IMPORTANT: Copy the forwarding URL!**
- Example: `0.tcp.ngrok.io:12345`
- You'll need this for Colab

#### Part B: Google Colab Setup

**1. In your Colab notebook, add this cell:**

```python
# Connect to remote Android emulator via ngrok
import subprocess

# Replace with your ngrok URL (without tcp://)
NGROK_HOST = "0.tcp.ngrok.io"
NGROK_PORT = "12345"

print(f"🔄 Connecting to remote emulator at {NGROK_HOST}:{NGROK_PORT}...")

# Connect to remote ADB server
result = subprocess.run(
    ["adb", "connect", f"{NGROK_HOST}:{NGROK_PORT}"],
    capture_output=True,
    text=True
)

print(result.stdout)
print(result.stderr)

# Verify connection
print("\n📱 Connected devices:")
!adb devices -l

# Test the connection
print("\n✅ Testing connection...")
!adb shell getprop ro.build.version.release
```

**2. Run AutoGLM commands normally!**

```python
# Configure AutoGLM
BASE_URL = "your-api-url"
MODEL_NAME = "your-model"
API_KEY = "your-api-key"

# Run AutoGLM task
!python main.py --base-url {BASE_URL} --model {MODEL_NAME} "Open Chrome and search for cats"
```

---

## Method 2: Using Tailscale (More Secure, Better for Long Sessions)

### Pros:
✅ Encrypted VPN connection
✅ Stable IP addresses
✅ No public endpoints
✅ Better security
✅ Free for personal use

### Cons:
❌ Requires Tailscale on both ends
❌ Slightly more complex setup
❌ Need to install Tailscale agent

### Step-by-Step Setup

#### Part A: Local Machine Setup

**1. Install Tailscale**

```bash
# macOS
brew install --cask tailscale

# Linux (Ubuntu/Debian)
curl -fsSL https://tailscale.com/install.sh | sh

# Windows
# Download from: https://tailscale.com/download
```

**2. Start Tailscale and Login**

```bash
# Start Tailscale
sudo tailscale up

# This will give you a URL to authenticate
# Open the URL in your browser and login
```

**3. Get Your Tailscale IP**

```bash
tailscale ip -4

# You'll get something like: 100.x.x.x
# Save this IP!
```

**4. Setup Android Emulator** (same as ngrok method)

```bash
# Start emulator
emulator -avd Pixel_7_API_33 &
adb wait-for-device

# Enable TCP/IP
adb -s emulator-5554 tcpip 5555
adb connect 127.0.0.1:5555
```

#### Part B: Google Colab Setup

**1. Install Tailscale in Colab**

```python
# Install Tailscale in Colab
!curl -fsSL https://tailscale.com/install.sh | sh

# Start Tailscale (you'll need to authenticate)
!tailscale up --authkey=YOUR_AUTH_KEY

# Get auth key from: https://login.tailscale.com/admin/settings/keys
```

**2. Connect to Your Local Machine**

```python
# Your local machine's Tailscale IP
LOCAL_IP = "100.x.x.x"  # Replace with your Tailscale IP
ADB_PORT = "5555"

print(f"🔄 Connecting to {LOCAL_IP}:{ADB_PORT}...")

# Connect via Tailscale
!adb connect {LOCAL_IP}:{ADB_PORT}

# Verify
print("\n📱 Connected devices:")
!adb devices -l
```

---

## Automated Setup Scripts

### Local Machine: `start_emulator_tunnel.sh`

I'll create this script for you in the next step...

---

## Security Considerations

### ngrok:
- Free tier URLs are **public** (anyone with URL can connect)
- Use ngrok's authentication features for production
- URLs change on each restart (free tier)

### Tailscale:
- **Private VPN** - only your devices can connect
- End-to-end encrypted
- Better for sensitive operations
- Recommended for production use

---

## Troubleshooting

### "Connection refused"
```bash
# On local machine, verify ADB is listening:
netstat -an | grep 5555

# Should show:
# tcp        0      0 0.0.0.0:5555            0.0.0.0:*               LISTEN
```

### "Device offline"
```bash
# Restart ADB on local machine:
adb kill-server
adb start-server
adb tcpip 5555
```

### "Cannot connect to ngrok"
```bash
# Check ngrok is running:
curl http://localhost:4040/api/tunnels

# Restart ngrok:
pkill ngrok
ngrok tcp 5555
```

### "Emulator not responding"
```bash
# Cold boot the emulator:
emulator -avd Pixel_7_API_33 -no-snapshot-load &
```

---

## Performance Tips

1. **Use a powerful emulator image**:
   - x86_64 images are faster than ARM
   - Enable hardware acceleration
   - Allocate sufficient RAM (4GB+)

2. **Optimize network**:
   - Use wired connection for local machine
   - Close unnecessary applications
   - Use Tailscale for lower latency

3. **Keep emulator running**:
   - Don't close emulator between tasks
   - Use snapshot save/restore

---

## Cost Comparison

### ngrok Free Tier:
- ✅ 1 online ngrok process
- ✅ 40 connections/minute
- ❌ Random URLs (change on restart)
- ❌ No custom domains

### ngrok Paid ($8/month):
- ✅ Static domains
- ✅ More connections
- ✅ Authentication support

### Tailscale:
- ✅ Free for personal use (up to 100 devices)
- ✅ All features included
- ✅ Unlimited connections

**Recommendation**: Start with ngrok free to test, then use Tailscale for regular use.

---

## Next Steps

1. Choose your tunneling method (ngrok or Tailscale)
2. Follow the setup steps above
3. Use the automated scripts (coming next)
4. Test the connection
5. Run AutoGLM from Colab!
