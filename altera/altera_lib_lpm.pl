#!/usr/bin/perl -w

use warnings;
use strict;

use lib 'blib/lib';
use Verilog::EditFiles;
use FindBin qw($RealBin $RealScript $Script);

my $outdir = shift @ARGV;

# Create a split object
my $split = Verilog::EditFiles->new
    (# Verilog::EditFiles will use the below program name in its comments
     program => $Script,

     # Name of the directory to write the output modules to.
     # I like to put all generated files under a dir named "gen"
     # so it is obvious the files are generated.
     # (But for the Verilog-Perl internal tests, this needs to be test_dir)
     outdir => $outdir,

     # If true, add "`celldefine" before every module statement.
     #celldefine => 1,

     # For the write_lint method, the name of the linter to use.
     #lint_command => 'vlint --brief',

     # If defined, add the provided text before every module statement.
     # Generally used to insert lint off pragmas.
     lint_header => "/*verilator lint_off CASEX*/
/*verilator lint_off COMBDLY*/
/*verilator lint_off INITIALDLY*/
/*verilator lint_off LITENDIAN*/
/*verilator lint_off MULTIDRIVEN*/
/*verilator lint_off UNOPTFLAT*/
/*verilator lint_off BLKANDNBLK*/
",

     # If defined, add the provided text before every module statement.
     # Generally used to insert lint off pragmas.
     #include_header => "`include \"my_defines.v\"\n",

     # If defined, add the provided text before every module statement.
     # Generally used to insert lint off pragmas.
     #timescale_header => "`include \"my_timescale.v\"\n",

     # If set, remove any `timescales.
     #timescale_removal => 1,

     # If 1, replace any synopsys translate on/offs with "`ifdef SYNTHESIS" and
     # "`endif"s.  If set to a string, use that string instead of "SYNTHESIS".
#     translate_synthesis => 'SYNTHESIS',

     # The suffix to add to convert a module name into a filename.  Defaults to
     #v_suffix => '.v',

     # If set, show what files are being read and written
     verbose => 1,
     );

# Read specified libraries and split them
$split->read_and_split(@ARGV);

# And write them out
$split->write_files();

# And create a lint file
$split->write_lint();

# Remove tristates
# TODO - VerilogPerl patch to make this less hacky
for my $file (keys %{$split->{_files}}) {
    $split->edit_file
        (
         filename=>"$split->{outdir}/$file.v",
         cb=>sub {
    	 my $wholefile = shift;
    	 $wholefile =~ s%(\btri[01]\b)(.*)%logic$2 // -- converted tristate to logic%g;
         $wholefile =~ s%(buf\s*\(\s*(\w+)\s*,\s*(\w+)\));%assign $2 = $3; // -- converted buf to assign%g;
         $wholefile =~ s%1'b[xz]%1'b0 /* converted x or z to 1'b0 */%g;
    	 return $wholefile;
         });
}

## If a file needs 'manual' search and replaces, we can do that too.
#$split->edit_file
#    (# The filename to be edited
#     filename=>"$split->{outdir}/a.v",
#     # Callback subroutine that takes file contents as a string
#     # and returns the new file contents
#     cb=>sub {
#	 my $wholefile = shift;
#	 # Globally search and comment out any lines with "pulldown PULLDOWN"
#	 # See "man perlre" for examples.
#	 # The %mg here means to match multiple lines (you can put
#	 # \n in the regexp), and to do it globally
#	 $wholefile =~ s%(pulldown PULLDOWN;)%//vsplitmodule: $1%mg;
#	 return $wholefile;
#     });
