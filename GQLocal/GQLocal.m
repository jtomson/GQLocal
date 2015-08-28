//
//  GQLocal.m
//  GQLocal
//
//  Created by James Tomson on 8/27/15.
//
//

#import "GQLocal.h"

#import <WebKit/WebKit.h>
#import <WebViewJavascriptBridge/WebViewJavascriptBridge.h>

@interface GQLocal () <UIWebViewDelegate>

@property (nonatomic, readwrite) BOOL isReady;

@property WebViewJavascriptBridge *bridge;
@property UIWebView *webView;
@property NSMutableDictionary *resolverDict;
@property NSMutableDictionary *schemaDict;

@end

typedef void(^ResolverBlock)(NSDictionary *, NSArray *, void (^)(id));

@implementation GQLocal

- (void)initUIWebview {
    [WebViewJavascriptBridge enableLogging];
    
    self.webView = [[UIWebView alloc] init];
    self.webView.delegate = self;
    
    // setup the bridge before we load our local page
    self.bridge = [WebViewJavascriptBridge bridgeForWebView:self.webView webViewDelegate:self handler:^(id data, WVJBResponseCallback responseCallback) {
        NSAssert([data isKindOfClass:[NSDictionary class]], @"need to send back an object type");
        
        NSDictionary *dataDict = (NSDictionary *)data;
        NSString *jsMethodName = dataDict[@"method"];
        
        NSAssert(jsMethodName.length > 0, @"need a mathod name");
        
        NSLog(@"ObjC received message from JS: %@", data);
        
        ResolverBlock resolver = self.resolverDict[jsMethodName];
        
        NSAssert(resolver != nil, @"no resolver block defined");
        
        resolver(dataDict[@"root"], dataDict[@"args"], ^(id result) {
            NSLog(@"Responding with result: %@", result);
            responseCallback(@{@"value" : result});
        });
    }];
}

- (instancetype)init {
    self = [super init];
    
    if (self) {
        [self initUIWebview];
        self.resolverDict = [NSMutableDictionary dictionary];
        self.schemaDict = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)bindJSResolver:(NSString *)jsName resolver:(ResolverBlock)resolver {
    self.resolverDict[jsName] = [resolver copy];
}

- (void)loadSchemaFileURL:(NSURL *)url jsName:(NSString *)jsName {
    NSAssert(url.isFileURL, @"%@ is not a file url");
    
    self.isReady = NO;
    
    self.schemaDict[jsName] = url.lastPathComponent;
    
    // build the script tags for inclusion
    NSMutableString *scripts = [NSMutableString string];
    for (NSString *filename in self.schemaDict.allValues) {
        NSString *script = [NSString stringWithFormat:@"<script type='text/babel' src='%@'></script>\n", filename];
        [scripts appendString:script];
    }
    
    // generate the html with those script tags
    NSURL *htmlTemplateURL = [[NSBundle mainBundle] URLForResource:@"gql.html" withExtension:@"in"];
    NSAssert(htmlTemplateURL != nil, @"");
    
    NSString *htmlTemplate = [NSString stringWithContentsOfURL:htmlTemplateURL encoding:NSUTF8StringEncoding error:nil];
    
    NSString *html = [htmlTemplate stringByReplacingOccurrencesOfString:@"@@SCHEMA_SCRIPT_INCLUDES@@" withString:scripts];
    
    // load the generated html
    [self.webView loadHTMLString:html baseURL:[htmlTemplateURL URLByDeletingLastPathComponent]];
}

- (void)query:(NSString*)graphQL schema:(NSString *)schemaName response:(void(^)(NSDictionary *, NSError *))callback {
    
    // send the query over the bridge, call the passed callback when complete
    NSMutableString *jsString = [NSMutableString string];
    for (NSString *schemaName in self.schemaDict.allKeys) {
        [jsString appendString:[NSString stringWithFormat:@"window.gql.schemas['%@'] && ", schemaName]];
    }
    [jsString appendString:@"true"]; // for final &&
    NSString *result = [self.webView stringByEvaluatingJavaScriptFromString:jsString];
    if ([result isEqualToString:@"true"]) {
        // UIWebView object has fully loaded.
        self.isReady = YES;
    }
    
    // Time the query
    NSDate *startTime = [NSDate date];
    
    [self.bridge send:@{ @"query": graphQL, @"schemaName":schemaName} responseCallback:^(id responseData) {
        NSDictionary *response = responseData;
        
        if (response[@"error"]) {
            NSLog(@"Error: %@", response[@"error"]);
            callback(nil, [NSError errorWithDomain:@"GQLite" code:-1 userInfo:@{NSLocalizedDescriptionKey: response[@"error"]}]);
        }
        else {
            NSLog(@"Result: %@", response[@"result"]);
            callback(response[@"result"], nil);
            NSLog(@"took: %f seconds", [[NSDate date] timeIntervalSinceDate:startTime]);
        }
        
    }];
}

- (void)pollForReady {
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        // build a string to check that all schemas are defined
        NSMutableString *jsString = [NSMutableString string];
        for (NSString *schemaName in self.schemaDict.allKeys) {
            [jsString appendString:[NSString stringWithFormat:@"window.gql.schemas['%@'] && ", schemaName]];
        }
        [jsString appendString:@"true"]; // for final &&
        
        // evaluate
        NSString *result = [self.webView stringByEvaluatingJavaScriptFromString:jsString];
        if ([result isEqualToString:@"true"]) {
            // UIWebView object has fully loaded.
            self.isReady = YES;
        }
        else {
            // try again in a bit
            [self pollForReady];
        }
    });
}

#pragma mark - UIWebViewDelegate methods

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    self.isReady = NO;
    [self pollForReady];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    NSLog(@"Error loading: %@", error);
}

@end

