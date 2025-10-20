const start = performance.now();

for (let i = 0; i < 1e6; i++) {
    Math.sqrt(i);
}

const end = performance.now();
console.log("Time taken:", (end - start) / 1000, "seconds");
