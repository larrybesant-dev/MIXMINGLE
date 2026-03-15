const { generateAgoraToken } = require("../index");

function mockReq(body) {
  return { body };
}
function mockRes() {
  const res = {};
  res.status = (code) => {
    res.statusCode = code;
    return res;
  };
  res.json = (payload) => {
    res.payload = payload;
    return res;
  };
  return res;
}

test("returns 400 when missing params", async () => {
  const req = mockReq({});
  const res = mockRes();
  await generateAgoraToken(req, res);
  expect(res.statusCode).toBe(400);
  expect(res.payload).toHaveProperty("error");
});

test("returns token when params present and secrets set", async () => {
  process.env.AGORA_APP_ID = "test";
  process.env.AGORA_APP_CERTIFICATE = "test";
  const req = mockReq({ roomId: "r1", userId: "1" });
  const res = mockRes();
  await generateAgoraToken(req, res);
  expect(res.payload).toHaveProperty("token");
});
