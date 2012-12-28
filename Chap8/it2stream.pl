

###
### iterator-to-stream.pl
###

## Chapter 8 section 1.4

use Stream 'node';

sub iterator_to_stream {
  my $it = shift;
  my $v = $it->();
  return unless defined $v;
  node($v, sub { iterator_to_stream($it) });
}

1;
