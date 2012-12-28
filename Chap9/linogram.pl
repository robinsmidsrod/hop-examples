

###
### linogram.pl
###

## Chapter 9 section 4.4

use Parser ':all';
use Lexer ':all';

my $input = sub { read INPUT, my($buf), 8192 or return; $buf };

my @keywords = map [uc($_), qr/\b$_\b/],
  qw(constraints define extends draw);

my $tokens = iterator_to_stream(
      make_lexer($input,
                 @keywords,
                 ['ENDMARKER',  qr/__END__.*/s,
                  sub {
                    my $s = shift;
                    $s =~ s/^__END__\s*//;
                    ['ENDMARKER', $s]
                  } ],
                 ['IDENTIFIER', qr/[a-zA-Z_]\w*/],
                 ['NUMBER', qr/(?: \d+ (?: \.\d*)?
                               | \.\d+)
                               (?: [eE]  \d+)? /x ],
                 ['FUNCTION',   qr/&/],
                 ['DOT',        qr/\./],
                 ['COMMA',      qr/,/],
                 ['OP',         qr|[-+*/]|],
                 ['EQUALS',     qr/=/],
                 ['LPAREN',     qr/[(]/],
                 ['RPAREN',     qr/[)]/],
                 ['LBRACE',     qr/[{]/],
                 ['RBRACE',     qr/[}]\n*/],
                 ['TERMINATOR', qr/;\n*/],
                 ['WHITESPACE', qr/\s+/, sub { "" }],
                 ));


## Chapter 9 section 4.4.2

my $ROOT_TYPE = Type->new('ROOT');
my %TYPES = ('number' => Type::Scalar->new('number'),
             'ROOT'   => $ROOT_TYPE,
            );
$program = star($Definition 
              | $Declaration
                > sub { add_declarations($ROOT_TYPE, $_[0]) }
              )
         - option($Perl_code) - $End_of_Input
  >> sub {
    $ROOT_TYPE->draw();
  };
$perl_code = _("ENDMARKER") > sub { eval $_[0];
                                    die if $@; 
                                  };


## Chapter 9 section 4.4.4

$defheader = _("DEFINE") - _("IDENTIFIER") - $Extends
  >> sub { ["DEFINITION", @_[1,2] ]};

$extends = option(_("EXTENDS") - _("IDENTIFIER") >> sub { $_[1] }) ;
$definition = labeledblock($Defheader, $Declaration)
  >> sub {
     my ($defheader, @declarations) = @_;
     my ($name, $extends) = @$defheader[1,2];
     my $parent_type = (defined $extends) ? $TYPES{$extends} : undef;
     my $new_type;

     if (exists $TYPES{$name}) {
       lino_error("Type '$name' redefined");
     }
     if (defined $extends && ! defined $parent_type) {
       lino_error("Type '$name' extended from unknown type '$extends'");
     }

     $new_type = Type->new($name, $parent_type);

     add_declarations($new_type, @declarations);

     $TYPES{$name} = $new_type;
  };


## Chapter 9 section 4.4.5

$type = lookfor("IDENTIFIER",
                sub {
                  exists($TYPES{$_[0][1]}) || lino_error("Unrecognized type '$_[0][1]'");
                  $_[0][1];
                }
               );


## Chapter 9 section 4.4.5

$declarator = _("IDENTIFIER") 
            - option(_("LPAREN")  - commalist($Param_Spec) - _("RPAREN")
                     >> sub { $_[1] }
                    )
  >> sub {
    { WHAT => 'DECLARATOR',
      NAME => $_[0],
      PARAM_SPECS => $_[1],
    };
  };


## Chapter 9 section 4.4.5

$param_spec = _("IDENTIFIER") - _("EQUALS") - $Expression
  >> sub {
    { WHAT => "PARAM_SPEC",
      NAME => $_[0],
      VALUE => $_[2],
    }
  }
  ;


