export interface CppCodeAnnotation {
  lineNumber: number;
  text: string;
  tone: string;
}

export interface CppToken {
  id: string;
  text: string;
  kind: string;
  color: string;
}

export interface CppDisplayLine {
  lineNumber: number;
  tokens: CppToken[];
  annotationText: string;
  annotationColor: string;
}

interface TokenizeResult {
  tokens: CppToken[];
  inBlockComment: boolean;
}

function colorFor(kind: string): string {
  switch (kind) {
    case 'keyword':
      return '#C792EA';
    case 'type':
    case 'function':
      return '#82AAFF';
    case 'standard':
      return '#FFCB6B';
    case 'string':
    case 'header':
      return '#C3E88D';
    case 'number':
    case 'literal':
      return '#F78C6C';
    case 'comment':
      return '#7FAD7A';
    case 'preprocessor':
    case 'operator':
    case 'punctuation':
      return '#89DDFF';
    default:
      return '#D6DEEB';
  }
}

const KEYWORDS: string[] = [
  'alignas', 'alignof', 'asm', 'auto', 'break', 'case', 'catch', 'class',
  'const', 'constexpr', 'continue', 'default', 'delete', 'do', 'else',
  'enum', 'explicit', 'extern', 'for', 'friend', 'goto', 'if', 'inline',
  'mutable', 'namespace', 'new', 'noexcept', 'private', 'protected',
  'public', 'register', 'reinterpret_cast', 'return', 'sizeof', 'static',
  'static_cast', 'struct', 'switch', 'template', 'this', 'throw', 'try',
  'typedef', 'typename', 'union', 'using', 'virtual', 'volatile', 'while'
];

const TYPES: string[] = [
  'bool', 'char', 'char8_t', 'char16_t', 'char32_t', 'double', 'float',
  'int', 'long', 'short', 'signed', 'unsigned', 'void', 'wchar_t',
  'size_t', 'Node'
];

const STANDARD_NAMES: string[] = [
  'std', 'string', 'vector', 'unordered_set', 'unique_ptr', 'shared_ptr',
  'nullptr_t', 'cout', 'cin', 'cerr', 'endl'
];

const LITERALS: string[] = ['true', 'false', 'nullptr', 'NULL'];

