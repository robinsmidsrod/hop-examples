

###
### DFSParser.pm
###

## Chapter 8 section 2.2

require "make-dfs-search";

sub make_parser_for_grammar {
  my ($start, $grammar, $target) = @_;

  my $is_nonterminal = sub {
    my $symbol = shift;
    exists $grammar->{$symbol};
  };
    my $is_interesting = sub {
      my $sentential_form = shift;
      my $i;
      for ($i=0; $i < @$sentential_form; $i++) {
        return 1 if $is_nonterminal->($sentential_form->[$i]);
        return if $i > $#$target;
        return if $sentential_form->[$i] ne $target->[$i];
      }
      return @$sentential_form == @$target ;
    };
  my $children = sub {
    my $sentential_form = shift;
    my $leftmost_nonterminal;
    my @children;

    for my $i (0 .. $#$sentential_form) {
      if ($is_nonterminal->($sentential_form->[$i])) {
        $leftmost_nonterminal = $i;
        last;
      } else {
        return if $i > $#$target;
        return if $target->[$i] ne $sentential_form->[$i];
      }
    }
    return unless defined $leftmost_nonterminal;   # no nonterminal symbols
    for my $production (@{$grammar->{$sentential_form->[$leftmost_nonterminal]}}) {
      my @child = @$sentential_form;
      splice @child, $leftmost_nonterminal, 1, @$production;
      push @children, \@child;
    }
    @children;
  };
  return sub {
    make_dfs_search([$start], $children, $is_interesting
                   );
  };
}

1;
