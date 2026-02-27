// Minimal Express server for local debugging of generateAgoraToken
const express = require("express");
const bodyParser = require("body-parser");
const app = express();
app.use(bodyParser.json());

// Import the handler from index.js
const { generateAgoraToken } = require("./index");

app.post("/generateAgoraToken", generateAgoraToken);

const port = process.env.PORT || 8080;
app.listen(port, () => {
  console.log(`Local server running on http://localhost:${port}`);
});
