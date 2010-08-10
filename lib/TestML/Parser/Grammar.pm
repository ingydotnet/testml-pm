package TestML::Parser::Grammar;
use base 'Pegex::Grammar';
use strict;
use warnings;

sub grammar_tree {
    return +{
  '_FIRST_RULE' => 'document',
  'assertion_call' => {
    '+any' => [
      {
        '+rule' => 'assertion_eq'
      },
      {
        '+rule' => 'assertion_ok'
      },
      {
        '+rule' => 'assertion_has'
      }
    ]
  },
  'assertion_call_test' => {
    '+re' => qr/(?-xism:\G(?:\.(?:[\ \t]|\r?\n|\#.*\r?\n)*|(?:[\ \t]|\r?\n|\#.*\r?\n)*\.)(?:EQ|OK|HAS)\()/
  },
  'assertion_eq' => {
    '+any' => [
      {
        '+rule' => 'assertion_operator_eq'
      },
      {
        '+rule' => 'assertion_function_eq'
      }
    ]
  },
  'assertion_function_eq' => {
    '+all' => [
      {
        '+re' => qr/(?-xism:\G(?:\.(?:[\ \t]|\r?\n|\#.*\r?\n)*|(?:[\ \t]|\r?\n|\#.*\r?\n)*\.)EQ\()/
      },
      {
        '+rule' => 'test_expression'
      },
      {
        '+re' => qr/(?-xism:\G\))/
      }
    ]
  },
  'assertion_function_has' => {
    '+all' => [
      {
        '+re' => qr/(?-xism:\G(?:\.(?:[\ \t]|\r?\n|\#.*\r?\n)*|(?:[\ \t]|\r?\n|\#.*\r?\n)*\.)HAS\()/
      },
      {
        '+rule' => 'test_expression'
      },
      {
        '+re' => qr/(?-xism:\G\))/
      }
    ]
  },
  'assertion_function_ok' => {
    '+re' => qr/(?-xism:\G(?:\.(?:[\ \t]|\r?\n|\#.*\r?\n)*|(?:[\ \t]|\r?\n|\#.*\r?\n)*\.)OK(?:\((?:[\ \t]|\r?\n|\#.*\r?\n)*\))?)/
  },
  'assertion_has' => {
    '+any' => [
      {
        '+rule' => 'assertion_operator_has'
      },
      {
        '+rule' => 'assertion_function_has'
      }
    ]
  },
  'assertion_ok' => {
    '+rule' => 'assertion_function_ok'
  },
  'assertion_operator_eq' => {
    '+all' => [
      {
        '+re' => qr/(?-xism:\G(?:[\ \t]|\r?\n|\#.*\r?\n)+==(?:[\ \t]|\r?\n|\#.*\r?\n)+)/
      },
      {
        '+rule' => 'test_expression'
      }
    ]
  },
  'assertion_operator_has' => {
    '+all' => [
      {
        '+re' => qr/(?-xism:\G(?:[\ \t]|\r?\n|\#.*\r?\n)+~~(?:[\ \t]|\r?\n|\#.*\r?\n)+)/
      },
      {
        '+rule' => 'test_expression'
      }
    ]
  },
  'blank_line' => {
    '+re' => qr/(?-xism:\G[\ \t]*\r?\n)/
  },
  'block_header' => {
    '+all' => [
      {
        '+rule' => 'block_marker'
      },
      {
        '+all' => [
          {
            '+re' => qr/(?-xism:\G[\ \t]+)/
          },
          {
            '+rule' => 'block_label'
          }
        ],
        '<' => '?'
      },
      {
        '+re' => qr/(?-xism:\G[\ \t]*\r?\n)/
      }
    ]
  },
  'block_label' => {
    '+rule' => 'unquoted_string'
  },
  'block_marker' => {
    '+re' => qr/(?-xism:\G===)/
  },
  'block_point' => {
    '+any' => [
      {
        '+rule' => 'lines_point'
      },
      {
        '+rule' => 'phrase_point'
      }
    ]
  },
  'call_indicator' => {
    '+re' => qr/(?-xism:\G(?:\.(?:[\ \t]|\r?\n|\#.*\r?\n)*|(?:[\ \t]|\r?\n|\#.*\r?\n)*\.))/
  },
  'comment' => {
    '+re' => qr/(?-xism:\G\#.*\r?\n)/
  },
  'core_transform' => {
    '+re' => qr/(?-xism:\G([A-Z]\w*))/
  },
  'data_block' => {
    '+all' => [
      {
        '+rule' => 'block_header'
      },
      {
        '+any' => [
          {
            '+rule' => 'blank_line'
          },
          {
            '+rule' => 'comment'
          }
        ],
        '<' => '*'
      },
      {
        '+rule' => 'block_point',
        '<' => '*'
      }
    ]
  },
  'data_section' => {
    '+any' => [
      {
        '+rule' => 'testml_data_section'
      },
      {
        '+rule' => 'yaml_data_section'
      },
      {
        '+rule' => 'json_data_section'
      },
      {
        '+rule' => 'xml_data_section'
      }
    ]
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
  'double_quoted_string' => {
    '+re' => qr/(?-xism:\G(?:"(([^\n\\"]|\\"|\\\\|\\[0nt])*?)"))/
  },
  'json_data_section' => {
    '+re' => qr/(?-xism:\G(\[.+))/
  },
  'lines_point' => {
    '+all' => [
      {
        '+rule' => 'point_marker'
      },
      {
        '+re' => qr/(?-xism:\G[\ \t]+)/
      },
      {
        '+rule' => 'point_name'
      },
      {
        '+re' => qr/(?-xism:\G[\ \t]*\r?\n)/
      },
      {
        '+rule' => 'point_lines'
      }
    ]
  },
  'meta_section' => {
    '+all' => [
      {
        '+re' => qr/(?-xism:\G(?:\#.*\r?\n|[\ \t]*\r?\n)*)/
      },
      {
        '+any' => [
          {
            '+rule' => 'meta_testml_statement'
          },
          {
            '+error' => 'No TestML meta directive found'
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
    '+re' => qr/(?-xism:\G%((?:(?:Title|Data|Plan|BlockMarker|PointMarker)|[a-z]\w*)):[\ \t]+((?:(?:'(([^\n\\']|\\'|\\\\)*?)')|(?:"(([^\n\\"]|\\"|\\\\|\\[0nt])*?)")|([^\ \t\n\#](?:[^\n\#]*[^\ \t\n\#])?)))(?:[\ \t]+\#.*\r?\n|\r?\n))/
  },
  'meta_testml_statement' => {
    '+re' => qr/(?-xism:\G%TestML:[\ \t]+(([0-9]\.[0-9]+))(?:[\ \t]+\#.*\r?\n|\r?\n))/
  },
  'phrase_point' => {
    '+all' => [
      {
        '+rule' => 'point_marker'
      },
      {
        '+re' => qr/(?-xism:\G[\ \t]+)/
      },
      {
        '+rule' => 'point_name'
      },
      {
        '+re' => qr/(?-xism:\G:[\ \t])/
      },
      {
        '+rule' => 'point_phrase'
      },
      {
        '+re' => qr/(?-xism:\G\r?\n)/
      },
      {
        '+re' => qr/(?-xism:\G(?:\#.*\r?\n|[\ \t]*\r?\n)*)/
      }
    ]
  },
  'point_call' => {
    '+re' => qr/(?-xism:\G(\*[a-z]\w*))/
  },
  'point_lines' => {
    '+re' => qr/(?-xism:\G((?:(?!===|---).*\r?\n)*))/
  },
  'point_marker' => {
    '+re' => qr/(?-xism:\G---)/
  },
  'point_name' => {
    '+re' => qr/(?-xism:\G([a-z]\w*))/
  },
  'point_phrase' => {
    '+re' => qr/(?-xism:\G(([^\ \t\n\#](?:[^\n\#]*[^\ \t\n\#])?)))/
  },
  'quoted_string' => {
    '+any' => [
      {
        '+rule' => 'single_quoted_string'
      },
      {
        '+rule' => 'double_quoted_string'
      }
    ]
  },
  'single_quoted_string' => {
    '+re' => qr/(?-xism:\G(?:'(([^\n\\']|\\'|\\\\)*?)'))/
  },
  'string_call' => {
    '+rule' => 'quoted_string'
  },
  'sub_expression' => {
    '+any' => [
      {
        '+rule' => 'point_call'
      },
      {
        '+rule' => 'string_call'
      },
      {
        '+rule' => 'transform_call'
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
            '+not' => 'assertion_call_test'
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
        '+rule' => 'test_expression'
      },
      {
        '+rule' => 'assertion_call',
        '<' => '?'
      },
      {
        '+any' => [
          {
            '+re' => qr/(?-xism:\G;)/
          },
          {
            '+error' => 'You seem to be missing a semicolon'
          }
        ]
      }
    ]
  },
  'testml_data_section' => {
    '+rule' => 'data_block',
    '<' => '*'
  },
  'transform_argument' => {
    '+rule' => 'sub_expression'
  },
  'transform_argument_list' => {
    '+all' => [
      {
        '+re' => qr/(?-xism:\G\((?:[\ \t]|\r?\n|\#.*\r?\n)*)/
      },
      {
        '+rule' => 'transform_arguments',
        '<' => '?'
      },
      {
        '+re' => qr/(?-xism:\G(?:[\ \t]|\r?\n|\#.*\r?\n)*\))/
      }
    ]
  },
  'transform_arguments' => {
    '+all' => [
      {
        '+rule' => 'transform_argument'
      },
      {
        '+all' => [
          {
            '+re' => qr/(?-xism:\G(?:[\ \t]|\r?\n|\#.*\r?\n)*,(?:[\ \t]|\r?\n|\#.*\r?\n)*)/
          },
          {
            '+rule' => 'transform_argument'
          }
        ],
        '<' => '*'
      }
    ]
  },
  'transform_call' => {
    '+all' => [
      {
        '+rule' => 'transform_name'
      },
      {
        '+rule' => 'transform_argument_list',
        '<' => '?'
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
  'unquoted_string' => {
    '+re' => qr/(?-xism:\G([^\ \t\n\#](?:[^\n\#]*[^\ \t\n\#])?))/
  },
  'user_transform' => {
    '+re' => qr/(?-xism:\G([a-z]\w*))/
  },
  'ws' => {
    '+re' => qr/(?-xism:\G(?:[\ \t]|\r?\n|\#.*\r?\n))/
  },
  'xml_data_section' => {
    '+re' => qr/(?-xism:\G(<.+))/
  },
  'yaml_data_section' => {
    '+re' => qr/(?-xism:\G(---[\ \t]*\r?\n.+))/
  }
};
}

1;
