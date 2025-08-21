#!/usr/bin/perl
use strict;
use warnings;

# NEW: Check for the debug environment variable ONCE at the start.
# This is more efficient than checking inside the loop.
my $is_debug = exists $ENV{CHANGELOG_DBG};

warn "Perl script starting...\n" if exists $ENV{CHANGELOG_DBG};

# Initialize the arrays that will hold the regex patterns and their corresponding replacements.
my @patterns = ();
my @replacements = ();

# Rule 1: Find and wrap URLs in angle brackets.
# This rule is more specific and should run first to avoid conflicts.
push @patterns, qr/(?<!<)(https?:\S+)(?<!>)\b/m;
push @replacements, '"<$1>"';

# Rule 2: Clean up any single trailing space or tab after a non-space character.
# This pattern uses a positive lookahead to find the whitespace that is
# followed by a newline sequence, without consuming the newline itself.
push @patterns, qr/(\S)(?: |\t)(?=\r|\n)/m;
push @replacements, '"$1"'; # The replacement template uses '\1' for the first capture group.

# Rule 3: Replace a leading asterisk-space with a dash-space for list items.
push @patterns, qr/^\* /m;
push @replacements, '"- "';

#FIXES_CONTENT_GOES_HERE#

# 1. Read the entire file into a single variable ("slurp mode").
my $content = do { local $/; <> };

# 2. Iterate through each rule and apply it to the entire content.
for my $i (0 .. $#patterns) {
    my $pattern = $patterns[$i];
    my $replacement = $replacements[$i];

    # NEW: The s///g operator in list context returns the number of substitutions made.
    # We capture this count to see if the rule did anything.
    my $match_count = ($content =~ s/$pattern/$replacement/gee);

    # NEW: If the debug flag is set, print the status of the rule application.
    if ($is_debug) {
        my $rule_num = $i + 1; # Use a 1-based index for user-friendly messages.
        if ($match_count > 0) {
            # This message prints to STDERR, so it won't affect the output file.
            warn "[DEBUG] Rule $rule_num: ✅ Applied successfully ($match_count matches) with pattern '$pattern': replacement '$replacement'.\n";
        } else {
            warn "[DEBUG] Rule $rule_num: ➖ No matches found for pattern '$pattern'.\n";
        }
    }
}

# 3. Print the final, modified content to standard output.
print $content;
