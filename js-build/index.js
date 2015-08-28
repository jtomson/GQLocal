import {
  GraphQLEnumType,
  GraphQLIDType,
  GraphQLInterfaceType,
  GraphQLObjectType,
  GraphQLList,
  GraphQLNonNull,
  GraphQLSchema,
  GraphQLString,
  graphql
} from 'graphql';

import util from 'util';

const bridgedResolve = (method, root, args) => {
  console.log("PROMISING: " + method);
  return new Promise((resolve, reject) => {
    console.log(`SENDING: ${method}, ${root}, ${JSON.stringify(args)}`);
    window.WebViewJavascriptBridge.send({method, root: root, args}, (response) => {
      console.log(`Bridged resolve result: ${JSON.stringify(response.value)}`);
      if (response.error) {
        reject(response.error);
      }
      else {
        resolve(response.value);
      }
    });
  });
}

// Attach 'exports' here
global.window.gql = {
    GraphQLEnumType,
    GraphQLIDType,
    GraphQLInterfaceType,
    GraphQLObjectType,
    GraphQLList,
    GraphQLNonNull,
    GraphQLSchema,
    GraphQLString,
    graphql,
    bridgedResolve
}

global.window.exports = {} // needed for browserify stuff apparently
