package TestML::Parser::Grammar;
use base 'Pegex::Grammar';

sub grammar_tree {
    return +{
  'NEVER' => {
    '+re' => qr/(?-xism:\G(?!))/
  },
  'TOP' => {
    '+all' => [
      {
        '+rule' => 'NEVER'
      },
      {
        '+rule' => 'code_section'
      },
      {
        '+rule' => 'data_section'
      }
    ]
  },
  '_FIRST_RULE' => 'TOP',
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
    '+re' => qr/(?-xism:\G(?:\.(?:[\ \t]|\r?\n|\#.*\r?\n)*|(?:[\ \t]|\r?\n|\#.*\r?\n)*\.)(?:EQ|OK|HAS))/
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
  'assignment_statement' => {
    '+all' => [
      {
        '+rule' => 'variable_name'
      },
      {
        '+re' => qr/(?-xism:\G\s+=\s+)/
      },
      {
        '+rule' => 'test_expression'
      },
      {
        '+rule' => 'semicolon'
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
  'code_section' => {
    '+any' => [
      {
        '+rule' => 'ws'
      },
      {
        '+rule' => 'assignment_statement'
      },
      {
        '+rule' => 'test_statement'
      }
    ],
    '<' => '*'
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
    '+rule' => 'data_block',
    '<' => '*'
  },
  'double_quoted_string' => {
    '+re' => qr/(?-xism:\G(?:"(([^\n\\"]|\\"|\\\\|\\[0nt])*?)"))/
  },
  'function_definition' => {
    '+all' => [
      {
        '+re' => qr/(?-xism:\G\{(?:[\ \t]|\r?\n|\#.*\r?\n)*)/
      },
      {
        '+rule' => 'test_statement',
        '<' => '*'
      },
      {
        '+re' => qr/(?-xism:\G(?:[\ \t]|\r?\n|\#.*\r?\n)*\})/
      }
    ]
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
  'number' => {
    '+re' => qr/(?-xism:\G([0-9]+))/
  },
  'number_call' => {
    '+rule' => 'number'
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
    '+re' => qr/(?-xism:\G([a-z]\w*|[A-Z]\w*))/
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
  'semicolon' => {
    '+any' => [
      {
        '+re' => qr/(?-xism:\G;)/
      },
      {
        '+error' => 'You seem to be missing a semicolon'
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
        '+rule' => 'function_definition'
      },
      {
        '+rule' => 'point_call'
      },
      {
        '+rule' => 'string_call'
      },
      {
        '+rule' => 'number_call'
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
        '+rule' => 'semicolon'
      }
    ]
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
  'variable_name' => {
    '+re' => qr/(?-xism:\G([a-zA-Z]\w*))/
  },
  'ws' => {
    '+re' => qr/(?-xism:\G(?:[\ \t]|\r?\n|\#.*\r?\n))/
  }
};
}

1;
