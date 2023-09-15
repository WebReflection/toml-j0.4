'use strict';
/*! (c) Jak Wings - MIT */

const { SyntaxError: _SyntaxError, parse: _parse } = require('./parser.js');

class TomlSyntaxError extends SyntaxError {
  constructor(message, { offset, line, column }) {
    super(message);
    this.offset = offset;
    this.line = line;
    this.column = column;
  }
}

const parse = src => {
  try {
    return _parse(src);
  } catch (err) {
    if (err instanceof _SyntaxError) {
      err.line = err.location.start.line;
      err.column = err.location.start.column;
      err.offset = err.location.start.offset;
      throw new TomlSyntaxError(err.message, err.location.start);
    } else {
      throw err;
    }
  }
};
exports.parse = parse;

exports.SyntaxError = TomlSyntaxError;
