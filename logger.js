const express = require('express');

async function viewChildAge(req, res) {
  const child_data_dict = req.body;
  const text = `Child number ${child_data_dict["id"]} is ${child_data_dict["age_months"]} months old`
  console.log(text);
  res.status(200).send(text);
  res.end();
}

function viewChildAgeApp() {
  const app = express();
  app.use(require('body-parser').json());
  app.use(viewChildAge);
  return app;
}

exports.mainFunction = viewChildAgeApp();
