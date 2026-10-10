#!/usr/bin/env bash
# Sets this config up on macOS or Linux: the tools it needs, a recent enough Neovim, the npm
# formatters Mason doesn't cover, the ~/.config/nvim link, and the plugins and Mason tools, so
# the first real `nvim` starts ready. Safe to re-run: anything already in place is skipped.
# Language toolchains (JDK, LaTeX, Racket, SBCL, ...) are left to the README: they're big and
# only needed per filetype. Windows isn't covered either; see the README.
#
#   ./install.sh            install what's missing
#   ./install.sh --dry-run  only show what would happen

set -euo pipefail

DRY_RUN=0
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
NVIM_MIN="0.12.1"

run() {
    if ((DRY_RUN)); then
        echo "    would run: $*"
    else
        "$@"
    fi
}

PM=""
for candidate in dnf apt-get pacman brew; do
    if command -v "$candidate" >/dev/null 2>&1; then
        PM="$candidate"
        break
    fi
done

# 1. Command line tools. On macOS the Xcode command line tools bring git, make and a C compiler.
if [[ "$(uname)" == "Darwin" ]]; then
    if xcode-select -p >/dev/null 2>&1; then
        echo "xcode command line tools: already installed"
    else
        echo "xcode command line tools: installing (finish the dialog, then re-run this script)"
        run xcode-select --install
        ((DRY_RUN)) || exit 0
    fi
fi

# tool <name> <commands that count as installed, |-separated> <dnf> <apt> <pacman> <brew>
# An empty package list means that package manager has nothing to install for it.
tool() {
    local name="$1" check="$2" packages=""
    local cmd
    for cmd in ${check//|/ }; do
        if command -v "$cmd" >/dev/null 2>&1; then
            echo "$name: already installed"
            return
        fi
    done
    case "$PM" in
        dnf) packages="$3" ;;
        apt-get) packages="$4" ;;
        pacman) packages="$5" ;;
        brew) packages="$6" ;;
        *)
            echo "$name: no supported package manager (dnf, apt, pacman, brew); install it by hand"
            return
            ;;
    esac
    if [[ -z "$packages" ]]; then
        echo "$name: not available through $PM; install it by hand"
        return
    fi
    echo "$name: installing ($packages)"
    # $packages is a word list on purpose: some tools are more than one package.
    # shellcheck disable=SC2086
    case "$PM" in
        dnf) run sudo dnf install -y $packages ;;
        apt-get) run sudo apt-get install -y $packages ;;
        pacman) run sudo pacman -S --needed --noconfirm $packages ;;
        brew) run brew install $packages ;;
    esac
}

#    name          installed if     dnf                  apt                  pacman              brew
tool git           git              git                  git                  git                 git
tool make          make             make                 make                 make                make
tool "C compiler"  "cc|gcc|clang"   "gcc gcc-c++"        build-essential      base-devel          ""
tool curl          curl             curl                 curl                 curl                curl
tool unzip         unzip            unzip                unzip                unzip               unzip
tool tar           tar              tar                  tar                  tar                 gnu-tar
tool ripgrep       rg               ripgrep              ripgrep              ripgrep             ripgrep
# Debian and Ubuntu install fd as `fdfind`; the picker looks for both names.
tool fd            "fd|fdfind"      fd-find              fd-find              fd                  fd
tool "node + npm"  npm              "nodejs npm"         "nodejs npm"         "nodejs npm"        node
tool python3       python3          "python3 python3-pip" "python3 python3-pip python3-venv" "python python-pip" python

# 2. Neovim itself. Fedora's and Debian's packages lag far behind, so on those the official
#    release build goes to /opt/nvim instead; Homebrew and Arch ship current versions.
nvim_version() {
    nvim --version 2>/dev/null | head -n 1 | sed -E 's/^NVIM v([0-9]+\.[0-9]+\.[0-9]+).*/\1/'
}

# version_at_least <version> <minimum>
version_at_least() {
    local IFS=.
    local -a have=($1) want=($2)
    local i
    for i in 0 1 2; do
        ((${have[i]:-0} > ${want[i]:-0})) && return 0
        ((${have[i]:-0} < ${want[i]:-0})) && return 1
    done
    return 0
}

install_nvim_release() {
    local arch
    case "$(uname -m)" in
        x86_64) arch="x86_64" ;;
        aarch64 | arm64) arch="arm64" ;;
        *)
            echo "    no Neovim release build for $(uname -m); install Neovim >= $NVIM_MIN by hand"
            return
            ;;
    esac
    local url="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-$arch.tar.gz"
    if ((DRY_RUN)); then
        echo "    would download $url, unpack it to /opt/nvim and link /usr/local/bin/nvim"
        return
    fi
    local tmp
    tmp="$(mktemp -d)"
    curl -fL --progress-bar -o "$tmp/nvim.tar.gz" "$url"
    tar -xzf "$tmp/nvim.tar.gz" -C "$tmp"
    sudo rm -rf /opt/nvim
    sudo mv "$tmp/nvim-linux-$arch" /opt/nvim
    sudo ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim
    rm -rf "$tmp"
}

