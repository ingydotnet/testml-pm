package TestML::Test;
use strict;
use warnings;

use TestML::Base -base;

field 'meta' => -init => 'TestML::Test::Meta->new';
field 'tests' => -init => 'TestML::Test::Tests->new';
field 'data' => -init => 'TestML::Test::Data->new';

package TestML::Test::Meta;
use TestML::Base -base;

field 'tests' => 0;

1;
