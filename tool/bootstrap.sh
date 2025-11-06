#!/usr/bin/env bash
set -euo pipefail

say(){ printf "\033[1;36m%s\033[0m\n" "$*"; }
warn(){ printf "\033[1;33m%s\033[0m\n" "$*"; }
err(){ printf "\033[1;31m%s\033[0m\n" "$*" >&2; }
HAS(){ command -v "$1" >/dev/null 2>&1; }

OS="$(uname -s || echo Unknown)"
PM="none"
if   HAS brew;    then PM="brew"
elif HAS apt-get; then PM="apt"
fi
say "==> Package manager: $PM (${OS})"

# 0) Ensure Git repository (pre-commit requires it)
if [ ! -d .git ]; then
  if [ "${BOOTSTRAP_GIT_INIT:-yes}" = "yes" ]; then
    say "==> Initializing git repository"
    git init
    git add .
    git commit -m "chore: bootstrap policies (initial)" || true
  else
    warn "Not a git repo; run: git init && git add . && git commit -m 'init'"
  fi
fi

# 1) Core tools
say "==> Installing core tools (best effort)"
case "$PM" in
  brew)
    brew install pre-commit llvm clang-format jq node cppcheck cmake pipx || true
    ;;
  apt)
    sudo apt-get update -y || true
    sudo apt-get install -y git pre-commit clang-tidy clang-format jq nodejs npm cppcheck cmake pipx || true
    ;;
  *)
    warn "No package manager detected. Ensure: git, pre-commit, clang-tidy, clang-format, jq, node/npm, cppcheck, cmake, pipx"
    ;;
esac

# 2) Python/Node helpers via pipx/npm (PEP 668 safe)
say "==> Installing Python/Node helpers (pipx + npm)"
export PATH="$HOME/.local/bin:$PATH"
if HAS pipx; then pipx ensurepath >/dev/null 2>&1 || true; fi
(if HAS pipx; then pipx install --include-deps semgrep || true; fi) || true
(if HAS pipx; then pipx install detect-secrets || true; fi) || true
(if HAS pipx; then pipx install lizard || true; fi) || true
npm i -g jscpd@4 || true

# 3) Secrets baseline (idempotent)
say "==> Generating secrets baseline (if missing)"
if [ ! -f .secrets.baseline ]; then
  if HAS detect-secrets; then
    detect-secrets scan --exclude-files '(\\.git|build|external)/' > .secrets.baseline || true
    git add .secrets.baseline 2>/dev/null || true
  else
    warn "detect-secrets not found; skipping baseline"
  fi
fi

# 4) compile_commands.json (best effort)
say "==> Preparing compile_commands.json"
if [ -d build ] && [ -f build/compile_commands.json ]; then
  say "   found build/compile_commands.json"
elif [ -f compile_commands.json ]; then
  say "   found ./compile_commands.json"
else
  if HAS cmake && [ -f CMakeLists.txt ]; then
    cmake -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON >/dev/null || true
    if [ -f build/compile_commands.json ]; then
      cp -f build/compile_commands.json ./compile_commands.json || true
    fi
  else
    warn "No CMakeLists.txt; clang-tidy will fall back to -Iinclude"
  fi
fi

# 5) Install hooks (idempotent if already installed)
if [ -d .git ]; then
  say "==> Installing pre-commit hooks"
  pre-commit install || true
else
  warn "Skipping pre-commit install (no .git)"
fi

# 6) One full policy run
say "==> Running full policy once"
if [ -d .git ]; then
  pre-commit run --all-files || { err "Policy run completed with failures"; exit 1; }
else
  warn "Not a git repo: run 'make policy' after initializing git"
fi

say "==> Bootstrap complete"
