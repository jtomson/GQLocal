
//
//  GQLocalTests.m
//  GQLocalTests
//
//  Created by James Tomson on 8/25/15.
//  Copyright (c) 2015 James Tomson. All rights reserved.
//

#import "GQLocal.h"
#import "StarWarsData.h"

#import <KVOController/FBKVOController.h>

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

@interface GQLocalTests : XCTestCase
@property (nonatomic) GQLocal *gqlocal;
@property (nonatomic) FBKVOController *kvo;
@property (nonatomic) dispatch_queue_t queue;
@end

@implementation GQLocalTests

- (void)setUp {
    [super setUp];
    self.gqlocal = [[GQLocal alloc] init];
    
    // All resolvers will run asynchronously on this queue
    self.queue = dispatch_queue_create("GQLocalTests", DISPATCH_QUEUE_CONCURRENT);
    
    [self.gqlocal bindJSResolver:@"getHero" resolver:^(NSDictionary *root, NSArray *args, void (^callback)(id)) {
        dispatch_async(self.queue, ^{ callback([StarWarsData hero:args[0]]); });
    }];
    
    [self.gqlocal bindJSResolver:@"getFriends" resolver:^(NSDictionary *root, NSArray *args, void (^callback)(id)) {
        dispatch_async(self.queue, ^{ callback([StarWarsData friends:args[0]]); });
    }];
    
    [self.gqlocal bindJSResolver:@"getHuman" resolver:^(NSDictionary *root, NSArray *args, void (^callback)(id)) {
        dispatch_async(self.queue, ^{ callback([StarWarsData human:args[0]]); });
    }];
    
    [self.gqlocal bindJSResolver:@"getDroid" resolver:^(NSDictionary *root, NSArray *args, void (^callback)(id)) {
        dispatch_async(self.queue, ^{ callback([StarWarsData droid:args[0]]); });
    }];
    
    // Load the js schema
    NSURL *schemaURL = [[NSBundle mainBundle] URLForResource:@"bridgedStarWarsSchema" withExtension:@"js"];
    [self.gqlocal loadSchemaFileURL:schemaURL jsName:@"StarWarsSchema"];
    
    // Wait for the GQLocal instance to load the schemas
    self.kvo = [FBKVOController controllerWithObserver:self];
    
    XCTestExpectation *e = [self expectationWithDescription:@"loaded OK"];
    
    [self.kvo observe:self.gqlocal keyPath:@"isReady" options:NSKeyValueObservingOptionNew block:^(id observer, id object, NSDictionary *change) {
        if ([change[NSKeyValueChangeNewKey] boolValue]) {
            [e fulfill];
            [self.kvo unobserve:self.gqlocal keyPath:@"isReady"];
        }
    }];
    
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
    self.gqlocal = nil;
    self.kvo = nil;
    self.queue = nil;
}

- (void)testBasicQueryArtooHero {
    
    XCTestExpectation *e = [self expectationWithDescription:@"query returned"];
    
    [self.gqlocal query:@"query HeroNameQuery { hero { name } }" schema:@"StarWarsSchema" response:^(NSDictionary *result, NSError *error) {
        
        NSDictionary *expected = @{
            @"data": @{ @"hero": @{ @"name": @"R2-D2" } }
        };
        
        XCTAssertEqualObjects(result, expected);
        
        [e fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];

}

- (void)testBasicQueryArtooHeroFriends {
    XCTestExpectation *e = [self expectationWithDescription:@"query returned"];
    
    [self.gqlocal query:@"query HeroNameAndFriendsQuery { hero { id name friends { name } } }" schema:@"StarWarsSchema" response:^(NSDictionary *result, NSError *error) {
        
        NSDictionary *expected = @{
            @"data": @{
               @"hero": @{
                   @"id": @"2001",
                   @"name": @"R2-D2",
                   @"friends": @[
                       @{ @"name": @"Luke Skywalker" },
                       @{ @"name": @"Han Solo" },
                       @{ @"name": @"Leia Organa" },
                   ]
               }
            }
        };
        
        XCTAssertEqualObjects(result, expected);
        
        [e fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testNestedQueryArtooHeroFriends {
    XCTestExpectation *e = [self expectationWithDescription:@"query returned"];
    
    [self.gqlocal query:@"{ hero { name friends { name appearsIn friends { name } } } }" schema:@"StarWarsSchema" response:^(NSDictionary *result, NSError *error) {
        
        NSDictionary *expected = @{
            @"data":
                @{ @"hero": @{
                    @"name": @"R2-D2",
                    @"friends": @[
                        @{
                            @"name": @"Luke Skywalker",
                            @"appearsIn": @[ @"NEWHOPE", @"EMPIRE", @"JEDI" ],
                            @"friends": @[
                                @{ @"name": @"Han Solo" },
                                @{ @"name": @"Leia Organa" },
                                @{ @"name": @"C-3PO" },
                                @{ @"name": @"R2-D2" }
                            ]
                        },
                        @{
                            @"name":  @"Han Solo",
                            @"appearsIn": @[ @"NEWHOPE", @"EMPIRE", @"JEDI" ],
                            @"friends": @[
                                @{ @"name": @"Luke Skywalker" },
                                @{ @"name": @"Leia Organa" },
                                @{ @"name": @"R2-D2" }
                          ]
                        },
                        @{
                          @"name":  @"Leia Organa",
                          @"appearsIn": @[ @"NEWHOPE",  @"EMPIRE",  @"JEDI" ],
                          @"friends": @[
                            @{ @"name": @"Luke Skywalker" },
                            @{ @"name": @"Han Solo" },
                            @{ @"name": @"C-3PO" },
                            @{ @"name": @"R2-D2" }
                          ]
                        }
                    ]
                }
        }};
    
        XCTAssertEqualObjects(result, expected);
        
        [e fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testPerformanceShallowQuery {
    
    [self measureBlock:^{
        XCTestExpectation *expectation = [self expectationWithDescription:@"query completed"];
        
        [self.gqlocal query:@"{ hero { name } }" schema:@"StarWarsSchema" response:^(NSDictionary *result, NSError *error) {
            XCTAssertNil(error, @"");
            [expectation fulfill];
        }];
        
        [self waitForExpectationsWithTimeout:1.0 handler:nil];
    }];
}

- (void)testPerformanceNestedQuery {
    
    // This is an example of a performance test case.
    [self measureBlock:^{
        XCTestExpectation *expectation = [self expectationWithDescription:@"query completed"];
        
        [self.gqlocal query:@"{ hero { name friends { name appearsIn friends { name } } } }" schema:@"StarWarsSchema" response:^(NSDictionary *result, NSError *error) {
            XCTAssertNil(error, @"");
            [expectation fulfill];
        }];
        
        [self waitForExpectationsWithTimeout:1.0 handler:nil];
    }];
}

@end
