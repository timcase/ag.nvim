#!/bin/bash
# vim:ts=2:sw=2:sts=2
cd $(dirname $(readlink -m ${0}))

# [[ "$EDITOR" =~ vim ]] || EDITOR=vim
EDITOR=vim

die() { printf "Err: '"${0##*/}"' %s${1+\n}" "$1"; exit 1; }
while getopts 'vc-' opt; do case "$opt"
in v) VERBOSE=1
;; c) CLEAN=1
;; -) eval 'opt=${'$((OPTIND>2? --OPTIND :OPTIND))'#--}'
  OPTARG="${opt#*=}"; case "${opt%%=*}"
  in verbose) VERBOSE=1
  ;; clean) CLEAN=1
  ;; *) die "invalid long option '--$opt'"
  esac; OPTIND=1; shift
;; "?") die
;; :) die "needs value for '-$opt'"
;; *) die "has mismatched option '-$opt'"
esac; done; shift $((OPTIND-1));


color() { printf "%s" "$(tput setaf $1)${@:2}$(tput sgr0)"; }
get_deps() {
  (($CLEAN)) && rm -rf vader.vim
  [[ -d vader.vim ]] || git clone -b master --single-branch --depth=1 \
       https://github.com/junegunn/vader.vim && echo
}

urun() { local file="$1" name="$2" cmd
  cp -r ../fixture . && bash ../${name}.sh >/dev/null 2>&1
  cmd="$EDITOR -i NONE -u NONE -U NONE -nNS ../helper.vim" # SEE: -es
  cmd+=" -c 'Vader!' -c 'echo\"\"\|qall!' -- ../${file}"
  if ! ((VERBOSE)); then cmd+=' 2>/dev/null'; else
    cmd+=" 2> >(echo;sed -n '/^Starting Vader/,\$p')"; fi
  eval $cmd
}

utest() {
  local file="$1" name="${1%.vader}"
  local title="$(sed -rn '/^"""\s*([^"].*)/ s//\1/p' $file)"
  local expect="$(sed -rn '/^\s*""""\s*/ s///p' $file)"
  local entry="$(color 4 ${name}) ${title}"

  if [[ " $SKIP_TESTS " =~ " $name " ]]; then
    echo "$entry $(color 3 skip)"; continue
  fi

  tempdir=$(mktemp -d "${name}.XXX")
  trap "rm -rf '$tempdir'" RETURN INT TERM EXIT
  (cd "$tempdir" && urun "$file" "$name")
  RET=$?

  case "$expect"
    in failed) FAILURE=1; ((RET)) && msg="2 failed correctly" || msg="1 not failed"
    ;;      *) FAILURE=0; ((RET)) && msg="1 ko" || msg="2 ok"
  esac
  ((STATUS)) || STATUS=$(( !RET != !FAILURE ))  # Logical XOR
  echo "$entry $(color $msg)"
}

testsuite() {
  for testcase in *.vader; do
    utest "$testcase"
  done
  echo $(if ((STATUS))
  then color '1 some test failed'
  else color '2 test suite passed'
  fi)
  return $STATUS
}

if (($#)); then utest $@; else get_deps && testsuite; fi
