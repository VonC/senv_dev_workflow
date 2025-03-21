# Description:
#   This AWK program searches for the first line starting with a given pattern.
#   If no pattern is provided, it considers the first line of the file.
#   Once the target line is found, it prints that line followed by an empty line.
#   From the found line onwards:
#     - It prints non-empty lines.
#     - If a line is empty and the previous line was not empty, it prints the empty line.
#     - It ignores empty lines if the previous line was also empty.
#     - If a line starts with at least three '-', the script exits without printing that line.
#     - Before exiting, it removes the trailing newline of the last printed line.

BEGIN {
    # Initialize flags and buffer
    found = 0
    print_empty_line = 0
    buffer = ""

    # Set the search pattern if provided via the -v option
    if (pattern != "") {
        search_pattern = "^" pattern
    } else {
        search_pattern = ""
    }
}

{
    if (!found) {
        if (search_pattern != "") {
            # Check if the line starts with the search pattern
            if ($0 ~ search_pattern) {
                buffer = $0
                found = 1
                print_empty_line = 1
                next
            }
        } else {
            # No pattern provided; consider the first line
            buffer = $0
            found = 1
            print_empty_line = 1
            next
        }
    } else {
        if ($0 ~ /^-{3,}/) {
            exit                # Do not print and exit when line starts with at least three '-'
        } else if ($0 ~ /\S/) {
            if (print_empty_line == 1) {
                buffer = buffer "\n"        # Print an empty line before the first non-empty line
                print_empty_line = 0
            }
            buffer = buffer "\n" $0            # Update the buffer with the current non-empty line
        } else {
            print_empty_line = 1    # Indicate that an empty line should be printed before the next non-empty line
        }
    }
}

END {
    # Print any remaining buffered line without adding a newline
    if (buffer != "") {
        printf "%s", buffer
    }

    if (pattern != "" && !found) {
        print "Pattern \"" pattern "\" not found." > "/dev/stderr"
        exit 1
    }
}