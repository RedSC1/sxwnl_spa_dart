#!/usr/bin/env node

// Verify generated ephB fixed-star tables against the original source.
// This intentionally evaluates both sides and compares every item, so a
// generated file cannot silently drift from sxwnl when the source is updated.

import fs from 'node:fs';
import vm from 'node:vm';

const sourcePath = process.argv[2] ?? '../sxwnl/src/ephB.js';
const dartPath = process.argv[3] ?? 'lib/src/sxwnl/ephb_star_data.dart';
const source = fs.readFileSync(sourcePath, 'utf8');
const dart = fs.readFileSync(dartPath, 'utf8');

function sourceSlice(startMarker, endMarker) {
  const start = source.indexOf(startMarker);
  const end = source.indexOf(endMarker, start);
  if (start < 0 || end < 0) throw new Error(`Missing ${startMarker}`);
  return source.slice(start, end);
}

const sourceContext = {Math};
vm.runInNewContext(
  `${sourceSlice('var evTab =', 'function evSSB')}\n` +
    `${sourceSlice('var epTab =', 'function epSSB')}\n` +
    `${sourceSlice('var xz88=', 'function schHXK')}\n` +
    'globalThis.tables = {evTab, epTab, xz88, HXK};',
  sourceContext,
  {filename: sourcePath},
);

function dartExpression(name) {
  const declaration = dart.indexOf(` ${name} =`);
  if (declaration < 0) throw new Error(`Missing Dart table ${name}`);
  const open = dart.indexOf('[', declaration);
  let depth = 0;
  let quote = false;
  let escaped = false;
  for (let i = open; i < dart.length; i++) {
    const c = dart[i];
    if (quote) {
      if (escaped) escaped = false;
      else if (c === '\\') escaped = true;
      else if (c === '"') quote = false;
      continue;
    }
    if (c === '"') {
      quote = true;
      continue;
    }
    if (c === '[') depth++;
    if (c === ']') {
      depth--;
      if (depth === 0) return dart.slice(open, i + 1);
    }
  }
  throw new Error(`Unterminated Dart table ${name}`);
}

function parseDart(name) {
  return vm.runInNewContext(`(${dartExpression(name)})`, {}, {filename: dartPath});
}

function compare(path, expected, actual) {
  if (Array.isArray(expected) !== Array.isArray(actual)) {
    return `${path}: array shape differs`;
  }
  if (Array.isArray(expected)) {
    if (expected.length !== actual.length) {
      return `${path}: length ${expected.length} != ${actual.length}`;
    }
    for (let i = 0; i < expected.length; i++) {
      const difference = compare(`${path}[${i}]`, expected[i], actual[i]);
      if (difference) return difference;
    }
    return null;
  }
  return Object.is(expected, actual) ? null : `${path}: ${expected} != ${actual}`;
}

for (const name of ['evTab', 'epTab', 'xz88', 'HXK']) {
  const difference = compare(name, sourceContext.tables[name], parseDart(name));
  if (difference) throw new Error(difference);
  console.log(`${name}: exact generated-table match`);
}
