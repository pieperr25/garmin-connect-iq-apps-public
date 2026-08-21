import assert from "node:assert/strict";

const normalize = degrees => ((degrees % 360) + 360) % 360;
const relative = (windFromDegrees, riderHeadingDegrees) =>
  normalize(windFromDegrees - riderHeadingDegrees);

assert.equal(relative(0, 0), 0, "north wind while riding north is a headwind");
assert.equal(relative(0, 180), 180, "a U-turn reverses headwind to tailwind");
assert.equal(relative(90, 0), 90, "east wind while riding north comes from right");
assert.equal(relative(45, 90), 315, "a 90 degree turn rotates the arrow 90 degrees");
assert.equal(relative(359, 1), 358, "angles wrap cleanly around north");

console.log("Wind direction checks passed.");
