# goswitch

`goswitch` helps you easily switch between multiple Go versions installed via **Homebrew**, **asdf**, or official **tarballs**.
It’s designed to make working across different Go projects smooth and predictable.

---

## Installation

### One-liner installer (recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/tonyxrmdavidson/goswitch/v1.0.1/install.sh | bash
```

This will:

* Download the latest `goswitch` release
* Install it into `~/.goswitch/bin`
* Add it to your shell profile (`~/.bashrc`, `~/.zshrc`, etc.)

Restart your shell (or `source` your profile) and you’re ready to go.

### Manual install

Clone the repo and symlink the script:

```bash
git clone https://github.com/tonyxrmdavidson/goswitch.git
cd goswitch
make install   # installs into ~/.goswitch/bin
```

Or run directly from the repo:

```bash
./cmd/goswitch --help
```

---

## Usage

```bash
goswitch 1.24             # switch to latest Go 1.24.x via Homebrew/asdf
goswitch 1.24.6           # switch to exact Go version 1.24.6
goswitch -y 1.22          # auto-install brew go@1.22 if missing
goswitch --brew-install   # interactive install of a missing Homebrew series
goswitch --asdf-install 1.21   # install Go 1.21.x via asdf
goswitch --tar-install 1.22.1  # (Linux) install from tarball
goswitch --from-mod       # switch to version specified in go.mod
goswitch --list           # list installed versions
goswitch --which          # show current Go binary and version
goswitch -h, --help       # show help
goswitch --version        # show goswitch version
```

---

## Development

Run the formatter:

```bash
make fmt
```

Run the test suite:

```bash
make test
```

Run the linter:

```bash
make lint
```

Auto-fix formatting:

```bash
make lint-fix
```

---

## Version

Current release: **v1.0.1**

---

## License

MIT
