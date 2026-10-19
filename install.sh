#!/usr/bin/env bash
# Sets this config up on macOS or Linux: the tools it needs, a recent enough Neovim, the npm
# formatters Mason doesn't cover, the ~/.config/nvim link, Neovim as git's editor and merge
# tool, and the plugins and Mason tools, so the first real `nvim` starts ready. Safe to
# re-run: anything already in place is skipped.
# Where mise is installed, it brings the JDK for jdtls, fd and ripgrep (mise/nvim.toml).
# Other language toolchains (LaTeX, Racket, SBCL, ...) are left to the README: they're big and
# only needed per filetype. Windows isn't covered either; see the README.
#
#   ./install.sh                     install what's missing
#   ./install.sh --update            update Neovim to its latest release, then the mise tools,
#                                    plugins and Mason tools (nothing else), rebuilding Mason's
#                                    Python tools if mise's Python has moved to a new minor
#   ./install.sh --dry-run           only show what would happen; combines with --update

set -euo pipefail

DRY_RUN=0
UPDATE=0
for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=1 ;;
        --update) UPDATE=1 ;;
        *)
            echo "unknown option: $arg (use --dry-run and/or --update)" >&2
            exit 1
            ;;
    esac
done

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
NVIM_MIN="0.12.1"
MASON="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/mason"
# For the plugin and Mason steps. wakatime is kept off for these runs: it would prompt for an
# API key and log the install as coding time.
headless=(nvim --headless --cmd "let g:loaded_wakatime = 1")

# Run from this checkout, with tools resolved through mise's shims: they follow the current
# directory, while the PATH `mise activate` set up follows the one you started in. So a
# project's pinned versions (a python 3.12 in a work repo, say) don't leak in, above all into
# the python3 that Mason builds its Python tools on.
cd "$REPO"
if command -v mise >/dev/null 2>&1; then
    export PATH="${XDG_DATA_HOME:-$HOME/.local/share}/mise/shims:$PATH"
fi

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

# Neovim helpers, used by --update and by step 2
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

# link <file in this repo> <destination>: a real file already there is moved aside, never
# overwritten; an existing link to somewhere else is just re-pointed
link() {
    local src="$1" dest="$2"
    if [[ -L "$dest" && "$(readlink "$dest")" == "$src" ]]; then
        echo "$dest: already linked"
        return
    fi
    if [[ -e "$dest" && ! -L "$dest" ]]; then
        echo "$dest: moving the existing file to $dest.bak"
        run mv "$dest" "$dest.bak"
    fi
    echo "$dest: linking to $src"
    run mkdir -p "$(dirname "$dest")"
    run ln -sfn "$src" "$dest"
}

