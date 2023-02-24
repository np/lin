MODE=nix
# MODE=stack-nix
# MODE=stack
# MODE=cabal
# MODE=docker
LING_GHC_RTS=()
BUILD_OPTS=(--fast --pedantic)
#LING_GHC_RTS=(+RTS -p)
#BUILD_OPTS=(--profile --trace --pedantic)
buildling() {
  stack "${STACK_FLAGS[@]}" build "${BUILD_OPTS[@]}" "$@"
}
envexec(){
  stack "${STACK_FLAGS[@]}" --docker-run-args '--memory 100m --memory-swap 100m' exec -- "$@"
}
ling() {
  envexec ling "$@" "${LING_GHC_RTS[@]}"
}
ling-fmt() {
  envexec ling-fmt "$@" "${LING_GHC_RTS[@]}"
}
checkling() {
  envexec ./check.sh
}
cmdr() {
  local args=()
  while [ "$1" != -- ]; do
    args=("$1" "${args[@]}")
    shift
  done
  shift
  local dir="$1"
  shift
  for i; do
    mv "$i" fixtures/all/
    i="$(basename "$i")"
    i="${i%.ll}"
    pushd fixtures/all/
    mkdir -p ../../tests/"$dir"
    cmdrecord ../../tests/"$dir/$i".t --no-stdin --source "$i".ll --env empty -- ling "${args[@]}" "$i".ll
    popd
    ln -s ../all/"$i".ll fixtures/"$dir"/
    rm tests/"$dir"/"$i".t/"$i".ll
    ln -s ../../../fixtures/all/"$i".ll tests/"$dir"/"$i".t/
    git add fixtures/all/"$i".ll fixtures/"$dir/$i".ll tests/"$dir/$i".t
  done
}
cmdrsuccess(){
  cmdr --check -- success "$@"
}
cmdrfailure(){
  cmdr --check -- failure "$@"
}
cmdrstrictparfailure(){
  cmdr --strict-par --check -- strict-par-failure "$@"
}
cmdrseq(){
  cmdr --pretty --no-check --seq -- sequence "$@"
}
cmdrfuse(){
  cmdr --pretty --no-check --seq --fuse -- fusion "$@"
}
cmdrcompile(){
  cmdr --no-check --seq --fuse --compile -- compile "$@"
}
cmdrpretty(){
  cmdr --pretty --no-check --no-norm -- pretty "$@"
}
cmdrnorm(){
  cmdr --pretty --no-check -- norm "$@"
}
cmdrallbase(){
  local tst="$1"
  local fix="$2"
  shift 2
  rm -r tests/"$tst"
  find fixtures/"$fix" -name '*.ll' -print0 |
    sort -z |
    xargs -0 -n 1 cat |
    cmdrecord tests/"$tst" --batch --env empty -- "$@"
}
alias cmdrseqall='cmdrallbase sequence/all.t sequence ling --pretty --no-check --seq'
alias cmdrfuseall='cmdrallbase fusion/all.t fusion ling --pretty --no-check --seq --fuse'
alias cmdrcompileall='cmdrallbase compile/all.t compile ling --no-check --seq --compile-prims --compile'
alias cmdrfmtall='cmdrallbase fmt/all.t all ling-fmt'
alias cmdrprettyall='cmdrallbase pretty/all.t all ling --pretty --no-check --no-norm'
alias cmdrnormall='cmdrallbase norm/all.t success ling --pretty --no-check'
alias cmdrstrictparsuccessall='cmdrallbase success/strict-par.t strict-par-success ling --strict-par --check'
alias cmdrexpandall='cmdrallbase expand/all.t success ling --pretty --no-check --expand'
alias cmdrreduceall='cmdrallbase reduce/all.t success ling --pretty --no-check --reduce'

cmdrall(){
  cmdrseqall
  cmdrfuseall
  cmdrcompileall
  cmdrfmtall
  cmdrprettyall
  cmdrnormall
  cmdrstrictparsuccessall
  cmdrexpandall
  cmdrreduceall
}

# error() @ https://gist.github.com/3736727 {{{
error(){
  local code="$1"
  shift
  echo "error: $@" >>/dev/stderr
  exit "$code"
}
# }}}

# Adapted from:
# link() @ https://gist.github.com/3181899 {{{1
# Example:
# cd ~/configs
# link .zshrc ~/.zshrc
# link .vimrc ~/.vimrc
link(){
  # dst is the TARGET
  # src is the LINK_NAME
  local dst="$1"
  local ldst="$1"
  local src="$2"
  case "$dst" in
    /*) : ;;
    *) ldst="$(realpath "$dst" --relative-to="$(dirname "$2")")";;
  esac
  if [ -L "$src" ]; then
    # Check if the link is already as expected.
    [ $(readlink "$src") != "$ldst" ] || return 0
    rm "$src"
  elif [ -e "$src" ]; then
    if [ -e "$dst" ]; then
      until cmp "$src" "$dst"; do
        vimdiff "$src" "$dst"
      done
      if cmp "$src" "$dst"; then
        if [ -L "$dst" ]; then
          rm "$dst"
          mv "$src" "$dst"
        else
          rm "$src"
        fi
      fi
    else
      echo "moving $src to $dst" >>/dev/stderr
      mv "$src" "$dst"
    fi
  elif [ ! -e "$dst" ]; then
    # if nothing exists we do nothing
    return 0
  fi
  echo "linking $dst" >>/dev/stderr
  ln -s "$ldst" "$src"
}
# }}}

TOP=`pwd`
DIST="$TOP"/dist
case "$MODE" in
  (docker)
    cmdcheck() {
      envexec "$TOP"/tools/cmdcheck "$@"
    }
    cmdrecord() {
      envexec "$TOP"/tools/cmdrecord "$@"
    }
    rm -rf "$DIST"/shims
    STACK_FLAGS=(--docker);;
  (stack-nix)
    STACK_FLAGS=(--nix)
    # nixpkgs commit ef17efa99b0e644bbd2a28c0c3cfe5a2e57b21ea
    current_nixpkgs=$HOME/hub/NixOS/nixpkgs-stack
    [ ! -d "$current_nixpkgs" ] || export NIX_PATH=nixpkgs=$current_nixpkgs
    export PATH="$(stack "${STACK_FLAGS[@]}" path --local-install-root)"/bin:"$DIST"/shims:$PATH

    mkdir -p "$DIST"/shims

    for i in \
      ling \
      ling-fmt \
      bnfc \
      cabal \
      gcc \
      ghc \
      ghci \
      ghc-make \
      ghc-mod \
      ghc-modi \
      ghc-pkg \
      hlint \
      stylish-haskell
    do
      link 'run-in-nix-shell' "$DIST"/shims/"$i"
    done
    ;;
  (stack)
    rm -rf "$DIST"/shims
    export PATH="$DIST"/build/ling:"$DIST"/build/ling-fmt:$PATH;;
  (cabal)
    rm -rf "$DIST"/shims
    export PATH="$DIST"/build/ling:"$DIST"/build/ling-fmt:$PATH
    buildling(){
      echo TODO cabal build...
    }
    ;;
esac
