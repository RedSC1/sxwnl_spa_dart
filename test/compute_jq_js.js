const fs = require("fs");
const path = require("path");
const vm = require("vm");

function loadScript(filePath) {
  const code = fs.readFileSync(filePath, "utf8");
  vm.runInThisContext(code, { filename: filePath });
}

const baseDir = path.join(__dirname, "sxwnl_js", "src");
loadScript(path.join(baseDir, "eph0.js"));
loadScript(path.join(baseDir, "eph.js"));

function uniqueSorted(values) {
  values.sort((a, b) => a - b);
  const out = [];
  for (const v of values) {
    if (out.length === 0 || Math.abs(v - out[out.length - 1]) > 1e-9) {
      out.push(v);
    }
  }
  return out;
}

function qiAccurate(w) {
  const t = XL.S_aLon_t(w) * 36525;
  return t - dt_T(t) + 8 / 24;
}

function suoAccurate(w) {
  const t = XL.MS_aLon_t(w) * 36525;
  return t - dt_T(t) + 8 / 24;
}

function collectYearJQ(year) {
  const start = JD.JD(year, 1, 1);
  const candidates = [];
  const y = year - 2000;
  for (let i = -30; i < 60; i++) {
    const w = (y + i / 24 + 1) * 2 * Math.PI;
    const jd = qiAccurate(w);
    candidates.push(jd);
  }
  const sorted = uniqueSorted(candidates);
  let idx = 0;
  for (; idx < sorted.length; idx++) {
    if (sorted[idx] + J2000 >= start - 1e-9) break;
  }
  return sorted.slice(idx, idx + 24);
}

function collectYearSuo(year) {
  const start = JD.JD(year, 1, 1);
  const end = JD.JD(year + 1, 1, 1);
  const candidates = [];
  const y = year - 2000;
  const n0 = Math.floor(y * (365.2422 / 29.53058886));
  for (let i = -3; i < 17; i++) {
    const w = (n0 + i) * 2 * Math.PI;
    const jd = suoAccurate(w);
    candidates.push(jd);
  }
  const sorted = uniqueSorted(candidates);
  return sorted.filter((jd) => {
    const abs = jd + J2000;
    return abs >= start - 1e-9 && abs < end - 1e-9;
  });
}

const startYear = -2000;
const endYear = 5000;
const jq = [];
const mismatches = [];
const suo = [];
const suoMismatches = [];

for (let y = startYear; y <= endYear; y++) {
  const list = collectYearJQ(y);
  if (list.length !== 24) {
    mismatches.push({ year: y, count: list.length });
  }
  jq.push(list);
  const suoList = collectYearSuo(y);
  if (suoList.length < 12 || suoList.length > 13) {
    suoMismatches.push({ year: y, count: suoList.length });
  }
  suo.push(suoList);
  if ((y - startYear) % 500 === 0) {
    process.stdout.write(".");
  }
}

const output = { startYear, endYear, jq, mismatches, suo, suoMismatches };
fs.writeFileSync(
  path.join(__dirname, "js_jq.json"),
  JSON.stringify(output),
  "utf8"
);
