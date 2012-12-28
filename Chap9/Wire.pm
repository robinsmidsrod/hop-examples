

###
### Wire.pm
###

## Chapter 9 section 2.1

package Wire;

my $N = 0;
sub new {
  my ($class, $name) = @_;
  $name ||= "wire" . ++$N;
  bless { N => $name, S => undef, V => undef, A => [] } => $class;
}
sub make {
  my $class = shift;
  my $N = shift;
  my @wires;
  push @wires, $class->new while $N--;
  @wires;
}
sub set {
  my ($self, $settor, $value) = @_;
  if (! $self->has_settor || $self->settor_is($settor)) {
    $self->{V} = $value;
    $self->{S} = $settor;
    $self->notify_all_but($settor, $value);
  } elsif ($self->has_settor) {
    unless ($value == $self->value) {
      my $v = $self->value;
      my $N = $self->name;
      warn "Wire $N inconsistent value ($value != $v)\n";
    }
  }
}
sub notify_all_but {
  my ($self, $exception, $value) = @_;
  for my $node ($self->attachments) {
    next if $node == $exception;
    $node->notify;
  }
}
sub attach {
  my ($self, @nodes) = @_;
  push @{$self->{A}}, @nodes;
}

sub attachments { @{$_[0]->{A}} }
sub name {
  $_[0]{N} || "$_[0]";
}

sub settor { $_[0]{S} }
sub has_settor { defined $_[0]{S} }
sub settor_is { $_[0]{S} == $_[1] }
sub revoke {
  my ($self, $revoker) = @_;
  return unless $self->has_value;
  return unless $self->settor_is($revoker);
  undef $self->{V};
  $self->notify_all_but($revoker, undef);
  undef $self->{S};
}

1;
sub value { my ($self, $querent) = @_;
            return if $self->settor_is($querent);
            $self->{V};
          }

sub has_value { my ($self, $querent) = @_;
                return if $self->settor_is($querent);
                defined $_[0]{V};
              }
