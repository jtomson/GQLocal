// Boilerplate taken from https://github.com/marcuswestin/WebViewJavascriptBridge/blob/master/README.md

// Register when the bridge is ready
const connectWebViewJavascriptBridge = (callback) => {
  if (window.WebViewJavascriptBridge) {
    callback(window.WebViewJavascriptBridge);
  }
  else {
    document.addEventListener('WebViewJavascriptBridgeReady', () => callback(window.WebViewJavascriptBridge), false);
  }
}

connectWebViewJavascriptBridge((bridge) => {
  // we're ready
  bridge.init((message, responseCallback) => {
    console.log("Sending query: " + message);
    window.doQuery(message.query, message.schemaName, responseCallback);
  });
});

window.gql.schemas = {};

const doQuery = (queryString, schemaName, callback) => {
  
  if (window.gql.schemas[schemaName] === undefined) {
    console.log(`Can't find schema named ${schemaName}`);
    callback({error: `can't find schema named ${schemaName}`});
    return;
  }

  // TODO more input validation

window.gql.graphql(window.gql.schemas[schemaName], queryString)
  .then((result) => {
    console.log(`Got result: ${JSON.stringify(result)} for schema: ${schemaName}`);
    callback({result});
    console.log(`Called callback`);
  })
  .catch((error) => {
   console.log(`Got error: ${JSON.stringify(error)}`);
   callback({error: error});
   console.log(`Called error callback with schema ${schemaName}`);
 });
}

// "export"
window.doQuery = doQuery;
