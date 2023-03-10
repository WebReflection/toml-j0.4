{
  var genMsgRedefined, isFiniteNumber, isArray, hasOwnProperty, stringify,
      unescape, fromCodePoint, checkTableKey, findContext;

  genMsgRedefined = function (key) {
    return ('Value for ' + key + ' should not be redefined in the same table.');
  };

  isFiniteNumber = Number.isFinite || function (n) {
    return typeof n === 'number' && isFinite(n);
  };

  isArray = Array.isArray || function (obj) {
    return Object.prototype.toString.call(obj) === '[object Array]';
  };

  hasOwnProperty = function (obj, key) {
    return Object.prototype.hasOwnProperty.call(obj, key);
  };

  stringify = typeof JSON === 'object' && JSON ? JSON.stringify : function (o) {
    return '"' + String(o).replace(/[\x00-\x1F"\\]/g, function (c) {
      switch (c) {
        case '"': case '\\': return '\\' + c;
        case '\t': return '\\t';
        case '\n': return '\\n';
        case '\r': return '\\r';
        case '\b': return '\\b';
        case '\f': return '\\f';
        default:
          var hex = c.charCodeAt(0).toString(16);
          return '\\u' + '0000'.substr(hex.length) + hex;
      }
    }) + '"';
  };

  unescape = function (c) {
    switch (c) {
      case '"': case '\\': return c;
      case 't': return '\t';
      case 'n': return '\n';
      case 'r': return '\r';
      case 'b': return '\b';
      case 'f': return '\f';
      default: error(stringify(c) + ' cannot be escaped.');
    }
  };

  fromCodePoint = function (codepoint) {
    if (!isFiniteNumber(codepoint) || codepoint < 0 || codepoint > 0x10FFFF) {
      error('U+' + codepoint.toString(16) +
          ' is not a valid Unicode code point.');
    }
    if (String.fromCodePoint) {
      return String.fromCodePoint(codepoint);
    }
    // See: punnycode.ucs2.encode from https://github.com/bestiejs/punycode.js
    var c = '';
    if (codepoint > 0xFFFF) {
      codepoint -= 0x10000;
      c += String.fromCharCode((codepoint >>> 10) & 0x3FF | 0xD800);
      codepoint = 0xDC00 | codepoint & 0x3FF;
    }
    c += String.fromCharCode(codepoint);
    return c;
  };

  checkTableKey = function (table, k) {
    if (hasOwnProperty(table, k)) {
      error(genMsgRedefined(stringify(k)));
    }
  };

  findContext = function (table, isTableArray, path) {
    var s = '';
    for (var i = 0, l = path.length; i < l; i++) {
      var k = path[i];
      s += (s ? '.' : '') + stringify(k);
      if (!hasOwnProperty(table, k)) {
        if (isTableArray && i + 1 === l) {
          var t = {};
          table[k] = [t];
          table = t;
          g_table_arrays[s] = true;
        } else {
          table = table[k] = {};
          g_tables[s] = true;
        }
      } else {
        if (isTableArray) {
          if (isArray(table[k])) {
            if (!g_table_arrays[s]) {
              error(genMsgRedefined(s));
            }
            if (i + 1 === l) {
              var t = {};
              table[k].push(t);
              table = t;
            } else {
              s += '.' + stringify(table[k].length - 1);
              table = table[k][table[k].length-1];
            }
          } else {
            if (!g_tables[s]) {
              error(genMsgRedefined(s));
            }
            table = table[k];
          }
        } else {
          if (isArray(table[k])) {
            if (!g_table_arrays[s] || i + 1 === l) {
              error(genMsgRedefined(s));
            }
            s += '.' + stringify(table[k].length - 1);
            table = table[k][table[k].length-1];
          } else {
            if (!g_tables[s]) {
              error(genMsgRedefined(s));
            }
            table = table[k];
          }
        }
      }
    }
    if (isTableArray) {
      if (!g_table_arrays[s]) {
        error(genMsgRedefined(s));
      }
    } else {
      if (g_defined_tables[s] || g_table_arrays[s]) {
        error(genMsgRedefined(s));
      }
      g_defined_tables[s] = true;
    }
    return {
      table: table,
      path: path
    };
  };

  var g_root = {};             // TOML table
  var g_context = {            // current context
    table: g_root,
    path: []
  };
  var g_tables = {};           // paths to tables
  var g_defined_tables = {};   // paths to tables directly defined
  var g_table_arrays = {};     // paths to table arrays
}


Expressions
    = ( Whitespace / Newline / Comment )*
      ( Expression
        ( Whitespace / Comment )*
        ( Newline Expressions )? )?
      {
        return g_root;
      }

