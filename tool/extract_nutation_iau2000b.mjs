#!/usr/bin/env node

// Extract the IAU 2000B nutation table used by ephB.js.  Keep this as a
// mechanical source-to-source step so the long coefficient table is never
// transcribed by hand.

import fs from 'node:fs';
import vm from 'node:vm';

const sourcePath = process.argv[2] ?? '../sxwnl/src/eph0.js';
const source = fs.readFileSync(sourcePath, 'utf8');
const start = source.indexOf('var nuTab=new Array(');
const end = source.indexOf('function nutation(', start);
if (start < 0 || end < 0) throw new Error('nuTab table was not found');

const tableSource = source.slice(start, end).replace('var nuTab=', 'globalThis.nuTab=');
const context = {Math};
vm.runInNewContext(tableSource, context, {filename: sourcePath});
const table = context.nuTab;
if (!Array.isArray(table) || table.length !== 847) {
  throw new Error(`Unexpected nuTab length: ${table?.length}`);
}

const number = (value) => {
  if (!Number.isFinite(value)) throw new Error(`Non-finite coefficient: ${value}`);
  return Number.isInteger(value) ? `${value}.0` : String(value);
};
const lines = [
  '/// Generated from sxwnl eph0.js by tool/extract_nutation_iau2000b.mjs.',
  '/// Do not hand-edit: rerun the extractor when the source table changes.',
  '// ignore_for_file: non_constant_identifier_names',
  'const List<double> nuTab = [',
];
for (let i = 0; i < table.length; i += 11) {
  lines.push(`  ${table.slice(i, i + 11).map(number).join(', ')},`);
}
lines.push('];', '');
process.stdout.write(lines.join('\n'));