# Mason's Python tools are venvs on whichever python3 was current when they were installed.
# After a Python minor bump in mise they stay on the old one, and break once it's removed:
# rebuild the ones on another minor version than the current python3.
rebuild_stale_python_tools() {
    local want cfg have
    local -a stale=()
    want="$(python3 -c 'import sys; print("%d.%d" % sys.version_info[:2])' 2>/dev/null)" || return 0
    for cfg in "$MASON"/packages/*/venv/pyvenv.cfg; do
        [[ -f "$cfg" ]] || continue
        have="$(sed -nE 's/^version = ([0-9]+\.[0-9]+).*/\1/p' "$cfg")"
        if [[ -n "$have" && "$have" != "$want" ]]; then
            stale+=("$(basename "$(dirname "$(dirname "$cfg")")")")
        fi
    done
    if ((${#stale[@]} == 0)); then
        echo "mason python tools: all on Python $want"
        return 0
    fi
    echo "mason python tools: rebuilding ${stale[*]} on Python $want"
    # Headless, :MasonInstall waits until the installs are done
    run "${headless[@]}" "+MasonUninstall ${stale[*]}" "+MasonInstall ${stale[*]}" +qa ||
        echo "    rebuilding failed; open nvim and run :MasonInstall ${stale[*]}"
}

# The official release build, unpacked to /opt/nvim. Installs use it on Fedora and Debian;
# --update also uses it on a Mac whose Neovim already lives in /opt/nvim.
install_nvim_release() {
    local os=linux arch
    [[ "$(uname)" == "Darwin" ]] && os=macos
    case "$(uname -m)" in
        x86_64) arch="x86_64" ;;
        aarch64 | arm64) arch="arm64" ;;
        *)
            echo "    no Neovim release build for $(uname -m); install Neovim >= $NVIM_MIN by hand"
            return
            ;;
    esac
    local url="https://github.com/neovim/neovim/releases/latest/download/nvim-$os-$arch.tar.gz"
    if ((DRY_RUN)); then
        echo "    would download $url, unpack it to /opt/nvim and link /usr/local/bin/nvim"
        return
    fi
    local tmp
    tmp="$(mktemp -d)"
    curl -fL --progress-bar -o "$tmp/nvim.tar.gz" "$url"
    tar -xzf "$tmp/nvim.tar.gz" -C "$tmp"
    sudo rm -rf /opt/nvim
    sudo mv "$tmp/nvim-$os-$arch" /opt/nvim
    sudo mkdir -p /usr/local/bin
    sudo ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim
    rm -rf "$tmp"
}

# The latest release's version. The releases/latest page redirects to .../tag/vX.Y.Z, which
# needs no API token and has no rate limit.
latest_nvim_release() {
    curl -fsSLI -o /dev/null -w '%{url_effective}' https://github.com/neovim/neovim/releases/latest |
        sed -E 's|.*/tag/v?||'
}

