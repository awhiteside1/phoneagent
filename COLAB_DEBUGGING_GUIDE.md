# AutoGLM Colab Debugging Workflow

This guide explains how to run AutoGLM in Google Colab while collaborating with Claude Code to debug and fix issues.

## Quick Start

1. **Upload the notebook to Google Colab**:
   - Go to https://colab.research.google.com
   - Click `File → Upload notebook`
   - Select `AutoGLM_Colab_Setup.ipynb`

2. **Run cells sequentially** through the notebook

3. **When you hit an error**, follow the workflow below

## Collaborative Debugging Workflow

### When You Encounter an Error:

```
Step 1: Don't panic!
Step 2: Copy the error output
Step 3: Run the "System Diagnostics" cell
Step 4: Share with Claude in this format ↓
```

### Error Report Format

Copy and paste this template, filling in your information:

```
Error in cell: [Step X: Cell Name]

Error message:
[Paste the complete error output here, including stack trace]

System diagnostics:
[Paste the output from the System Diagnostics cell here]

What I was trying to do:
[Briefly describe what you expected to happen]
```

### Example Error Report

```
Error in cell: Step 2: Install Python Dependencies

Error message:
ERROR: Could not find a version that satisfies the requirement anthropic==0.25.0
ERROR: No matching distribution found for anthropic==0.25.0

System diagnostics:
============================================================
SYSTEM DIAGNOSTICS - Copy this when reporting errors
============================================================

📍 Python Version: 3.10.12
📍 Platform: Linux-5.15.0-1045-gcp-x86_64-with-glibc2.35
📍 Python Path: /usr/bin/python3

📂 Current Directory: /content/Open-AutoGLM
✓ In AutoGLM directory

📦 Installed packages (key ones):
requests 2.31.0
pillow 10.0.1

What I was trying to do:
Install the required Python packages from requirements.txt
```

## What Claude Will Do

After you share the error:

1. **Analyze the issue** - Claude will identify the root cause
2. **Provide a fix** - You'll get a code block to copy
3. **Explain the solution** - Understanding what went wrong
4. **Update the notebook** - Modified cells if needed

## How to Apply Fixes

### Option 1: Single Cell Fix
```python
# Claude will provide something like this:
# "Replace Step 2 cell with:"

try:
    print("🔄 Installing Python dependencies...")
    !pip install --upgrade pip
    !pip install -r requirements.txt
    print("✅ Dependencies installed!")
except Exception as e:
    print(f"❌ ERROR: {str(e)}")
    raise
```

**How to apply:**
1. Click on the cell with the error
2. Delete the existing code
3. Paste Claude's new code
4. Run the cell

### Option 2: New Cell to Insert
```python
# Claude might say: "Add this cell before Step 3:"

# Workaround for package version conflict
!pip uninstall -y anthropic
!pip install anthropic==0.26.0
```

**How to apply:**
1. Click between two cells where you want to insert
2. Click `+ Code` button
3. Paste Claude's code
4. Run the cell

### Option 3: Environment Variable Fix
```python
# Claude might provide:
import os
os.environ['SOME_VAR'] = 'value'
```

**How to apply:**
1. Create a new cell at the top of the notebook
2. Paste the code
3. Run it before other cells

## Common Issues and Quick Fixes

### Issue: "requirements.txt not found"
**Likely cause:** Not in the AutoGLM directory
**Quick check:** Run `!pwd` and `!ls -la`
**Fix:** Run the "Clone Repository" cell again

### Issue: "No module named 'X'"
**Likely cause:** Dependency installation failed
**Quick check:** Run `!pip list | grep X`
**Fix:** Install specific package: `!pip install X`

### Issue: "ADB not found"
**Likely cause:** ADB installation didn't complete
**Quick check:** Run `!which adb`
**Fix:** Re-run Step 3 (Install ADB)

### Issue: "Permission denied"
**Likely cause:** File permissions in Colab
**Quick check:** Run `!ls -la`
**Fix:** Usually not needed in Colab, but try `!chmod +x filename`

## Tips for Smooth Debugging

### ✅ DO:
- Copy complete error messages (including stack traces)
- Run the System Diagnostics cell after each error
- Mention what you were trying to accomplish
- Share the step number where the error occurred
- Try re-running the cell once before reporting (sometimes transient errors)

### ❌ DON'T:
- Skip the diagnostics cell
- Paraphrase or summarize errors
- Skip steps in the notebook
- Run cells out of order
- Modify multiple cells before testing

## Advanced: Creating Debug Cells

You can add custom debugging cells anywhere:

```python
# Debug cell template
print("=== DEBUG INFO ===")
import os
print(f"Current dir: {os.getcwd()}")
print(f"Files here: {os.listdir('.')}")
print(f"Python path: {sys.path[:3]}")
!pip list | grep -i keyword
print("=== END DEBUG ===")
```

## Saving Your Progress

### Save notebook with fixes:
1. `File → Save a copy in Drive`
2. Or `File → Download → Download .ipynb`

### Export error log:
1. `Edit → Clear all outputs` (to reset)
2. Run cells sequentially
3. `File → Print` and save as PDF

## Getting Help

If you're stuck:

1. **Share the full notebook state**:
   - "I'm on Step X, completed Y, now seeing error Z"

2. **Provide context**:
   - "This worked yesterday but fails today"
   - "I modified cell ABC before this happened"

3. **Ask specific questions**:
   - "Should I skip this step?"
   - "Can I use a different package version?"
   - "What does this error mean?"

## Workflow Diagram

```
┌─────────────────┐
│  Run Cell       │
└────────┬────────┘
         │
         ▼
    Error? ──No──▶ Continue
         │
        Yes
         │
         ▼
┌─────────────────┐
│ Copy Error      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Run Diagnostics │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Share with      │
│ Claude          │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Get Fix         │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Apply Fix       │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Test Fix        │
└────────┬────────┘
         │
         ▼
   Works? ──Yes──▶ Continue
         │
        No
         │
         ▼
    (Repeat)
```

## Expected Limitations in Colab

Remember, these are **NORMAL** and not errors:

1. **No physical device connection** - USB devices can't connect to Colab servers
2. **ADB shows no devices** - Expected, this is for local use
3. **Some features won't work** - Phone control requires local execution

You're using Colab to:
- ✅ Install and configure AutoGLM
- ✅ Understand the codebase
- ✅ Test the setup process
- ✅ Prepare for local deployment

You're NOT using Colab to:
- ❌ Actually control your phone
- ❌ Run the full agent end-to-end
- ❌ Connect physical devices

## Success Metrics

You've succeeded when:
- ✅ All installation cells run without errors
- ✅ All verification checks pass
- ✅ Configuration is set correctly
- ✅ You understand the AutoGLM structure

## Next Steps After Successful Setup

1. Download the repository to your local machine
2. Install dependencies locally
3. Connect your Android device via USB
4. Run AutoGLM commands locally

---

**Questions?** Just ask Claude! Share your screen output and we'll figure it out together.
