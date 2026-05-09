# 🛰️ CoolPing

CoolPing is a stylish, user-friendly alternative to the classic `ping` command. It provides emoji-based feedback, colorized output, continuous monitoring, and convenient logging, making network diagnostics more fun and informative.

## 📦 Features

### Core Features
- **Emoji Feedback:** Instantly see success ✅ or failure ❌ for each ping.
- **Color Output:** Colorful terminal output for easy reading (can be disabled with `--color never`).
- **Custom Packet Count:** Specify the number of pings with `--count N`.
- **Logging:** Optional logging to `~/coolping.log` with `--log` flag.
- **No-Emoji Mode:** Compatible with legacy terminals using `--no-emoji`.

### 🆕 New Features (v2.0)

- **📊 Continuous Monitoring:** Run indefinitely with live updating statistics dashboard
  - Real-time packet loss visualization with progress bars
  - Min/Max/Average/Recent latency tracking
  - Connection quality rating (★★★★★)
  - Uptime counter
  - Press Ctrl+C to stop and see final stats

## 🚀 Installation

### Debian/Ubuntu

```bash
# The .deb file is already included in this directory—no build needed!
sudo dpkg -i coolping.deb
```

#### Or install directly from GitHub (no git required)

```bash
wget https://github.com/edrisranjbar/coolping/raw/main/coolping.deb -O coolping.deb
sudo dpkg -i coolping.deb
```

### Manual Install

Copy the `coolping` binary from `usr/local/bin/` to a directory in your `$PATH`, such as `/usr/local/bin`.

## 🛠️ Usage

```bash
coolping [OPTIONS] <host>
coolping --help
```

### Options

- `--count N`      Number of packets to send (default: 4)
- `--continuous`   Run indefinitely with live updating stats
- `--log`          Enable logging to ~/coolping.log
- `--no-emoji`     Disable emoji feedback
- `--color never`  Disable color output
- `--verbose`      Show verbose output
- `--help`         Show help message

### Examples

#### Basic Usage
```bash
# Standard ping (4 packets)
coolping google.com

# Custom packet count
coolping --count 10 google.com

# With logging
coolping --log google.com
```

#### Continuous Monitoring
```bash
# Monitor with live stats dashboard
coolping --continuous google.com

# Monitor with logging enabled
coolping --continuous --log 8.8.8.8
```

## 📖 Manual Page

After installation, you can view the full manual with:

```bash
man coolping
```

This provides detailed usage, options, and examples for CoolPing.

## 📄 Logging

Enable logging with the `--log` flag. All ping results will be saved to `~/coolping.log`. You can review your ping history at any time.

## 🤝 Contributing

Contributions are welcome! Please open issues or pull requests on GitHub.

## 📜 License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
