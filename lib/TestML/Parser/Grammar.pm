package TestML::Parser::Grammar;
use lib '../parse-pegex-pm/lib';
use base 'Parse::Pegex';
use strict;
use warnings;

sub grammar_text {
    open my $fh, "../testml-grammar/testml.grammar"
      or die;
    return do { local $/; <$fh> };
}

1;

__END__

sub grammar_text {
    return q%
# XXX Move these and others to pegex

# Pegex Atoms
ALWAYS: //      # Always match
ALL: /[\s\S]/   # Any unicode character
ANY: /./        # Any character except newline
SPACE: /[\ \t]/ # A space or tab character
SPACES: /\ \t/  #   For use in character classes
BREAK: /\n/     # A newline character
EOL: /\r?\n/    # A Unix or DOS line ending
LOWER: /[a-z]/  # Lower case ASCII alphabetic character
UPPER: /[A-Z]/  # Upper case ASCII alphabetic character
WORD: /\w/      # ie /[A-Za-z0-9_]/ - A "word" character
DIGIT: /[0-9]/  # A numeric digit
EQUAL: /=/      # An equals sign
TILDE: /~/      # A tilde character
STAR: /\*/      # An asterisk character
DASH: /-/       # A dash character
DOT: /\./       # A period character
COMMA: /,/      # A comma character
COLON: /:/      # A colon character
SEMI: /;/       # A semicolon character
HASH: /#/       # An octothorpe/pound/splat/hash character
BACK: /\\/      # A backslash character
SINGLE: /'/     # A single quote character
DOUBLE: /"/     # A double quote character
LPAREN: /\(/    # A left parenthesis
RPAREN: /\)/    # A right parenthesis
LSQUARE: /\[/   # A left square bracket
LANGLE: /</     # A left angle bracket


# General Tokens
escape: /[0nt]/
line: /<ANY>*<EOL>/
blank_line: /<SPACE>*<EOL>/
comment: /<HASH><line>/
ws: /(?:<SPACE>|<EOL>|<comment>)/

quoted_string: ( <single_quoted_string> | <double_quoted_string> )

single_quoted_string: /(?:<SINGLE>(([^<BREAK><BACK><SINGLE>]|<BACK><SINGLE>|<BACK><BACK>)*?)<SINGLE>)/

double_quoted_string: /(?:<DOUBLE>(([^<BREAK><BACK><DOUBLE>]|<BACK><DOUBLE>|<BACK><BACK>|<BACK><escape>)*?)<DOUBLE>)/

unquoted_string: /([^<SPACES><BREAK><HASH>](?:[^<BREAK><HASH>]*[^<SPACES><BREAK><HASH>])?)/


# TestML Document
document:
- <meta_section>
- <test_section>
- <data_section>?


# TestML Meta Section
meta_section:
- /(?:<comment>|<blank_line>)*/
- ( <meta_testml_statement> | <NO_META_TESTML_ERROR> )
- ( <meta_statement> | <comment> | <blank_line> )*

meta_testml_statement: /<PERCENT>TestML:<SPACE>+(<testml_version>)(?:<SPACE>+<comment>|<EOL>)/

testml_version: /(<DIGIT><DOT><DIGIT>+)/

meta_statement: <PERCENT>(<meta_keyword>):<SPACE>+(<meta_value>)(?:<SPACE>+<comment>|<EOL>)/

meta_keyword: /(?:<core_meta_keyword>|<user_meta_keyword>)/
core_meta_keyword: /(?:Title|Data|Plan|BlockMarker|PointMarker)/
user_meta_keyword: /<LOWER><WORD>*/

meta_value: /(?:<single_quoted_string>|<double_quoted_string>|<unquoted_string>)/


# TestML Meta Section
test_section: ( <ws> | <test_statement> )*

test_statement:
- <test_expression>
- <assertion_call>?
- ( <SEMI> | <SEMICOLON_ERROR> )

test_expression:
- <sub_expression>
- (
    <!assertion_call_test>
    <call_indicator>
    <sub_expression>
  )*

sub_expression: (
    <point_call> |
    <string_call> |
    <transform_call>
  )

point_call: /(<STAR><LOWER><WORD>*)/

string_call: <quoted_string>

transform_call:
- <transform_name>
- <transform_argument_list>?

transform_name: ( <user_transform> | <core_transform> )

user_transform: /(<LOWER><WORD>*)/

core_transform: /(<UPPER><WORD>*)/

call_indicator: /(?:<DOT><ws>*|<ws>*<DOT>)/

transform_argument_list:
- /<LPAREN><ws>*/
- <transform_arguments>?
- /<ws>*<RPAREN>/

transform_arguments:
- <transform_argument>
- ( /<ws>*<COMMA><ws>*/ <transform_argument> )*

transform_argument: <sub_expression>

assertion_call_test: /<call_indicator>(?:EQ|OK|HAS)<LPAREN>/

assertion_call: (
    <assertion_eq> |
    <assertion_ok> |
    <assertion_has>
  )

assertion_eq: (
    <assertion_operator_eq> |
    <assertion_function_eq>
  )

assertion_operator_eq:
- /<ws>+<EQUAL><EQUAL><ws>+/
- <test_expression>

assertion_function_eq:
- /<call_indicator>EQ<LPAREN>/
- <test_expression>
- /<RPAREN>/

assertion_ok: <assertion_function_ok>

assertion_function_ok: /<call_indicator>OK<empty_parens>?/

assertion_has: (
    <assertion_operator_has> |
    <assertion_function_has>
  )

assertion_operator_has:
- /<ws>+<TILDE><TILDE><ws>+/
- <test_expression>

assertion_function_has:
- /<call_indicator>HAS<LPAREN>/
- <test_expression>
- /<RPAREN>/

empty_parens: /(?:<LPAREN><ws>*<RPAREN>)/

# TestML Data Section
data_section: (
    <testml_data_section> |
    <yaml_data_section> |
    <json_data_section> |
    <xml_data_section>
  )

testml_data_section: <data_block>*

yaml_data_section: /(<DASH><DASH><DASH><SPACE>*<EOL><rest>)/

json_data_section: /(<LSQUARE><rest>)/

xml_data_section: /(<LANGLE><rest>)/

rest: /<ANY>+/

data_block:
- <block_header>
- ( <blank_line> | <comment> )*
- <block_point>*

block_header:
- <block_marker>
- ( /<SPACE>+/ <block_label> )?
- /<SPACE>*<EOL>/

block_marker: /<EQUAL><EQUAL><EQUAL>/

block_label: <unquoted_string>

block_point: ( <lines_point> | <phrase_point> )

lines_point:
- <point_marker>
- /<SPACE>+/
- <point_name>
- /<SPACE>*<EOL>/
- <point_lines>

point_lines: /((?:(?!<block_marker>|<point_marker>)<line>)*)/

phrase_point:
- <point_marker>
- /<SPACE>+/
- <point_name>
- /<COLON><SPACE>/
- <point_phrase>
- /<EOL>/
- /(?:<comment>|<blank_line>)*/

point_marker: /<DASH><DASH><DASH>/

point_name: /(<LOWER><WORD>*)/

point_phrase: /(<unquoted_string>)/

# Errors
NO_META_TESTML_ERROR: <ALWAYS>
SEMICOLON_ERROR: <ALWAYS>
%;
}

1;

__END__

our $grammar = +{
  'ALWAYS' => {
    '+re' => qr/(?-xism:\G)/
  },
  'NO_META_TESTML_ERROR' => {
    '+rule' => 'ALWAYS'
  },
  'SEMI' => {
    '+re' => qr/(?-xism:\G;)/
  },
  'SEMICOLON_ERROR' => {
    '+rule' => 'ALWAYS'
  },
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
    '+re' => qr/(?-xism:\G(?:\.(?:[\ \t]|\r?\n|#.*\r?\n)*|(?:[\ \t]|\r?\n|#.*\r?\n)*\.)(?:EQ|OK|HAS)\()/
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
        '+re' => qr/(?-xism:\G(?:\.(?:[\ \t]|\r?\n|#.*\r?\n)*|(?:[\ \t]|\r?\n|#.*\r?\n)*\.)EQ\()/
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
        '+re' => qr/(?-xism:\G(?:\.(?:[\ \t]|\r?\n|#.*\r?\n)*|(?:[\ \t]|\r?\n|#.*\r?\n)*\.)HAS\()/
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
    '+re' => qr/(?-xism:\G(?:\.(?:[\ \t]|\r?\n|#.*\r?\n)*|(?:[\ \t]|\r?\n|#.*\r?\n)*\.)OK(?:\((?:[\ \t]|\r?\n|#.*\r?\n)*\))?)/
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
        '+re' => qr/(?-xism:\G(?:[\ \t]|\r?\n|#.*\r?\n)+==(?:[\ \t]|\r?\n|#.*\r?\n)+)/
      },
      {
        '+rule' => 'test_expression'
      }
    ]
  },
  'assertion_operator_has' => {
    '+all' => [
      {
        '+re' => qr/(?-xism:\G(?:[\ \t]|\r?\n|#.*\r?\n)+~~(?:[\ \t]|\r?\n|#.*\r?\n)+)/
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
    '+re' => qr/(?-xism:\G(?:\.(?:[\ \t]|\r?\n|#.*\r?\n)*|(?:[\ \t]|\r?\n|#.*\r?\n)*\.))/
  },
  'comment' => {
    '+re' => qr/(?-xism:\G#.*\r?\n)/
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
        '+re' => qr/(?-xism:\G(?:#.*\r?\n|[\ \t]*\r?\n)*)/
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
    '+re' => qr/(?-xism:\G<PERCENT>((?:(?:Title|Data|Plan|BlockMarker|PointMarker)|[a-z]\w*)):[\ \t]+((?:(?:'(([^\n\\']|\\'|\\\\)*?)')|(?:"(([^\n\\"]|\\"|\\\\|\\[0nt])*?)")|([^\ \t\n#](?:[^\n#]*[^\ \t\n#])?)))(?:[\ \t]+#.*\r?\n|\r?\n))/
  },
  'meta_testml_statement' => {
    '+re' => qr/(?-xism:\G<PERCENT>TestML:[\ \t]+(([0-9]\.[0-9]+))(?:[\ \t]+#.*\r?\n|\r?\n))/
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
        '+re' => qr/(?-xism:\G(?:#.*\r?\n|[\ \t]*\r?\n)*)/
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
    '+re' => qr/(?-xism:\G(([^\ \t\n#](?:[^\n#]*[^\ \t\n#])?)))/
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
            '+rule' => 'SEMI'
          },
          {
            '+rule' => 'SEMICOLON_ERROR'
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
        '+re' => qr/(?-xism:\G\((?:[\ \t]|\r?\n|#.*\r?\n)*)/
      },
      {
        '+rule' => 'transform_arguments',
        '<' => '?'
      },
      {
        '+re' => qr/(?-xism:\G(?:[\ \t]|\r?\n|#.*\r?\n)*\))/
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
            '+re' => qr/(?-xism:\G(?:[\ \t]|\r?\n|#.*\r?\n)*,(?:[\ \t]|\r?\n|#.*\r?\n)*)/
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
    '+re' => qr/(?-xism:\G([^\ \t\n#](?:[^\n#]*[^\ \t\n#])?))/
  },
  'user_transform' => {
    '+re' => qr/(?-xism:\G([a-z]\w*))/
  },
  'ws' => {
    '+re' => qr/(?-xism:\G(?:[\ \t]|\r?\n|#.*\r?\n))/
  },
  'xml_data_section' => {
    '+re' => qr/(?-xism:\G(<.+))/
  },
  'yaml_data_section' => {
    '+re' => qr/(?-xism:\G(---[\ \t]*\r?\n.+))/
  }
};

sub grammar {
    return $grammar;
}

1;
