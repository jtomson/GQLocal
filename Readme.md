# What

GQLocal provides a local GraphQL executor for iOS (Android to follow?).

With GQLocal you can provide offline GraphQL query resolvers from embedded databases (e.g. Core Data, SQLite) or 'online' resolvers for remote calls (e.g REST API), all within your app.

# Why?

I wanted to start playing with GraphQL and Relay concepts with mobile apps using embedded data stores, where the "UI" layer can have its dependencies resolved via GraphQL regardless of network connection.

# Example

More details can be found in the GQLocal XCTests.

### Javascript Schema Definition with Bindings

This should included in your app bundle. ES6 (Babel) is supported.

```js
/**
 * the 'gql' variable is magically available - all graphql-js exports are available there...
 * call 'bridgedResolve' to return a promise from an Obj-C bridged call
 */

 [...]

 var queryType = new gql.GraphQLObjectType({
  name: 'Query',
  fields: () => ({
    hero: {
      type: characterInterface,
      args: {
        episode: {
          description: 'If omitted, returns the hero of the whole saga. If ' +
                       'provided, returns the hero of that particular episode.',
          type: episodeEnum
        }
      },
      resolve: (root, { episode }) => gql.bridgedResolve("getHero", root, [episode]),
    },
    human: {
      type: humanType,
      args: {
        id: {
          description: 'id of the human',
          type: new gql.GraphQLNonNull(gql.GraphQLString)
        }
      },
      resolve: (root, { id }) => gql.bridgedResolve("getHuman", root, [id]),
    },
    droid: {
      type: droidType,
      args: {
        id: {
          description: 'id of the droid',
          type: new gql.GraphQLNonNull(gql.GraphQLString)
        }
      },
      resolve: (root, { id }) => gql.bridgedResolve("getDroid", root, [id])
    },
  })
});

[...]

/**
 * register this schema with the GQLocal bridge
 */

gql.schemas.StarWarsSchema = new gql.GraphQLSchema({
    query: queryType
});

```

### Objective-C usage
```obj-c
GQLocal *gqlocal = [[GQLocal alloc] init];

// bind any 'resolve' callbacks defined in the js here
[gqlocal bindJSResolver:@"getHero" resolver:^(NSDictionary *root, NSArray *args, void (^callback)(id)) {
        dispatch_async(queue, ^{ callback([StarWarsData hero:args[0]]); });
    }];
 
[gqlocal bindJSResolver:@"getFriends" resolver:^(NSDictionary *root, NSArray *args, void (^callback)(id)) {
    dispatch_async(queue, ^{ callback([StarWarsData friends:args[0]]); });
}];
// ...

// Load the js schema
NSURL *schemaURL = [[NSBundle mainBundle] URLForResource:@"bridgedStarWarsSchema" withExtension:@"js"];
[gqlocal loadSchemaFileURL:schemaURL jsName:@"StarWarsSchema"];

// wait until gqlocal.isReady
// ...

[gqlocal query:@"query HeroNameQuery { hero { name } }"
        schema:@"StarWarsSchema"
      response:^(NSDictionary *result, NSError *error) {
        // result should be an NSDictionary: { @"data": @{ @"hero": @{ @"name": @"R2-D2" } } }
        NSLog(@"Result: %@", result);
}];
```

# How?

Since there is no existing Obj-C, C, or C++ implementation of GraphQL, GQLocal uses a UIWebView internally to evaluate a [Browserified](http://browserify.org) instance of the NodeJS-based [graphql-js](https://github.com/graphql/graphql-js) reference implementation. More information can be found in the `js-build` directory.

Asynchronous RPC communication between the graphql-js methods and the Obj-C methods is accomplished using [WebViewJavaScriptBridge](https://github.com/marcuswestin/WebViewJavascriptBridge).


# TODO

In its current state this is basically a proof of concept. There is a lot of cool stuff we could do here though - class generation based on schema definitions etc... 

It would also be nice to remove the JS schema and replace it with an Obj-C DSL-type of definition (builder pattern?).

If/when there is an opportunity to drop the javascript requirement across the board and use a native implementation (c++/go?) that might be desireable as well!



