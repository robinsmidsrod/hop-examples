

###
### Curry.pm
###

## Chapter 7 section 2.1

package Curry;
use base 'Exporter';
@EXPORT = ('curry');
@EXPORT_OK = qw(curry_listfunc curry_n);

sub curry_listfunc {
  my $f = shift;
  return sub { 
    my $first_arg = shift;
    return sub { $f->($first_arg, @_) };
  };
}

sub curry {
  my $f = shift;
  return sub { 
    my $first_arg = shift;
    my $r = sub { $f->($first_arg, @_) };
    return @_ ? $r->(@_) : $r;
  };
}

1;


## Chapter 7 section 2.3

sub curry_n {
  my $N = shift;
  my $f = shift;
  my $c;
  $c = sub {
    if (@_ >= $N) { $f->(@_) }
    else {
      my @a = @_;
      curry_n($N-@a, sub { $f->(@a, @_) });
    }
  };
}