## Chapter 9 section 4.4.5

$declaration = $Type - commalist($Declarator) - _("TERMINATOR")
                 >> sub { my ($type, $decl_list) = @_;
                          unless (exists $TYPES{$type}) {
                            lino_error("Unknown type name '$type' in declaration '@_'\n");
                          }
                          for (@$decl_list) {
                            $_->{TYPE} = $type;
                            check_declarator($TYPES{$type}, $_);
                          }
                          {WHAT => 'DECLARATION', 
                           DECLARATORS => $decl_list };
                        }


## Chapter 9 section 4.4.5

| $Constraint_section 
| $Draw_section
;


## Chapter 9 section 4.4.5

sub check_declarator {
  my ($type, $declarator) = @_;
  for my $pspec (@{$declarator->{PARAM_SPECS}}) {
    my $name = $pspec->{NAME};
    unless ($type->has_subfeature($name)) {
      lino_error("Declaration of '$declarator->{NAME}' " 
               . "specifies unknown subfeature '$name' "
               . "for type '$type->{N}'\n");  
    }
  }
}


## Chapter 9 section 4.4.5

$constraint_section = labeledblock(_("CONSTRAINTS"), $Constraint)
  >> sub { shift;
           { WHAT => 'CONSTRAINTS', CONSTRAINTS => [@_] }
         };
$constraint = $Expression - _("EQUALS") - $Expression - _("TERMINATOR")
  >> sub { Expression->new('-', $_[0], $_[2]) } ;


## Chapter 9 section 4.4.5

$draw_section = labeledblock(_("DRAW"), $Drawable)
  >> sub { shift; { WHAT => 'DRAWABLES', DRAWABLES => [@_] } };
$drawable = $Name - _("TERMINATOR")
                >> sub { { WHAT => 'NAMED_DRAWABLE',
                           NAME => $_[1],
                         }
                       }
          | _("FUNCTION") - _("IDENTIFIER") - _("TERMINATOR")
                 >> sub { my $ref = \&{$_[1]};
                          { WHAT => 'FUNCTIONAL_DRAWABLE',
                            REF => $ref,
                            NAME => $_[1],
                          };
                        };


## Chapter 9 section 4.4.5

my %add_decl = ('DECLARATION' => \&add_subfeature_declaration,
                'CONSTRAINTS' => \&add_constraint_declaration,
                'DRAWABLES' => \&add_draw_declaration,
                'DEFAULT' =>  sub {
                  lino_error("Unknown declaration kind '$[1]{WHAT}'");
                },
               );

sub add_declarations {
  my ($type, @declarations) = @_;

  for my $declaration (@declarations) {
    my $decl_kind = $declaration->{WHAT};
    my $func = $add_decl{$decl_kind} || $add_decl{DEFAULT};
    $func->($type, $declaration);
  }
}
sub add_subobj_declaration {
  my ($type, $declaration) = @_;
  my $declarators = $declaration->{DECLARATORS};
  for my $decl (@$declarators) {
    my $name = $decl->{NAME};
    my $decl_type = $decl->{TYPE};
    my $decl_type_obj = $TYPES{$decl_type};
    $type->add_subfeature($name, $decl_type_obj);
    for my $pspec (@{$decl->{PARAM_SPECS}}) {
      my $pspec_name = $pspec->{NAME};
      my $constraints = convert_param_specs($type, $name, $pspec);
      $type->add_constraints($constraints);
    }
  }
}
sub add_constraint_declaration {
  my ($type, $declaration) = @_;
  my $constraint_expressions = $declaration->{CONSTRAINTS};
  my @constraints 
    = map expression_to_constraints($type, $_), 
          @$constraint_expressions;
  $type->add_constraints(@constraints);
}
sub add_draw_declaration {
  my ($type, $declaration) = @_;
  my $drawables = $declaration->{DRAWABLES};

  for my $d (@$drawables) {
    my $drawable_type = $d->{WHAT};
    if ($drawable_type eq "NAMED_DRAWABLE") {
      unless ($type->has_subfeature($d->{NAME})) {
        lino_error("Unknown drawable feature '$d->{NAME}'");
      }
      $type->add_drawable($d->{NAME});
    } elsif ($drawable_type eq "FUNCTIONAL_DRAWABLE") {
      $type->add_drawable($d->{REF});
    } else {
      lino_error("Unknown drawable type '$type'");
    }
  }
} 
$expression = operator($Term,
                       [_('OP', '+'), sub { Expression->new('+', @_) } ],
                       [_('OP', '-'), sub { Expression->new('-', @_) } ],
                      );

