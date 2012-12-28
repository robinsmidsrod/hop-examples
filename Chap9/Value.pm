

###
### Value.pm
###

## Chapter 9 section 4.2

package Value;

my %op = ("add" => 
          {
           "FEATURE,FEATURE"     => 'add_features',
           "FEATURE,CONSTANT"   => 'add_feature_con',
           "FEATURE,TUPLE"      => 'add_feature_tuple',
           "TUPLE,TUPLE"       => 'add_tuples',
           "TUPLE,CONSTANT"    => undef,
           "CONSTANT,CONSTANT" => 'add_constants',
           NAME => "Addition",
          },
          "mul" => 
          {
           NAME => "Multiplication",
           "FEATURE,CONSTANT"   => 'mul_feature_con',
           "TUPLE,CONSTANT" => 'mul_tuple_con',
           "CONSTANT,CONSTANT" => 'mul_constants',
          },
         );
sub op {
  my ($self, $op, $operand) = @_;
  my ($k1, $k2) = ($self->kindof, $operand->kindof);
  my $method;
  if ($method = $op{$op}{"$k1,$k2"}) {
    $self->$method($operand);
  } elsif ($method = $op{$op}{"$k2,$k1"}) {
    $operand->$method($self);
  } else {
    my $name = $op{$op}{NAME} || "'$op'";
    die "$name of '$k1' and '$k2' not defined";
  }
}
sub negate { $_[0]->scale(-1) }
sub reciprocal { die "Nonlinear division" }
package Value::Constant;
@Value::Constant::ISA = 'Value';

sub new {
  my ($base, $con) = @_;
  my $class = ref $base || $base;
  bless { WHAT => $base->kindof,
          VALUE => $con,
        } => $class;
}

sub kindof { "CONSTANT" }

sub value { $_[0]{VALUE} }
sub scale {
  my ($self, $coeff) = @_;
  $self->new($coeff * $self->value);
}
sub reciprocal {
  my ($self, $coeff) = @_;
  my $v = $self->value;
  if ($v == 0) {
    die "Division by zero";
  }
  $self->new(1/$v);
}
sub add_constants {
  my ($c1, $c2) = @_;
  $c1->new($c1->value + $c2->value);
}

sub mul_constants {
  my ($c1, $c2) = @_;
  $c1->new($c1->value * $c2->value);
}
package Value::Tuple;
@Value::Tuple::ISA = 'Value';

sub kindof { "TUPLE" }

sub new {
  my ($base, %tuple) = @_;
  my $class = ref $base || $base;
  bless { WHAT => $base->kindof,
          TUPLE => \%tuple,
        } => $class;
}
sub components { keys %{$_[0]{TUPLE}} }
sub has_component { exists $_[0]{TUPLE}{$_[1]} }
sub component { $_[0]{TUPLE}{$_[1]} }
sub to_hash { $_[0]{TUPLE} }
sub scale {
    my ($self, $coeff) = @_;
    my %new_tuple;
    for my $k ($self->components) {
      $new_tuple{$k} = $self->component($k)->scale($coeff);
    }
    $self->new(%new_tuple);
}
sub has_same_components_as {
  my ($t1, $t2) = @_;
  my %t1c;
  for my $c ($t1->components) {
    return unless $t2->has_component($c);
    $t1c{$c} = 1;
  }
  for my $c ($t2->components) {
    return unless $t1c{$c};
  }
  return 1;
}
sub add_tuples {
  my ($t1, $t2) = @_;
  croak("Nonconformable tuples") unless $t1->has_same_components_as($t2);

  my %result ;
  for my $c ($t1->components) {
    $result{$c} = $t1->component($c) + $t2->component($c);
  }
  $t1->new(%result);
}
sub mul_tuple_con {
  my ($t, $c) = @_;

  $t->scale($c->value);
}
package Intrinsic_Constraint_Set;

sub new {
  my ($base, @constraints) = @_;
  my $class = ref $base || $base;
  bless \@constraints => $class;
}

sub constraints  { @{$_[0]} }
sub apply {
  my ($self, $func) = @_;
  my @c = map $func->($_), $self->constraints;
  $self->new(@c);
}
sub qualify {
  my ($self, $prefix) = @_;
  $self->apply(sub { $_[0]->qualify($prefix) });
}
sub union {
  my ($self, @more) = @_;
  $self->new($self->constraints, map {$_->constraints} @more);
}
package Synthetic_Constraint_Set;

