#!/bin/bash
# shellcheck source-path=SCRIPTDIR

UPDATE_CHANGELOG_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"

# shellcheck disable=SC1091
source "${UPDATE_CHANGELOG_DIR}/shcolors/echos"

main() {
  gcliff=("$(cygpath -u "${PRGS}/git-cliffs/current/git-cliff.exe")" -c "${DEV_WORKFLOW_DIR}/cliff.toml" -w "${PRJ_DIR}" -s footer -o "${PRJ_DIR}/CHANGELOG.tmp.md")
  # info "gcliff='${gcliff[*]}'"
  "${gcliff[@]}" -V

  v_tag_name="${1}"
  if [[ "${v_tag_name}" == "latest" ]]; then v_tag_name=""; fi

  previous_tag=""
  if [[ ! -e "${PRJ_DIR}/CHANGELOG.md" ]]; then
    range=()
    "${gcliff[@]}" --
  elif [[ -z "${v_tag_name}" ]]; then
    range=(-- "$(git -C "${PRJ_DIR}" describe --abbrev=0 --tags)..HEAD")
    "${gcliff[@]}" "${range[@]}"
  elif git show-ref --tags --quiet --verify "refs/tags/${v_tag_name}" && [ "$(git cat-file -t "${v_tag_name}")" = "tag" ]; then
    previous_tag=$(git tag --sort=-version:refname | awk "/^${v_tag_name}\$/ {getline; print; exit}")
    info "Previous tag of '${v_tag_name}' is '${previous_tag}'"
    if [[ -z "${previous_tag}" ]]; then
      fatal "Failed to retrieve previous tag of '${v_tag_name}'" 1
    elif [[ "${previous_tag}" == "${v_tag_name}" ]]; then
      # no previous tag: get the first commit of the current branch
      range=()
      "${gcliff[@]}" --
    else
      range=(-- "${previous_tag}..HEAD")
      "${gcliff[@]}" "${range[@]}"
    fi
  else
    fatal "Tag '${v_tag_name}' not found" 1
  fi

  sed -i "s/### Build/### 🔨 Build/g" "${PRJ_DIR}/CHANGELOG.tmp.md"
  sed -i "s/### Wip/### 🚧 Wip/g" "${PRJ_DIR}/CHANGELOG.tmp.md"
  sed -i -e :a -e '/^\n*$/{$d;N;};/\n$/ba' "${PRJ_DIR}/CHANGELOG.tmp.md"
  sed -i 's/\r$//' "${PRJ_DIR}/CHANGELOG.tmp.md"
  sed -i 's/ - v[0-9]\+.*\? - / - /g' "${PRJ_DIR}/CHANGELOG.tmp.md"
  sed -i 's/\] - [0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\} -/\] -/g' "${PRJ_DIR}/CHANGELOG.tmp.md"

  # check if the current commit is tagged
  if ! git describe --exact-match --tags HEAD >/dev/null 2>&1; then
    # If not, use $(git rev-parse HEAD) to get the commit hash
    commit_hash=$(git -C "${PRJ_DIR}" rev-parse HEAD)

    # Include content of version.txt under the ## [unreleased] - line
    version_content=$(sed '1d' "${PRJ_DIR}/version.txt") # Remove the first line
    echo "${version_content}" >"${PRJ_DIR}/version.tmp.txt"
    sed -i "/## \[unreleased\] -/r ${PRJ_DIR}/version.tmp.txt" "${PRJ_DIR}/CHANGELOG.tmp.md"

    # Extract the version and title from the first line of version.txt
    read -r version version_title < <(head -n 1 "${PRJ_DIR}/version.txt" | awk -F ' -- ' '{print $1, $2}')

    # Modify the ## [unreleased] - line with the version, title, and commit hash
    if [[ -z "${make_new_release}" ]]; then
      sed -i "s/## \[unreleased\] -/## [v${version} unreleased] ${version_title} - ${commit_hash}/" "${PRJ_DIR}/CHANGELOG.tmp.md"
    else
      sed -i "s/## \[unreleased\] -/## [v${version}] - $(date +%Y-%m-%d) - ${version_title}/" "${PRJ_DIR}/CHANGELOG.tmp.md"
    fi
  fi

  if [[ ${#range[@]} -eq 0 ]]; then
    cat "${PRJ_DIR}/CHANGELOG.tmp.md" >>"${PRJ_DIR}/CHANGELOG.new.md"
    mv "${PRJ_DIR}/CHANGELOG.new.md" "${PRJ_DIR}/CHANGELOG.tmp.md"
    mv "${PRJ_DIR}/CHANGELOG.tmp.md" "${PRJ_DIR}/CHANGELOG.md"
  else
    if [[ -z "${previous_tag}" ]]; then
      # Replace lines in CHANGELOG.md until the first occurrence of ## [vx.y.z] with the content of CHANGELOG.tmp.md
      sed -i '/^## \[v[0-9]\+\.[0-9]\+\.[0-9]\+\]/,$!d' "${PRJ_DIR}/CHANGELOG.md"
    else
      # Replace lines in CHANGELOG.md between the last instance of '## [${previous_tag}]'' with the content of CHANGELOG.tmp.md

      # Find the line number of the last occurrence of the pattern
      last_line=$(grep -n -E "## \[${previous_tag}\] " "${PRJ_DIR}/CHANGELOG.md" | tail -n 1 | cut -d: -f1)
      if [[ -z "${last_line}" ]]; then
        fatal "Failed to find the last line of '${previous_tag}' in CHANGELOG.md" 1
      fi
      last_line=$((last_line - 1))
      # Ensure that new_last_line is a positive integer
      if [[ "${last_line}" -ge 1 ]]; then
        # Delete all lines from the start of the file up to new_last_line
        sed -i "1,${last_line}d" "${PRJ_DIR}/CHANGELOG.md"
      else
        info "No lines to delete before line ${last_line}."
      fi
    fi

    # Remove any existing sections with the same version to avoid duplicates
    if [[ -n "${version}" ]]; then
      task "Checking for duplicate v${version} sections to remove..."

      # Create a temporary file for the output
      temp_changelog="${PRJ_DIR}/CHANGELOG.cleaned.md"

      # Run the AWK script to remove any existing section with this version
      "${UPDATE_CHANGELOG_DIR}/changelog_duplicate_version_section_remover.awk" -v version="v${version}" "${PRJ_DIR}/CHANGELOG.md" >"${temp_changelog}"
      awk_status=$?

      case $awk_status in
      0)
        info "Found and removed existing v${version} section(s)"
        mv "${temp_changelog}" "${PRJ_DIR}/CHANGELOG.md"
        ;;
      2)
        info "No existing v${version} sections found"
        rm "${temp_changelog}"
        ;;
      *)
        fatal "Error removing duplicate sections for v${version}" $awk_status
        ;;
      esac
    fi

    (
      cat "${PRJ_DIR}/CHANGELOG.tmp.md"
      echo ""
      cat "${PRJ_DIR}/CHANGELOG.md"
    ) >"${PRJ_DIR}/CHANGELOG.new.md"
    mv "${PRJ_DIR}/CHANGELOG.new.md" "${PRJ_DIR}/CHANGELOG.md"
  fi

  rm -f "${PRJ_DIR}/CHANGELOG.tmp.md"
  rm -f "${PRJ_DIR}/version.tmp.txt"

  cat "${HEADER_CHANGELOG_FILE}" >"${PRJ_DIR}/CHANGELOG.new.md"
  echo "" >>"${PRJ_DIR}/CHANGELOG.new.md" # Add blank line after header
  cat "${PRJ_DIR}/CHANGELOG.md" >>"${PRJ_DIR}/CHANGELOG.new.md"

  # Label changelog sections with version numbers
  task "Must label changelog sections with version numbers..."
  "${UPDATE_CHANGELOG_DIR}/changelog_section_labeler.awk" "${PRJ_DIR}/CHANGELOG.new.md" >"${PRJ_DIR}/CHANGELOG.labeled.md"
  awk_status=$?

  if [ $awk_status -ne 0 ]; then
    fatal "Failed to label changelog sections with version numbers" $awk_status
  else
    info "Successfully labeled changelog sections with version numbers"
    mv "${PRJ_DIR}/CHANGELOG.labeled.md" "${PRJ_DIR}/CHANGELOG.new.md"
  fi

  # Apply custom fixes from .changelog.fixes if it exists
  if [ -f "${PRJ_DIR}/.changelog.fixes" ]; then
    task "Must apply custom fixes from .changelog.fixes file..."

    # Create a temporary Perl script to process all replacements in one pass
    perl_script="${PRJ_DIR}/tmp_fixes.pl"

    # Start writing the Perl script with header
    cat >"${perl_script}" <<'EOF'
#!/usr/bin/perl -pi
BEGIN {
  @patterns = ();
  @replacements = ();
}

# Process each line of the input file
{
  my $line = $_;
  foreach my $i (0..$#patterns) {
    $line =~ s/$patterns[$i]/$replacements[$i]/g;
  }
  $_ = $line;
}
EOF

    # Add the patterns and replacements to the Perl script
    echo "BEGIN {" >>"${perl_script}"

    # Check if .changelog.fixes begins with PERL_CODE marker
    if grep -q "^PERL_CODE$" "${PRJ_DIR}/.changelog.fixes"; then
      # Extract everything after the PERL_CODE marker and append directly to the script
      sed -n '/^PERL_CODE$/,${/^PERL_CODE$/d;p}' "${PRJ_DIR}/.changelog.fixes" >>"${perl_script}"
      info "Using direct Perl code from .changelog.fixes"
    else
      # Process in traditional way with => separator
      while IFS= read -r line; do
        # Trim whitespace and skip comments/empty lines
        line=$(echo "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        if [[ "$line" == "" || "$line" == \#* ]]; then
          continue
        fi

        # Process valid lines with => separator
        if [[ "$line" == *"=>"* ]]; then
          regex="${line%%=>*}"
          replacement="${line#*=>}"

          # Trim whitespace
          regex=$(echo "$regex" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
          replacement=$(echo "$replacement" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

          # Escape special characters for Perl string
          regex=$(echo "$regex" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g')
          replacement=$(echo "$replacement" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g')

          # Add to Perl arrays
          echo "  push @patterns, \"$regex\";" >>"${perl_script}"
          echo "  push @replacements, \"$replacement\";" >>"${perl_script}"

          info "Added replacement rule: '$regex' => '$replacement'"
        else
          warn "Ignoring malformed line in .changelog.fixes: ${line}"
        fi
      done <"${PRJ_DIR}/.changelog.fixes"
    fi

    # Close the BEGIN block
    echo "}" >>"${perl_script}"

    # Run the Perl script on CHANGELOG.new.md
    if perl -i "${perl_script}" "${PRJ_DIR}/CHANGELOG.new.md"; then
      ok "All .changelog.fixes rules applied successfully in a single pass"
    else
      warn "Some rules from .changelog.fixes may have failed to apply"
    fi

    # Clean up
    rm -f "${perl_script}"
  else
    info "No .changelog.fixes file found, skipping custom fixes"
  fi

  mv "${PRJ_DIR}/CHANGELOG.new.md" "${PRJ_DIR}/CHANGELOG.md"

}

main "$@"
