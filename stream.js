import http from "node:http";
const options = {
    hostname: "localhost",
    port: 8080,
    path: "/",
    method: "GET",
    headers: {
        "Transfer-Encoding": "chunked", // important
        "Content-Type": "text/plain",
    },
};

const req = http.request(options, (res) => {
    console.log(`Server response: ${res.statusCode}`);
    res.on("data", (d) => process.stdout.write(d));
});

req.on("error", (error) => {
    console.error(error);
});

// Send chunks every 5 seconds
let count = 0;
const interval = setInterval(() => {
    count++;
    const chunk = `Chunk #${count} at ${new Date().toISOString()}\n`;
    req.write(chunk);
    console.log("Sent:", chunk.trim());

    if (count === 20) {
        clearInterval(interval);
        req.end(); // finalize the request
    }
}, 5000);
