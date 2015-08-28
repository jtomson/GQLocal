//
//  GQLocal.h
//  GQLocal
//
//  Created by James Tomson on 8/27/15.
//
//

#import <Foundation/Foundation.h>

@interface GQLocal : NSObject

@property (nonatomic, readonly) BOOL isReady;

/**
 *  Execture a GraphQL query for the given schema name, and define a callback block to receive the result
 *
 *  @param graphQL    the GraphQL query string
 *  @param schemaName the name of the schema used in the query (see loadSchemaFileURL:jsName)
 *  @param callback   the block to be invoked when the result is ready or an error occurs
 */
- (void)query:(NSString*)graphQL schema:(NSString *)schemaName response:(void(^)(NSDictionary *, NSError *))callback;

/**
 *  This will bind the given javascript function, passed as jsName, to the given resolver block
 *
 *  @param jsName   the name of the javascript function that will be bound to the resolver block
 *  @param resolver a block taking an NSDictionary * representing the parent query result, and an NSArray of arguments
 *         and a callback block to provide the response
 */

- (void)bindJSResolver:(NSString*)jsName resolver:(void(^)(NSDictionary *, NSArray *, void (^)(id)))resolver;

/**
 *  This will load the es6 schema at the provided file URL, bound to the passed js name
 *
 *  @param url    the file URL for the js schem file
 *  @param jsName the name that this schema is exported as via 'gql.schemas`
 */
- (void)loadSchemaFileURL:(NSURL *)url jsName:(NSString *)jsName;

@end
