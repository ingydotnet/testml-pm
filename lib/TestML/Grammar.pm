package TestML::Grammar;
use base 'Pegex::Grammar';
# use base 'Pegex::Grammar::Bootstrap';

sub build_tree {
    return +{
  '+top' => 'TOP',
  'NEVER' => {
    '.rgx' => qr/(?-xism:\G(?!))/
  },
  'TOP' => {
    '.all' => [
      {
        '.rul' => 'NEVER'
      },
      {
        '.rul' => 'code_section'
      },
      {
        '.rul' => 'data_section'
      }
    ]
  },
  'assertion_call' => {
    '.any' => [
      {
        '.rul' => 'assertion_eq'
      },
      {
        '.rul' => 'assertion_ok'
      },
      {
        '.rul' => 'assertion_has'
      }
    ]
  },
  'assertion_call_test' => {
    '.rgx' => qr/(?-xism:\G(?:\.(?:[\ \t]|\r?\n|\#.*\r?\n)*|(?:[\ \t]|\r?\n|\#.*\r?\n)*\.)(?:EQ|OK|HAS))/
  },
  'assertion_eq' => {
    '.any' => [
      {
        '.rul' => 'assertion_operator_eq'
      },
      {
        '.rul' => 'assertion_function_eq'
      }
    ]
  },
  'assertion_function_eq' => {
    '.all' => [
      {
        '.rgx' => qr/(?-xism:\G(?:\.(?:[\ \t]|\r?\n|\#.*\r?\n)*|(?:[\ \t]|\r?\n|\#.*\r?\n)*\.)EQ\()/
      },
      {
        '.rul' => 'code_expression'
      },
      {
        '.rgx' => qr/(?-xism:\G\))/
      }
    ]
  },
  'assertion_function_has' => {
    '.all' => [
      {
        '.rgx' => qr/(?-xism:\G(?:\.(?:[\ \t]|\r?\n|\#.*\r?\n)*|(?:[\ \t]|\r?\n|\#.*\r?\n)*\.)HAS\()/
      },
      {
        '.rul' => 'code_expression'
      },
      {
        '.rgx' => qr/(?-xism:\G\))/
      }
    ]
  },
  'assertion_function_ok' => {
    '.rgx' => qr/(?-xism:\G(?:\.(?:[\ \t]|\r?\n|\#.*\r?\n)*|(?:[\ \t]|\r?\n|\#.*\r?\n)*\.)OK(?:\((?:[\ \t]|\r?\n|\#.*\r?\n)*\))?)/
  },
  'assertion_has' => {
    '.any' => [
      {
        '.rul' => 'assertion_operator_has'
      },
      {
        '.rul' => 'assertion_function_has'
      }
    ]
  },
  'assertion_ok' => {
    '.rul' => 'assertion_function_ok'
  },
  'assertion_operator_eq' => {
    '.all' => [
      {
        '.rgx' => qr/(?-xism:\G(?:[\ \t]|\r?\n|\#.*\r?\n)+==(?:[\ \t]|\r?\n|\#.*\r?\n)+)/
      },
      {
        '.rul' => 'code_expression'
      }
    ]
  },
  'assertion_operator_has' => {
    '.all' => [
      {
        '.rgx' => qr/(?-xism:\G(?:[\ \t]|\r?\n|\#.*\r?\n)+~~(?:[\ \t]|\r?\n|\#.*\r?\n)+)/
      },
      {
        '.rul' => 'code_expression'
      }
    ]
  },
  'assignment_statement' => {
    '.all' => [
      {
        '.rul' => 'variable_name'
      },
      {
        '.rgx' => qr/(?-xism:\G\s+=\s+)/
      },
      {
        '.rul' => 'code_expression'
      },
      {
        '.rul' => 'semicolon'
      }
    ]
  },
  'blank_line' => {
    '.rgx' => qr/(?-xism:\G[\ \t]*\r?\n)/
  },
  'block_header' => {
    '.all' => [
      {
        '.rul' => 'block_marker'
      },
      {
        '.all' => [
          {
            '.rgx' => qr/(?-xism:\G[\ \t]+)/
          },
          {
            '.rul' => 'block_label'
          }
        ],
        '<' => '?'
      },
      {
        '.rgx' => qr/(?-xism:\G[\ \t]*\r?\n)/
      }
    ]
  },
  'block_label' => {
    '.rul' => 'unquoted_string'
  },
  'block_marker' => {
    '.rgx' => qr/(?-xism:\G===)/
  },
  'block_point' => {
    '.any' => [
      {
        '.rul' => 'lines_point'
      },
      {
        '.rul' => 'phrase_point'
      }
    ]
  },
  'call_indicator' => {
    '.rgx' => qr/(?-xism:\G(?:\.(?:[\ \t]|\r?\n|\#.*\r?\n)*|(?:[\ \t]|\r?\n|\#.*\r?\n)*\.))/
  },
  'code_expression' => {
    '.all' => [
      {
        '.rul' => 'code_object'
      },
      {
        '.rul' => 'unit_call',
        '<' => '*'
      }
    ]
  },
  'code_object' => {
    '.any' => [
      {
        '.rul' => 'function_object'
      },
      {
        '.rul' => 'point_object'
      },
      {
        '.rul' => 'string_object'
      },
      {
        '.rul' => 'number_object'
      },
      {
        '.rul' => 'transform_object'
      }
    ]
  },
  'code_section' => {
    '.any' => [
      {
        '.rgx' => qr/(?-xism:\G(?:[\ \t]|\r?\n|\#.*\r?\n)+)/
      },
      {
        '.rul' => 'assignment_statement'
      },
      {
        '.rul' => 'code_statement'
      }
    ],
    '<' => '*'
  },
  'code_statement' => {
    '.all' => [
      {
        '.rul' => 'code_expression'
      },
      {
        '.rul' => 'assertion_call',
        '<' => '?'
      },
      {
        '.rul' => 'semicolon'
      }
    ]
  },
  'comment' => {
    '.rgx' => qr/(?-xism:\G\#.*\r?\n)/
  },
  'core_transform' => {
    '.rgx' => qr/(?-xism:\G([A-Z]\w*))/
  },
  'data_block' => {
    '.all' => [
      {
        '.rul' => 'block_header'
      },
      {
        '.any' => [
          {
            '.rul' => 'blank_line'
          },
          {
            '.rul' => 'comment'
          }
        ],
        '<' => '*'
      },
      {
        '.rul' => 'block_point',
        '<' => '*'
      }
    ]
  },
  'data_section' => {
    '.rul' => 'data_block',
    '<' => '*'
  },
  'double_quoted_string' => {
    '.rgx' => qr/(?-xism:\G(?:"(([^\n\\"]|\\"|\\\\|\\[0nt])*?)"))/
  },
  'function_object' => {
    '.all' => [
      {
        '.rul' => 'function_signature',
        '<' => '?'
      },
      {
        '.rgx' => qr/(?-xism:\G(?:[\ \t]|\r?\n|\#.*\r?\n)*\{(?:[\ \t]|\r?\n|\#.*\r?\n)*)/
      },
      {
        '.any' => [
          {
            '.rgx' => qr/(?-xism:\G(?:[\ \t]|\r?\n|\#.*\r?\n)+)/
          },
          {
            '.rul' => 'assignment_statement'
          },
          {
            '.rul' => 'code_statement'
          }
        ],
        '<' => '*'
      },
      {
        '.rgx' => qr/(?-xism:\G(?:[\ \t]|\r?\n|\#.*\r?\n)*\})/
      }
    ]
  },
  'function_signature' => {
    '.all' => [
      {
        '.rgx' => qr/(?-xism:\G\((?:[\ \t]|\r?\n|\#.*\r?\n)*)/
      },
      {
        '.rul' => 'function_variables',
        '<' => '?'
      },
      {
        '.rgx' => qr/(?-xism:\G(?:[\ \t]|\r?\n|\#.*\r?\n)*\))/
      }
    ]
  },
  'function_variable' => {
    '.rgx' => qr/(?-xism:\G([a-zA-Z]\w*))/
  },
  'function_variables' => {
    '.all' => [
      {
        '.rul' => 'function_variable'
      },
      {
        '.all' => [
          {
            '.rgx' => qr/(?-xism:\G(?:[\ \t]|\r?\n|\#.*\r?\n)*,(?:[\ \t]|\r?\n|\#.*\r?\n)*)/
          },
          {
            '.rul' => 'function_variable'
          }
        ],
        '<' => '*'
      }
    ]
  },
  'lines_point' => {
    '.all' => [
      {
        '.rul' => 'point_marker'
      },
      {
        '.rgx' => qr/(?-xism:\G[\ \t]+)/
      },
      {
        '.rul' => 'point_name'
      },
      {
        '.rgx' => qr/(?-xism:\G[\ \t]*\r?\n)/
      },
      {
        '.rul' => 'point_lines'
      }
    ]
  },
  'number' => {
    '.rgx' => qr/(?-xism:\G([0-9]+))/
  },
  'number_object' => {
    '.rul' => 'number'
  },
  'phrase_point' => {
    '.all' => [
      {
        '.rul' => 'point_marker'
      },
      {
        '.rgx' => qr/(?-xism:\G[\ \t]+)/
      },
      {
        '.rul' => 'point_name'
      },
      {
        '.rgx' => qr/(?-xism:\G:[\ \t])/
      },
      {
        '.rul' => 'point_phrase'
      },
      {
        '.rgx' => qr/(?-xism:\G\r?\n)/
      },
      {
        '.rgx' => qr/(?-xism:\G(?:\#.*\r?\n|[\ \t]*\r?\n)*)/
      }
    ]
  },
  'point_lines' => {
    '.rgx' => qr/(?-xism:\G((?:(?!===|---).*\r?\n)*))/
  },
  'point_marker' => {
    '.rgx' => qr/(?-xism:\G---)/
  },
  'point_name' => {
    '.rgx' => qr/(?-xism:\G([a-z]\w*|[A-Z]\w*))/
  },
  'point_object' => {
    '.rgx' => qr/(?-xism:\G(\*[a-z]\w*))/
  },
  'point_phrase' => {
    '.rgx' => qr/(?-xism:\G(([^\ \t\n\#](?:[^\n\#]*[^\ \t\n\#])?)))/
  },
  'quoted_string' => {
    '.any' => [
      {
        '.rul' => 'single_quoted_string'
      },
      {
        '.rul' => 'double_quoted_string'
      }
    ]
  },
  'semicolon' => {
    '.any' => [
      {
        '.rgx' => qr/(?-xism:\G;)/
      },
      {
        '.err' => 'You seem to be missing a semicolon'
      }
    ]
  },
  'single_quoted_string' => {
    '.rgx' => qr/(?-xism:\G(?:'(([^\n\\']|\\'|\\\\)*?)'))/
  },
  'string_object' => {
    '.rul' => 'quoted_string'
  },
  'transform_argument' => {
    '.rul' => 'code_expression'
  },
  'transform_argument_list' => {
    '.all' => [
      {
        '.rgx' => qr/(?-xism:\G\((?:[\ \t]|\r?\n|\#.*\r?\n)*)/
      },
      {
        '.rul' => 'transform_arguments',
        '<' => '?'
      },
      {
        '.rgx' => qr/(?-xism:\G(?:[\ \t]|\r?\n|\#.*\r?\n)*\))/
      }
    ]
  },
  'transform_arguments' => {
    '.all' => [
      {
        '.rul' => 'transform_argument'
      },
      {
        '.all' => [
          {
            '.rgx' => qr/(?-xism:\G(?:[\ \t]|\r?\n|\#.*\r?\n)*,(?:[\ \t]|\r?\n|\#.*\r?\n)*)/
          },
          {
            '.rul' => 'transform_argument'
          }
        ],
        '<' => '*'
      }
    ]
  },
  'transform_name' => {
    '.any' => [
      {
        '.rul' => 'user_transform'
      },
      {
        '.rul' => 'core_transform'
      }
    ]
  },
  'transform_object' => {
    '.all' => [
      {
        '.rul' => 'transform_name'
      },
      {
        '.rul' => 'transform_argument_list',
        '<' => '?'
      }
    ]
  },
  'unit_call' => {
    '.all' => [
      {
        '.rul' => 'assertion_call_test',
        '<' => '!'
      },
      {
        '.rul' => 'call_indicator'
      },
      {
        '.rul' => 'code_object'
      }
    ]
  },
  'unquoted_string' => {
    '.rgx' => qr/(?-xism:\G([^\ \t\n\#](?:[^\n\#]*[^\ \t\n\#])?))/
  },
  'user_transform' => {
    '.rgx' => qr/(?-xism:\G([a-z]\w*))/
  },
  'variable_name' => {
    '.rgx' => qr/(?-xism:\G([a-zA-Z]\w*))/
  }
};
}

1;
