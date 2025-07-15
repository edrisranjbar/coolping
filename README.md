# 🛰️ CoolPing

CoolPing is a stylish, user-friendly alternative to the classic `ping` command. It provides emoji-based feedback, colorized output, and convenient logging, making network diagnostics more fun and informative.

## 📦 Features

- **Emoji Feedback:** Instantly see success ✅ or failure ❌ for each ping.
- **Logging:** All results are saved to `~/coolping.log` for later review.
- **Color Output:** Colorful terminal output for easy reading (can be disabled with `--color never`).
- **No-Emoji Mode:** Compatible with legacy terminals using `--no-emoji`.
- **Custom Packet Count:** Specify the number of pings with `--count N`.
- **Simple CLI:** Easy to use, with helpful command-line options.

## 🚀 Installation

### Debian/Ubuntu

```bash
git clone https://github.com/yourusername/coolping.git
cd coolping
dpkg-deb --build .
sudo dpkg -i coolping.deb
```

### Manual Install

Copy the `coolping` binary from `usr/local/bin/` to a directory in your `$PATH`, such as `/usr/local/bin`.

## 🛠️ Usage

```bash
coolping [OPTIONS] <host>
```

### Options

- `--count N`   Number of packets to send (default: 4)
- `--color never` Disable color output
- `--no-emoji`  Disable emoji feedback
- `--help`    Show help message

### Example

```bash
coolping --count 10 google.com
```

## 📄 Logging

All ping results are automatically logged to `~/coolping.log`. You can review your ping history at any time.

## 🤝 Contributing

Contributions are welcome! Please open issues or pull requests on GitHub.

## 📜 License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
