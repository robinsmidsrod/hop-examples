

###
### Constraint.pm
###

## Chapter 9 section 4.1.3

package Constraint;
use Equation;
@Constraint::ISA = qw(Equation);
sub qualify {
  my ($self, $prefix) = @_;
  my %result = ("" => $self->constant);
  for my $var ($self->varlist) {
    $result{"$prefix.$var"} = $self->coefficient($var);
  }
  $self->new(%result);
}
sub new_constant {
  my ($base, $val) = @_;
  my $class = ref $base || $base;
  $class->new("" => $val);
}
sub add_constant {
  my ($self, $v) = @_;
  $self->add_equations($self->new_constant($v));
}

sub mul_constant {
  my ($self, $v) = @_;
  $self->scale_equation($v);
}
package Constraint_Set;
@Constraint_Set::ISA = 'Equation::System';

sub constraints {
  my $self = shift;
  $self->equations;
}

1;
