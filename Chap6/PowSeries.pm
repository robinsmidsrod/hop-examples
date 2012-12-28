

###
### PowSeries.pm
###

## Chapter 6 section 7

package PowSeries;
use base 'Exporter';
@EXPORT_OK = qw(add2 mul2 partial_sums powers_of term_values
                evaluate derivative multiply recip divide
                $sin $cos $exp $log_ $tan);
use Stream ':all';

sub tabulate {
  my $f = shift;
  &transform($f, upfrom(0));
}
my @fact = (1);
sub factorial {
  my $n = shift;
  return $fact[$n] if defined $fact[$n];
  $fact[$n] = $n * factorial($n-1);
}


$sin = tabulate(sub { my $N = shift;
                      return 0 if $N % 2 == 0;
                      my $sign = int($N/2) % 2 ? -1 : 1;
                      $sign/factorial($N) 
                    });


$cos = tabulate(sub { my $N = shift;
                      return 0 if $N % 2 != 0;
                      my $sign = int($N/2) % 2 ? -1 : 1;
                      $sign/factorial($N) 
                   });


## Chapter 6 section 7

sub add2 {
  my ($s, $t) = @_;
  return unless $s && $t;
  node(head($s) + head($t),
       promise { add2(tail($s), tail($t)) });
}
sub mul2 {
  my ($s, $t) = @_;
  return unless $s && $t;
  node(head($s) * head($t),
       promise { mul2(tail($s), tail($t)) });
}
sub partial_sums {
  my $s = shift;
  my $r;
  $r = node(head($s), promise { add2($r, tail($s)) });
}
sub powers_of {
  my $x = shift;
  iterate_function(sub {$_[0] * $x}, 1);
}
sub term_values {
  my ($s, $x) = @_;
  mul2($s, powers_of($x));
}
sub evaluate {
  my ($s, $x) = @_;
  partial_sums(term_values($s, $x));
}


## Chapter 6 section 7

# Get the n'th term from a stream
sub nth {
  my $s = shift;
  my $n = shift;
  return $n == 0 ? head($s) : nth(tail($s), $n-1);
}

# Calculate the approximate cosine of x
sub cosine {
  my $x = shift;
  nth(evaluate($cos, $x), 20);
}
sub is_zero_when_x_is_pi {
  my $x = shift;
  my $c = cosine($x/6);
  $c * $c - 3/4;
}


## Chapter 6 section 7.1

sub derivative {
  my $s = shift;
  mul2(upfrom(1), tail($s));
}


## Chapter 6 section 7.2

$exp = tabulate(sub { my $N = shift; 1/factorial($N) });


## Chapter 6 section 7.2

$log_ = tabulate(sub { my $N = shift; 
                       $N==0 ? 0 : (-1)**$N/-$N });


## Chapter 6 section 7.3

sub multiply {
  my ($S, $T) = @_;
  my ($s, $t) = (head($S), head($T));
  node($s*$t,
       promise { add2(scale(tail($T), $s),
                 add2(scale(tail($S), $t),
                      node(0,
                       promise {multiply(tail($S), tail($T))}),
                     ))
               }
       );
}


## Chapter 6 section 7.3

sub scale {
  my ($s, $c) = @_;
  return    if $c == 0;
  return $s if $c == 1;
  transform { $_[0]*$c } $s;
}


## Chapter 6 section 7.3

sub sum {
  my @s = grep $_, @_;
  my $total = 0;
  $total += head($_) for @s;
  node($total,
       promise { sum(map tail($_), @s) }
      );
}
sub multiply {
  my ($S, $T) = @_;
  my ($s, $t) = (head($S), head($T));
  node($s*$t,
       promise { sum(scale(tail($T), $s),
                     scale(tail($S), $t),
                     node(0,
                       promise {multiply(tail($S), tail($T))}),
                     )
               }
       );
}


## Chapter 6 section 7.3

# Only works if head($s) = 1
sub recip {
  my ($s) = shift;
  my $r;
  $r = node(1, 
            promise { scale(multiply($r, tail($s)), -1) });
}
sub divide {
  my ($s, $t) = @_;
  multiply($s, recip($t));
}

$tan = divide($sin, $cos);
