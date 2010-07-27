package TestML::Document;
use strict;
use warnings;

use TestML::Base -base;

field 'meta' => -init => 'TestML::Document::Meta->new';
field 'test' => -init => 'TestML::Document::Test->new';
field 'data' => -init => 'TestML::Document::Data->new';

#-----------------------------------------------------------------------------
package TestML::Document::Meta;
use TestML::Base -base;

field 'data' => {
    'TestML', '',
    'Data' => [],
    'Title' => '',
    'Plan' => 0,
    'BlockMarker' => '===',
    'PointMarker' => '---',
};

#-----------------------------------------------------------------------------
package TestML::Document::Test;
use TestML::Base -base;

field 'statements' => [];

#-----------------------------------------------------------------------------
package TestML::Statement;
use TestML::Base -base;

field 'expression', -init => 'TestML::Expression->new';
field 'assertion';
field 'points' => [];

#-----------------------------------------------------------------------------
package TestML::Expression;
use TestML::Base -base;

field 'transforms' => [];

#-----------------------------------------------------------------------------
package TestML::Assertion;
use TestML::Base -base;

field 'name';
field 'expression', -init => 'TestML::Expression->new';

#-----------------------------------------------------------------------------
package TestML::Transform;
use TestML::Base -base;

field 'name';
field 'args' => [];

#-----------------------------------------------------------------------------
package TestML::Document::Data;
use TestML::Base -base;

field 'blocks' => [];

#-----------------------------------------------------------------------------
package TestML::Block;
use TestML::Base -base;

field 'label' => '';
field 'points' => {};

1;
