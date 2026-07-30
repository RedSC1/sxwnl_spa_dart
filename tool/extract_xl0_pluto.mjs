#!/usr/bin/env node

// Extract the XL0Pluto numeric table from the original sxwnl eph0.js and
// print a Dart const declaration. This deliberately evaluates only the table
// expression, so the generated data can be reviewed/reproduced without any
// hand transcription.

import fs from 'node:fs';
import vm from 'node:vm';

const sourcePath = process.argv[2] ?? '../sxwnl/src/eph0.js';
const source = fs.readFileSync(sourcePath, 'utf8');
const start = source.indexOf('var XL0Pluto=new Array');
const end = source.indexOf('var XL0_xzb', start);

if (start < 0 || end < 0) {
  throw new Error(`XL0Pluto table was not found in ${sourcePath}`);
}

const tableSource = source
  .slice(start, end)
  .replace('var XL0Pluto=', 'globalThis.XL0Pluto=');
const context = {Math};
vm.runInNewContext(tableSource, context, {filename: sourcePath});

const table = context.XL0Pluto;
if (!Array.isArray(table) || table.length != 9 || !table.every(Array.isArray)) {
  throw new Error('Unexpected XL0Pluto shape');
}

const format = (value) => {
  if (!Number.isFinite(value)) throw new Error(`Non-finite table value: ${value}`);
  return Number.isInteger(value) ? `${value}.0` : String(value);
};
const lines = ['/// Generated from sxwnl eph0.js by tool/extract_xl0_pluto.mjs.', 'const List<List<double>> xl0Pluto = ['];
for (const row of table) {
  lines.push('  [');
  for (let i = 0; i < row.length; i += 12) {
    lines.push(`    ${row.slice(i, i + 12).map(format).join(', ')},`);
  }
  lines.push('  ],');
}
lines.push('];');
process.stdout.write(`${lines.join('\n')}\n`);
