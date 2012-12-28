

###
### Parser::Exception.pm
###

## Chapter 8 section 4.7.2

sub End_of_Input {
  my $input = shift;
  return (undef, undef) unless defined($input);
  die ["End of input", $input];
}
sub lookfor {
  my $wanted = shift;
  my $value = shift || sub { $_[0][1] };
  my $u = shift;
  $wanted = [$wanted] unless ref $wanted;

  my $parser = parser {
    my $input = shift;
    unless (defined $input) {
      die ['TOKEN', $input, $wanted];
    }
    my $next = head($input);
    for my $i (0 .. $#$wanted) {
      next unless defined $wanted->[$i];
      unless ($wanted->[$i] eq $next->[$i]) {
        die ['TOKEN', $input, $wanted];
      }
    }
    my $wanted_value = $value->($next, $u);
    return ($wanted_value, tail($input));
  };

  $N{$parser} = "[@$wanted]";
  return $parser;
}
sub alternate {
  my @p = @_;
  return parser { return () } if @p == 0;
  return $p[0]                if @p == 1;

  my $p;
  $p = parser {
    my $input = shift;
    my ($v, $newinput);
    my @failures;

    for (@p) {
      eval { ($v, $newinput) = $_->($input) };
      if ($@) {
        die unless ref $@;
        push @failures, $@;
      } else {
        return ($v, $newinput);
      }
    }
    die ['ALT', $input, \@failures];
  };
  $N{$p} = "(" . join(" | ", map $N{$_}, @p) . ")";
  return $p;
}
sub error {
  my ($try) = @_;
  my $p;
  $p = parser {
    my $input = shift;
    my @result = eval { $try->($input) };
    if ($@) {
      display_failures($@) if ref $@;
      die;
    }
    return @result;
  };
}
sub display_failures {
  my ($fail, $depth) = @_;
  $depth ||= 0;
  my $I = "  " x $depth;
  my ($type, $position, $data) = @$fail;
  my $pos_desc = "";

  while (length($pos_desc) < 40) {
    if ($position) {
      my $h = head($position);
      $pos_desc .= "[@$h] ";
    } else {
      $pos_desc .= "End of input ";
      last;
    }
    $position = tail($position);
  }
  chop $pos_desc;
  $pos_desc .= "..." if defined $position;

  if ($type eq 'TOKEN') {
    print $I, "Wanted [@$data] instead of '$pos_desc'\n";
  } elsif ($type eq 'End of input') {
    print $I, "Wanted EOI instead of '$pos_desc'\n";
  } elsif ($type eq 'ALT') {
    print $I, ($depth ? "Or any" : "Any"), " of the following:\n";
    for (@$data) {
      display_failures($_, $depth+1);
    }
  }
}
