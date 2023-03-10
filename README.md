# TOML-j0.4

[![Build Status](https://github.com/jakwings/toml-j0.4/actions/workflows/test.yml/badge.svg)](https://github.com/jakwings/toml-j0.4/actions/workflows/test.yml)
[![NPM version](https://badge.fury.io/js/toml-j0.4.svg)](http://badge.fury.io/js/toml-j0.4)

As its name *TOML-j0.4* says, this is a [TOML] v[0.4.0] compliant parser built with [PEG.js]. You can customize it easily by modifying the grammar file `toml.pegjs`.

[TOML]: https://github.com/toml-lang/toml
[0.4.0]: https://toml.io/en/v0.4.0 (https://github.com/toml-lang/toml/blob/cea4a77e97e9292aeb612af70b1be4f36cea4357/versions/en/toml-v0.4.0.md)
[PEG.js]: http://pegjs.org


### Live Demo

<http://jakwings.github.io/toml-j0.4/>


### Usage

You can install it via `npm install toml-j0.4`, or just include the script `dist/toml-browser.js` in your web pages.

```javascript
var toml = toml || require('toml-j0.4');

try {
    var data = toml.parse(src);
} catch (err) {
    if (err instanceof toml.SyntaxError) {
        // do something
    }
}
```

*   `toml.parse` only accept one argument — data text in TOML
*   The instance of `toml.SyntaxError` has these properties:
    * `line`: the line number
    * `column`: the column number
    * `offset`: the zero-based offset from the start of the text
    * `message`: error message

There is no other API for now.


### Known Problems

*   This parser does not support big integer, until a major version change happens.

    All numbers are floats. Any integer bigger than `Number.MAX_SAFE_INTEGER` (9007199254740991 < 2^63 - 1) or smaller than `Number.MIN_SAFE_INTEGER` (-9007199254740991 > -(2^63 - 1)) is not safe when being converted or used as pure integer!

    But you can still store big integers as strings.

*   RFC 3339 is not the sole criterion of truth.

    You can't imagine how terrible all minitue details of the standard are! So
    don't expect some date-times will work anytime and anywhere, for instance,
    "2015-02-29T00:00:00Z", "2015-12-25T24:00:00Z", "2015-11-10T00:60:00Z",
    "2015-11-10T00:00:60Z", "2015-12-25T24:00:00+24:00",
    "0000-01-01T00:00:00Z".


### Contribute

If you found bugs, welcome to send me a pull request with (only) updated test scripts/fixtures!

In order to test this package thoroughly, you have to do these first:

1.  Clone this project with git.
2.  Excute this command in the project directory: `npm install`

The scripts `lib/parser.js` and `dist/toml-browser.js` are generated via this command:

```bash
npm run build
```

Then you can test them via this command:

```bash
npm test
```

You can also do some benchmarks with other TOML parsers:

```bash
npm run benchmark
```


### Others

This package is also used by other projects:

*   [tomlify-j0.4](https://github.com/jakwings/tomlify-j0.4)
*   [meta-matter](https://github.com/jakwings/meta-matter)
