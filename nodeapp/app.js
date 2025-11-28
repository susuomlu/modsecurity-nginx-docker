const express = require("express");
const app = express();
app.get("/", (req, res) => res.send("Hello from HSOC"));
app.listen(3000);
