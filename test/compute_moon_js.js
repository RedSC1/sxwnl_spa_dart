const fs = require("fs");
const path = require("path");
const vm = require("vm");

function loadScript(filePath) {
  const code = fs.readFileSync(filePath, "utf8");
  vm.runInThisContext(code, { filename: filePath });
}

// 指向您根目录下的原版源码
const baseDir = path.join(__dirname, "../../sxwnl/src");
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

function suoAccurate(w) {
  const t = XL.MS_aLon_t(w) * 36525;
  return t - dt_T(t) + 8 / 24;
}

function collectYearMoonPhases(year) {
  const start = JD.JD(year, 1, 1);
  const end = JD.JD(year + 1, 1, 1);
  const candidates = [];
  const y = year - 2000;
  const n0 = Math.floor(y * (365.2422 / 29.53058886));
  
  for (let i = -3; i < 60; i++) {
    const w = (n0 + i * 0.25) * 2 * Math.PI;
    const jd = suoAccurate(w);
    candidates.push(jd);
  }
  
  const sorted = uniqueSorted(candidates);
  return sorted.filter((jd) => {
    const abs = jd + J2000;
    return abs >= start - 1e-9 && abs < end - 1e-9;
  });
}

const startYear = 2020;
const endYear = 2030;
const results = [];

process.stdout.write(`正在计算 ${startYear} - ${endYear} 的原版月相数据...`);

for (let y = startYear; y <= endYear; y++) {
  results.push(collectYearMoonPhases(y));
  process.stdout.write(".");
}

const output = { startYear, endYear, moonPhases: results };
fs.writeFileSync(
  path.join(__dirname, "js_moon_phase.json"),
  JSON.stringify(output),
  "utf8"
);
console.log("\n计算完成，数据已写入 test/js_moon_phase.json");
