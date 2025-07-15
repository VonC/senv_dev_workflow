#!/usr/bin/perl -pi

# This BEGIN block is executed once before the first line of the input file is read.
# It initializes the patterns and replacements arrays and populates them with rules
# that will be injected by the calling script.
BEGIN {
  # Initialize the arrays that will hold the regex patterns and their corresponding replacements.
  @patterns = ();
  @replacements = ();

  #FIXES_CONTENT_GOES_HERE#
}

# This block is executed for each line of the input file.
{
  # Alias the current line to a more descriptive variable.
  my $line = $_;

  # Iterate through each pattern/replacement pair.
  foreach my $i (0..$#patterns) {
    my $pattern = $patterns[$i];
    my $replacement_template = $replacements[$i];
    my $new_line = "";
    my $last_pos = 0;

    # This loop programmatically performs a global search and replace.
    # The m/$pattern/g in a while loop finds each successive match.
    # The =~ operator is the fundamental way in Perl to apply a regex to a string.
    while ($line =~ m/$pattern/g) {
      # Append the part of the string from the end of the last match
      # to the beginning of the current one. $-[0] is the start offset of the match.
      $new_line .= substr($line, $last_pos, $-[0] - $last_pos);

      # Immediately save the capture variables ($1, $2, etc.) from the match.
      my @captures = ($1, $2, $3, $4, $5, $6, $7, $8, $9);

      # Build the final replacement string by substituting the \1, \2 placeholders
      # in our template with the content of the saved capture variables. This loop
      # avoids the =~ operator for this task, using split and join instead.
      my $current_replacement = $replacement_template;
      foreach my $j (0..8) {
          # Create the placeholder string, e.g., '\1', '\2'
          my $placeholder = '\\' . ($j + 1);
          # Get the corresponding captured value, defaulting to an empty string if undefined.
          my $value = $captures[$j] // "";
          # Use split with a regex for the placeholder. The -1 limit preserves trailing empty fields.
          # The \Q...\E ensures the placeholder (e.g., '\1') is treated literally and not as a regex.
          $current_replacement = join($value, split(/\Q$placeholder\E/, $current_replacement, -1));
      }

      # Append the fully-built replacement string.
      $new_line .= $current_replacement;

      # Update our position to the end of the current match.
      # $+[0] is the end offset of the match.
      $last_pos = $+[0];
    }

    # After the loop, append the remainder of the original string
    # that came after the very last match.
    $new_line .= substr($line, $last_pos);

    # Overwrite the original line with our newly constructed one for the next rule.
    $line = $new_line;
  }

  # Update the special $_ variable so the -i flag writes the final result to the file.
  $_ = $line;
}
