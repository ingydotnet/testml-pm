package TestML::Grammar;
use TestML::Mo;
extends 'Pegex::Grammar';

sub tree_ {
  {
    '+top' => 'testml_document',
    'assertion_call' => {
      '.any' => [
        {
          '-wrap' => 1,
          '.ref' => 'assertion_eq'
        },
        {
          '-wrap' => 1,
          '.ref' => 'assertion_ok'
        },
        {
          '-wrap' => 1,
          '.ref' => 'assertion_has'
        }
      ]
    },
    'assertion_call_test' => {
      '.rgx' => qr/(?-xism:\G(?:\.(?:[\ \t]|\r?\n|\#.*\r?\n)*|(?:[\ \t]|\r?\n|\#.*\r?\n)*\.)(?:EQ|OK|HAS))/
    },
    'assertion_eq' => {
      '.any' => [
        {
          '-wrap' => 1,
          '.ref' => 'assertion_operator_eq'
        },
        {
          '-wrap' => 1,
          '.ref' => 'assertion_function_eq'
        }
      ]
    },
    'assertion_function_eq' => {
      '.all' => [
        {
          '.rgx' => qr/(?-xism:\G(?:\.(?:[\ \t]|\r?\n|\#.*\r?\n)*|(?:[\ \t]|\r?\n|\#.*\r?\n)*\.)EQ\()/
        },
        {
          '.ref' => 'code_expression'
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
          '.ref' => 'code_expression'
        },
        {
          '.rgx' => qr/(?-xism:\G\))/
        }
      ]
    },
    'assertion_function_ok' => {
      '.rgx' => qr/(?-xism:\G(?:\.(?:[\ \t]|\r?\n|\#.*\r?\n)*|(?:[\ \t]|\r?\n|\#.*\r?\n)*\.)(OK)(?:\((?:[\ \t]|\r?\n|\#.*\r?\n)*\))?)/
    },
    'assertion_has' => {
      '.any' => [
        {
          '-wrap' => 1,
          '.ref' => 'assertion_operator_has'
        },
        {
          '-wrap' => 1,
          '.ref' => 'assertion_function_has'
        }
      ]
    },
    'assertion_ok' => {
      '.ref' => 'assertion_function_ok'
    },
    'assertion_operator_eq' => {
      '.all' => [
        {
          '.rgx' => qr/(?-xism:\G(?:[\ \t]|\r?\n|\#.*\r?\n)+==(?:[\ \t]|\r?\n|\#.*\r?\n)+)/
        },
        {
          '.ref' => 'code_expression'
        }
      ]
    },
    'assertion_operator_has' => {
      '.all' => [
        {
          '.rgx' => qr/(?-xism:\G(?:[\ \t]|\r?\n|\#.*\r?\n)+~~(?:[\ \t]|\r?\n|\#.*\r?\n)+)/
        },
        {
          '.ref' => 'code_expression'
        }
      ]
    },
    'assignment_statement' => {
      '.all' => [
        {
          '.ref' => 'variable_name'
        },
        {
          '.rgx' => qr/(?-xism:\G\s+=\s+)/
        },
        {
          '.ref' => 'code_expression'
        },
        {
          '.ref' => 'semicolon'
        }
      ]
    },
    'blank_line' => {
      '.rgx' => qr/(?-xism:\G[\ \t]*\r?\n)/
    },
    'block_header' => {
      '.all' => [
        {
          '.ref' => 'block_marker'
        },
        {
          '+max' => 1,
          '.all' => [
            {
              '.rgx' => qr/(?-xism:\G[\ \t]+)/
            },
            {
              '.ref' => 'block_label'
            }
          ]
        },
        {
          '.rgx' => qr/(?-xism:\G[\ \t]*\r?\n)/
        }
      ]
    },
    'block_label' => {
      '.ref' => 'unquoted_string'
    },
    'block_marker' => {
      '.rgx' => qr/(?-xism:\G===)/
    },
    'block_point' => {
      '.any' => [
        {
          '.ref' => 'lines_point'
        },
        {
          '.ref' => 'phrase_point'
        }
      ]
    },
    'call_indicator' => {
      '.rgx' => qr/(?-xism:\G(?:\.(?:[\ \t]|\r?\n|\#.*\r?\n)*|(?:[\ \t]|\r?\n|\#.*\r?\n)*\.))/
    },
    'code_expression' => {
      '.all' => [
        {
          '.ref' => 'code_object'
        },
        {
          '+min' => 0,
          '.ref' => 'unit_call'
        }
      ]
    },
    'code_object' => {
      '.any' => [
        {
          '.ref' => 'function_object'
        },
        {
          '.ref' => 'point_object'
        },
        {
          '.ref' => 'string_object'
        },
        {
          '.ref' => 'number_object'
        },
        {
          '.ref' => 'transform_object'
        }
      ]
    },
    'code_section' => {
      '+min' => 0,
      '.any' => [
        {
          '.rgx' => qr/(?-xism:\G(?:[\ \t]|\r?\n|\#.*\r?\n)+)/
        },
        {
          '.ref' => 'assignment_statement'
        },
        {
          '.ref' => 'code_statement'
        }
      ]
    },
    'code_statement' => {
      '.all' => [
        {
          '.ref' => 'code_expression'
        },
        {
          '+max' => 1,
          '.ref' => 'assertion_call'
        },
        {
          '.ref' => 'semicolon'
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
          '.ref' => 'block_header'
        },
        {
          '+min' => 0,
          '-skip' => 1,
          '.any' => [
            {
              '.ref' => 'blank_line'
            },
            {
              '.ref' => 'comment'
            }
          ]
        },
        {
          '+min' => 0,
          '.ref' => 'block_point'
        }
      ]
    },
    'data_section' => {
      '+min' => 0,
      '.ref' => 'data_block'
    },
    'double_quoted_string' => {
      '.rgx' => qr/(?-xism:\G(?:"((?:[^\n\\"]|\\"|\\\\|\\[0nt])*?)"))/
    },
    'function_object' => {
      '.all' => [
        {
          '+max' => 1,
          '.ref' => 'function_signature'
        },
        {
          '.ref' => 'function_start'
        },
        {
          '+min' => 0,
          '.any' => [
            {
              '.rgx' => qr/(?-xism:\G(?:[\ \t]|\r?\n|\#.*\r?\n)+)/
            },
            {
              '.ref' => 'assignment_statement'
            },
            {
              '.ref' => 'code_statement'
            }
          ]
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
          '+max' => 1,
          '.ref' => 'function_variables'
        },
        {
          '.rgx' => qr/(?-xism:\G(?:[\ \t]|\r?\n|\#.*\r?\n)*\))/
        }
      ]
    },
    'function_start' => {
      '.rgx' => qr/(?-xism:\G(?:[\ \t]|\r?\n|\#.*\r?\n)*(\{)(?:[\ \t]|\r?\n|\#.*\r?\n)*)/
    },
    'function_variable' => {
      '.rgx' => qr/(?-xism:\G([a-zA-Z]\w*))/
    },
    'function_variables' => {
      '+min' => 1,
      '.ref' => 'function_variable',
      '.sep' => {
        '.rgx' => qr/(?-xism:\G(?:[\ \t]|\r?\n|\#.*\r?\n)*,(?:[\ \t]|\r?\n|\#.*\r?\n)*)/
      }
    },
    'lines_point' => {
      '.all' => [
        {
          '.ref' => 'point_marker'
        },
        {
          '.rgx' => qr/(?-xism:\G[\ \t]+)/
        },
        {
          '.ref' => 'point_name'
        },
        {
          '.rgx' => qr/(?-xism:\G[\ \t]*\r?\n)/
        },
        {
          '.ref' => 'point_lines'
        }
      ]
    },
    'number' => {
      '.rgx' => qr/(?-xism:\G([0-9]+))/
    },
    'number_object' => {
      '.ref' => 'number'
    },
    'phrase_point' => {
      '.all' => [
        {
          '.ref' => 'point_marker'
        },
        {
          '.rgx' => qr/(?-xism:\G[\ \t]+)/
        },
        {
          '.ref' => 'point_name'
        },
        {
          '.rgx' => qr/(?-xism:\G:[\ \t])/
        },
        {
          '.ref' => 'point_phrase'
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
      '.rgx' => qr/(?-xism:\G((?:(?!===|\-\-\-).*\r?\n)*))/
    },
    'point_marker' => {
      '.rgx' => qr/(?-xism:\G\-\-\-)/
    },
    'point_name' => {
      '.rgx' => qr/(?-xism:\G([a-z]\w*|[A-Z]\w*))/
    },
    'point_object' => {
      '.rgx' => qr/(?-xism:\G(\*[a-z]\w*))/
    },
    'point_phrase' => {
      '.ref' => 'unquoted_string'
    },
    'quoted_string' => {
      '.any' => [
        {
          '.ref' => 'single_quoted_string'
        },
        {
          '.ref' => 'double_quoted_string'
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
      '.rgx' => qr/(?-xism:\G(?:'((?:[^\n\\']|\\'|\\\\)*?)'))/
    },
    'string_object' => {
      '.ref' => 'quoted_string'
    },
    'testml_document' => {
      '.all' => [
        {
          '.ref' => 'code_section'
        },
        {
          '+max' => 1,
          '.ref' => 'data_section'
        }
      ]
    },
    'transform_argument' => {
      '.ref' => 'code_expression'
    },
    'transform_argument_list' => {
      '.all' => [
        {
          '.rgx' => qr/(?-xism:\G\((?:[\ \t]|\r?\n|\#.*\r?\n)*)/
        },
        {
          '+min' => 0,
          '.ref' => 'transform_argument',
          '.sep' => {
            '.rgx' => qr/(?-xism:\G(?:[\ \t]|\r?\n|\#.*\r?\n)*,(?:[\ \t]|\r?\n|\#.*\r?\n)*)/
          }
        },
        {
          '.rgx' => qr/(?-xism:\G(?:[\ \t]|\r?\n|\#.*\r?\n)*\))/
        }
      ]
    },
    'transform_name' => {
      '.any' => [
        {
          '.ref' => 'user_transform'
        },
        {
          '.ref' => 'core_transform'
        }
      ]
    },
    'transform_object' => {
      '.all' => [
        {
          '.ref' => 'transform_name'
        },
        {
          '+max' => 1,
          '.ref' => 'transform_argument_list'
        }
      ]
    },
    'unit_call' => {
      '.all' => [
        {
          '+asr' => -1,
          '.ref' => 'assertion_call_test'
        },
        {
          '.ref' => 'call_indicator'
        },
        {
          '.ref' => 'code_object'
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
  }
}
