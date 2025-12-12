// ReScript language definition for Prism.js
// Based on the ReScript language syntax

export function addReScriptLanguage(Prism) {
  Prism.languages.rescript = {
    'comment': [
      {
        pattern: /\/\/.*/,
        greedy: true
      },
      {
        pattern: /\/\*[\s\S]*?\*\//,
        greedy: true
      }
    ],
    'string': {
      pattern: /"(?:\\.|[^\\"\r\n])*"|`(?:\\.|[^\\`])*`/,
      greedy: true
    },
    'char': {
      pattern: /'(?:\\.|[^\\'\r\n])'/,
      greedy: true
    },
    'keyword': /\b(?:and|as|assert|async|await|begin|class|constraint|do|done|downto|else|end|exception|external|false|for|fun|function|functor|if|in|include|inherit|initializer|lazy|let|method|module|mutable|new|nonrec|object|of|open|or|private|rec|sig|struct|switch|then|to|true|try|type|val|virtual|when|while|with)\b/,
    'builtin': /\b(?:option|Some|None|list|array|int|string|bool|float|unit|exn|ref)\b/,
    'boolean': /\b(?:true|false)\b/,
    'number': /\b0x[\da-f]+\b|(?:\b\d+(?:\.\d*)?|\B\.\d+)(?:e[+-]?\d+)?/i,
    'operator': /->|=>|==|!=|<=|>=|<|>|\+\.|\+|\-\.|\-|\*\.|\*|\/\.|\/|\|>|@@|@|\|\||&&|!|::|:=/,
    'punctuation': /[{}[\];(),.:]/,
    'type-variable': /'[a-z]\w*/,
    'module': {
      pattern: /\b[A-Z]\w*(?:\.[A-Z]\w*)*/,
      alias: 'class-name'
    },
    'attribute': /@[\w.]+/,
    'label': /~\w+/
  };

  // Add javascript/jsx support for raw blocks
  Prism.languages.rescript.raw = {
    pattern: /%raw\(.*?\)/,
    inside: {
      'string': /"(?:\\.|[^\\"\r\n])*"|`(?:\\.|[^\\`])*`/,
      'keyword': /%raw/
    }
  };
}
