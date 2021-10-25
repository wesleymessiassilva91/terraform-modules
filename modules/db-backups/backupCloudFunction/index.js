const { google } = require("googleapis");
const { auth } = require("google-auth-library");
var sqladmin = google.sqladmin("v1beta4");

exports.backup = async (_req, res) => {
  const authRes = await auth.getApplicationDefault();
  let authClient = authRes.credential;
  var request = {
    project: process.env.PROJECT_ID,
    instance: process.env.DB_INSTANCE_NAME,
    resource: {
      exportContext: {
        kind: "sql#exportContext",
        fileType: "SQL", 
        uri: `gs://${process.env.BUCKET_NAME}/${(new Date()).toISOString()}-backup.gz`,
        databases: [process.env.DB_NAME_TO_EXPORT]
      }
    },
    auth: authClient
  };
  
  try {
    const result = await sqladmin.instances.export(request);
    console.log(result);
    res.status(200).send("Command completed", null, result);
  } catch(err) {
    console.log(err);
    res.status(500).send("Error", err);
  }
};