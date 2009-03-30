package Text::Darts;
use strict;
use warnings;
use Carp;
our $VERSION = sprintf "%d.%02d", q$Revision: 0.5 $ =~ /(\d+)/g;
our $DEBUG = 0;

require XSLoader;
XSLoader::load('Text::Darts', $VERSION);

sub new{
    my $pkg = shift;
    my $dpi = xs_make([sort @_]);
    bless \$dpi, $pkg;
}

sub open{
    my $pkg = shift;
    my $filename = shift;
    my $dpi = xs_open($filename) 
	or carp __PACKAGE__, " cannot open $filename";
    bless \$dpi, $pkg;
}

sub DESTROY{
    if ($DEBUG){
	no warnings 'once';
	require Data::Dumper;
	local $Data::Dumper::Terse  = 1;
	local $Data::Dumper::Indent = 0;
	warn "DESTROY:", Data::Dumper::Dumper($_[0]);
    }
    xs_free(${$_[0]});
}

sub search{
    xs_search(${$_[0]}, $_[1]);
}

sub gsub{
    my $cbstr = $_[2];
    no warnings 'uninitialized';
    my $cb = ref $cbstr ? $cbstr : sub { $cbstr };
    xs_gsub(${$_[0]}, $_[1], $cb);
}


if ($0 eq __FILE__){
    sub say { print @_, "\n" };
    my @a = ("ALGOL", "ANSI", "ARCO",  "ARPA", "ARPANET", "ASCII");
    my %a = map { $_ => lc $_ } @a;
    my $da = __PACKAGE__->new(@a);
    say $da->gsub("I don't like ALGOL at all!", sub{"<$_[0]>"});
    say $da->gsub("I don't like nomatch at all!");
    say $da->gsub("I don't like ALGOL at all!", \%a);
    if (@ARGV){
	$da = __PACKAGE__->open(shift);
	say $da->gsub("The quick brown fox jumps over the black lazy dog",
		      sub{"<$_[0]>"});
    }
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Text::Darts - Perl interface to DARTS by Taku Kudoh

=head1 SYNOPSIS

  use Text::Darts;
  my @words = qw/ALGOL ANSI ARCO ARPA ARPANET ASCII/;
  my %word   = map { $_ => lc $_ } @words;
  my $td     = Text::Darts->new(@words);
  my $newstr = $td->gsub("ARPANET is a net by ARPA", sub{ "<<$_[0]>>" });
  # $newstr is now "<<ARPANET>> is a net by <<ARPA>>".
  my $lstr   = $td->gsub("ARPANET is a net by ARPA", \%words);
  # $Lstr is now "<<ARPANET>> is a net by <<ARPA>>".
  # or
  my $td     = Text::Darts->open("words.darts");
  my $newstr = $td->gsub($str, sub{ 
     qq(<a href="http://dictionary.com/browse/$_[0]">$_[0]</a>)
  }); # link'em all!

=head1 DESCRIPTION

Darts, or Double-ARray Trie System is a C++ Template Library by Taku Kudoh.
This module makes use of Darts to implement global replace like below;

  $str = s{ (foo|bar|baz) }{ "<<$1>>" }msgex;

The problem with regexp is that it is slow with alterations.  Suppose
you want to anchor all words that appear in /usr/share/dict/words with
regexp.  It would be impractical with regexp but Darts make it
practical.

Since Version 0.05, L<Text::Darts> also accepts a hash reference instead of a code reference.  In such cases gsub behaves as follows.

  $str = s{ (foo|bar|baz) }{$replacement{$1}}msgx;

like C<s///ge> vs C<s///g>, this is less flexible but faster.

=head1 REQUIREMENT

Darts 0.32 or above.  Available at 

L<http://chasen.org/~taku/software/darts/index.html> (Japanese)

L<http://chasen.org/~taku/software/darts/src/darts-0.32.tar.gz>

To install, just

  fetch http://chasen.org/~taku/software/darts/src/darts-0.32.tar.gz
  tar zxvf darts-0.32.tar.gz
  cd darts-0.32
  configure
  make
  make check
  sudo make install

=head2 EXPORT

None.

=head1 SEE ALSO

L<http://chasen.org/~taku/software/darts/index.html> (Japanese)

L<Regexp::Assemble>

=head1 AUTHOR

Dan Kogai, E<lt>dankogai@dan.co.jpE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Dan Kogai

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
