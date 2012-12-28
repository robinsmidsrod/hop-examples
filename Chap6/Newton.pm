

###
### Newton.pm
###

## Chapter 6 section 6

sub sqrt2 {
  my $g = 2;   # Initial guess
  until (close_enough($g*$g, 2)) {
    $g = ($g*$g + 2) / (2*$g);
  }
  $g;
}

sub close_enough {
  my ($a, $b) = @_;
  return abs($a - $b) < 1e-12;
}
sub sqrtn {
  my $n = shift;
  my $g = $n;   # Initial guess
  until (close_enough($g*$g, $n)) {
    $g = ($g*$g + $n) / (2*$g);
  }
  $g;
}


## Chapter 6 section 6.1

use Stream 'iterate_function';

sub sqrt_stream {
  my $n = shift;
  iterate_function (sub { my $g = shift;
                         ($g*$g + $n) / (2*$g);
                        },
                    $n);
}

1;


## Chapter 6 section 6.2

sub slope {
  my ($f, $x) = @_;
  my $e = 0.00000095367431640625;
  ($f->($x+$e) - $f->($x-$e)) / (2*$e);
}


## Chapter 6 section 6.2

# Return a stream of numbers $x that make $f->($x) close to 0
sub solve {
  my $f = shift;
  my $guess = shift || 1;
  iterate_function(sub { my $g = shift;
                         $g - $f->($g)/slope($f, $g);
                       },
                   $guess);
}
