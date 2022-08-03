#!/usr/bin/env perl
use strict;
use warnings;

=head1 NAME

buildtable.pl - Build and check the syllabics composition table.

=head1 SYNOPSIS

  ./buildtable.pl check "myfont.woff" "My Font Name" < chartable.txt
  ./buildtable.pl build < chartable.txt

=head1 DESCRIPTION

This script takes on standard input the syllabics character data table.
In C<check> mode it prints out an HTML page containing all characters
organized in tables, allowing you to check that everything in the
character data table is correct.  You must provide the path to a WOFF
font to use for displaying within the tables and the font name used in
the CSS.

In C<build> mode it prints out a JSON object that maps key strings to
value strings.  The key strings are composition strings that store two
or more Ojitype composeable syllabics entities, sorted in ascending
value of numeric codepoint.  The value strings contain the resulting
codepoint encoded as a single-character string.

=head2 Character data table format

The character data table is a plain US-ASCII text file.  Each line is
either blank or contains a record.  Records are four base-16 digits
identifying a Unicode codepoint, a space, and then a definition.

Definitions can have multiple formats.

I<Symbol> definitions are an asterisk, a space, and then a sequence of
letters and underscores giving the symbol a name.  These definitions are
used for punctuation marks and special symbols.

I<Ghost> definitions are a tilde, a space, and then a sequence of
letters and underscores giving the character a name.  These definitions
are used for characters that are not visible.

I<Eastern> definitions are for eastern finals.  They consist of just one
of the following consonant characters:

  p t c k m n s S y l r

The capital S means the sh consonant.  For C<l> and C<r> this format
indicates the final form.

I<Western> definitions are for western finals.  They consist of an
apostrophe followed by one of the eastern final characters.  For C<l>
and C<r> this format indicates the full-height medial form.

I<Alternate> definitions consist of an ASCII double-quote followed by
one of the following characters:

  y l r

For C<y> this is the high-plus alternate form.  For C<l> and C<r> this
format indicates the raised medial form.

I<Common> definitions are for finals that are the same in both eastern
and western styles.  They consist of just one of the following consonant
characters:

  w h

I<Syllable> definitions are for symbols that are neither finals nor
special symbols.  They have the following structure, in the following
order of elements:

(1) Optionally, one of the eastern final characters.

(2) Optionally, C<w> or C<u> to indicate a w-dot, with C<w> used for
dots to the left and C<u> used for dots to the right.

(3) Optionally, a C<+> sign indicating a long vowel dot.

(4) One of the four vowels C<a> C<e> C<i> C<o> which is B<required.>

Each record must have a unique definition and a unique codepoint.

=cut

# =========
# Constants
# =========

# Set that maps missing syllable definitions to value of one.
#
# Unicode does not define all possible syllablics syllables.  This set
# contains the definitions that Unicode is missing.
#
my %MISSING_DFN = (
  'Sru.a' => 1,
  'Sru.i' => 1,
  'Sru.o' => 1,
  'Sru+i' => 1,
  'Sru+o' => 1
);

# ==================
# Program entrypoint
# ==================

