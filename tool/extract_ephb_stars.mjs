#!/usr/bin/env node

// Mechanically extract the optional fixed-star data from sxwnl ephB.js.
// The source file keeps the tables as concatenated JavaScript strings and
// includes a few arithmetic expressions in epTab; evaluating only the table
// declarations avoids hand-copying either coefficients or catalog records.

import fs from 'node:fs';
import vm from 'node:vm';

const sourcePath = process.argv[2] ?? '../sxwnl/src/ephB.js';
const source = fs.readFileSync(sourcePath, 'utf8');

function sliceBetween(startMarker, endMarker) {
  const start = source.indexOf(startMarker);
  const end = source.indexOf(endMarker, start);
  if (start < 0 || end < 0) {
    throw new Error(`Could not locate ${startMarker} .. ${endMarker}`);
  }
  return source.slice(start, end);
}

const context = {Math};
const tableSource = [
  sliceBetween('var evTab =', 'function evSSB'),
  sliceBetween('var epTab =', 'function epSSB'),
  sliceBetween('var xz88=', 'function schHXK'),
].join('\n');
vm.runInNewContext(`${tableSource}\nglobalThis.__tables = {evTab, epTab, xz88, HXK};`, context, {
  filename: sourcePath,
});

const tables = context.__tables;
if (!Array.isArray(tables.evTab) || tables.evTab.length !== 468) {
  throw new Error(`Unexpected evTab length: ${tables.evTab?.length}`);
}
if (!Array.isArray(tables.epTab) || tables.epTab.length !== 144) {
  throw new Error(`Unexpected epTab length: ${tables.epTab?.length}`);
}
if (!Array.isArray(tables.xz88) || tables.xz88.length !== 440) {
  throw new Error(`Unexpected xz88 length: ${tables.xz88?.length}`);
}
if (!Array.isArray(tables.HXK) || tables.HXK.length === 0) {
  throw new Error('Unexpected HXK table');
}

function number(value) {
  if (!Number.isFinite(value)) throw new Error(`Non-finite number: ${value}`);
  if (Number.isInteger(value)) return `${value}.0`;
  return String(value);
}

function numericList(values) {
  return `[
${values.map((value) => `  ${number(value)},`).join('\n')}
]`;
}

function stringList(values) {
  return JSON.stringify(values, null, 2)
    .split('\n')
    .map((line) => `  ${line}`)
    .join('\n')
    .replace(/^  \[/, '[')
    .replace(/\n  \]$/, '\n]');
}

const output = [
  '/// Generated from sxwnl ephB.js by tool/extract_ephb_stars.mjs.',
  '/// Do not hand-edit: rerun the extractor when the source tables change.',
  '// ignore_for_file: non_constant_identifier_names, constant_identifier_names',
  `const List<double> evTab = ${numericList(tables.evTab)};`,
  `const List<double> epTab = ${numericList(tables.epTab)};`,
  `const List<String> xz88 = ${stringList(tables.xz88)};`,
  `const List<String> HXK = ${stringList(tables.HXK)};`,
  '',
].join('\n');
process.stdout.write(output);
