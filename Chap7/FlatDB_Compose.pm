

###
### FlatDB_Composable.pm
###

## Chapter 7 section 4

package FlatDB_Composable;
use base 'FlatDB';
use base 'Exporter';
@EXPORT_OK = qw(query_or query_and query_not query_without);
use Iterator_Logic;

# usage: $dbh->query(fieldname, value)
# returns all records for which (fieldname) matches (value)
sub query {
  my $self = shift;
  my ($field, $value) = @_;
  my $fieldnum = $self->{FIELDNUM}{uc $field};
  return unless defined $fieldnum;
  my $fh = $self->{FH};
  seek $fh, 0, 0;
  <$fh>;                # discard header line
  my $position = tell $fh;
  my $recno = 0;

  return sub {
    local $_;
    seek $fh, $position, 0;
    while (<$fh>) {
      chomp;
      $recno++;
      $position = tell $fh;         
      my @fields = split $self->{FIELDSEP};
      my $fieldval = $fields[$fieldnum];
      return [$recno, @fields] if $fieldval eq $value;
    }
    return;
  };
}


## Chapter 7 section 4

BEGIN { *query_or  =  i_or(sub { $_[0][0] <=> $_[1][0] });
        *query_and = i_and(sub { $_[0][0] <=> $_[1][0] });
      }


## Chapter 7 section 4

BEGIN { *query_without = i_without(sub { $_[0][0] <=> $_[1][0] }); }

sub callbackquery {
  my $self = shift;
  my $is_interesting = shift;
  my $fh = $self->{FH};
  seek $fh, 0, SEEK_SET;
  <$fh>;                # discard header line
  my $position = tell $fh;
  my $recno = 0;

  return sub {
    local $_;
    seek $fh, $position, SEEK_SET;
    while (<$fh>) {
      $position = tell $fh;         
      chomp;
      $recno++;
      my %F;
      my @fieldnames = @{$self->{FIELDS}};
      my @fields = split $self->{FIELDSEP};
      for (0 .. $#fieldnames) {
        $F{$fieldnames[$_]} = $fields[$_];
      }
      return [$recno, @fields] if $is_interesting->(%F);
    }
    return;
  };
}

1;


## Chapter 7 section 4

sub query_not {
  my $self = shift;
  my $q = shift;
  query_without($self->all, $q);
}
sub all {
  $_[0]->callbackquery(sub { 1 });
}

1;
