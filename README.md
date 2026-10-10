# nvim-odin

> This readme was generated using Claude. It's probably incomplete but if you're
> using Neovim you're probably clever enough to figure out the missing parts.

My personal Neovim configuration, built on [lazy.nvim](https://github.com/folke/lazy.nvim). It includes LSP (via `mason.nvim` + native `vim.lsp`), completion (`blink.cmp`), fuzzy finding (`snacks.nvim`'s picker), git integration (`gitsigns`, `vim-fugitive`), formatting (`conform.nvim`), treesitter, and a handful of quality-of-life plugins (`harpoon`, `oil.nvim`, `multicursor.nvim`, `zen-mode`, `which-key`, etc).

> **Requires Neovim 0.12.1+.** This config uses the new `vim.lsp.config()` / `vim.lsp.enable()` API, which does not exist on older versions.

## Quick start (macOS / Linux)

Clone the repo anywhere and run the install script from it:

```bash
git clone <this-repo-url> ~/.dotfiles/nvim-config
~/.dotfiles/nvim-config/install.sh --dry-run   # see what it would do
~/.dotfiles/nvim-config/install.sh
```

It installs what's missing and skips the rest, so it's safe to re-run:

- **Tools:** git, make, a C compiler, curl, unzip, tar, `rg`, `fd`, Node + npm and Python 3, through dnf, apt, pacman or Homebrew (Xcode command line tools on macOS).
- **Neovim ≥ 0.12.1:** Homebrew/pacman on macOS and Arch; elsewhere the official release build in `/opt/nvim`, since Fedora's and Debian's packages are too old.
- **npm formatters:** the confirmed ones from [Global npm packages](#global-npm-packages).
- **`~/.config/nvim`:** linked to the clone. An existing config is moved to `nvim.bak` first.
- **Plugins and Mason tools:** installed headlessly. LSP servers follow on the first real start.

Not covered: Windows, a Nerd Font, and the per-language toolchains (JDK, LaTeX, Racket, SBCL, …). For those, and for doing it by hand, see the sections below.

---

## 1. Prerequisites

These are needed regardless of OS for the config to work correctly:

| Tool                                          | Why                                                                                                                      |
| --------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------ |
| **Neovim ≥ 0.12.1**                           | The editor itself                                                                                                        |
| **git**                                       | Bootstraps `lazy.nvim` and plugins, used by the picker's `git_files`                                                     |
| **A C compiler** (gcc/clang) + **make**       | Builds treesitter parsers                                                                                                |
| **ripgrep (`rg`)**                            | Powers the picker's grep, and its file search when `fd` isn't installed                                                  |
| **fd**                                        | Faster file finding — an external CLI the picker prefers over `rg`, not a Neovim plugin                                  |
| **curl**, **unzip**, **tar**                  | Used by `mason.nvim` to download LSP servers/tools                                                                       |
| **Node.js + npm**                             | Required by many Mason-installed LSP servers                                                                             |
| **Python 3 + pip**                            | Required for Mason's Python tools: `pyrefly`, `ruff`, and the `black`/`isort` fallbacks (a project's own venv copy wins) |
| **A [Nerd Font](https://www.nerdfonts.com/)** | Icons in `nvim-web-devicons`, `lualine` — install it and set it as your **terminal's** font, not inside Neovim           |

Optional, only needed if you actually use these filetypes:

| Tool                                                                                                      | Used for                                                                                                                                                                                                                                                                   |
| --------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **A JDK** (e.g. Temurin 17+)                                                                              | `jdtls` (Java LSP)                                                                                                                                                                                                                                                         |
| **A LaTeX distribution** + `latexmk`                                                                      | `texlab` LSP, which also builds `.tex` on save. macOS: BasicTeX or MacTeX (MiKTeX's macOS build is stuck at 22.1, Intel-only). Windows: MiKTeX                                                                                                                             |
| **clang-format**                                                                                          | C formatting (usually ships with LLVM/clang)                                                                                                                                                                                                                               |
| **Racket**                                                                                                | `racket_langserver`                                                                                                                                                                                                                                                        |
| **SBCL** (+ Quicklisp)                                                                                    | The custom `cl_identify` Lisp formatter in `conform.lua`                                                                                                                                                                                                                   |
| **Erlang + `erlfmt`**                                                                                     | Erlang formatting                                                                                                                                                                                                                                                          |
| **Clojure + `cljfmt`**                                                                                    | Clojure formatting                                                                                                                                                                                                                                                         |
| **`stylua`, `prettier`/`prettierd`, `black`, `isort`, `clang-format`, `latexindent`, `ormolu`, `cljfmt`** | Formatters for conform. These install via `mason-tool-installer` (along with `ruff` and `jdtls`, which are LSPs) — run `:MasonToolsInstall`. `astyle` (Java), `erlfmt`, `sbcl` and `raco` are **not** in the Mason registry and must come from your system package manager |

Formatters and LSP servers that Mason can manage will be installed automatically the first time you launch Neovim (see the `servers` table in `lua/odin/plugins/lsp-config.lua`) — you mainly need Node/Python/a compiler present so Mason's installers succeed.

**A couple of tools are _not_ reliably pulled in by Mason and need installing by hand via `npm` — see the "Global npm packages" box in the Fedora section below. The `prettier` stack there is confirmed necessary; the rest is an educated guess from an old, not-fully-verified install script.**

---

## 2. OS-specific setup

### Fedora (Linux)

```bash
sudo dnf install -y git gcc gcc-c++ make curl unzip tar \
    ripgrep fd-find nodejs npm python3 python3-pip \
    java-latest-openjdk texlive-scheme-medium latexmk clang-tools-extra
```

Fedora's `dnf` repos are typically stuck around Neovim 0.10, which is **too old** for this config. Skip `dnf` for Neovim itself and grab a current release instead — the two easiest options:

**Option A — prebuilt tarball (fastest):**

```bash
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
tar xzf nvim-linux-x86_64.tar.gz
sudo mv nvim-linux-x86_64 /opt/nvim
sudo ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim
```

**Option B — build from source:**

```bash
sudo dnf install -y ninja-build cmake gettext curl
git clone https://github.com/neovim/neovim.git
cd neovim
git checkout stable   # or a specific tag like v0.12.1
make CMAKE_BUILD_TYPE=Release
sudo make install
```

Either way, confirm the version afterward:

```bash
nvim --version
```

#### Global npm packages

Mason doesn't reliably pull all of these down on its own. From an old install script — the `prettier` stack is confirmed needed; the rest were flagged as "suspected missing" but never fully verified, so treat them as a good first guess rather than gospel. If Mason installs a server fine on its own now, you can probably skip the matching npm line.

```bash
# Formatters used by conform.lua — confirmed necessary
npm install -g prettier @fsouza/prettierd prettier-plugin-astro

# --- everything below is unconfirmed / suspected-but-unverified ---

# TypeScript: nothing global needed. vtsls comes from Mason; projects on TS 7+ use
# their own node_modules/.bin/tsc --lsp instead (see lua/odin/typescript.lua).

# html / cssls — vscode-langservers-extracted bundles both
npm install -g vscode-langservers-extracted

# dockerls
npm install -g dockerfile-language-server-nodejs
```

If in doubt, skip the unconfirmed block, run `:Mason` / `:checkhealth vim.lsp` on a matching file, and only install a package by hand if the server actually fails to launch.

#### Racket

`racket_langserver` **is confirmed to require manual installation** — Mason does not provide it. Install [DrRacket](https://racket-lang.org/) (which ships `raco`), make sure `raco` is on your `PATH`, then:

```bash
raco pkg install racket-langserver
```

Other optional extras:

```bash
sudo dnf install -y sbcl erlang clojure
cargo install stylua   # or install via :Mason inside nvim
```

### Other Linux distributions

The same packages apply, just swap `dnf` for your package manager:

```bash
# Debian/Ubuntu
sudo apt update
sudo apt install -y git gcc g++ make curl unzip ripgrep fd-find \
    nodejs npm python3 python3-pip default-jdk texlive latexmk clang

# Arch
sudo pacman -S neovim git base-devel curl unzip ripgrep fd \
    nodejs npm python python-pip jdk-openjdk texlive-core latexmk clang
```

On Ubuntu/Debian, `apt`'s `neovim` package is also often outdated — prefer the [official AppImage](https://github.com/neovim/neovim/releases) or the neovim-ppa (`ppa:neovim-ppa/unstable`) for 0.12.1+. Note that on Debian/Ubuntu the `fd` binary is installed as `fdfind` — symlink it if a plugin expects `fd`:

```bash
mkdir -p ~/.local/bin
ln -s $(which fdfind) ~/.local/bin/fd
```

### macOS (Homebrew)

```bash
xcode-select --install   # gives you a C compiler + make + git

brew install neovim ripgrep fd node python@3.12 openjdk make
brew install --cask mactex-no-gui   # LaTeX (full MacTeX also works, just bigger)
```

Link the JDK if `jdtls` can't find it:

```bash
sudo ln -sfn $(brew --prefix openjdk)/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk.jdk
```

Same global npm packages as the Fedora section above apply here too — `prettier`, `@fsouza/prettierd`, and `prettier-plugin-astro` are confirmed necessary; `vscode-langservers-extracted` and `dockerfile-language-server-nodejs` are an educated guess Mason may already handle on its own.

For Racket, install [DrRacket](https://racket-lang.org/) (bundles `raco`) rather than a Homebrew package — this one **is** confirmed manual — then run `raco pkg install racket-langserver`.

Other optional extras:

```bash
brew install sbcl erlang clojure clojure-lsp
brew install stylua   # or install via :Mason inside nvim
```

### Windows

The cleanest path is **`winget`** (or **Scoop**, shown as an alternative). You'll also want a Bash-capable shell, since `lua/odin/plugins/lsp-config.lua` looks for `msys64` or Git Bash to run shell commands.

```powershell
winget install Neovim.Neovim
winget install Git.Git
winget install BurntSushi.ripgrep.MSVC
winget install sharkdp.fd
winget install OpenJS.NodeJS.LTS
winget install Python.Python.3.12
winget install EclipseAdoptium.Temurin.17.JDK
winget install MiKTeX.MiKTeX
winget install MSYS2.MSYS2
```

After installing MSYS2, open the **MSYS2 MinGW64** shell once and install a compiler/make so treesitter parsers can build:

```bash
pacman -S mingw-w64-x86_64-gcc make
```

Then make sure `C:\msys64\usr\bin` (or wherever you installed it) and `C:\msys64\mingw64\bin` are on your **PATH**, since `get_shell()` in the config specifically checks for `C:\msys64\mingw64.exe` and Git Bash at `C:\Program Files\Git\bin\bash.exe`.

Scoop alternative:

```powershell
scoop install neovim git ripgrep fd nodejs python temurin17-jdk miktex
```

---

## 3. Installing this config

Neovim's config directory is:

- **Linux/macOS:** `~/.config/nvim`
- **Windows:** `%LOCALAPPDATA%\nvim` (i.e. `C:\Users\<you>\AppData\Local\nvim`)

Back up any existing config first, then clone this repo into that path.

**Linux/macOS:**

```bash
mv ~/.config/nvim ~/.config/nvim.bak 2>/dev/null
git clone <this-repo-url> ~/.config/nvim
```

**Windows (PowerShell):**

```powershell
Rename-Item $env:LOCALAPPDATA\nvim nvim.bak -ErrorAction SilentlyContinue
git clone <this-repo-url> $env:LOCALAPPDATA\nvim
```

---

## 4. First launch

1. Open Neovim: `nvim`
2. `lazy.nvim` will bootstrap itself and install every plugin automatically. Wait for it to finish, then restart Neovim.
3. Run `:Mason` and confirm the LSP servers/tools listed in `lua/odin/plugins/lsp-config.lua` installed successfully. If something fails (usually Node/Python/Java not on PATH), fix the underlying toolchain and re-run `:MasonInstall <name>`.
4. Treesitter parsers install automatically per-filetype the first time you open a matching file (see the `FileType` autocommand in `lua/odin/plugins/nvim-treesitter.lua`) — just open a file of that type once.
5. Install and select a **Nerd Font** in your terminal emulator's settings so icons render correctly.
6. `vim-wakatime` will prompt you for an API key on first use if you have a [WakaTime](https://wakatime.com/) account; it writes it to `~/.wakatime.cfg`, not into this repo.

---

## 5. Troubleshooting

- **Icons show as boxes/question marks** → your terminal font isn't a Nerd Font, or your terminal emulator hasn't been told to use it.
- **An LSP server never attaches** → run `:checkhealth vim.lsp` in the buffer, and `:Mason` to check the server actually installed; most failures trace back to a missing Node.js/Python/JDK.
- **`:TSUpdate` / parser errors** → make sure your C compiler is on PATH; treesitter compiles parsers locally.
- **LaTeX files don't build on save** → confirm `latexmk` is on PATH, and restart Neovim after installing a TeX distribution so texlab inherits the new PATH. texlab is the only thing that builds (`after/lsp/texlab.lua`).
