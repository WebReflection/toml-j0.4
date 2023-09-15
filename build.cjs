var fs = require('fs');
var PEG = require('pegjs');


var grammar = fs.readFileSync(__dirname + '/toml.pegjs', {
  encoding: 'utf8'
}).toString();
var source = PEG.generate(grammar, {
  output: 'source',
  optimize: 'speed'
});
source = `const { SyntaxError, parse } =\n${source};\nexport { SyntaxError, parse };\n`;
fs.writeFileSync(__dirname + '/lib/parser.js', source, {
  encoding: 'utf8'
});