$term = operator($Atom, 
                       [_('OP', '*'), sub { Expression->new('*', @_) } ],
                       [_('OP', '/'), sub { Expression->new('/', @_) } ],
                );
package Expression;

sub new {
  my ($base, $op, @args) = @_;
  my $class = ref $base || $base;
  unless (exists $eval_op{$op}) {
    die "Unknown operator '$op' in expression '$op @args'\n";
  }
  bless [ $op, @args ] => $class;
}
package main;

$atom = $Name
      | $Tuple
      | lookfor("NUMBER", sub { Expression->new('CON', $_[0][1]) })
      | _('OP', '-') - $Expression
          >> sub { Expression->new('-', Expression->new('CON', 0), $_[1]) }
      | _("LPAREN") - $Expression - _("RPAREN") >> sub {$_[1]};
$name = $Base_name 
      - star(_("DOT") - _("IDENTIFIER") >> sub { $_[1] })
      > sub { Expression->new('VAR', join(".", $_[0], @{$_[1]})) }
      ;

$base_name = _"IDENTIFIER";


## Chapter 9 section 4.4.6

$tuple = _("LPAREN")
       - commalist($Expression) / sub { @{$_[0]} > 1 }
       - _("RPAREN")
  >> sub {
    my ($explist) = $_[1];
    my $N = @$explist;
    my @axis = qw(x y z);
    if ($N == 2 || $N == 3) {
      return [ 'TUPLE',
               { map { $axis[$_] => $explist->[$_] } (0 .. $N-1) }
             ];
    } else {
      lino_error("$N-tuples are not supported\n");
    }
  } ;


## Chapter 9 section 4.4.6

sub expression_to_constraints {
  my ($context, $expr) = @_;


## Chapter 9 section 4.4.6

unless (defined $expr) {
  Carp::croak("Missing expression in 'expression_to_constraints'");
}
my ($op, @s) = @$expr;
if ($op eq 'VAR') {
  my $name = $s[0];
  return Value::Feature->new_from_var($name, $context->subfeature($name));
} elsif ($op eq 'CON') {
  return Value::Constant->new($s[0]);
} elsif ($op eq 'TUPLE') {
  my %components;
  for my $k (keys %{$s[0]}) {
    $components{$k} = expression_to_constraints($context, $s[0]{$k});
  }
  return Value::Tuple->new(%components);
}
my $e1 = expression_to_constraints($context, $s[0]);
my $e2 = expression_to_constraints($context, $s[1]);
my %opmeth = ('+' => 'add',
              '-' => 'sub',
              '*' => 'mul',
              '/' => 'div',
             );

my $meth = $opmeth{$op};
if (defined $meth) {
  return $e1->$meth($e2);
} else {
  lino_error("Unknown operator '$op' in AST");
}
        }


## Chapter 9 section 4.4.6

sub convert_param_specs {
  my ($context, $subobj, $pspec) = @_;
  my @constraints;
  my $left = Value::Feature->new_from_var("$subobj." . $pspec->{NAME}, 
                                          $context->subfeature($subobj)
                                          ->subfeature($pspec->{NAME})
                                         );
  my $right = expression_to_constraints($context, $pspec->{VALUE});
  return $left->sub($right);
}