# Determine program mode from argument
#
($#ARGV >= 0) or die "Wrong number of program arguments, stopped";
my $mode = $ARGV[0];

(($mode eq 'check') or ($mode eq 'build')) or
  die "Unknown mode '$mode', stopped";

# Get and check additional arguments based on program mode
#
my $font_path;
my $font_name;

if ($mode eq 'check') {
  ($#ARGV == 2) or
    die "Wrong number of program arguments for mode, stopped";
  
  $font_path = $ARGV[1];
  $font_name = $ARGV[2];
  
  ($font_path =~ /\A[\x{20}-\x{26}\x{28}-\x{7e}]+\z/) or
    die "Font path is invalid, stopped";
  
  ($font_name =~ /\A[\x{20}-\x{26}\x{28}-\x{7e}]+\z/) or
    die "Font name is invalid, stopped";
  
} elsif ($mode eq 'build') {
  ($#ARGV == 0) or
    die "Wrong number of program arguments for mode, stopped";
  
} else {
  die "Unexpected";
}

# Define a map of definitions to their integer codepoint values; see the
# %code_map for structure of definitions
#
my %dfn_map;

# Define a map of decimal codepoint values to parsed definitions;
# parsed definitions are special strings; the first character of the
# string is P or G or E or W or C or A or S, indicating the type
# (Punctuation, Ghost, Eastern, Western, Common, Alternate, or
# Syllable); for P types, the rest of the string is the name of the
# punctuation symbol; for G types, the rest of the string is the name of
# the ghost character; for E types and W types, the second character is
# one of the eastern final characters; for C types, the second character
# is one of the common symbol characters; for A types, the second
# character is one of the alternate characters; for S types, second
# character is eastern final or dot if none, third character is w or u
# or dot if none, fourth character is + or dot for none, fifth character
# is vowel
#
my %code_map;

# Read standard input, building the definition maps
#
while (<STDIN>) {
  
  # Drop line breaks
  chomp;
  
  # Skip if blank
  (not /\A\s*\z/) or next;
  
  # Parse a record and process it
  if (/\A([0-9a-fA-F]{4}) \* ([A-Za-z_]+)\s*\z/) { # ===================
    # Symbol -- get fields
    my $cpv   = hex($1);
    my $sname = $2;
    
    # Build the definition string
    my $dfn = "P$sname";
    
    # Check that neither codepoint nor definition already defined
    (not defined $code_map{$cpv}) or
      die (sprintf "Codepoint %04x redefined, stopped", $cpv);
    (not defined $dfn_map{$dfn}) or
      die "Definition $dfn used twice, stopped";
    
    # Add to both maps
    $code_map{$cpv} = $dfn;
    $dfn_map{ $dfn} = $cpv;
    
  } elsif (/\A([0-9a-fA-F]{4}) ~ ([A-Za-z_]+)\s*\z/) { # ===============
    # Ghost character -- get fields
    my $cpv   = hex($1);
    my $sname = $2;
    
    # Build the definition string
    my $dfn = "G$sname";
    
    # Check that neither codepoint nor definition already defined
    (not defined $code_map{$cpv}) or
      die (sprintf "Codepoint %04x redefined, stopped", $cpv);
    (not defined $dfn_map{$dfn}) or
      die "Definition $dfn used twice, stopped";
    
    # Add to both maps
    $code_map{$cpv} = $dfn;
    $dfn_map{ $dfn} = $cpv;
    
  } elsif (/\A([0-9a-fA-F]{4}) ([ptckmnsSylr])\s*\z/) { # ==============
    # Eastern final -- get fields
    my $cpv = hex($1);
    my $fch = $2;
    
    # Build the definition string
    my $dfn = "E$fch";
    
    # Check that neither codepoint nor definition already defined
    (not defined $code_map{$cpv}) or
      die (sprintf "Codepoint %04x redefined, stopped", $cpv);
    (not defined $dfn_map{$dfn}) or
      die "Definition $dfn used twice, stopped";
    
    # Add to both maps
    $code_map{$cpv} = $dfn;
    $dfn_map{ $dfn} = $cpv;
    
  } elsif (/\A([0-9a-fA-F]{4}) '([ptckmnsSylr])\s*\z/) { # =============
    # Western final -- get fields
    my $cpv = hex($1);
    my $fch = $2;
    
    # Build the definition string
    my $dfn = "W$fch";
    
    # Check that neither codepoint nor definition already defined
    (not defined $code_map{$cpv}) or
      die (sprintf "Codepoint %04x redefined, stopped", $cpv);
    (not defined $dfn_map{$dfn}) or
      die "Definition $dfn used twice, stopped";
    
    # Add to both maps
    $code_map{$cpv} = $dfn;
    $dfn_map{ $dfn} = $cpv;
  
  } elsif (/\A([0-9a-fA-F]{4}) ([wh])\s*\z/) { # =======================
    # Common final -- get fields
    my $cpv = hex($1);
    my $fch = $2;
    
    # Build the definition string
    my $dfn = "C$fch";
    
    # Check that neither codepoint nor definition already defined
    (not defined $code_map{$cpv}) or
      die (sprintf "Codepoint %04x redefined, stopped", $cpv);
    (not defined $dfn_map{$dfn}) or
      die "Definition $dfn used twice, stopped";
    
    # Add to both maps
    $code_map{$cpv} = $dfn;
    $dfn_map{ $dfn} = $cpv;
  
  } elsif (/\A([0-9a-fA-F]{4}) "([ylr])\s*\z/) { # =====================
    # Alternate -- get fields
    my $cpv = hex($1);
    my $fch = $2;
    
    # Build the definition string
    my $dfn = "A$fch";
    
    # Check that neither codepoint nor definition already defined
    (not defined $code_map{$cpv}) or
      die (sprintf "Codepoint %04x redefined, stopped", $cpv);
    (not defined $dfn_map{$dfn}) or
      die "Definition $dfn used twice, stopped";
    
    # Add to both maps
    $code_map{$cpv} = $dfn;
    $dfn_map{ $dfn} = $cpv;
    
  } elsif # ============================================================
    (/\A([0-9a-fA-F]{4}) ([ptckmnsSylr])?(w|u)?(\+)?([aeio])?\s*\z/) {
    # Syllable -- get fields
    my $cpv  = hex($1);
    my $cons = $2;
    my $wdot = $3;
    my $vlen = $4;
    my $vowl = $5;
    
    # If vowel is "e" then vowel length is not allowed
    if (($vowl eq 'e') and (defined $vlen)) {
      die "Syllable $_ is invalid, stopped";
    }
    
    # Build the definition string
    my $dfn = "S";
    
    if (defined $cons) {
      $dfn = $dfn . $cons;
    } else {
      $dfn = $dfn . '.';
    }
    
    if (defined $wdot) {
      $dfn = $dfn . $wdot;
    } else {
      $dfn = $dfn . '.';
    }
    
    if (defined $vlen) {
      $dfn = $dfn . $vlen;
    } else {
      $dfn = $dfn . '.';
    }
    
    $dfn = $dfn . $vowl;
    
    # Check that neither codepoint nor definition already defined
    (not defined $code_map{$cpv}) or
      die (sprintf "Codepoint %04x redefined, stopped", $cpv);
    (not defined $dfn_map{$dfn}) or
      die "Definition $dfn used twice, stopped";
    
    # Add to both maps
    $code_map{$cpv} = $dfn;
    $dfn_map{ $dfn} = $cpv;
    
  } else { # ===========================================================
    die "Can't parse record: $_";
  }
}

# Make sure all eastern and western finals are defined
#
for my $c (split //, "ptckmnsSylr") {
  (defined $dfn_map{"W$c"}) or
    die "Missing western final $c, stopped";
  (defined $dfn_map{"E$c"}) or
    die "Missing eastern final $c, stopped";
}

# Make sure all common finals are defined
#
for my $c (split //, "wh") {
  (defined $dfn_map{"C$c"}) or
    die "Missing common final $c, stopped";
}

# Make sure all alternate finals are defined
#
for my $c (split //, "ylr") {
  (defined $dfn_map{"A$c"}) or
    die "Missing alternate final $c, stopped";
}

# Warn which syllable combinations are missing -- not all combinations
# are defined by Unicode, so there will be warnings
#
for my $initial (split //, ".ptckmnsSylr") {
  for my $wdot (split //, ".wu") {
    for my $vlen (split //, ".+") {
      for my $vowl (split //, "aeio") {
        # If vowel is e, then skip any lengthened versions
        (not (($vowl eq 'e') and ($vlen eq '+'))) or next;
        
        # Build current syllable definition
        my $dfn = "S$initial$wdot$vlen$vowl";
        
        # If syllable is on the missing syllable list, skip it
        (not defined $MISSING_DFN{$dfn}) or next;
        
        # Check that syllable definition is present or warn
        (defined $dfn_map{$dfn}) or
          die "Missing syllable $dfn, stopped";
      }
    }
  }
}

# Perform requested action with the data
#
if ($mode eq 'check') { # ==============================================
  # Switch to UTF-8 output in CR+LF mode
  binmode(STDOUT, ":encoding(UTF-8) :crlf") or
    die "Failed to set UTF-8 output, stopped";
  
  # Write the HTML header
  print <<EOF;
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8"/>
    <title>Syllabics test charts</title>
    <meta name="viewport" 
      content="width=device-width, initial-scale=1.0"/>
    <style>

EOF

  # Write the font declaration
  print '@font-face {';
  print "\n";
  print <<EOF;
    font-family: '$font_name';
    src: url('$font_path') format('woff');
    font-weight: normal;
    font-style: normal;
}

EOF

  # Write the rest of the HTML header
  print <<EOF;
body {
  max-width: 35em;
  margin-left: auto;
  margin-right: auto;
  padding-left: 0.5em;
  padding-right: 0.5em;
  margin-top: 2.5em;
  margin-bottom: 5em;
  font-family: '$font_name', sans-serif;
  color: black;
  background-color: linen;
}

table {
  border-collapse: collapse;
  margin-top: 2.5em;
  margin-bottom: 2.5em;
}

td {
  border: thin solid;
  padding: 0.5em;
  text-align: center;
}

th {
  border: thin solid;
  padding: 0.5em;
  font-weight: bold;
  text-align: center;
}

.missing {
  background-color: silver;
}
    
    </style>
  </head>
  <body>
EOF

  # Write the punctuation table
  print <<EOF;
<table>
  <tr>
    <th>Punctuation</th>
    <th colspan="2">Symbol</th>
  </tr>
EOF

  for my $k (sort keys %dfn_map) {
    # Only proceed if key is for a punctuation symbol
    if ($k =~ /\AP([A-Za-z_]+)\z/) {
      my $pname = $1;
      my $sym   = chr($dfn_map{$k});
      my $cpv   = sprintf "U+%04X", $dfn_map{$k};
      print <<EOF;
  <tr>
    <td>$pname</td>
    <td>$sym</td>
    <td>$cpv</td>
  </tr>
EOF
    }
  }
  
  print "</table>\n";
  
  # Write the ghost symbols table
  print <<EOF;
<table>
  <tr>
    <th>Ghost symbol</th>
    <th>Codepoint</th>
  </tr>
EOF

  for my $k (sort keys %dfn_map) {
    # Only proceed if key is for a ghost symbol
    if ($k =~ /\AG([A-Za-z_]+)\z/) {
      my $pname = $1;
      my $cpv   = sprintf "U+%04X", $dfn_map{$k};
      print <<EOF;
  <tr>
    <td>$pname</td>
    <td>$cpv</td>
  </tr>
EOF
    }
  }
  
  print "</table>\n";
  
  # Write the common finals table
  print <<EOF;
<table>
  <tr>
    <th>Common final</th>
    <th colspan="2">Symbol</th>
  </tr>
EOF

  for my $c (split //, "wh") {
    my $sym = chr($dfn_map{"C$c"});
    my $cpv = sprintf "U+%04X", $dfn_map{"C$c"};
    print <<EOF;
  <tr>
    <td>$c</td>
    <td>$sym</td>
    <td>$cpv</td>
  </tr>
EOF
  }
  
  print "</table>\n";
  
  # Write the eastern and western finals table
  print <<EOF;
<table>
  <tr>
    <th>Final</th>
    <th colspan="2">Eastern</th>
    <th colspan="2">Western</th>
    <th colspan="2">Alternate</th>
  </tr>
EOF

  for my $c (split //, "ptckmnsSylr") {
    my $west = chr($dfn_map{"W$c"});
    my $east = chr($dfn_map{"E$c"});
    my $altc;
    my $wcpv = sprintf "%04X", $dfn_map{"W$c"};
    my $ecpv = sprintf "%04X", $dfn_map{"E$c"};
    my $acpv;
    
    if (($c eq 'y') or ($c eq 'l') or ($c eq 'r')) {
      $altc = chr($dfn_map{"A$c"});
      $acpv = sprintf "%04X", $dfn_map{"A$c"};
    }
    
    if ($c eq 'S') {
      $c = 'sh';
    }
    
    if (defined $altc) {
      print <<EOF;
  <tr>
    <td>$c</td>
    <td>$east</td>
    <td>$ecpv</td>
    <td>$west</td>
    <td>$wcpv</td>
    <td>$altc</td>
    <td>$acpv</td>
  </tr>
EOF
    } else {
      print <<EOF;
  <tr>
    <td>$c</td>
    <td>$east</td>
    <td>$ecpv</td>
    <td>$west</td>
    <td>$wcpv</td>
    <td class="missing" colspan="2">&nbsp;</td>
  </tr>
EOF
    }
  }
  
  print "</table>\n";
  
  # Write each of the syllable charts
  for my $wdot (split //, ".wu") {
    # Print appropriate header
    if ($wdot eq '.') {
      print <<EOF;
<table>
  <tr>
    <th>Initial</th>
    <th>e</th>
    <th colspan="2">i</th>
    <th colspan="2">o</th>
    <th colspan="2">a</th>
  </tr>
EOF
      
    } else {
      print <<EOF;
<table>
  <tr>
    <th>Initial</th>
    <th>we</th>
    <th colspan="2">wi</th>
    <th colspan="2">wo</th>
    <th colspan="2">wa</th>
  </tr>
EOF
    }
    
    # Print each row
    for my $initial (split //, ".ptckmnsSylr") {
    
      # Start the row with the initial
      if ($initial eq 'S') {
        print <<EOF;
  <tr>
    <th>sh</th>
EOF
      } elsif ($initial eq '.') {
        print <<EOF;
  <tr>
    <th>&mdash;</th>
EOF
      } else {
        print <<EOF;
  <tr>
    <th>$initial</th>
EOF
      }
      
      # Go through all recognized length and vowel combinations in the
      # same order as in the header
      for my $suf ('.e', '.i', '+i', '.o', '+o', '.a', '+a') {
        # Get current syllable definition
        my $sdfn = "S$initial$wdot$suf";
        
        # If current syllable definition is missing, then print a
        # missing cell and skip
        if (defined $MISSING_DFN{$sdfn}) {
          print <<EOF;
    <td class="missing">&nbsp;</td>
EOF
          next;
        }
        
        # Get the current syllable symbol
        my $sym = chr($dfn_map{$sdfn});
        
        # Print the current syllable symbol
        print <<EOF;
    <td>$sym</td>
EOF
      }
      
      # Finish the row
      print <<EOF;
  </tr>
EOF
    }
    
    # Finish the table
    print "</table>\n";
  }
  
  # Finish the page
  print "  </body>\n</html>\n";
  
} elsif ($mode eq 'build') { # =========================================
  # Switch to UTF-8 output
  binmode(STDOUT, ":encoding(UTF-8)") or
    die "Failed to set UTF-8 output, stopped";
  
  # Start the JSON object
  print "{";
  
  # Print each record
  my $first_rec = 1;
  for my $initial (split //, ".ptckmnsSylr") {
    for my $wdot (split //, ".wu") {
      for my $vlen (split //, ".+") {
        for my $vowl (split //, "aeio") {
          # Skip if this is the illegal e with vowel length
          (not (($vlen eq '+') and ($vowl eq 'e'))) or next;
          
          # Get the definition
          my $dfn = "S$initial$wdot$vlen$vowl";
          
          # Skip if this is one of the missing definitions
          (not defined $MISSING_DFN{$dfn}) or next;
          
          # Get all the component entity codepoints
          my @ea;
          
          if ($initial ne '.') {
            push @ea, ($dfn_map{"S$initial..a"});
          }
          
          if ($wdot eq 'w') {
            push @ea, (0x140e);
            
          } elsif ($wdot eq 'u') {
            push @ea, (0x140f);
          }
          
          if ($vlen eq '+') {
            push @ea, (0x1404);
          }
          
          push @ea, ($dfn_map{"S...$vowl"});
          
          # Skip if there are less than two component entities
          (scalar(@ea) > 1) or next;
          
          # Sort in numeric order of codepoint
          my @eas = sort { $a <=> $b } @ea;
          
          # Translate codepoints into individual string characters and
          # then rejoin into a single string
          my $key_string = join "", (map chr, @eas);
          
          # Print appropriate delimiter
          if ($first_rec) {
            print "\n";
            $first_rec = 0;
          } else {
            print ",\n";
          }
          
          # Print the mapping
          printf "\"%s\": \"%s\"", $key_string, chr($dfn_map{$dfn});
        }
      }
    }
  }
  
  # Finish the JSON object
  print "\n}\n";
  
} else { # =============================================================
  die "Unexpected";
}

=head1 AUTHOR

Noah Johnson, C<noah.johnson@loupmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022 Multimedia Data Technology Inc.

MIT License:

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files
(the "Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=cut
