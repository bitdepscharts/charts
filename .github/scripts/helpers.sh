#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset

: "${charts_dir:=}"

# shellcheck disable=SC1091
. .github/scripts/runt.sh

errexit() {
  >&2 echo "$*"; exit 1;
}

excluded_charts_path() {
  local rpath
  rpath=$(basename "$charts_dir" | sed -e 's/^\.$//')
  yq -r '."excluded-charts"|.[]' < .github/ct.yaml | sed "s/^/${rpath}\//"  || echo
}

charts_basename() {
  sed 's@.*/@@'
}

lookup_latest_tag() {
  git fetch --tags >/dev/null 2>&1
  if ! git describe --tags --abbrev=0 HEAD~ 2>/dev/null; then
    git rev-list --max-parents=0 --first-parent HEAD
  fi
}

filter_charts() {
  local charts=()
  while read -r path; do
    if [[ -d "$path" && -f "${path}/Chart.yaml" ]]; then
      charts+=("$path")
    fi
  done
  printf "%s\n" "${charts[@]}"
}

list_changed() {
  latest_tag="${latest_tag:-$(lookup_latest_tag)}"
  lookup_changed_charts "$latest_tag" | exclude_lines "$(excluded_charts_path)"
}

exclude_lines() {
  local temp; temp=$(mktemp)
  printf "%s\n" "$@" > "$temp"; grep -vxf "$temp" || true
  rm -f "$temp" &>/dev/null || true
}

library_paths() {
  local rpath paths=()
  for rpath in "$@"; do
      [ -f "${rpath}/Chart.yaml" ] || continue
      sed -En '/^type:\s+/ { s/^type:\s+//; p; }' "${rpath}/Chart.yaml" | grep -q 'library' || continue
      paths+=("${rpath}")
  done
  printf "%s\n" "${paths[@]}"
}

lookup_changed_charts() {
  local commit="$1"

  local changed_files
  changed_files=$(git diff --find-renames --name-only "$commit" -- "$charts_dir")

  local depth=$(($(tr "/" "\n" <<<"$charts_dir" | sed '/^\(\.\)*$/d' | wc -l) + 1))
  local fields="1-${depth}"

  cut -d '/' -f "$fields" <<<"$changed_files" | uniq | filter_charts
}

find_charts_dir() {
  local cdirs=()
  if [ -n "$charts_dir" ]; then return; fi
  if [ -f "helm/Chart.yaml" ]; then cdirs+=("."); fi
  if [ -f "chart/Chart.yaml" ]; then cdirs+=("."); fi
  if (( "${#cdirs[@]}" > 1 )); then
    errexit "ERROR: Can't use both helm and chart directory."
  fi
  charts_dir="${cdirs[0]:-charts/}"
}

run_unittest() {
  local path testing_paths rs=0 test_run=false;
  read -ra testing_paths <<<"$(list_changed)"

  # update the specified helm repositories
  yq -r '."chart-repos"|.[]' < .github/ct.yaml | sed 's/=/ /' | xargs -rn2 helm repo add

  for path in "${testing_paths[@]}"; do
    if (ls -1 "$path"/tests/*_test.yaml &>/dev/null); then
      test_run=true
      helm dependency update "$path" 
      helm unittest --color "$path" || rs=1
    fi
  done
  ($test_run) || echo ">>> No charts to test. Skipping helm unittest!"
  return $rs
}

set_testing_output() {
  local testing=false testing_paths=() library_paths=() excluded=() excluded_library=()
  readarray -t testing_paths <<< "$(list_changed)"
  # shellcheck disable=SC2068
  readarray -t library_paths <<< "$(library_paths ${testing_paths[@]})"
  readarray -t testing_paths <<< "$(printf "%s\n" "${testing_paths[@]}" | exclude_lines "${library_paths[@]}")"
  readarray -t excluded <<< "$(excluded_charts_path | charts_basename)"

  if [[ -n "${testing_paths[*]}" ]]; then
    testing=true
    if [[ -n "${library_paths[*]}" ]]; then
      readarray -t excluded_library <<< "$(printf "%s\n" "${library_paths[@]}" | charts_basename)"
      echo "excluded-charts=--excluded-charts $(IFS=,; echo "${excluded[*]} ${excluded_library[*]}")" >> "$GITHUB_OUTPUT"
    fi
  else
    echo ">>> No charts updated. Nothing to test!"
  fi

  [ -z "${excluded[*]}" ] || echo "✓ Excluded charts: ${excluded[*]}"
  [ -z "${excluded_library[*]}" ] || echo "✓ Excluded library charts: ${excluded_library[*]}"
  echo "testing=$testing" >> "$GITHUB_OUTPUT"
}

setup_helpers() {
  local tool; tool="$(which_tool python3 apk)"
  echo ">>> Installing yq (using $tool)... "
  runt "$tool" python3 -m pip install yq &> /dev/null
  runt "$tool" apk add yq &> /dev/null

  if (which git &> /dev/null); then
    # required in in-container unit-test workflow: "fatal: detected dubious ownership in repository at ..."
    # make sure git is installed before using helpers.sh
    git config --global --add safe.directory "$GITHUB_WORKSPACE"
  fi

  find_charts_dir
  echo ">>> Using charts directory: ${charts_dir}"
}

setup_helpers