sub new { 
  my $base = shift;
  my $class = ref $base || $base;

  my $constraints;
  if (@_ == 1) {
    $constraints = shift;
  } elsif (@_ % 2 == 0) {
    my %constraints = @_;
    $constraints = \%constraints;
  } else {
    my $n = @_;
    require Carp;
    Carp::croak("$n arguments to Synthetic_Constraint_Set::new");
  }

  bless $constraints => $class;
}
sub constraints { values %{$_[0]} }
sub constraint { $_[0]->{$_[1]} }
sub labels { keys %{$_[0]} }
sub has_label { exists $_[0]->{$_[1]} }
sub add_labeled_constraint {
  my ($self, $label, $constraint) = @_;
  $self->{$label} = $constraint;
}
sub apply {
  my ($self, $func) = @_;
  my %result;
  for my $k ($self->labels) {
    $result{$k} = $func->($self->constraint($k));
  }
  $self->new(\%result);
}
sub qualify {
  my ($self, $prefix) = @_;
  $self->apply(sub { $_[0]->qualify($prefix) });
}
sub scale {
  my ($self, $coeff) = @_;
  $self->apply(sub { $_[0]->scale_equation($coeff) });
}
sub apply2 {
  my ($self, $arg, $func) = @_;
  my %result;
  for my $k ($self->labels) {
    next unless $arg->has_label($k);
    $result{$k} = $func->($self->constraint($k), 
                           $arg->constraint($k));
  }
  $self->new(\%result);
}


## Chapter 9 section 4.2.5

sub apply_hash {
  my ($self, $hash, $func) = @_;
  my %result;
  for my $c (keys %$hash) {
    my $dotc = ".$c";
    for my $k ($self->labels) {
      next unless $k eq $c || substr($k, -length($dotc)) eq $dotc;
      $result{$k} = $func->($self->constraint($k), $hash->{$c});
    }
  }
  $self->new(\%result);
}
package Value::Feature;
@Value::Feature::ISA = 'Value';

sub kindof { "FEATURE" }

sub new {
    my ($base, $intrinsic, $synthetic) = @_;
    my $class = ref $base || $base;
    my $self = {WHAT => $base->kindof,
                SYNTHETIC => $synthetic,
                INTRINSIC => $intrinsic,
               };
    bless $self => $class;
}
sub new_from_var {
  my ($base, $name, $type) = @_;
  my $class = ref $base || $base;
  $base->new($type->qualified_intrinsic_constraints($name),
             $type->qualified_synthetic_constraints($name),
            );
}
sub intrinsic { $_[0]->{INTRINSIC} }
sub synthetic { $_[0]->{SYNTHETIC} }
sub scale {
  my ($self, $coeff) = @_;
  return 
    $self->new($self->intrinsic, 
               $self->synthetic->scale($coeff),
              );
}
sub add_features {
  my ($o1, $o2) = @_;
  my $intrinsic = $o1->intrinsic->union($o2->intrinsic);
  my $synthetic = $o1->synthetic->apply2($o2->synthetic,
                                         sub { $_[0]->add_equations($_[1]) },
                                        );
  $o1->new($intrinsic, $synthetic);
}
sub mul_feature_con {
  my ($o, $c) = @_;
  $o->scale($c->value);
}
sub add_feature_con {
  my ($o, $c) = @_;
  my $v = $c->value;
  my $synthetic = $o->synthetic->apply(sub { $_[0]->add_constant($v) });
  $o->new($o->intrinsic, $synthetic);
}
sub add_feature_tuple {
  my ($o, $t) = @_;
  my $synthetic = 
    $o->synthetic->apply_hash($t->to_hash, 
                              sub { 
                                my ($constr, $comp) = @_;
                                my $kind = $comp->kindof;
                                if ($kind eq "CONSTANT") {
                                  $constr->add_constant($comp->value);
                                } elsif ($kind eq "FEATURE") {
                                  $constr->add_equations($comp->synthetic->constraint(""));
                                } elsif ($kind eq "TUPLE") {
                                  die "Tuple with subtuple component";
                                } else {
                                  die "Unknown tuple component type '$kind'";
                                }
                              },
                             );
  $o->new($o->intrinsic, $synthetic);
}

1;
