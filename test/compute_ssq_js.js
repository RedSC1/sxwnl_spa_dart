const fs = require("fs");
const path = require("path");
const vm = require("vm");

function loadScript(filePath) {
    const code = fs.readFileSync(filePath, "utf8");
    vm.runInThisContext(code, { filename: filePath });
}

const baseDir = path.join(__dirname, "../../sxwnl/src");
loadScript(path.join(baseDir, "eph0.js"));
loadScript(path.join(baseDir, "eph.js"));
loadScript(path.join(baseDir, "lunar.js"));

const startYear = -2000;
const endYear = 5000;
const results = [];

for (let y = startYear; y <= endYear; y++) {
    SSQ.calcY(JD.JD(y, 1, 1));
    // After calcY, SSQ properties are populated:
    // ZQ: 25 elements (float/int relative to J2000)
    // HS: 15 elements
    // dx: 14 elements (number of days)
    // ym: 14 elements (strings, month names)
    // leap: int (index of leap month, 0 if none)

    results.push({
        ZQ: Array.from(SSQ.ZQ),
        HS: Array.from(SSQ.HS),
        dx: Array.from(SSQ.dx),
        ym: Array.from(SSQ.ym),
        leap: SSQ.leap,
    });

    if ((y - startYear) % 500 === 0) {
        process.stdout.write(".");
    }
}

const output = { startYear, endYear, results };
fs.writeFileSync(
    path.join(__dirname, "js_ssq.json"),
    JSON.stringify(output),
    "utf8"
);
console.log("\nDone generating JS SSQ data.");
