package TestML::Grammar;
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
        '+rule' => 'code_expression'
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
        '+rule' => 'code_expression'
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
        '+rule' => 'code_expression'
      }
    ]
  },
  'assertion_operator_has' => {
    '+all' => [
      {
        '+re' => qr/(?-xism:\G(?:[\ \t]|\r?\n|\#.*\r?\n)+~~(?:[\ \t]|\r?\n|\#.*\r?\n)+)/
      },
      {
        '+rule' => 'code_expression'
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
        '+rule' => 'code_expression'
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
  'code_expression' => {
    '+all' => [
      {
        '+rule' => 'code_object'
      },
      {
        '+rule' => 'unit_call',
        '<' => '*'
      }
    ]
  },
  'code_object' => {
    '+any' => [
      {
        '+rule' => 'function_object'
      },
      {
        '+rule' => 'point_object'
      },
      {
        '+rule' => 'string_object'
      },
      {
        '+rule' => 'number_object'
      },
      {
        '+rule' => 'transform_object'
      }
    ]
  },
  'code_section' => {
    '+any' => [
      {
        '+re' => qr/(?-xism:\G(?:[\ \t]|\r?\n|\#.*\r?\n)+)/
      },
      {
        '+rule' => 'assignment_statement'
      },
      {
        '+rule' => 'code_statement'
      }
    ],
    '<' => '*'
  },
  'code_statement' => {
    '+all' => [
      {
        '+rule' => 'code_expression'
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
  'function_object' => {
    '+all' => [
      {
        '+rule' => 'function_signature',
        '<' => '?'
      },
      {
        '+re' => qr/(?-xism:\G(?:[\ \t]|\r?\n|\#.*\r?\n)*\{(?:[\ \t]|\r?\n|\#.*\r?\n)*)/
      },
      {
        '+any' => [
          {
            '+re' => qr/(?-xism:\G(?:[\ \t]|\r?\n|\#.*\r?\n)+)/
          },
          {
            '+rule' => 'assignment_statement'
          },
          {
            '+rule' => 'code_statement'
          }
        ],
        '<' => '*'
      },
      {
        '+re' => qr/(?-xism:\G(?:[\ \t]|\r?\n|\#.*\r?\n)*\})/
      }
    ]
  },
  'function_signature' => {
    '+all' => [
      {
        '+re' => qr/(?-xism:\G\((?:[\ \t]|\r?\n|\#.*\r?\n)*)/
      },
      {
        '+rule' => 'function_variables',
        '<' => '?'
      },
      {
        '+re' => qr/(?-xism:\G(?:[\ \t]|\r?\n|\#.*\r?\n)*\))/
      }
    ]
  },
  'function_variable' => {
    '+re' => qr/(?-xism:\G([a-zA-Z]\w*))/
  },
  'function_variables' => {
    '+all' => [
      {
        '+rule' => 'function_variable'
      },
      {
        '+all' => [
          {
            '+re' => qr/(?-xism:\G(?:[\ \t]|\r?\n|\#.*\r?\n)*,(?:[\ \t]|\r?\n|\#.*\r?\n)*)/
          },
          {
            '+rule' => 'function_variable'
          }
        ],
        '<' => '*'
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
  'number_object' => {
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
  'point_lines' => {
    '+re' => qr/(?-xism:\G((?:(?!===|---).*\r?\n)*))/
  },
  'point_marker' => {
    '+re' => qr/(?-xism:\G---)/
  },
  'point_name' => {
    '+re' => qr/(?-xism:\G([a-z]\w*|[A-Z]\w*))/
  },
  'point_object' => {
    '+re' => qr/(?-xism:\G(\*[a-z]\w*))/
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
  'string_object' => {
    '+rule' => 'quoted_string'
  },
  'transform_argument' => {
    '+rule' => 'code_expression'
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
  'transform_object' => {
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
  'unit_call' => {
    '+all' => [
      {
        '+not' => 'assertion_call_test'
      },
      {
        '+rule' => 'call_indicator'
      },
      {
        '+rule' => 'code_object'
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
  }
};
}

1;
