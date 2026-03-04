const fs = require("fs");
const path = require("path");
const vm = require("vm");

function loadScript(filePath) {
    const code = fs.readFileSync(filePath, "utf8");
    vm.runInThisContext(code, { filename: filePath });
}

const baseDir = "j:/ziwei_core_v2/sxwnl/src";
loadScript(path.join(baseDir, "eph0.js"));
loadScript(path.join(baseDir, "eph.js"));

function collectYearSzj(year, location) {
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
        const m = SZJ.Mt(jdUtNoon);

        // Store offsets in seconds relative to jdUtNoon
        // sunS, sunZ, sunJ, moonS, moonZ, moonJ
        out.push([
            Number(((r.s - jdUtNoon) * 86400).toFixed(4)),
            Number(((r.z - jdUtNoon) * 86400).toFixed(4)),
            Number(((r.j - jdUtNoon) * 86400).toFixed(4)),
            Number(((m.s - jdUtNoon) * 86400).toFixed(4)),
            Number(((m.z - jdUtNoon) * 86400).toFixed(4)),
            Number(((m.j - jdUtNoon) * 86400).toFixed(4)),
        ]);
    }
    return out;
}

const startYear = -2000;
const endYear = 5000;
const szjData = [];
const szjDayCounts = [];

const location = {
    longitudeDeg: 116.3833,
    latitudeDeg: 39.9,
    timezone: 8,
};

for (let y = startYear; y <= endYear; y++) {
    const list = collectYearSzj(y, location);
    szjData.push(list);
    szjDayCounts.push(list.length);
    if ((y - startYear) % 500 === 0) {
        process.stdout.write(".");
    }
}

const output = {
    startYear,
    endYear,
    szj: {
        location,
        days: szjData,
        dayCounts: szjDayCounts,
    },
};

fs.writeFileSync(
    path.join(__dirname, "js_szj.json"),
    JSON.stringify(output),
    "utf8"
);
console.log("\nDone generating JS SZJ data.");
