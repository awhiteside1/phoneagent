# AutoGLM with Remote Emulator - Quick Start Guide

Run AutoGLM in Google Colab connected to an Android emulator on your local machine!

## 🎯 What You'll Achieve

```
Your Local Machine          Internet Cloud          Google Colab
┌─────────────────┐         ┌──────────┐         ┌─────────────────┐
│ Android         │────────▶│ ngrok or │────────▶│ AutoGLM         │
│ Emulator        │         │Tailscale │         │ Running Tasks   │
└─────────────────┘         └──────────┘         └─────────────────┘
```

**Result**: Control an Android phone from Colab using AI!

---

## ⚡ Quick Start (5 Minutes)

### Step 1: Choose Your Tunnel Method

**Option A: ngrok** (Easier, good for testing)
- Free tier available
- Setup in 2 minutes
- URL changes each restart

**Option B: Tailscale** (Better for production)
- More secure (private VPN)
- Stable connection
- Free for personal use

---

## 🚀 Method A: Using ngrok (Recommended for First Time)

### On Your Local Machine:

**1. Download the setup script**

The script is in your `phoneagent` directory:
- `start_emulator_ngrok.sh`

**2. Make it executable and run**

```bash
cd /Users/awhiteside/Development/personal/phoneagent
chmod +x start_emulator_ngrok.sh
./start_emulator_ngrok.sh
```

**3. Wait for the script to complete**

You'll see output like:
```
╔════════════════════════════════════════════════════════════╗
║                   🎉 SETUP COMPLETE! 🎉                    ║
╔════════════════════════════════════════════════════════════╗

🌐 ngrok Tunnel Information:
   Host:         0.tcp.ngrok.io
   Port:         12345

Copy this for Google Colab:

NGROK_HOST = "0.tcp.ngrok.io"
NGROK_PORT = "12345"
```

**4. Copy the NGROK_HOST and NGROK_PORT values**

### In Google Colab:

**1. Upload the notebook**
- Go to https://colab.research.google.com
- File → Upload notebook
- Select: `AutoGLM_Colab_Remote.ipynb`

**2. Run cells in order:**
- Run Steps 1-4 (Installation)
- Run Step 5 (Configure your API)
- Run **Option A: Connect via ngrok**
  - Paste your NGROK_HOST and NGROK_PORT
  - Run the cell

**3. Test the connection:**
```python
!adb devices -l
```

You should see your emulator!

**4. Run AutoGLM tasks:**
```python
!python main.py --base-url YOUR_API --model YOUR_MODEL "Open Chrome"
```

---

## 🔒 Method B: Using Tailscale (For Longer Sessions)

### On Your Local Machine:

**1. Run the Tailscale setup script**

```bash
cd /Users/awhiteside/Development/personal/phoneagent
chmod +x start_emulator_tailscale.sh
./start_emulator_tailscale.sh
```

**2. Authenticate Tailscale** (first time only)
- Script will open a browser
- Login to Tailscale
- Authorize the device

**3. Copy your Tailscale IP**

From the script output:
```
Your IP:      100.64.1.23
```

**4. Create a Tailscale auth key**
- Go to: https://login.tailscale.com/admin/settings/keys
- Generate new key
- Enable: ✓ Ephemeral ✓ Reusable
- Copy the key (starts with `tskey-auth-`)

### In Google Colab:

**1. Upload notebook** (same as ngrok method)

**2. Run installation cells** (Steps 1-5)

**3. Run Option B: Connect via Tailscale**
- Cell 1: Install Tailscale
- Cell 2: Paste your auth key
- Cell 3: Paste your local machine's Tailscale IP

**4. Run AutoGLM** tasks normally!

---

## 📋 Complete File List

You now have these files:

```
phoneagent/
├── AutoGLM_Colab_Setup.ipynb          # Basic installation (no remote)
├── AutoGLM_Colab_Remote.ipynb         # With remote emulator support ⭐
├── start_emulator_ngrok.sh            # Local setup with ngrok ⭐
├── start_emulator_tailscale.sh        # Local setup with Tailscale ⭐
├── REMOTE_EMULATOR_SETUP.md           # Detailed guide
├── COLAB_DEBUGGING_GUIDE.md           # Troubleshooting help
└── QUICK_START.md                     # This file
```

