#!/usr/bin/env node

// Verify the generated IAU 2000B table against sxwnl eph0.js.

import fs from 'node:fs';
import vm from 'node:vm';

const sourcePath = process.argv[2] ?? '../sxwnl/src/eph0.js';
const dartPath = process.argv[3] ?? 'lib/src/sxwnl/ephb_nutation_data.dart';
const source = fs.readFileSync(sourcePath, 'utf8');
const dart = fs.readFileSync(dartPath, 'utf8');
const start = source.indexOf('var nuTab=new Array(');
const end = source.indexOf('function nutation(', start);
if (start < 0 || end < 0) throw new Error('nuTab table was not found');
const context = {Math};
vm.runInNewContext(
  source.slice(start, end).replace('var nuTab=', 'globalThis.nuTab='),
  context,
  {filename: sourcePath},
);

const open = dart.indexOf('[', dart.indexOf(' nuTab ='));
const close = dart.indexOf('];', open);
if (open < 0 || close < 0) throw new Error('Dart nuTab table was not found');
const generated = vm.runInNewContext(`(${dart.slice(open, close + 1)})`, {}, {
  filename: dartPath,
});
if (context.nuTab.length !== generated.length) {
  throw new Error(`nuTab length ${context.nuTab.length} != ${generated.length}`);
}
for (let i = 0; i < generated.length; i++) {
  if (!Object.is(context.nuTab[i], generated[i])) {
    throw new Error(`nuTab[${i}]: ${context.nuTab[i]} != ${generated[i]}`);
  }
}
console.log(`nuTab: exact generated-table match (${generated.length} values)`);
