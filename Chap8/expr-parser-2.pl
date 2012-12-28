

###
### simple-expr-parser-2.pl
###

## Chapter 8 section 4

use Parser ':all';
use Lexer ':all';

my ($expression, $term, $factor);
my $Expression = parser { $expression->(@_) };
my $Term       = parser { $term      ->(@_) };
my $Factor     = parser { $factor    ->(@_) };
$expression = alternate(concatenate($Term,
                                    lookfor(['OP', '+']),
                                    $Expression),
                        $Term);

$term       = alternate(concatenate($Factor,
                                    lookfor(['OP', '*']),
                                    $Term),
                        $Factor);

$factor     = alternate(lookfor('INT'),
                        concatenate(lookfor(['OP', '(']),
                                    $Expression,
                                    lookfor(['OP', ')']))
                        );

$entire_input = concatenate($Expression, \&End_of_Input);
