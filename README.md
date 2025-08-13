# goswitch – Go Version Switcher

`goswitch` is a Bash-based tool for switching between multiple Go versions installed via **Homebrew**, **asdf**, or (optionally) official tarballs.

It supports **macOS** and **Linux** with OS-specific precedence rules:

* **macOS** → Prefer **Homebrew**, fallback to **asdf** if Homebrew is unavailable or missing the requested version.
* **Linux** → Prefer **asdf**, fallback to **Homebrew** if available, then to official tarball installation.

---

## 📦 Features

* Switch between Go versions instantly.
* Auto-install missing versions via Homebrew or asdf.
* List installed versions from both managers.
* Show the currently active Go binary and version.
* Cross-platform support for macOS and Linux.
* Modularised codebase for easy maintenance.

---

## 🚀 Installation

1. **Clone or download** the `goswitch` script and supporting files.

2. Ensure it’s in your `PATH`:

   ```bash
   export PATH="$HOME/goswitch/cmd:$PATH"
   ```

   Add the above to your `~/.bash_profile`, `~/.bashrc`, or `~/.zshrc`.

3. **Reload your shell**:

   ```bash
   source ~/.bash_profile
   ```

---

## 🔧 Usage

```bash
goswitch <version>         # Switch to a specific Go version
goswitch --list            # Show installed versions (Homebrew + asdf)
goswitch --which           # Show current Go binary and version
goswitch --brew-install    # Install a missing Homebrew version
goswitch --asdf-install    # Install a missing asdf version
goswitch --from-mod        # (Optional) Switch to Go version from go.mod
goswitch -h, --help        # Show help
```

---

## 📋 Examples

Switch to Go 1.21 (will use Homebrew on macOS, asdf on Linux):

```bash
goswitch 1.21
```

List all installed versions from Homebrew and asdf:

```bash
goswitch --list
```

Show the current active Go binary and version:

```bash
goswitch --which
```

Install a new version with Homebrew (if available):

```bash
goswitch --brew-install
```

Install a new version with asdf (if available):

```bash
goswitch --asdf-install
```

Switch to the Go version defined in a project’s `go.mod`:

```bash
cd my-project
goswitch --from-mod
```

---

## 🖥️ OS Precedence Logic

**macOS**:

1. Homebrew (brew) → auto-install if missing.
2. Fallback to asdf → auto-install if missing.

**Linux**:

1. asdf → auto-install if missing.
2. Fallback to Homebrew → auto-install if missing.
3. Fallback to official Go tarball installation.

---

## ⚠️ Notes

* If you uninstall a Go version from Homebrew or asdf, `goswitch` will fall back automatically.
* `go` in `go.mod` defines the language version; `toolchain` defines the compiler/tool version.
  For dependency bumps, use the `toolchain` version if present, otherwise use the `go` directive.
* On Linux, you’ll need **asdf** or **Homebrew/Linuxbrew** installed for best results.

---

## 🛠️ Dependencies

* **Bash** ≥ 4.0 (for `mapfile` support)
* Either:

  * **Homebrew** (macOS or Linux)
  * **asdf** with [asdf-golang plugin](https://github.com/asdf-community/asdf-golang)
* Optional: `curl` or `wget` for tarball installation fallback on Linux.

---

## 📜 License

MIT License – feel free to modify and share.
