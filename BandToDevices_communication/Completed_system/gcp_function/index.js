const { onValueWritten } = require("firebase-functions/v2/database"); // Triggers the function whenever the DB path changes
const { defineSecret } = require("firebase-functions/params"); //Securely defines secrets (not hardcoded in code)
const { onInit } = require("firebase-functions/v2/core"); // Used to initialize variables before the function runs (once per container lifecycle)
const admin = require("firebase-admin"); //To initialize Firebase services 
const AWS = require("aws-sdk");//To interact with AWS IoT Core using Node.js

admin.initializeApp();// initialize firebase sdk to access the db

// Declare secrets
const AWS_ACCESS_KEY_ID = defineSecret("AWS_ACCESS_KEY_ID");
const AWS_SECRET_ACCESS_KEY = defineSecret("AWS_SECRET_ACCESS_KEY");
const AWS_IOT_ENDPOINT = defineSecret("AWS_IOT_ENDPOINT");
const AWS_REGION = defineSecret("AWS_REGION");

let getIotClient = null;

//  onInit: Create a factory function — no secrets accessed here
onInit(() => { //can’t access secrets here directly — they’re only available inside the function handler.
  getIotClient = ({ accessKeyId, secretAccessKey, endpoint, region }) => {
    return new AWS.IotData({
      accessKeyId,
      secretAccessKey,
      endpoint,
      region,
    });
  };
});

exports.testFunctions3 = onValueWritten(
  {
    ref: "/symbols/{symbolId}",
    region: "asia-southeast1",
    secrets: [
      AWS_ACCESS_KEY_ID,
      AWS_SECRET_ACCESS_KEY,
      AWS_IOT_ENDPOINT,
      AWS_REGION,
    ],
  },
  async (event) => {
    const symbolId = event.params.symbolId;
    const afterData = event.data.after.val();

    if (!afterData) {
      console.log(`Symbol ${symbolId} deleted — skipping`);
      return null;
    }

    const { source, state, name, available } = afterData;

    if (source === "mobile") {
      const payload = {
        symbolId,
        state,
        available,
        name,
      };

      const iotClient = getIotClient({
        accessKeyId: AWS_ACCESS_KEY_ID.value(),
        secretAccessKey: AWS_SECRET_ACCESS_KEY.value(),
        endpoint: AWS_IOT_ENDPOINT.value(),
        region: AWS_REGION.value(),
      });

      const params = {
        topic: "firebase/device-control",
        qos: 1,
        payload: JSON.stringify(payload),
      };

      try {
        await iotClient.publish(params).promise();
        console.log(`Published to AWS IoT for symbol: ${symbolId}`);
      } catch (error) {
        console.error("AWS IoT Publish Error:", error);
      }
    }

    return null;
  }
);
