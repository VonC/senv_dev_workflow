#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;

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
my $ignored_output_file = "$update_version_dir/git/dirty_ignored_files.tmp";
my @exempted_patterns = ();
my @project_exempted_patterns = (); # Separate array for project-specific patterns

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
        push @project_exempted_patterns, $line;
        push @exempted_patterns, $line; # Also add to combined patterns
    }
    close $fh;
}

my $found_src = 0;
my $found_files = 0;
my @matched_lines = ();
my @ignored_lines = ();  # Only for project-specific exempted files

# Process STDIN (git status output)
while (my $line = <STDIN>) {
    chomp $line;
    my $is_exempted = 0;
    my $is_project_exempted = 0;
    
    # Debug - Print the line being processed
    if (defined $ENV{'UV_DEBUG_FILTER'}) {
        print STDERR "Processing line: '$line'\n";
    }

    # First check if line matches any project-specific exempted pattern
    for my $pattern (@project_exempted_patterns) {
        if (defined $ENV{'UV_DEBUG_FILTER'}) {
            print STDERR "  Checking against project pattern: '$pattern'\n";
        }

        if ($line =~ /(\s+\S+\s+)($pattern)$/) {
            $is_project_exempted = 1;
            $is_exempted = 1;
            push @ignored_lines, $line;

            if (defined $ENV{'UV_DEBUG_FILTER'}) {
                print STDERR "  ✓ MATCHED project pattern! Line added to ignored_lines\n";
            }
            last;
        } else {
            if (defined $ENV{'UV_DEBUG_FILTER'}) {
                print STDERR "  ✗ No match for project pattern\n";
            }
        }
    }

    # If not project-exempted, check if it matches any standard exempted pattern
    if (!$is_project_exempted) {
        for my $pattern (@exempted_patterns) {
            if (defined $ENV{'UV_DEBUG_FILTER'}) {
                print STDERR "  Checking against standard pattern: '$pattern'\n";
            }

            if ($line =~ /(\s+\S+\s+)($pattern)$/) {
                $is_exempted = 1;

                if (defined $ENV{'UV_DEBUG_FILTER'}) {
                    print STDERR "  ✓ MATCHED standard pattern! Line will be excluded from matched_lines\n";
                }
                last;
            } else {
                if (defined $ENV{'UV_DEBUG_FILTER'}) {
                    print STDERR "  ✗ No match for standard pattern\n";
                }
            }
        }
    }
    
    # If line DOESN'T match any exempted pattern, add it to our results
    if (!$is_exempted) {
        push @matched_lines, $line;
        $found_files = 1;
        $found_src = 1 if $line =~ /src\//;

        if (defined $ENV{'UV_DEBUG_FILTER'}) {
            print STDERR "  → Line not exempted, added to matched_lines\n";
            if ($line =~ /src\//) {
                print STDERR "  → src/ detected in path\n";
            }
        }
    }

    if (defined $ENV{'UV_DEBUG_FILTER'}) {
        print STDERR "------------------------------------\n";
    }
}

# Write results to output file if matches found
if ($found_files) {
    open my $out, '>', $output_file or die "Cannot open $output_file for writing: $!";
    foreach my $line (@matched_lines) {
        print $out "$line\n";
    }
    close $out;
}

# Write ignored files to separate output file
if (@ignored_lines) {
    open my $out, '>', $ignored_output_file or die "Cannot open $ignored_output_file for writing: $!";
    foreach my $line (@ignored_lines) {
        print $out "$line\n";
    }
    close $out;
}

# --- DEBUGGING OUTPUT START ---
# Conditionally print debug info if the UV_DEBUG_FILTER environment variable is set.
if (defined $ENV{'UV_DEBUG_FILTER'}) {
    # Get the number of matched lines by evaluating the array in a scalar context.
    my $num_matched_lines = scalar(@matched_lines);
    my $num_ignored_lines = scalar(@ignored_lines);

    # Print the values to STDERR so they don't interfere with STDOUT.
    print STDERR "--- DEBUG INFO ---\n";
    print STDERR "Value of \$found_files: " . Dumper($found_files);
    print STDERR "Value of \$found_src: " . Dumper($found_src);
    print STDERR "Number of matched lines found: $num_matched_lines\n";
    print STDERR "Number of ignored lines found: $num_ignored_lines\n";
    print STDERR "------------------\n";
}

# Exit with special codes for batch script to detect
exit(3) if $found_src && $found_files;
exit(2) if $found_files;
exit(0);
