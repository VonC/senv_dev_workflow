#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper; # Using Data::Dumper for clear output

# Parameters: git-dirty-filter.pl [path-to-update-version-dir] [path-to-project-dir]
# Get the arguments or use environment variables as fallback
my $update_version_dir = $ARGV[0];
my $prj_dir = $ARGV[1];

# Validate or use environment fallbacks
if (!defined $update_version_dir || $update_version_dir eq '') {
    $update_version_dir = $ENV{'update-version_dir'} || die "Missing update-version-dir path";
}

if (!defined $prj_dir || $prj_dir eq '') {
    $prj_dir = $ENV{'PRJ_DIR'} || die "Missing project-dir path";
}

my $output_file = "$update_version_dir/git/dirty_files.tmp";
my @exempted_patterns = ();

# Read exempted patterns from update-version_dir file
my $exempted_file = "$update_version_dir/git/exempt-files.txt";
if (-e $exempted_file) {
    open my $fh, '<', $exempted_file or die "Cannot open $exempted_file: $!";
    while (my $line = <$fh>) {
        chomp $line;
        next if $line =~ /^\s*#/ || $line =~ /^\s*$/;  # Skip comments and empty lines
        push @exempted_patterns, $line;
    }
    close $fh;
}

# Read exempted patterns from project directory if exists
my $project_exempted_file = "$prj_dir/.exempt-files";
if (-e $project_exempted_file) {
    open my $fh, '<', $project_exempted_file or die "Cannot open $project_exempted_file: $!";
    while (my $line = <$fh>) {
        chomp $line;
        next if $line =~ /^\s*#/ || $line =~ /^\s*$/;  # Skip comments and empty lines
        push @exempted_patterns, $line;
    }
    close $fh;
}

my $found_src = 0;
my $found_files = 0;
my @matched_lines = ();

# Process STDIN (git status output)
while (my $line = <STDIN>) {
    chomp $line;
    my $is_exempted = 0;
    
    # Check if line matches any exempted pattern
    for my $pattern (@exempted_patterns) {
        if ($line =~ /(\s+\S+\s+)($pattern)$/) {
            $is_exempted = 1;
            last;
        }
    }
    
    # If line DOESN'T match any exempted pattern, add it to our results
    if (!$is_exempted) {
        push @matched_lines, $line;
        $found_files = 1;
        $found_src = 1 if $line =~ /src\//;
    }
}

# Write results to output file if matches found
if ($found_files) {
    open my $out, '>', $output_file or die "Cannot open $output_file for writing: $!";
    print $out join("\n", @matched_lines);
    close $out;
}

# --- DEBUGGING OUTPUT START ---
# Conditionally print debug info if the UV_DEBUG_FILTER environment variable is set.
if (defined $ENV{'UV_DEBUG_FILTER'}) {
    # Get the number of matched lines by evaluating the array in a scalar context.
    my $num_matched_lines = scalar(@matched_lines);

    # Print the values to STDERR so they don't interfere with STDOUT.
    print STDERR "--- DEBUG INFO ---\n";
    print STDERR "Value of \$found_files: " . Dumper($found_files);
    print STDERR "Value of \$found_src: " . Dumper($found_src);
    print STDERR "Number of matched lines found: $num_matched_lines\n";
    print STDERR "------------------\n";
}
# --- DEBUGGING OUTPUT END ---

# Exit with special codes for batch script to detect
exit(3) if $found_src && $found_files;
exit(2) if $found_files;
exit(0);
