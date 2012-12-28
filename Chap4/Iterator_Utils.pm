

###
### Iterator_Utils.pm
###

## Chapter 4 section 2.1

package Iterator_Utils;
use base Exporter;
@EXPORT_OK = qw(NEXTVAL Iterator 
                append imap igrep
                iterate_function filehandle_iterator list_iterator);
%EXPORT_TAGS = ('all' => \@EXPORT_OK);

sub NEXTVAL { $_[0]->() }


## Chapter 4 section 2.1.1

sub Iterator (&) { return $_[0] }


## Chapter 4 section 3.1

sub iterate_function {
  my $n = 0;
  my $f = shift;
  return Iterator {  
    return $f->($n++);
  };
}


## Chapter 4 section 3.3

sub filehandle_iterator {
  my $fh = shift;
  return Iterator { <$fh> };
}
1;


## Chapter 4 section 4.1

sub imap (&$) {
  my ($transform, $it) = @_;
  return Iterator {
    local $_ = NEXTVAL($it);
    return unless defined $_;
    return $transform->();
  }
}


## Chapter 4 section 4.2

sub igrep (&$) {
  my ($is_interesting, $it) = @_;
  return Iterator {
    local $_;
    while (defined ($_ = NEXTVAL($it))) {
      return $_ if $is_interesting->();
    }
    return;
  }
}


## Chapter 4 section 4.3

sub list_iterator {
  my @items = @_;
  return Iterator {
    return shift @items;
  };
}


## Chapter 4 section 4.4

sub append {
  my @its = @_;
  return Iterator {
    while (@its) {
      my $val = NEXTVAL($its[0]);
      return $val if defined $val;
      shift @its;  # Discard exhausted iterator
    }
    return;
  };
}


## Chapter 4 section 7.2

sub igrep_l (&$) {
  my ($is_interesting, $it) = @_;
  return Iterator {
    while (my @vals = NEXTVAL($it)) {
      return @vals if $is_interesting->(@vals);
    }
    return;
  }
}