current="$(nvim_version || true)"
if [[ -n "$current" ]] && version_at_least "$current" "$NVIM_MIN"; then
    echo "neovim: $current, already >= $NVIM_MIN"
else
    echo "neovim: ${current:-not installed}, needs >= $NVIM_MIN; installing"
    case "$PM" in
        brew)
            if brew list neovim >/dev/null 2>&1; then
                run brew upgrade neovim
            else
                run brew install neovim
            fi
            ;;
        pacman) run sudo pacman -S --needed --noconfirm neovim ;;
        *) install_nvim_release ;;
    esac
    hash -r
    current="$(nvim_version || true)"
    if ((!DRY_RUN)) && ! { [[ -n "$current" ]] && version_at_least "$current" "$NVIM_MIN"; }; then
        echo "    \`nvim\` is still ${current:-missing}: check that /usr/local/bin comes before /usr/bin on PATH"
    fi
fi

# 3. npm formatters conform uses that Mason doesn't cover: prettier only finds the astro
#    plugin when both are installed globally. (The README lists more npm packages that may be
#    needed; those are unconfirmed, so they're left out here.)
npm_packages=(prettier @fsouza/prettierd prettier-plugin-astro)
if ! command -v npm >/dev/null 2>&1; then
    echo "npm formatters: npm isn't installed yet, so would install ${npm_packages[*]} after it"
else
    missing=()
    for package in "${npm_packages[@]}"; do
        npm ls -g --depth=0 "$package" >/dev/null 2>&1 || missing+=("$package")
    done
    if ((${#missing[@]} == 0)); then
        echo "npm formatters: already installed"
    else
        echo "npm formatters: installing ${missing[*]}"
        # A system Node (dnf, apt) keeps global packages in a root-owned prefix.
        prefix="$(npm prefix -g)"
        if [[ -w "$prefix/lib" || (! -e "$prefix/lib" && -w "$prefix") ]]; then
            run npm install -g "${missing[@]}"
        else
            run sudo npm install -g "${missing[@]}"
        fi
    fi
fi

# 4. Point ~/.config/nvim at this checkout. A real config already there is moved aside, never
#    overwritten; an existing link to somewhere else is just re-pointed.
if [[ "$(cd "$REPO" && pwd -P)" == "$(cd "$CONFIG" 2>/dev/null && pwd -P)" ]]; then
    echo "config link: $CONFIG already points here"
elif [[ -L "$CONFIG" ]]; then
    echo "config link: re-pointing $CONFIG from $(readlink "$CONFIG") to $REPO"
    run ln -sfn "$REPO" "$CONFIG"
elif [[ -e "$CONFIG" ]]; then
    backup="$CONFIG.bak"
    [[ -e "$backup" ]] && backup="$CONFIG.bak.$(date +%Y%m%d-%H%M%S)"
    echo "config link: moving the existing $CONFIG to $backup, then linking it here"
    run mv "$CONFIG" "$backup"
    run ln -s "$REPO" "$CONFIG"
else
    echo "config link: linking $CONFIG to $REPO"
    run mkdir -p "$(dirname "$CONFIG")"
    run ln -s "$REPO" "$CONFIG"
fi

# 5. Plugins and Mason tools, headless. `Lazy! install` only adds missing plugins, at the
#    lockfile's versions, so re-running never rolls back plugins you've updated since.
#    LSP servers install on the first real start (mason-lspconfig). wakatime is kept off for
#    these runs: it would prompt for an API key and log the install as coding time.
current="$(nvim_version || true)"
if ((DRY_RUN)) || [[ -z "$current" ]] || ! version_at_least "$current" "$NVIM_MIN"; then
    echo "plugins + mason tools: would install them headlessly (needs Neovim >= $NVIM_MIN)"
else
    headless=(nvim --headless --cmd "let g:loaded_wakatime = 1")
    echo "plugins: installing what's missing"
    "${headless[@]}" "+Lazy! install" +qa
    echo
    echo "mason tools: installing (formatters and jdtls; can take a few minutes)"
    "${headless[@]}" "+Lazy! load mason-tool-installer.nvim" "+MasonToolsInstallSync" +qa ||
        echo "    some Mason tools failed; open nvim and run :Mason to see which"
    echo
fi

echo
echo "Done. Still by hand: a Nerd Font in your terminal, and any language toolchains you need"
echo "(JDK, LaTeX, Racket, ...) from the README."
