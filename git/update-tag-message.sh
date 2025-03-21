#!/bin/bash
# shellcheck source-path=SCRIPTDIR

UPDATE_CHANGELOG_DIR="$( cd "$( dirname "$(readlink -f "${BASH_SOURCE[0]}")" )" && pwd )"
# echo "SETUP_DIR='${SETUP_DIR}'"
source "${UPDATE_CHANGELOG_DIR}/../../src/echos/echos"

main() {
  # Assign arguments to variables for clarity
  v_tag_name="${1}"
  file="$2"

  if [[ -z "${v_tag_name}" ]]; then
    git tag -l
    fatal "Tag name is required: vx.y.z" 1
  fi
  tag_before=$(git tag -n "${v_tag_name}")
  if [[ -z "${tag_before}" ]]; then
    fatal "Tag '${v_tag_name}' not found" 1
  fi
  info "Tag '${v_tag_name}' message before: '${tag_before}'"

  c_date_time=$(git show -s --format=%ci "${v_tag_name}"^{})
  c_date=$(printf "%s" "${c_date_time}" | cut -f1 -d' ' )
  GIT_COMMITTER_DATE="${c_date_time}"
  GIT_AUTHOR_DATE="${c_date_time}"
  if [[ -z "${file}" ]]; then
    warning "Tag file is missing"
    task "Must only update the creation date of the tag to '${c_date_time}', c_date='${c_date}'"
    tag_msg=$(git show -s --format=%N "${v_tag_name}" | tail -n +4 | sed "1s/^.*\? --\? /${c_date} -- /")
    info "Tag message: '${tag_msg}'"
    if ! printf "%s" "${tag_msg}" | git tag -f -a -F - -- "${v_tag_name}" "$(git rev-parse "${v_tag_name}"^{})" ; then
      fatal "Failed to update tag date for '${v_tag_name}' with date '${GIT_AUTHOR_DATE}' / '${GIT_COMMITTER_DATE}" $?
    fi
    ok "Tag date updated for '${v_tag_name}' at date '$(git for-each-ref "refs/tags/${v_tag_name}" --format="Date: %(taggerdate)")'"
    exit 0
  fi

  if [[ ! -e "${file}" ]]; then
    fatal "Tag file '${file}' not found" 1
  fi

  # Remove leading 'v' if present using parameter expansion
  # This removes the first 'v' only if it exists at the start
  tag_pattern="${v_tag_name#v}"

  tag_after=$(awk -v pattern="${tag_pattern}" -f release_reader.awk "${file}" | sed "1s/^.*\? --\? /${c_date} -- /")
  awk_exit_status=$?  # Capture the exit status immediately
  # Check if AWK executed successfully
  if [ "${awk_exit_status}" -ne 0 ]; then
      fatal "Failed to read tag message from '${file}'" "${awk_exit_status}"
  fi
  info "Tag '$1' message after: '${tag_after}'"

  if [[ "${tag_before}" == "${tag_after}" ]]; then
    ok "Tag message is the same"
    return 0
  fi

  task "Must update tag message from '${v_tag_name}'"
  if ! printf "%s" "${tag_after}" | git tag -f -a -F - -- "${v_tag_name}" "$(git rev-parse "${v_tag_name}"^{})" ; then
    fatal "Failed to update tag message for '${v_tag_name}' with date '${GIT_COMMITTER_DATE}'" $?
  fi
  ok "Tag message updated for '${v_tag_name}'"
  info "Tag '${v_tag_name}' message after: '$(git tag -n1000 "${v_tag_name}")'"
}

main "$@"
