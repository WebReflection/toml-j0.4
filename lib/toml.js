/*! (c) Jak Wings - MIT */

import { SyntaxError as _SyntaxError, parse as _parse } from './parser.js';

class TomlSyntaxError extends SyntaxError {
  constructor(message, { offset, line, column }) {
    super(message);
    this.offset = offset;
    this.line = line;
    this.column = column;
  }
}

export const parse = src => {
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

export { TomlSyntaxError as SyntaxError };
