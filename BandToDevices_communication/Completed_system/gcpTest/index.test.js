const functionTest = require("firebase-functions-test")({
  databaseURL: "https://flicknestfirebase-default-rtdb.asia-southeast1.firebasedatabase.app/",
  projectId: "flicknestfirebase",
  storageBucket: "gs://flicknestfirebase.firebasestorage.app"
}, "./serviceAccountKey.json");

const sinon = require("sinon");
const { expect } = require("chai");
const proxyquire = require("proxyquire");

describe("testFunctions3 - Debug Version", () => {
  let publishStub;
  let IotDataStub;
  let myFunctions;
  let consoleLogSpy;

  before(() => {
    // Create stubs
    publishStub = sinon.stub();
    publishStub.returns({
      promise: () => Promise.resolve("published")
    });

    IotDataStub = sinon.stub();
    IotDataStub.returns({
      publish: publishStub,
    });

    // Stub the entire AWS module
    const AWSStub = {
      IotData: IotDataStub,
    };

    // Create a simple secret stub
    const defineSecretStub = (secretName) => ({
      value: () => `test-${secretName}`
    });

    // Spy on console.log to see what's happening
    consoleLogSpy = sinon.spy(console, 'log');

    // Load the function with stubs
    myFunctions = proxyquire("../index.js", {
      "firebase-functions/params": {
        defineSecret: defineSecretStub,
      },
      "aws-sdk": AWSStub,
    });
  });

  beforeEach(() => {
    publishStub.resetHistory();
    IotDataStub.resetHistory();
    consoleLogSpy.resetHistory();
  });

  after(() => {
    consoleLogSpy.restore();
    functionTest.cleanup();
  });

  it("should work with mobile source - basic test", async () => {
    console.log("Starting test...");
    
    const testData = {
      source: "mobile",
      name: "circle",
      state: true,
      available: false,
    };

    // Create snapshots
    const beforeSnapshot = functionTest.database.makeDataSnapshot(null, "symbols/sym_001");
    const afterSnapshot = functionTest.database.makeDataSnapshot(testData, "symbols/sym_001");
    
    console.log("Before snapshot:", beforeSnapshot.val());
    console.log("After snapshot:", afterSnapshot.val());
    
    // Create change object
    const change = functionTest.makeChange(beforeSnapshot, afterSnapshot);
    
    // Create event object - this is the key part
    const event = {
      data: change,
      params: {
        symbolId: "sym_001"
      }
    };

    console.log("Event params:", event.params);
    console.log("Event data after:", event.data.after.val());

    // Call the function
    console.log("Calling function...");
    const result = await myFunctions.testFunctions3(event);
    
    console.log("Function result:", result);
    console.log("Console logs during execution:", consoleLogSpy.getCalls().map(call => call.args));
    
    // Basic assertions
    expect(result).to.be.null;
    
    // Check if AWS IoT was called
    console.log("IotDataStub called:", IotDataStub.called);
    console.log("publishStub called:", publishStub.called);
    
    if (publishStub.called) {
      const publishArgs = publishStub.firstCall.args[0];
      console.log("Publish args:", publishArgs);
      
      expect(publishArgs.topic).to.equal("firebase/device-control");
      expect(publishArgs.qos).to.equal(1);
      
      const payload = JSON.parse(publishArgs.payload);
      expect(payload.symbolId).to.equal("sym_001");
      expect(payload.source).to.be.undefined; // source should not be in payload
      expect(payload.name).to.equal("circle");
      expect(payload.state).to.be.true;
      expect(payload.available).to.be.false;
    }
  });

  it("should skip when source is not mobile", async () => {
    const testData = {
      source: "broker",
      name: "wave",
      state: false,
      available: true,
    };

    const beforeSnapshot = functionTest.database.makeDataSnapshot(null, "symbols/sym_002");
    const afterSnapshot = functionTest.database.makeDataSnapshot(testData, "symbols/sym_002");
    const change = functionTest.makeChange(beforeSnapshot, afterSnapshot);

    const event = {
      data: change,
      params: {
        symbolId: "sym_002"
      }
    };

    const result = await myFunctions.testFunctions3(event);
    
    expect(result).to.be.null;
    expect(publishStub.called).to.be.false;
    expect(IotDataStub.called).to.be.false;
  });

  it("should skip when data is deleted", async () => {
    const beforeData = {
      source: "mobile",
      name: "updown"
    };

    const beforeSnapshot = functionTest.database.makeDataSnapshot(beforeData, "symbols/sym_003");
    const afterSnapshot = functionTest.database.makeDataSnapshot(null, "symbols/sym_003");
    const change = functionTest.makeChange(beforeSnapshot, afterSnapshot);

    const event = {
      data: change,
      params: {
        symbolId: "sym_003"
      }
    };

    const result = await myFunctions.testFunctions3(event);
    
    console.log("Console logs for deletion test:", consoleLogSpy.getCalls().map(call => call.args));
    
    expect(result).to.be.null;
    expect(publishStub.called).to.be.false;
    expect(IotDataStub.called).to.be.false;
    
    // Should have logged the deletion message
    const deletionLog = consoleLogSpy.getCalls().find(call => 
      call.args[0] && call.args[0].includes('deleted — skipping')
    );
    expect(deletionLog).to.exist;
  });
});