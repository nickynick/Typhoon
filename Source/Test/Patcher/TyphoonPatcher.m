////////////////////////////////////////////////////////////////////////////////
//
//  TYPHOON FRAMEWORK
//  Copyright 2013, Jasper Blues & Contributors
//  All Rights Reserved.
//
//  NOTICE: The authors permit you to use, modify, and distribute this file
//  in accordance with the terms of the license agreement accompanying it.
//
////////////////////////////////////////////////////////////////////////////////

#import "TyphoonDefinition.h"
#import "TyphoonPatcher.h"
#import "TyphoonPatchObjectFactory.h"
#import "TyphoonInitializer.h"
#import "OCLogTemplate.h"
#import "TyphoonDefinition+InstanceBuilder.h"
#import "TyphoonComponentFactory.h"
#import "TyphoonDefinition+Infrastructure.h"

@implementation TyphoonPatcher

/* ====================================================================================================================================== */
#pragma mark - Initialization & Destruction

- (id)init
{
    self = [super init];
    if (self)
    {
        _patches = [[NSMutableDictionary alloc] init];
    }
    return self;
}

/* ====================================================================================================================================== */
#pragma mark - Interface Methods

- (void)patchDefinitionWithKey:(NSString*)key withObject:(TyphoonPatchObjectCreationBlock)objectCreationBlock
{
    [_patches setObject:objectCreationBlock forKey:key];
}

- (void)patchDefinition:(TyphoonDefinition*)definition withObject:(TyphoonPatchObjectCreationBlock)objectCreationBlock
{
    [self patchDefinitionWithKey:definition.key withObject:objectCreationBlock];
}

/* ====================================================================================================================================== */
#pragma mark - Protocol Methods

- (void)postProcessComponentFactory:(TyphoonComponentFactory*)factory
{
    for (TyphoonDefinition* newDefinition in [self newDefinitionsToRegister])
    {
        [factory register:newDefinition];
    }

    for (TyphoonDefinition* definition in [factory registry])
    {
        [self patchDefinitionIfNeeded:definition];
    }
}

- (NSArray*)newDefinitionsToRegister
{
    NSMutableArray* newDefinitions = [[NSMutableArray alloc] init];
    for (NSString* key in [_patches allKeys])
    {
        TyphoonDefinition* patchFactory =
                [[TyphoonDefinition alloc] initWithClass:[TyphoonPatchObjectFactory class] key:[self patchFactoryNameForKey:key]];
        patchFactory.initializer = [[TyphoonInitializer alloc] initWithSelector:@selector(initWithCreationBlock:)];
        [patchFactory.initializer injectWithObjectInstance:[_patches objectForKey:key]];
        [newDefinitions addObject:patchFactory];
    }
    return [newDefinitions copy];
}

- (void)patchDefinitionIfNeeded:(TyphoonDefinition*)definition
{
    id patchObject = [_patches objectForKey:definition.key];
    if (patchObject)
    {
        LogDebug(@"Patching component with key: '%@'", definition.key);
        [definition setFactoryReference:[self patchFactoryNameForKey:definition.key]];
        [definition setInitializer:[[TyphoonInitializer alloc] initWithSelector:@selector(patchObject)]];
        [definition setValue:nil forKey:@"injectedProperties"];
    }
}

/* ====================================================================================================================================== */
#pragma mark - Private Methods

- (NSString*)patchFactoryNameForKey:(NSString*)key
{
    return [NSString stringWithFormat:@"%@$$$patcher", key];
}


@end