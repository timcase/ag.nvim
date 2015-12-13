#!/bin/bash
# vim:ts=2:sw=2:sts=2
cd $(dirname $(readlink -m ${0}))

[[ -n "$TMPDIR" ]] || TMPDIR="$(dirname $(mktemp --dry-run --tmpdir))"
PJROOT="${PWD%/*}"
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
show() {
  printf "$(color ${1%% *} '[%7s] -%s-') %s %s\n" \
      "${1#* }" "$2" "$(color $3)" "$4";
}
get_deps() {
  local url="https://github.com/junegunn/vader.vim"
  local vader="$TMPDIR/${url##*/}"
  (($CLEAN)) && rm -rf "$vader"
  [[ -d "$vader" ]] || (cd "${vader%/*}" &&
    git clone -b master --single-branch --depth=1 "$url" && echo)
}

urun() { local file="$1" name="$2" cmd
  cp -r "$PJROOT/t/fixture" . && bash "$PJROOT/t/${name}.sh" >/dev/null 2>&1
  cmd="$EDITOR -i NONE -u NONE -U NONE -nNesS '$PJROOT/scripts/helper.vim'"
  cmd+=" -c 'Vader!' -c 'echo\"\"\|qall!' -- '${file}'"
  if ! ((VERBOSE)); then cmd+=' 2>/dev/null'; else
    cmd+=" 2> >(echo;sed -n '/^Starting Vader/,\$p')"; fi
  eval $cmd
}

utest() {
  local file="$1" name="${1##*/}"; name="${name%.vader}"
  local title="$(sed -rn '/^"""\s*([^"].*)/ s//\1/p' "$file")"
  local expect="$(sed -rn '/^\s*""""\s*/ s///p' "$file")"

  if [[ " $SKIP_TESTS " =~ " $name " ]]; then
    show "3 SKIP" "--" "3 $name" "$title"; continue
  fi

  testdir="$(mktemp --tmpdir -d "${name}.XXX")"
  trap "rm -rf '$testdir'" RETURN INT TERM EXIT
  (cd "$testdir" && urun "$file" "$name")
  RET=$?
  ((--RET))  # EXPL: Until clarified, treat 0 as error also.

  case "$expect"
    in failed) FAILURE=1; ((RET)) && msg="2 FAIL/OK" || msg="1 FAIL/NO"
    ;;      *) FAILURE=0; ((RET)) && msg="1 FAILURE" || msg="2 OK"
  esac
  ((STATUS)) || STATUS=$(( !RET != !FAILURE ))  # Logical XOR
  ((++NUM))
  show "$msg" "$(printf "%02d" "$NUM")" "4 $name" "$title"
}

testsuite() { local NUM=0
  for rgx in "${@:-.*}"; do
    for fl in "$PJROOT/t/tests"/*.vader; do
      if [[ "${fl##*/}" =~ $rgx ]]
      then utest "$fl"; fi
    done
    ((NUM<2)) || echo $(color 3 ' ~~~~~~~~~~~~~~~~~~~')
  done
  ((NUM<2)) || echo $(if ((STATUS))
  then color 1 ' -some tests failed-'
  else color 2 ' +test suite passed+'
  fi)
  return $STATUS
}

get_deps && testsuite "$@"