**⭐ = Main files you'll use**

---

## 🎬 Complete Workflow Example

### Scenario: Test AutoGLM from Colab with local emulator

**1. Local Machine - Terminal 1:**
```bash
cd ~/Development/personal/phoneagent
./start_emulator_ngrok.sh
# Wait for setup to complete
# Copy the NGROK_HOST and NGROK_PORT
```

**2. Google Colab - New Notebook:**
```python
# Upload AutoGLM_Colab_Remote.ipynb

# Run installation cells (1-4)
# Takes ~3 minutes

# Run API configuration (Step 5)
BASE_URL = "https://api.z.ai/v1"
MODEL_NAME = "glm-4v-plus"
API_KEY = "your-api-key"

# Connect via ngrok (Option A)
NGROK_HOST = "0.tcp.ngrok.io"  # From your local terminal
NGROK_PORT = "12345"            # From your local terminal

!adb connect {NGROK_HOST}:{NGROK_PORT}
!adb devices  # Should show connected device

# Run a task!
!python main.py --base-url {BASE_URL} --model {MODEL_NAME} \
  "Open Chrome and search for Python tutorials"
```

**3. Watch your local emulator!**
- You'll see the actions happen in real-time
- AutoGLM controls it from Colab

---

## 💰 Cost Breakdown

### Free Option (Good for testing):
- ✅ ngrok free tier (random URL)
- ✅ Google Colab free tier
- ✅ Local emulator (free)
- ✅ Tailscale personal (free)
- 💵 API calls (pay per use)

**Total upfront cost: $0**

### Paid Options (For heavy use):
- ngrok Pro: $8/month (static URLs)
- Colab Pro: $10/month (better GPUs, longer sessions)
- Vision model APIs: varies by provider

---

## 🐛 Troubleshooting

### "Connection refused" in Colab

**Check:**
1. Is your local script still running?
2. Did the ngrok URL change? (free tier resets on restart)
3. Firewall blocking the connection?

**Fix:**
```bash
# On local machine:
pkill ngrok
./start_emulator_ngrok.sh  # Get new URL
```

### "Device offline" in Colab

**Fix:**
```python
# In Colab:
!adb disconnect
!adb connect {NGROK_HOST}:{NGROK_PORT}
!adb devices
```

### "Emulator not starting"

**Check:**
```bash
# On local machine:
emulator -list-avds  # Are there any AVDs?

# Create one via Android Studio if needed:
# Tools → Device Manager → Create Device
```

### "ngrok not found"

**Install:**
```bash
# macOS:
brew install ngrok

# Linux:
curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | \
  sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null && \
  echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | \
  sudo tee /etc/apt/sources.list.d/ngrok.list && \
  sudo apt update && sudo apt install ngrok
```

---

## 📞 Need Help?

1. **Run diagnostics** (first cell in Colab notebook)
2. **Check the detailed guide**: `REMOTE_EMULATOR_SETUP.md`
3. **Debugging help**: `COLAB_DEBUGGING_GUIDE.md`
4. **Share error with Claude** - I'll help you fix it!

---

## ✨ What You Can Do Now

With this setup, you can:

- ✅ Control Android from anywhere (via Colab)
- ✅ Run AutoGLM without a physical phone
- ✅ Test automations before deploying
- ✅ Demo to others without sharing your device
- ✅ Run long tasks while your laptop sleeps
- ✅ Share the Colab notebook with team members

---

## 🎓 Next Steps

1. **Try a simple task**: "Open Chrome"
2. **Try something complex**: "Search for cats, take screenshot, share via email"
3. **Explore supported apps**: Check AutoGLM documentation
4. **Automate your workflow**: Create task sequences
5. **Build custom agents**: Use the AutoGLM API

---

## 🌟 Pro Tips

1. **Keep the local terminal open** - you'll see helpful status updates
2. **Use Tailscale for long sessions** - more stable than ngrok
3. **Create snapshots** of your emulator state for quick restarts
4. **Monitor ngrok dashboard**: http://localhost:4040 (on local machine)
5. **Save working Colab notebooks** - they expire after inactivity

---

## 🎉 You're Ready!

You now have a complete cloud-based Android automation setup. Go automate something amazing!

**Questions?** Just ask Claude - I'm here to help debug and optimize your setup.
