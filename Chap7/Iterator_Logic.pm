

###
### Iterator_Logic.pm
###

## Chapter 7 section 3.1

package Iterator_Logic;
use base 'Exporter';
@EXPORT = qw(i_or_ i_or i_and_ i_and i_without_ i_without);

sub i_or_ {
  my ($cmp, $a, $b) = @_;
  my ($av, $bv) = ($a->(), $b->());
  return sub {
    if (! defined $av && ! defined $bv) { return }
    elsif (! defined $av) { $rv = $bv; $bv = $b->() }
    elsif (! defined $bv) { $rv = $av; $av = $a->() }
    else {
      my $d = $cmp->($av, $bv);
      if    ($d < 0) { $rv = $av; $av = $a->() }
      elsif ($d > 0) { $rv = $bv; $bv = $b->() }
      else           { $rv = $av; $av = $a->(); $bv = $b->() }
    }
    return $rv;
  }
}

use Curry;
BEGIN { *i_or = curry(\&i_or_) }


## Chapter 7 section 3.1

sub i_and_ {
  my ($cmp, $a, $b) = @_;
  my ($av, $bv) = ($a->(), $b->());
  return sub {
    my $d;
    until (! defined $av || ! defined $bv || 
           ($d = $cmp->($av, $bv)) == 0) {
      if ($d < 0) { $av = $a->() }
      else        { $bv = $b->() }
    }
    return unless defined $av && defined $bv;
    my $rv = $av;
    ($av, $bv) = ($a->(), $b->());
    return $rv;
  }
}

BEGIN { *i_and = curry \&i_and_ }


## Chapter 7 section 4

# $a but not $b
sub i_without_ {
  my ($cmp, $a, $b) = @_;
  my ($av, $bv) = ($a->(), $b->());
  return sub {
    while (defined $av) {
      my $d;
      while (defined $bv && ($d = $cmp->($av, $bv)) > 0) {
        $bv = $b->();
      }
      if ( ! defined $bv || $d < 0 ) {
        my $rv = $av; $av = $a->(); return $rv;
      } else {
        $bv = $b->();
        $av = $a->();
      }
    }
    return;
  }
}

BEGIN {
  *i_without = curry \&i_without_;
  *query_without = 
    i_without(sub { my ($a,$b) = @_; $a->[0] <=> $b->[0] });
}

1;
