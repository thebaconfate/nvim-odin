# nvim-odin

> This readme was generated using Claude. It's probably incomplete but if you're
> using Neovim you're probably clever enough to figure out the missing parts.

My personal Neovim configuration, built on [lazy.nvim](https://github.com/folke/lazy.nvim). It includes LSP (via `mason.nvim` + native `vim.lsp`), completion (`nvim-cmp`), fuzzy finding (`telescope.nvim`), git integration (`gitsigns`, `vim-fugitive`), formatting (`conform.nvim`), treesitter, and a handful of quality-of-life plugins (`harpoon`, `oil.nvim`, `multicursor.nvim`, `zen-mode`, `which-key`, etc).

> **Requires Neovim 0.12.1+.** This config uses the new `vim.lsp.config()` / `vim.lsp.enable()` API, which does not exist on older versions.

---

## 1. Prerequisites

These are needed regardless of OS for the config to work correctly:

| Tool                                          | Why                                                                                                                          |
| --------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------- |
| **Neovim ≥ 0.12.1**                           | The editor itself                                                                                                            |
| **git**                                       | Bootstraps `lazy.nvim` and plugins, used by `telescope`'s `git_files`                                                        |
| **A C compiler** (gcc/clang) + **make**       | Builds treesitter parsers and `telescope-fzf-native`                                                                         |
| **ripgrep (`rg`)**                            | Powers Telescope file search & grep                                                                                          |
| **fd**                                        | Faster file finding (optional but referenced as a Telescope dependency)                                                      |
| **curl**, **unzip**, **tar**                  | Used by `mason.nvim` to download LSP servers/tools                                                                           |
| **Node.js + npm**                             | Required by many Mason-installed LSP servers                                                                                 |
| **Python 3 + pip**                            | Required for `pyright` and the `ruff_format` formatter                                                                       |
| **A [Nerd Font](https://www.nerdfonts.com/)** | Icons in `nvim-web-devicons`, `mini.icons`, `lualine` — install it and set it as your **terminal's** font, not inside Neovim |

Optional, only needed if you actually use these filetypes:

| Tool                                                              | Used for                                                                                                                                     |
| ----------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- |
| **A JDK** (e.g. Temurin 17+)                                      | `jdtls` (Java LSP)                                                                                                                           |
| **A LaTeX distribution** (TeX Live / MacTeX / MiKTeX) + `latexmk` | `texlab` LSP + auto-build `.tex` on save                                                                                                     |
| **clang-format**                                                  | C formatting (usually ships with LLVM/clang)                                                                                                 |
| **Racket**                                                        | `racket_langserver`                                                                                                                          |
| **SBCL** (+ Quicklisp)                                            | The custom `cl_identify` Lisp formatter in `conform.lua`                                                                                     |
| **Erlang + `erlfmt`**                                             | Erlang formatting                                                                                                                            |
| **Clojure + `cljfmt`**                                            | Clojure formatting                                                                                                                           |
| **`stylua`, `prettier`/`prettierd`, `astyle`, `ormolu`**          | Formatters for Lua/JS-TS/Java/Haskell — most of these can be installed straight from Mason (`:Mason`) instead of your system package manager |

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

# TypeScript + its LSP (ts_ls)
npm install -g typescript typescript-language-server

# html / cssls — vscode-langservers-extracted bundles both
npm install -g vscode-langservers-extracted

# dockerls
npm install -g dockerfile-language-server-nodejs
```

If in doubt, skip the unconfirmed block, run `:Mason` / `:LspInfo` on a matching file, and only install a package by hand if the server actually fails to launch.

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

Same global npm packages as the Fedora section above apply here too — `prettier`, `@fsouza/prettierd`, and `prettier-plugin-astro` are confirmed necessary; `typescript`, `typescript-language-server`, `vscode-langservers-extracted`, and `dockerfile-language-server-nodejs` are an educated guess Mason may already handle on its own.

For Racket, install [DrRacket](https://racket-lang.org/) (bundles `raco`) rather than a Homebrew package — this one **is** confirmed manual — then run `raco pkg install racket-langserver`.

Other optional extras:

```bash
brew install sbcl erlang clojure clojure-lsp
brew install stylua   # or install via :Mason inside nvim
```

### Windows

The cleanest path is **`winget`** (or **Scoop**, shown as an alternative). You'll also want a Bash-capable shell, since `lua/odin/plugins/lsp-config.lua` and `lua/odin/plugins/telescope.lua` both look for `msys64` or Git Bash to run shell commands (e.g. building `telescope-fzf-native`).

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

After installing MSYS2, open the **MSYS2 MinGW64** shell once and install a compiler/make so `telescope-fzf-native` and treesitter parsers can build:

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
- **`telescope-fzf-native` build fails** → you're missing a C compiler/`make` (Windows: install via MSYS2 as above).
- **An LSP server never attaches** → run `:LspInfo` in the buffer, and `:Mason` to check the server actually installed; most failures trace back to a missing Node.js/Python/JDK.
- **`:TSUpdate` / parser errors** → make sure your C compiler is on PATH; treesitter compiles parsers locally.
- **LaTeX files don't build on save** → confirm `latexmk` is on PATH (`lua/odin/init.lua` runs it via an autocommand, and `texlab.lua` also calls it).
