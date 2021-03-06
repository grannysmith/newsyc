//
//  HNSession.m
//  newsyc
//
//  Created by Grant Paul on 3/13/11.
//  Copyright 2011 Xuzz Productions, LLC. All rights reserved.
//

#import "HNKit.h"
#import "HNSession.h"
#import "HNAPISubmission.h"
#import "HNSubmission.h"
#import "HNAnonymousSession.h"

static HNSession *current = nil;

@implementation HNSession
@synthesize user, token, loaded, password;

+ (HNSession *)currentSession {
    return current;
}

+ (void)setCurrentSession:(HNSession *)session {
    [current autorelease];
    current = [session retain];
    
    if (session != nil) {
        [[NSUserDefaults standardUserDefaults] setObject:[session token] forKey:@"HNKit:SessionToken"];
        [[NSUserDefaults standardUserDefaults] setObject:[[session user] identifier] forKey:@"HNKit:SessionName"];
        [[NSUserDefaults standardUserDefaults] setObject:[session password] forKey:@"HNKit:SessionPassword"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"HNKit:SessionToken"];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"HNKit:SessionName"];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"HNKit:SessionPassword"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        HNSession *session = [[HNAnonymousSession alloc] init];
        [self setCurrentSession:[session autorelease]];
    }
}

+ (void)initialize {
    // XXX: is it safe to use NSUserDefaults here?
    HNSessionToken token = (HNSessionToken) [[NSUserDefaults standardUserDefaults] objectForKey:@"HNKit:SessionToken"];
    NSString *password = [[NSUserDefaults standardUserDefaults] objectForKey:@"HNKit:SessionPassword"];
    NSString *name = [[NSUserDefaults standardUserDefaults] objectForKey:@"HNKit:SessionName"];
    
    if (name != nil && token != nil) {
        HNSession *session = [[HNSession alloc] initWithUsername:name password:password token:token];
        [self setCurrentSession:[session autorelease]];
    } else {
        [self setCurrentSession:nil];
    }
}

- (id)initWithUsername:(NSString *)username password:(NSString *)password_ token:(NSString *)token_ {
    if ((self = [super init])) {
        HNUser *user_ = [[HNUser alloc] initWithIdentifier:username];
        
        [self setUser:[user_ autorelease]];
        [self setToken:token_];
        [self setPassword:password_];
        [self setLoaded:YES];
    }
    
    return self;
}

- (void)sessionAuthenticatorDidRecieveFailure:(HNSessionAuthenticator *)authenticator_ {
    [authenticator autorelease];
    authenticator = nil;
}

- (void)sessionAuthenticator:(HNSessionAuthenticator *)authenticator_ didRecieveToken:(HNSessionToken)token_ {
    [authenticator autorelease];
    authenticator = nil;
    
    [self setToken:token_];
}

- (void)reloadToken {
    // XXX: maybe this should return an error code
    if (authenticator != nil) return;
    
    authenticator = [[HNSessionAuthenticator alloc] initWithUsername:[user identifier] password:password];
    [authenticator setDelegate:self];
    [authenticator beginAuthenticationRequest];
}

- (BOOL)isAnonymous {
    return NO;
}

- (void)performSubmission:(HNSubmission *)submission {
    HNAPISubmission *api = [[HNAPISubmission alloc] initWithSubmission:submission];
    [api performSubmissionWithToken:[self token]];
    [api autorelease];
}

@end
