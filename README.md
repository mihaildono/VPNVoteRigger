# VPNVoteRigger

Automated voting system that uses VPN connections to bypass IP restrictions and submit multiple votes with unique email addresses.

## Overview

This project contains two automated voting scripts that continuously submit votes by rotating through different VPN connections and generating unique email addresses:

1. **vote_automation.sh** - Uses Mullvad VPN with worldwide server rotation
2. **vote_automation_nordvpn.sh** - Uses NordVPN with fastest/nearest server connections

Both scripts are optimized for locked screen operation and run continuously until manually stopped.

## Features

- 🔄 **Automatic VPN rotation** - Connects to different VPN servers for each vote
- 📧 **Random email generation** - Generates unique Bulgarian-style email addresses
- 🌍 **IP tracking** - Avoids reusing IP addresses that have already been tried
- 📊 **Progress tracking** - Shows success rate and statistics
- 🔒 **Locked screen compatible** - Uses CLI/URL schemes, no GUI required
- ⚡ **Continuous operation** - Runs indefinitely for maximum vote count
- 🎯 **Multi-instance support** - Run multiple instances in parallel

## Prerequisites

### For vote_automation.sh (Mullvad VPN)
- [Mullvad VPN](https://mullvad.net/) installed and configured
- Mullvad CLI available in PATH
- Active Mullvad subscription

### For vote_automation_nordvpn.sh (NordVPN)
- [NordVPN macOS app](https://nordvpn.com/) installed
- NordVPN app running and logged in
- Active NordVPN subscription
- macOS (uses URL scheme integration)

### Common Requirements
- Bash shell
- curl
- Internet connection

## Configuration

### Environment Variables

Copy the example environment file and configure your voting parameters:

```bash
cp env.example .env
```

Edit `.env` with your values:

```bash
# Post ID for the voting endpoint
POST_ID=__YOUR_POST_ID__

# Base URL for the voting API endpoint
BASE_URL=__YOUR_VOTE_API_URL__

# Referer URL (the page where the vote is being made)
REFERER_URL=__YOUR_REFERER_URL__

# Origin URL (the main domain)
ORIGIN_URL=__YOUR_ORIGIN_URL__
```

**Note:** The `.env` file is required for the scripts to work. Make sure to configure it before running.

## Usage

### Mullvad VPN Script

**Single instance with random countries:**
```bash
./vote_automation.sh
```

**Single instance with specific country:**
```bash
./vote_automation.sh --country bg  # Bulgaria
./vote_automation.sh --country ro  # Romania
```

**Multiple instances with different countries:**
```bash
./vote_automation.sh --instance 1 --country bg &
./vote_automation.sh --instance 2 --country ro &
./vote_automation.sh --instance 3 --country gr &
```

**Run in background (survives terminal close):**
```bash
nohup ./vote_automation.sh > vote_log.txt 2>&1 &
```

### NordVPN Script

**Single instance:**
```bash
./vote_automation_nordvpn.sh
```

**Multiple instances:**
```bash
./vote_automation_nordvpn.sh --instance 1 &
./vote_automation_nordvpn.sh --instance 2 &
```

**Run in background:**
```bash
nohup ./vote_automation_nordvpn.sh > vote_log_nordvpn.txt 2>&1 &
```

### Command Line Options

#### vote_automation.sh (Mullvad)
- `--instance ID` - Instance ID for logging (e.g., 1, 2, 3)
- `--country CODE` - Assign specific country code (us, gb, de, fr, it, bg, ro, etc.)
- `--log FILE` - Custom log file name (default: vote_log.txt)
- `-h, --help` - Show help message

#### vote_automation_nordvpn.sh (NordVPN)
- `--instance ID` - Instance ID for logging (e.g., 1, 2, 3)
- `--log FILE` - Custom log file name (default: vote_log_nordvpn.txt)
- `-h, --help` - Show help message

## How It Works

1. **VPN Connection**: Connects to a random VPN server (or specified country)
2. **IP Verification**: Gets current IP and checks if it hasn't been used before
3. **Email Generation**: Creates a unique random email address
4. **Vote Submission**: Sends HTTP POST request with randomized headers
5. **Response Parsing**: Checks if vote was successful
6. **Repeat**: Disconnects and repeats the process indefinitely

## Vote Tracking

The scripts maintain tracking files to avoid duplicate attempts:
- **Tried IPs**: `/tmp/tried_ips_*.txt` - Stores used IP addresses
- **Used Emails**: `/tmp/used_emails_*.txt` - Stores generated email addresses

These files are automatically cleaned up to keep only the last 1000 entries.

## Stopping the Scripts

**Stop all Mullvad instances:**
```bash
pkill -f vote_automation.sh
```

**Stop all NordVPN instances:**
```bash
pkill -f vote_automation_nordvpn.sh
```

**Stop specific instance by PID:**
```bash
ps aux | grep vote_automation
kill <PID>
```

## Output & Monitoring

The scripts provide colored console output:
- 🔵 **Blue** - Status/info messages
- ✅ **Green** - Success messages
- ❌ **Red** - Error messages
- ⚠️ **Yellow** - Warning messages

**View logs in real-time:**
```bash
tail -f vote_log.txt
```

**Check progress:**
The script prints statistics every 10 cycles:
- Total successful votes
- Total failed votes
- Success rate percentage
- IPs tried and emails used

## Disclaimer

This tool is for educational purposes only. Automated voting may violate terms of service of voting platforms. Use responsibly and at your own risk. The authors are not responsible for any misuse or consequences.

## License

MIT License - See LICENSE file for details
