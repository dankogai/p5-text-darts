use strict;
use warnings;
use Test::More tests => 2;
use Text::Darts;

my @words = qw/ALGOL ANSI ARCO ARPA ARPANET ASCII/;
my %word   = map { $_ => lc $_ } @words;
my $td     = Text::Darts->new(@words);

my $newstr = $td->gsub("ARPANET is a net by ARPA", sub{ "<<$_[0]>>" });
is $newstr, "<<ARPANET>> is a net by <<ARPA>>";

my $lstr   = $td->gsub("ARPANET is a net by ARPA", \%word);
is $lstr, "arpanet is a net by arpa";

