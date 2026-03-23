const functions = require('firebase-functions-test')();
const myFunctions = require('../index');
const request = require('supertest');
const express = require('express');

describe('createCheckoutSession', () => {
  it('should return 400 if userId is missing', async () => {
    const app = express();
    app.use(express.json());
    app.post('/createCheckoutSession', myFunctions.createCheckoutSession);
    await request(app)
      .post('/createCheckoutSession')
      .send({})
      .expect(400);
  });
});
