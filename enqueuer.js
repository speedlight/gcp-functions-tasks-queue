const express = require('express');
const { CloudTasksClient } = require('@google-cloud/tasks');
const display_child_age_url = "https://northamerica-northeast1-ringed-enigma-334420.cloudfunctions.net/viewChild"
const queue_name = "childAge-03"
const service_account_email = "ringed-enigma-334420@appspot.gserviceaccount.com"

async function postToQueue(queue_client, queue_parent, child_data_dict) {
  const task = {
    httpRequest: {
      httpMethod: 'POST',
      url: display_child_age_url,
      headers: {
        'content-type': 'application/json',
      },
      body: Buffer.from(JSON.stringify(child_data_dict)).toString('base64'),
      oidcToken: {
        serviceAccountEmail: service_account_email,
      },
    }
  };
  const [response] = await queue_client.createTask({parent:queue_parent, task:task});
  console.log(`Created task ${response.name}`);
}

async function processQueue(child_list) {
  const queue_client = new CloudTasksClient();
  const location = "northamerica-northeast1"
  const gcp_project = "ringed-enigma-334420"
  const queue_parent = queue_client.queuePath(gcp_project, location, queue_name);
  for (const child_data_dict of child_list) {
    try {
    await postToQueue(queue_client, queue_parent, child_data_dict);
    } catch (error) {
    console.error('Error:', new Error(error.message));
    }
  }
}

async function enqueueChilds(req, res) {
  const payload = req.body;
  await processQueue(payload["child_data"]);
  const text = "Childs enqueued"
  console.log(text);
  console.log(payload["child_data"]);
  res.status(200).send(text);
  res.end();
}

function enqueueChildsApp() {
  const app = express();
  app.use(require('body-parser').json());
  app.use(enqueueChilds);
  return app;
}

exports.mainFunction = enqueueChildsApp();
