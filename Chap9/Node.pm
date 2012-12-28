

###
### Node.pm
###

## Chapter 9 section 2.1

package Node;
my %NAMES;
sub new {
  my ($class, $base_name, $behavior, $wiring) = @_;
  my $self = {N => $base_name . ++$NAMES{$base_name}, 
              B => $behavior,
              W => $wiring,
             };
  for my $wire (values %$wiring) {
    $wire->attach($self);
  }
  bless $self => $class;
}
sub notify {
  my $self = shift;
  my %vals;
  while (my ($name, $wire) = each %{$self->{W}}) {
    $vals{$name} = $wire->value($self);
  }
  $self->{B}->($self, %vals);
}
sub name {
  my $self = shift;
  $self->{N}|| "$self";
}

sub wire { $_[0]{W}{$_[1]} }
sub set_wire {
  my ($self, $wire, $value) = @_;
  my $wire = $self->wire($wire);
  $wire->set($self, $value);
}

sub revoke_wire {
  my ($self, $wire) = @_;
  my $wire = $self->wire($wire);
  $wire->revoke($self);
}