Expression
    = path:TableArrayHeader
      {
        g_context = findContext(g_root, true, path);
      }
    / path:TableHeader
      {
        g_context = findContext(g_root, false, path);
      }
    / keyValue:KeyValue
      {
        checkTableKey(g_context.table, keyValue[0]);
        g_context.table[keyValue[0]] = keyValue[1];
      }

Newline                                         "Newline"
    = "\n"
    / "\r\n"

Whitespace                                      "Whitespace"
    = [ \t]

Comment                                         "Comment"
    = "#" ( !Newline . )*

KeyValue
    = key:Key Whitespace* "=" Whitespace* value:Value
      {
        return [key, value.value];
      }

Key
    = BareKey
    / QuotedKey

BareKey
    = BareKeyCharacter+
      {
        return text();
      }

BareKeyCharacter                                '[a-z], [A-Z], [0-9], "-", "_"'
    = [a-zA-Z0-9\-_]

QuotedKey
    = DoubleQuote chars:BasicCharacter+ DoubleQuote
      {
        return chars.join('');
      }

DoubleQuote                                     "DoubleQuote"
    = '"'

SingleQuote                                     "SingleQuote"
    = "'"

ThreeDoubleQuotes                               "ThreeDoubleQuotes"
    = '"""'

ThreeSingleQuotes                               "ThreeSingleQuotes"
    = "'''"

Value
    = String
    / Boolean
    / DateTime
    / Float
    / Integer
    / Array
    / InlineTable

String
    = MultilineBasicString
    / BasicString
    / MultilineLiteralString
    / LiteralString

BasicString
    = DoubleQuote chars:BasicCharacter* DoubleQuote
      {
        return {
          type: 'String',
          value: chars.join('')
        };
      }

BasicCharacter
    = NormalCharacter
    / EscapedCharacter

