

###
### rng-iterator.pl
###

## Chapter 4 section 3.6

sub make_rand {
  my $seed = shift || (time & 0x7fff);
  return Iterator {
    $seed = (29*$seed+11111) & 0x7fff;
    return $seed;
  }
}
