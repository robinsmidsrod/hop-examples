

###
### Environment.pm
###

## Chapter 9 section 4.3.2

sub subset {
  my ($self, $name) = @_;
  my %result;
  for my $k (keys %$self) {
    my $kk = $k;
    if ($kk =~ s/^\Q$name.//) {
      $result{$kk} = $self->{$k};
    }
  }
  $self->new(%result);
}
