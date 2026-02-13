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

function jdTimeSeconds(jd) {
  let v = jd + 0.5;
  v = v - Math.floor(v);
  let s = Math.round(v * 86400);
  if (s >= 86400) s -= 86400;
  if (s < 0) s += 86400;
  return s;
}

function collectYearSolarNoon(year, location) {
  SZJ.L = (location.longitudeDeg * Math.PI) / 180;
  SZJ.fa = (location.latitudeDeg * Math.PI) / 180;
  const start = JD.JD(year, 1, 1);
  const end = JD.JD(year + 1, 1, 1);
  const days = Math.round(end - start);
  const out = [];
  for (let i = 0; i < days; i++) {
    const dayJd = start + i;
    const jdLocalNoon = dayJd + 0.5 - J2000;
    const jdUtNoon = jdLocalNoon - location.timezone / 24;
    const r = SZJ.St(jdUtNoon);
    const localNoon = r.z + location.timezone / 24;
    out.push(jdTimeSeconds(localNoon));
  }
  return out;
}

const startYear = -2000;
const endYear = 5000;
const solarNoon = [];
const solarNoonDayCounts = [];

const solarNoonLocation = {
  longitudeDeg: 116.3833,
  latitudeDeg: 39.9,
  timezone: 8,
};

for (let y = startYear; y <= endYear; y++) {
  const noonList = collectYearSolarNoon(y, solarNoonLocation);
  solarNoon.push(noonList);
  solarNoonDayCounts.push(noonList.length);
  if ((y - startYear) % 500 === 0) {
    process.stdout.write(".");
  }
}

const output = {
  startYear,
  endYear,
  solarNoon: {
    location: solarNoonLocation,
    days: solarNoon,
    dayCounts: solarNoonDayCounts,
  },
};
fs.writeFileSync(
  path.join(__dirname, "js_solar_noon.json"),
  JSON.stringify(output),
  "utf8"
);