# --update: Neovim through whatever installed it, then plugins and Mason tools
update() {
    local current latest nvim_path
    current="$(nvim_version || true)"
    nvim_path="$(command -v nvim || true)"
    if [[ -z "$nvim_path" ]]; then
        echo "neovim: not installed; run ./install.sh first"
        exit 1
    fi
    if [[ "$nvim_path" == /opt/nvim/* || "$(readlink "$nvim_path" || true)" == /opt/nvim/* ]]; then
        latest="$(latest_nvim_release || true)"
        if [[ -z "$latest" ]]; then
            echo "neovim: couldn't reach GitHub to look up the latest release"
            exit 1
        elif version_at_least "$current" "$latest"; then
            echo "neovim: $current, already the latest release"
        else
            echo "neovim: updating $current to $latest in /opt/nvim"
            install_nvim_release
        fi
    elif [[ "$PM" == brew ]] && brew list neovim >/dev/null 2>&1; then
        echo "neovim: updating through Homebrew"
        run brew upgrade neovim
    else
        echo "neovim: $nvim_path comes from your package manager; update it there (Arch: pacman -Syu)"
    fi
    hash -r

    if command -v mise >/dev/null 2>&1; then
        echo "mise tools: upgrading java, fd and ripgrep"
        run mise upgrade java fd ripgrep
    fi

    # Lazy! sync moves plugins past the lockfile to their latest versions, and records them in
    # lazy-lock.json: commit that so the other machines get the same versions
    echo "plugins: updating"
    run "${headless[@]}" "+Lazy! sync" +qa
    echo
    rebuild_stale_python_tools
    echo "mason tools: updating"
    run "${headless[@]}" "+Lazy! load mason-tool-installer.nvim" "+MasonToolsUpdateSync" +qa ||
        echo "    some Mason tools failed; open nvim and run :Mason to see which"
    echo
    if ! git -C "$REPO" diff --quiet -- lazy-lock.json; then
        echo "lazy-lock.json changed: commit it to keep your other machines on the same plugin versions"
    fi
}

if ((UPDATE)); then
    update
    exit 0
fi

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

# 1b. mise, when it's installed: the JDK for jdtls, fd and ripgrep at the same versions on
#     macOS and Linux, without sudo. mise/nvim.toml is linked in as an extra global config,
#     next to the dotfiles' own. mise/default-npm-packages gives every Node that mise installs
#     from now on the npm formatters; the Node you have now gets them in step 3. This comes
#     before the Mason step, so jdtls finds Java there.
if command -v mise >/dev/null 2>&1; then
    link "$REPO/mise/nvim.toml" "${XDG_CONFIG_HOME:-$HOME/.config}/mise/conf.d/nvim.toml"
    link "$REPO/mise/default-npm-packages" "$HOME/.default-npm-packages"
    echo "mise: installing java, fd and ripgrep"
    run mise install
    # Found through the shims on PATH (top of this script)
    hash -r
else
    echo "mise: not installed, so fd and ripgrep come from $PM, and the JDK by hand (see the README)"
fi

# Already there when mise installed them; the package manager is the fallback
tool ripgrep      rg               ripgrep              ripgrep              ripgrep             ripgrep
# Debian and Ubuntu install fd as `fdfind`; the picker looks for both names.
tool fd            "fd|fdfind"      fd-find              fd-find              fd                  fd
tool "node + npm"  npm              "nodejs npm"         "nodejs npm"         "nodejs npm"        node
tool python3       python3          "python3 python3-pip" "python3 python3-pip python3-venv" "python python-pip" python

# 2. Neovim itself. Fedora's and Debian's packages lag far behind, so on those the official
#    release build goes to /opt/nvim instead; Homebrew and Arch ship current versions.
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
#    plugin when both are installed globally. The list is mise/default-npm-packages, which
#    mise also reads for every Node it installs later. (The README lists more npm packages
#    that may be needed; those are unconfirmed, so they're left out here.)
npm_packages=()
while IFS= read -r package; do
    [[ -n "$package" ]] && npm_packages+=("$package")
done <"$REPO/mise/default-npm-packages"
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

# 4b. Neovim as git's editor and merge tool (git's built-in nvimdiff). Replaces nothing set, or
#     the vim defaults the dotfiles' bootstrap.sh sets; any other choice of yours stays.
# git_to_nvim <key> <vim value> <neovim value>
git_to_nvim() {
    local current
    current="$(git config --global --get "$1" || true)"
    if [[ "$current" == "$3" ]]; then
        echo "git $1: already $3"
    elif [[ -z "$current" || "$current" == "$2" ]]; then
        echo "git $1: ${current:-unset} -> $3"
        run git config --global "$1" "$3"
    else
        echo "git $1: keeping $current"
    fi
}
git_to_nvim core.editor vim nvim
git_to_nvim merge.tool vimdiff nvimdiff

# 5. Plugins and Mason tools, headless. `Lazy! install` only adds missing plugins, at the
#    lockfile's versions, so re-running never rolls back plugins you've updated since.
#    LSP servers install on the first real start (mason-lspconfig). Python tools built on
#    an older Python are rebuilt first (rebuild_stale_python_tools above).
current="$(nvim_version || true)"
if ((DRY_RUN)) || [[ -z "$current" ]] || ! version_at_least "$current" "$NVIM_MIN"; then
    echo "plugins + mason tools: would install them headlessly (needs Neovim >= $NVIM_MIN)"
else
    echo "plugins: installing what's missing"
    "${headless[@]}" "+Lazy! install" +qa
    echo
    rebuild_stale_python_tools
    echo "mason tools: installing (formatters and jdtls; can take a few minutes)"
    "${headless[@]}" "+Lazy! load mason-tool-installer.nvim" "+MasonToolsInstallSync" +qa ||
        echo "    some Mason tools failed; open nvim and run :Mason to see which"
    echo
fi

echo
echo "Done. Still by hand: a Nerd Font in your terminal, and any language toolchains you need"
echo "(LaTeX, Racket, ...; the JDK too without mise) from the README."
