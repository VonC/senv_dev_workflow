#!/usr/bin/awk -f
# Script to remove a specific version section from a changelog
# Usage: changelog_duplicate_version_section_remover.awk -v version=v0.18.0 input_file > output_file
# Returns: 0 if section removed, 2 if section not found

BEGIN {
  if (version == "") {
    print "Error: version parameter is required" > "/dev/stderr"
    exit 1
  }
  # Match the exact version followed by either a space or hyphen
  version_pattern = "^## \\[" version "[ \\-\\]]"
  in_section_to_remove = 0
  found_section = 0
}

# If we find the target version section header
$0 ~ version_pattern {
  in_section_to_remove = 1
  found_section = 1
  next
}

# If we find any other version section header while removing
/^## \[v[0-9]+\.[0-9]+\.[0-9]+/ {
  # Check if this new section also matches our target version
  if ($0 ~ version_pattern) {
    # Keep removing if it's another instance of our target version
    in_section_to_remove = 1
    found_section = 1
    next
  } else if (in_section_to_remove) {
    # Stop removing only if it's a different version
    in_section_to_remove = 0
  }
  print
  next
}

# Print all lines except those in the section to remove
{
  if (!in_section_to_remove) {
    print
  }
}

END {
  exit found_section ? 0 : 2
}
