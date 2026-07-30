#!/usr/bin/env node

// Mechanical coefficient-table audit for the sxwnl port. It evaluates the
// original JS data and the numeric Dart list literals, then compares every
// nested element exactly. No astronomical calculation is involved here: this
// is specifically intended to catch a dropped, reordered, or mistyped term.

import fs from 'node:fs';
import vm from 'node:vm';

const jsPath = process.argv[2] ?? '../sxwnl/src/eph0.js';
const dartPath = process.argv[3] ?? 'lib/src/sxwnl/xl_data.dart';
const jsContext = {Math};
vm.runInNewContext(fs.readFileSync(jsPath, 'utf8'), jsContext, {filename: jsPath});

const dart = fs.readFileSync(dartPath, 'utf8');

function listExpression(name) {
  const declaration = `const List<`;
  const index = dart.indexOf(` ${name} =`, dart.indexOf(declaration));
  if (index < 0) throw new Error(`Dart declaration ${name} was not found`);
  const open = dart.indexOf('[', index);
  let depth = 0;
  let lineComment = false;
  let blockComment = false;
  for (let i = open; i < dart.length; i++) {
    const c = dart[i];
    const next = dart[i + 1];
    if (lineComment) {
      if (c === '\n') lineComment = false;
      continue;
    }
    if (blockComment) {
      if (c === '*' && next === '/') {
        blockComment = false;
        i++;
      }
      continue;
    }
    if (c === '/' && next === '/') {
      lineComment = true;
      i++;
      continue;
    }
    if (c === '/' && next === '*') {
      blockComment = true;
      i++;
      continue;
    }
    if (c === '[') depth++;
    if (c === ']') {
      depth--;
      if (depth === 0) return dart.slice(open, i + 1);
    }
  }
  throw new Error(`Unterminated Dart list for ${name}`);
}

function dartTable(name) {
  const expression = listExpression(name).replace(/\/\*[\s\S]*?\*\//g, '').replace(/\/\/.*$/gm, '');
  return vm.runInNewContext(`(${expression})`, {}, {filename: dartPath});
}

function compare(path, a, b) {
  if (Array.isArray(a) !== Array.isArray(b)) return `${path}: array shape differs`;
  if (Array.isArray(a)) {
    if (a.length !== b.length) return `${path}: length ${a.length} != ${b.length}`;
    for (let i = 0; i < a.length; i++) {
      const difference = compare(`${path}[${i}]`, a[i], b[i]);
      if (difference) return difference;
    }
    return null;
  }
  return Object.is(a, b) ? null : `${path}: ${a} != ${b}`;
}

for (const [dartName, jsName] of [
  ['xl0Xzb', 'XL0_xzb'],
  ['xl0', 'XL0'],
  ['xl1', 'XL1'],
]) {
  const difference = compare(dartName, dartTable(dartName), jsContext[jsName]);
  if (difference) throw new Error(difference);
  console.log(`${dartName}: exact coefficient-table match`);
}
