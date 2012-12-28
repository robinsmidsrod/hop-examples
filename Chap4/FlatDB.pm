

###
### FlatDB.pm
###

## Chapter 4 section 3.4

package FlatDB;
my $FIELDSEP = qr/:/;

sub new {
  my $class = shift;
  my $file = shift;
  open my $fh, "< $file" or return;
  chomp(my $schema = <$fh>);
  my @field = split $FIELDSEP, $schema;
  my %fieldnum = map { uc $field[$_] => $_ } (0..$#field);
  bless { FH => $fh, FIELDS => \@field, FIELDNUM => \%fieldnum,
          FIELDSEP => $FIELDSEP }   => $class;
}


## Chapter 4 section 3.4.1

# usage: $dbh->query(fieldname, value)
# returns all records for which (fieldname) matches (value)
use Fcntl ':seek';
sub query {
  my $self = shift;
  my ($field, $value) = @_;
  my $fieldnum = $self->{FIELDNUM}{uc $field};
  return unless defined $fieldnum;
  my $fh = $self->{FH};
  seek $fh, 0, SEEK_SET;
  <$fh>;                # discard header line
  my $position = tell $fh;

  return Iterator {
    local $_;
    seek $fh, $position, SEEK_SET;
    while (<$fh>) {
      $position = tell $fh;         
      my @fields = split $self->{FIELDSEP};
      my $fieldval = $fields[$fieldnum];
      return $_ if $fieldval eq $value;
    }
    return;
  };
}


## Chapter 4 section 3.4.1

# callbackquery with bug fix
use Fcntl ':seek';
sub callbackquery {
  my $self = shift;
  my $is_interesting = shift;
  my $fh = $self->{FH};
  seek $fh, 0, SEEK_SET;
  <$fh>;                # discard header line
  my $position = tell $fh;

  return Iterator {
    local $_;
    seek $fh, $position, SEEK_SET;
    while (<$fh>) {
      $position = tell $fh;         
      my %F;
      my @fieldnames = @{$self->{FIELDS}};
      my @fields = split $self->{FIELDSEP};
      for (0 .. $#fieldnames) {
        $F{$fieldnames[$_]} = $fields[$_];
      }
      return [$position, $_] if $is_interesting->(%F);
    }
    return;
  };
}

1;