NormalCharacter                                 "NormalCharacter"
    = !Newline [^\x00-\x1F"\\]
      {
        return text();
      }

EscapedCharacter
    = Backslash ( ControlCharacter
                / DoubleQuote
                / Backslash
                / "u" FourHexadecimalDigits
                / "U" EightHexadecimalDigits )
      {
        var s = text();
        if (s.length <= 2) {
          return unescape(s[1]);
        }
        return fromCodePoint(parseInt(s.substr(2), 16));
      }

ControlCharacter                                '"b", "f", "n", "r", "t"'
    = [bfnrt]

Backslash                                       "Backslash"
    = "\\"

FourHexadecimalDigits                           "FourHexadecimalDigits"
    = HexDigit HexDigit HexDigit HexDigit

EightHexadecimalDigits                          "EightHexadecimalDigits"
    = HexDigit HexDigit HexDigit HexDigit
      HexDigit HexDigit HexDigit HexDigit

HexDigit
    = [0-9A-Fa-f]

LiteralString
    = SingleQuote LiteralCharacter* SingleQuote
      {
        var s = text();
        return {
          type: 'String',
          value: s.substr(1, s.length - 2)
        };
      }

LiteralCharacter                                "NormalCharacter"
    = !Newline [^\x00-\x08\x0A-\x1F']

MultilineBasicString
    = ThreeDoubleQuotes Newline? chars:MultilineBasicText* ThreeDoubleQuotes
      {
        return {
          type: 'String',
          value: chars.join('')
        };
      }

MultilineBasicText
    = MultilineBasicCharacter
    / Backslash Newline ( Whitespace / Newline )* { return ''; }
    / Newline

MultilineBasicCharacter
    = !ThreeDoubleQuotes MultilineNormalCharacter
      {
        return text();
      }
    / EscapedCharacter

MultilineNormalCharacter                        "NormalCharacter"
    = !Newline [^\x00-\x1F\\]

MultilineLiteralString
    = ThreeSingleQuotes Newline? chars:MultilineLiteralText* ThreeSingleQuotes
      {
        return {
          type: 'String',
          value: chars.join('')
        };
      }

MultilineLiteralText
    = !"'''" MultilineLiteralCharacter
      {
        return text();
      }
    / Newline

MultilineLiteralCharacter                       "AnyCharacter"
    = !Newline [^\x00-\x08\x0A-\x1F]

Boolean
    = "true"
      {
        return {
          type: 'Boolean',
          value: true
        };
      }
    / "false"
      {
        return {
          type: 'Boolean',
          value: false
        };
      }

Float
    = Integer ( Fraction Exponent? / Exponent )
      {
        // A double-precision 64-bit floating-point number in IEEE 754 standard.
        var s = text();
        var number = parseFloat(s.replace(/_/g, ''));
        if (!isFiniteNumber(number)) {
          error(s + 'is not a 64-bit floating-point number.');
        }
        return {
          type: 'Float',
          value: number
        };
      }

Fraction
    = "." Digit ( "_"? Digit )*

Exponent
    = ( "e" / "E" ) Integer

Integer
    = Sign? IntDigits
      {
        // Be careful of JavaScript limits:
        // 1) Number.MAX_SAFE_INTEGER = 9007199254740991
        // 2) Number.MIN_SAFE_INTEGER = -9007199254740991
        var s = text();
        var number = s.replace(/_/g, '');
        // Check if it is a 64-bit signed integer.
        var invalid = false;
        if (number[0] === '-') {
          var minInt = '-9223372036854775808';
          if (number.length > minInt.length ||
              (number.length === minInt.length && number > minInt)) {
            invalid = true;
          }
        } else {
          if (number[0] === '+') {
            number = number.substr(1);
          }
          var maxInt = '9223372036854775807';
          if (number.length > maxInt.length ||
              (number.length === maxInt.length && number > maxInt)) {
            invalid = true;
          }
        }
        if (invalid) {
          error(s + ' is not a 64-bit signed integer.');
        }
        number = parseInt(number, 10);
        if (!isFiniteNumber(number)) {
          error(s + ' is not a 64-bit signed integer.');
        }
        return {
          type: 'Integer',
          value: number
        };
      }

Sign
    = "+"
    / "-"

IntDigits
    = Digit_1to9 ( "_"? Digit )+
    / Digit

Digit_1to9
    = [1-9]

Digit
    = [0-9]

DateTime
    = FullDate "T" FullTime
      {
        var s = text();
        var date = new Date(s);
        if (!isFiniteNumber(date.getTime())) {
          error('Date-time ' + s + ' is invalid. It does not conform to RFC 3339 or this is a browser-specific problem.');
        }
        return {
          type: 'DateTime',
          value: date
        };
      }

FullDate                                        "FullDate (YYYY-mm-dd)"
    = Year "-" Month "-" MDay

Year
    = Digit Digit Digit Digit

Month
    = Digit Digit

MDay
    = Digit Digit

FullTime
    = Time TimeOffset

Time
    = Hour ":" Minute ":" Second SecondFraction?

Hour                                            "Hour (HH)"
    = Digit Digit

Minute                                          "Minute (MM)"
    = Digit Digit

Second                                          "Second (SS)"
    = Digit Digit

SecondFraction
    = "." Digit+

TimeOffset                                      "TimeOffset (Z or +/-HH:MM)"
    = "Z"
    / Sign Hour ":" Minute

Array
    = "[" ArraySpace*
          values:( ArrayValue
                   ArraySpace*
                   ( "," ArraySpace* )? )? "]"
      {
        var o = {
          type: 'Array',
          value: values ? values[0] : []
        };
        for (var i = 0, arr = o.value, l = arr.length; i < l; i++) {
          arr[i] = arr[i].value;
        }
        return o;
      }

ArrayValue
    = value:Value opt:( ArraySpace* "," ArraySpace* ArrayValue )?
      {
        var array = [value];
        if (opt) {
          var type = value.type;
          for (var i = 0, arr = opt[3], l = arr.length; i < l; i++) {
            if (type !== arr[i].type) {
              error(stringify(arr[i].value) + ' should be of type "' + type +
                  '".');
            }
            array.push(arr[i]);
          }
        }
        return array;
      }

ArraySpace
    = Whitespace
    / Newline
    / Comment

InlineTable
    = "{" Whitespace*
          opt:( KeyValue
                ( Whitespace* "," Whitespace* KeyValue )*
                Whitespace* )? "}"
      {
        var table = {};
        if (opt) {
          table[opt[0][0]] = opt[0][1];
          for (var i = 0, arr = opt[1], l = arr.length; i < l; i++) {
            var kv = arr[i][3];
            checkTableKey(table, kv[0]);
            table[kv[0]] = kv[1];
          }
        }
        return {
          type: 'InlineTable',
          value: table
        };
      }

TableArrayHeader
    = "[" path:TableHeader "]"
      {
        return path;
      }

TableHeader
    = "[" Whitespace*
          key:Key
          arr:( Whitespace* "." Whitespace* Key )*
          Whitespace* "]"
      {
        var path = [key];
        for (var i = 0, l = arr.length; i < l; i++) {
          path.push(arr[i][3]);
        }
        return path;
      }
