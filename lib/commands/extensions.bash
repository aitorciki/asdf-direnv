ASDF_LEGACY_FILENAMES="${XDG_DATA_HOME:-$HOME/.local/share}/asdf-direnv/legacy-filenames"

# modification time of a file in unix timestamp format
_mtime() {
  local file="$1"
  [ -f "$file" ] && date -r "$file" +%s
}

_find_up_all() {
  (
    local filenames=("$@")
    local found=()
    while true; do
      for i in "${!filenames[@]}"; do
        if [ -f "${filenames[$i]}" ]; then
          found+=("$PWD/${filenames[$i]}")
          unset "filenames[$i]"
        fi
      done
      if [ ${#filenames[@]} -eq 0 ] || [ "$PWD" = / ] || [ "$PWD" = // ]; then
        break
      fi
      cd ..
    done

    echo "${found[@]}"
  )
}

_load_legacy_and_mtime() {
  if [ ! -f "$ASDF_DIRENV_LEGACY_FILENAMES" ]; then
    return 1
  fi

  local filenames paths
  mapfile -t filenames < "$ASDF_DIRENV_LEGACY_FILENAMES"
  read -r -a paths <<< "$(_find_up_all "${filenames[@]}")"
  local paths_and_mtimes=()
  for p in "${paths[@]}"; do
    paths_and_mtimes+=("$p|$(_mtime "$p")")
  done

  echo "${paths_and_mtimes[@]}"
}

_store_legacy_filenames() {
  mkdir -p "$(dirname "$ASDF_LEGACY_FILENAMES")"
  find "${ASDF_DATA_DIR:-$HOME/.asdf}/plugins" -name "list-legacy-filenames" -print0 \
    | xargs -0 -n1 sh | tr ' ' $'\n' | sort -u \
    > "$ASDF_LEGACY_FILENAMES"
}

_cksum() {
  local file="$1"
  # shellcheck disable=SC2154
  cksum <(pwd) <(echo "$@") <("$direnv" status) <(test -f "$file" && ls -l "$file") <(_load_legacy_and_mtime) \
    | cut -d' ' -f 1 | tr $'\n' '-' | sed -e 's/-$//'
}