function isLetter(ch: string): boolean {
  return (ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z') || ch === '_';
}

function isDigit(ch: string): boolean {
  return ch >= '0' && ch <= '9';
}

function isIdentifierPart(ch: string): boolean {
  return isLetter(ch) || isDigit(ch);
}

function pushToken(tokens: CppToken[], text: string, kind: string): void {
  if (text.length === 0) {
    return;
  }
  const last = tokens.length > 0 ? tokens[tokens.length - 1] : null;
  if (last !== null && last.kind === kind) {
    last.text += text;
    return;
  }
  const token: CppToken = {
    id: tokens.length.toString(),
    text: text,
    kind: kind,
    color: colorFor(kind)
  };
  tokens.push(token);
}

function nextNonSpace(line: string, start: number): string {
  let index = start;
  while (index < line.length && (line[index] === ' ' || line[index] === '\t')) {
    index++;
  }
  return index < line.length ? line[index] : '';
}

function classifyIdentifier(word: string, next: string): string {
  if (KEYWORDS.indexOf(word) >= 0) {
    return 'keyword';
  }
  if (TYPES.indexOf(word) >= 0) {
    return 'type';
  }
  if (STANDARD_NAMES.indexOf(word) >= 0) {
    return 'standard';
  }
  if (LITERALS.indexOf(word) >= 0) {
    return 'literal';
  }
  if (next === '(') {
    return 'function';
  }
  return 'plain';
}

function tokenizeLine(line: string, startsInBlockComment: boolean): TokenizeResult {
  const tokens: CppToken[] = [];
  let index = 0;
  let inBlockComment = startsInBlockComment;
  let firstToken = true;

  while (index < line.length) {
    if (inBlockComment) {
      const close = line.indexOf('*/', index);
      if (close < 0) {
        pushToken(tokens, line.slice(index), 'comment');
        index = line.length;
      } else {
        pushToken(tokens, line.slice(index, close + 2), 'comment');
        index = close + 2;
        inBlockComment = false;
      }
      firstToken = false;
      continue;
    }

    const ch = line[index];
    if (ch === ' ' || ch === '\t') {
      pushToken(tokens, ch, 'plain');
      index++;
      continue;
    }

    if (firstToken && ch === '#') {
      let end = index + 1;
      while (end < line.length && isLetter(line[end])) {
        end++;
      }
      pushToken(tokens, line.slice(index, end), 'preprocessor');
      index = end;
      firstToken = false;
      continue;
    }

    if (ch === '/' && index + 1 < line.length && line[index + 1] === '/') {
      pushToken(tokens, line.slice(index), 'comment');
      index = line.length;
      continue;
    }

    if (ch === '/' && index + 1 < line.length && line[index + 1] === '*') {
      const close = line.indexOf('*/', index + 2);
      if (close < 0) {
        pushToken(tokens, line.slice(index), 'comment');
        inBlockComment = true;
        index = line.length;
      } else {
        pushToken(tokens, line.slice(index, close + 2), 'comment');
        index = close + 2;
      }
      continue;
    }

    if (ch === '"' || ch === "'") {
      const quote = ch;
      let end = index + 1;
      while (end < line.length) {
        if (line[end] === '\\') {
          end += 2;
          continue;
        }
        if (line[end] === quote) {
          end++;
          break;
        }
        end++;
      }
      pushToken(tokens, line.slice(index, Math.min(end, line.length)), 'string');
      index = Math.min(end, line.length);
      firstToken = false;
      continue;
    }

    if (ch === '<') {
      const closeHeader = line.indexOf('>', index + 1);
      if (closeHeader > index + 1 && line.slice(0, index).indexOf('#include') >= 0) {
        pushToken(tokens, line.slice(index, closeHeader + 1), 'header');
        index = closeHeader + 1;
        firstToken = false;
        continue;
      }
    }

    if (isLetter(ch)) {
      let end = index + 1;
      while (end < line.length && isIdentifierPart(line[end])) {
        end++;
      }
      const word = line.slice(index, end);
      const next = nextNonSpace(line, end);
      pushToken(tokens, word, classifyIdentifier(word, next));
      index = end;
      firstToken = false;
      continue;
    }

    if (isDigit(ch)) {
      let end = index + 1;
      while (end < line.length &&
        (isIdentifierPart(line[end]) || line[end] === '.' || line[end] === "'")) {
        end++;
      }
      pushToken(tokens, line.slice(index, end), 'number');
      index = end;
      firstToken = false;
      continue;
    }

    const twoChar = index + 1 < line.length ? line.slice(index, index + 2) : '';
    const threeChar = index + 2 < line.length ? line.slice(index, index + 3) : '';
    const operators: string[] = [
      '->*', '<<=', '>>=', '...', '->', '::', '++', '--', '==', '!=',
      '<=', '>=', '&&', '||', '<<', '>>', '+=', '-=', '*=', '/=', '%=',
      '&=', '|=', '^', '.*'
    ];
    if (operators.indexOf(threeChar) >= 0) {
      pushToken(tokens, threeChar, 'operator');
      index += 3;
    } else if (operators.indexOf(twoChar) >= 0) {
      pushToken(tokens, twoChar, 'operator');
      index += 2;
    } else if ('+-*/%=!<>&|^~?:'.indexOf(ch) >= 0) {
      pushToken(tokens, ch, 'operator');
      index++;
    } else {
      pushToken(tokens, ch, 'punctuation');
      index++;
    }
    firstToken = false;
  }

  if (tokens.length === 0) {
    pushToken(tokens, ' ', 'plain');
  }
  const result: TokenizeResult = {
    tokens: tokens,
    inBlockComment: inBlockComment
  };
  return result;
}

function annotationColor(tone: string): string {
  if (tone === 'pointer') {
    return '#80CBC4';
  }
  if (tone === 'memory') {
    return '#FFCB6B';
  }
  if (tone === 'safety') {
    return '#F78C6C';
  }
  if (tone === 'output') {
    return '#C3E88D';
  }
  if (tone === 'control') {
    return '#C792EA';
  }
  if (tone === 'library') {
    return '#89DDFF';
  }
  return '#82AAFF';
}

export function highlightCpp(
  source: string,
  annotations: CppCodeAnnotation[]
): CppDisplayLine[] {
  const sourceLines = source.split('\n');
  const result: CppDisplayLine[] = [];
  let inBlockComment = false;

  for (let i = 0; i < sourceLines.length; i++) {
    const parsed = tokenizeLine(sourceLines[i], inBlockComment);
    inBlockComment = parsed.inBlockComment;
    let noteText = '';
    let noteColor = '#82AAFF';

    for (let j = 0; j < annotations.length; j++) {
      if (annotations[j].lineNumber === i + 1) {
        noteText = annotations[j].text;
        noteColor = annotationColor(annotations[j].tone);
        break;
      }
    }

    const displayLine: CppDisplayLine = {
      lineNumber: i + 1,
      tokens: parsed.tokens,
      annotationText: noteText,
      annotationColor: noteColor
    };
    result.push(displayLine);
  }
  return result;
}
