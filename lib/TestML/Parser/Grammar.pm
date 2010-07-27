package TestML::Parser::Grammar;
use base 'TestML::Parser::Pegex';
use strict;
use warnings;

sub grammar {
    return +{
  'ALWAYS' => {
    '+re' => ''
  },
  'SEMI' => {
    '+re' => ';'
  },
  'assertion_call' => {
    '+any' => [
      {
        '+rule' => 'assertion_operator_call'
      },
      {
        '+rule' => 'assertion_function_call'
      }
    ]
  },
  'assertion_function_call' => {
    '+all' => [
      {
        '+re' => '(?:\\.(?:[\\ \\t]|\\r?\\n|#.*\\r?\\n)*|(?:[\\ \\t]|\\r?\\n|#.*\\r?\\n)*\\.)EQ\\((?:[\\ \\t]|\\r?\\n|#.*\\r?\\n)*'
      },
      {
        '+rule' => 'test_expression'
      },
      {
        '+re' => '(?:[\\ \\t]|\\r?\\n|#.*\\r?\\n)*\\)'
      }
    ]
  },
  'assertion_operator' => {
    '+re' => '(==)'
  },
  'assertion_operator_call' => {
    '+all' => [
      {
        '+re' => '(?:[\\ \\t]|\\r?\\n|#.*\\r?\\n)+'
      },
      {
        '+rule' => 'assertion_operator'
      },
      {
        '+re' => '(?:[\\ \\t]|\\r?\\n|#.*\\r?\\n)+'
      },
      {
        '+rule' => 'test_expression'
      }
    ]
  },
  'blank_line' => {
    '+re' => '[\\ \\t]*\\r?\\n'
  },
  'call_indicator' => {
    '+re' => '(?:\\.(?:[\\ \\t]|\\r?\\n|#.*\\r?\\n)*|(?:[\\ \\t]|\\r?\\n|#.*\\r?\\n)*\\.)'
  },
  'comment' => {
    '+re' => '#.*\\r?\\n'
  },
  'constant_call' => {
    '+re' => '([A-Z]\\w*)'
  },
  'core_transform' => {
    '+re' => '([A-Z]\\w*)'
  },
  'data_section' => {
    '+re' => '(===(?:[\\ \\t]|\\r?\\n)[\\s\\S]+|\\Z)'
  },
  'document' => {
    '+all' => [
      {
        '+rule' => 'meta_section'
      },
      {
        '+rule' => 'test_section'
      },
      {
        '+rule' => 'data_section',
        '<' => '?'
      }
    ]
  },
  'meta_section' => {
    '+all' => [
      {
        '+re' => '(?:#.*\\r?\\n|[\\ \\t]*\\r?\\n)*'
      },
      {
        '+any' => [
          {
            '+rule' => 'meta_testml_statement'
          },
          {
            '+rule' => 'NO_META_TESTML_ERROR'
          }
        ]
      },
      {
        '+any' => [
          {
            '+rule' => 'meta_statement'
          },
          {
            '+rule' => 'comment'
          },
          {
            '+rule' => 'blank_line'
          }
        ],
        '<' => '*'
      }
    ]
  },
  'meta_statement' => {
    '+re' => '%((?:(?:Title|Data|Plan|BlockMarker|PointMarker)|[a-z]\\w*)):[\\ \\t]+((?:(?:(?:\'(([^\\n\\\']|\\\'|\\\\)*?)\')|(?:"(([^\\n\\"]|\\"|\\\\|\\[0nt])*?)"))|[^\\ \\t\\n#](?:[^\\n#]*[^\\ \\t\\n#])?))(?:[\\ \\t]+#.*\\r?\\n|\\r?\\n)'
  },
  'meta_testml_statement' => {
    '+re' => '%TestML:[\\ \\t]+(([0-9]\\.[0-9]+))(?:[\\ \\t]+#.*\\r?\\n|\\r?\\n)'
  },
  'point_call' => {
    '+re' => '(\\*[a-z]\\w*)'
  },
  'quoted_string' => {
    '+re' => '(?:(?:\'(([^\\n\\\']|\\\'|\\\\)*?)\')|(?:"(([^\\n\\"]|\\"|\\\\|\\[0nt])*?)"))'
  },
  'string_call' => {
    '+rule' => 'quoted_string'
  },
  'sub_expression' => {
    '+any' => [
      {
        '+rule' => 'transform_call'
      },
      {
        '+rule' => 'point_call'
      },
      {
        '+rule' => 'string_call'
      },
      {
        '+rule' => 'constant_call'
      }
    ]
  },
  'test_expression' => {
    '+all' => [
      {
        '+rule' => 'sub_expression'
      },
      {
        '+all' => [
          {
            '+rule' => '!assertion_function_call'
          },
          {
            '+rule' => 'call_indicator'
          },
          {
            '+rule' => 'sub_expression'
          }
        ],
        '<' => '*'
      }
    ]
  },
  'test_section' => {
    '+any' => [
      {
        '+rule' => 'ws'
      },
      {
        '+rule' => 'test_statement'
      }
    ],
    '<' => '*'
  },
  'test_statement' => {
    '+all' => [
      {
        '+rule' => 'test_statement_start'
      },
      {
        '+rule' => 'test_expression'
      },
      {
        '+rule' => 'assertion_call',
        '<' => '?'
      },
      {
        '+any' => [
          {
            '+rule' => 'SEMI'
          },
          {
            '+rule' => 'SEMICOLON_ERROR'
          }
        ]
      }
    ]
  },
  'test_statement_start' => {
    '+rule' => 'ALWAYS'
  },
  'transform_argument' => {
    '+rule' => 'sub_expression'
  },
  'transform_argument_list' => {
    '+all' => [
      {
        '+rule' => 'transform_argument'
      },
      {
        '+all' => [
          {
            '+re' => '(?:[\\ \\t]|\\r?\\n|#.*\\r?\\n)*,(?:[\\ \\t]|\\r?\\n|#.*\\r?\\n)*'
          },
          {
            '+rule' => 'transform_argument'
          }
        ],
        '<' => '*'
      }
    ],
    '<' => '?'
  },
  'transform_argument_list_start' => {
    '+rule' => 'ALWAYS'
  },
  'transform_argument_list_stop' => {
    '+rule' => 'ALWAYS'
  },
  'transform_call' => {
    '+all' => [
      {
        '+rule' => 'transform_name'
      },
      {
        '+re' => '\\('
      },
      {
        '+rule' => 'transform_argument_list_start'
      },
      {
        '+re' => '(?:[\\ \\t]|\\r?\\n|#.*\\r?\\n)*'
      },
      {
        '+rule' => 'transform_argument_list'
      },
      {
        '+re' => '(?:[\\ \\t]|\\r?\\n|#.*\\r?\\n)*'
      },
      {
        '+rule' => 'transform_argument_list_stop'
      },
      {
        '+re' => '\\)'
      }
    ]
  },
  'transform_name' => {
    '+any' => [
      {
        '+rule' => 'user_transform'
      },
      {
        '+rule' => 'core_transform'
      }
    ]
  },
  'user_transform' => {
    '+re' => '([a-z]\\w*)'
  },
  'ws' => {
    '+re' => '(?:[\\ \\t]|\\r?\\n|#.*\\r?\\n)'
  }
};
}

1;
