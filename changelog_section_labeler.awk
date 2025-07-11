#!/usr/bin/awk -f

BEGIN {
    current_version = ""
}

# Extract version from lines starting with "## [v"
/^## \[v[0-9]+\.[0-9]+\.[0-9]+/ {
    # Use regex to extract just the version number (v0.17.0) 
    # regardless of whether it's a snapshot or released
    match($0, /v[0-9]+\.[0-9]+\.[0-9]+/, version_array)
    current_version = version_array[0]
    print $0
    next
}

# Process section headers (lines starting with ###)
/^### / {
    # Check if the line already has a version in parentheses
    if ($0 ~ /\(v[0-9]+\.[0-9]+\.[0-9]+\)/) {
        # If it already contains a version, print as is
        print $0
    } else {
        # If not, append the current version
        print $0 " (" current_version ")"
    }
    next
}

# Print all other lines unchanged
{
    print $0
}
