//
//  StarWarsData.h
//  GQLite
//
//  Created by James Tomson on 8/26/15.
//  Copyright (c) 2015 James Tomson. All rights reserved..
//

#import <Foundation/Foundation.h>

@interface StarWarsData : NSObject

// TODO - real types?

+ (id)hero:(NSNumber *)episode;
+ (id)friends:(NSDictionary *)character;
+ (id)human:(NSString *)identifier;
+ (id)droid:(NSString *)identifier;

@end
