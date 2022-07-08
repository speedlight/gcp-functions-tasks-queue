import * as pulumi from "@pulumi/pulumi"
import * as gcp from "@pulumi/gcp";

const path = require('path');

const bucket = new gcp.storage.Bucket("pm-task", {
  location: "US",
  project: "ringed-enigma-334420",
});

const q_archive = new gcp.storage.BucketObject("qChild", {
  bucket: bucket.name,
  source: new pulumi.asset.FileAsset(path.join(__dirname, '/files/enqueueChild.zip')),
});
const v_archive = new gcp.storage.BucketObject("vChild", {
  bucket: bucket.name,
  source: new pulumi.asset.FileArchive(path.join(__dirname, '/files/viewChild.zip')),
});

const defaultQueue = new gcp.cloudtasks.Queue("childAge-05", {
  name: "childAge-05",
  project: "ringed-enigma-334420",
  location: "northamerica-northeast1",
});

const _qfn = new gcp.cloudfunctions.Function("qfn", {
  name: "qChild",
  description: "Enqueuer child function",
  runtime: "nodejs16",
  availableMemoryMb: 128,
  sourceArchiveBucket: bucket.name,
  sourceArchiveObject: q_archive.name,
  triggerHttp: true,
  entryPoint: "mainFunction",
});

const _vfn = new gcp.cloudfunctions.Function("vfn", {
  name: "vChild",
  description: "View child function",
  runtime: "nodejs16",
  availableMemoryMb: 128,
  sourceArchiveBucket: bucket.name,
  sourceArchiveObject: v_archive.name,
  triggerHttp: true,
  entryPoint: "mainFunction",
});

const qinvoker = new gcp.cloudfunctions.FunctionIamMember("qinvoker", {
    project: _qfn.project,
    region: _qfn.region,
    cloudFunction: _qfn.name,
    role: "roles/cloudfunctions.invoker",
    member: "allUsers",
});
const vinvoker = new gcp.cloudfunctions.FunctionIamMember("vinvoker", {
    project: _vfn.project,
    region: _vfn.region,
    cloudFunction: _vfn.name,
    role: "roles/cloudfunctions.invoker",
    member: "allUsers",
});
