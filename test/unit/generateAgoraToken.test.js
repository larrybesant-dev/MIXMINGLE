const request = require("supertest");
const app = require("../../local-server");

describe("generateAgoraToken API", () => {
  it("should return a valid token for correct input", async () => {
    const res = await request(app)
      .post("/generateAgoraToken")
      .send({ roomId: "testRoom", userId: "testUser" });
    expect(res.statusCode).toBe(200);
    expect(res.body).toHaveProperty("token");
    expect(typeof res.body.token).toBe("string");
  });

  it("should fail with missing roomId", async () => {
    const res = await request(app).post("/generateAgoraToken").send({ userId: "testUser" });
    expect(res.statusCode).toBeGreaterThanOrEqual(400);
    expect(res.body).toHaveProperty("error");
  });

  it("should fail with missing userId", async () => {
    const res = await request(app).post("/generateAgoraToken").send({ roomId: "testRoom" });
    expect(res.statusCode).toBeGreaterThanOrEqual(400);
    expect(res.body).toHaveProperty("error");
  });

  it("should fail with expired token logic", async () => {
    // Simulate expired token scenario if possible
    // This may require mocking time or token generation
    // For now, just check error path
    const res = await request(app)
      .post("/generateAgoraToken")
      .send({ roomId: "expiredRoom", userId: "expiredUser", expire: -1 });
    expect(res.statusCode).toBeGreaterThanOrEqual(400);
    expect(res.body).toHaveProperty("error");
  });

  it("should handle concurrency edge cases", async () => {
    const promises = [];
    for (let i = 0; i < 5; i++) {
      promises.push(
        request(app)
          .post("/generateAgoraToken")
          .send({ roomId: "concurrentRoom", userId: `user${i}` }),
      );
    }
    const results = await Promise.all(promises);
    results.forEach((res) => {
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty("token");
    });
  });
});
