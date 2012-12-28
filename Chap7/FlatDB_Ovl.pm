

###
### FlatDB_Overloaded.pm
###

## Chapter 7 section 4.1

package FlatDB_Overloaded;
BEGIN {
  for my $f (qw(and or without)) {
    *{"query_$f"} = \&{"FlatDB_Composable::query_$f"};
  }
}
use base 'FlatDB_Composable';

sub query {
  $self = shift;
  my $q = $self->SUPER::query(@_);
  bless $q => __PACKAGE__;
}

sub callbackquery {
  $self = shift;
  my $q = $self->SUPER::callbackquery(@_);
  bless $q => __PACKAGE__;
}

1;


## Chapter 7 section 4.1

use overload '|' => \&query_or,
             '&' => \&query_and,
             '-' => \&query_without,
             'fallback' => 1;
