package TestML::Document;
use strict;
use warnings;

use TestML::Base -base;

has 'meta' => -init => 'TestML::Document::Meta->new';
has 'test' => -init => 'TestML::Document::Test->new';
has 'data' => -init => 'TestML::Document::Data->new';

#-----------------------------------------------------------------------------
package TestML::Document::Meta;
use TestML::Base -base;

has 'data' => {
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

has 'statements' => [];

#-----------------------------------------------------------------------------
package TestML::Statement;
use TestML::Base -base;

has 'expression', -init => 'TestML::Expression->new';
has 'assertion';
has 'points' => [];

#-----------------------------------------------------------------------------
package TestML::Expression;
use TestML::Base -base;

has 'transforms' => [];

#-----------------------------------------------------------------------------
package TestML::Assertion;
use TestML::Base -base;

has 'name';
has 'expression', -init => 'TestML::Expression->new';

#-----------------------------------------------------------------------------
package TestML::Transform;
use TestML::Base -base;

has 'name';
has 'args' => [];

#-----------------------------------------------------------------------------
package TestML::String;
use TestML::Transform -base;

has 'value' => '';

#-----------------------------------------------------------------------------
package TestML::Document::Data;
use TestML::Base -base;

has 'blocks' => [];

#-----------------------------------------------------------------------------
package TestML::Block;
use TestML::Base -base;

has 'label' => '';
has 'points' => {};

1;
