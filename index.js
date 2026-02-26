exports.generateAgoraToken = (req, res) => {
  res.json({
    ok: true,
// ...existing code...
exports.generateAgoraToken = (req, res) => {
  res.json({
    ok: true,
    envPort: process.env.PORT || null,
    time: new Date().toISOString()
  });
};
