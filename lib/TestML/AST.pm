package TestML::AST;

#-----------------------------------------------------------------------------
package TestML::Function;
use TestML::Base -base;

has 'meta' => -init => 'TestML::Document::Meta->new';
has 'data' => -init => 'TestML::Document::Data->new';

has 'statements' => [];

has 'current_expression';
has 'block';

has 'namespace' => {
    'Label' => '$BlockLabel',
};

#-----------------------------------------------------------------------------
package TestML::Document::Meta;
use TestML::Base -base;

# XXX Put above in 'namespace'.
has 'data' => {
    'TestML', '',
    'Data' => [],
    'Title' => '',
    'Plan' => 0,
    'BlockMarker' => '===',
    'PointMarker' => '---',
};

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
has 'error';
has 'set_called';

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
package TestML::Number;
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
