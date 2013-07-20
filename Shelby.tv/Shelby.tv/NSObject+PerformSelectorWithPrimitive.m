//
//  NSObject+PerformSelectorWithPrimitive.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 7/20/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "NSObject+PerformSelectorWithPrimitive.h"

@implementation NSObject (PerformSelectorWithPrimitive)

- (NSInvocation *)createInvocationForSelector:(SEL)aSelector withPrimitive:(void *)primitive1 withPrimitive:(void *)primitive2
{
    if (!aSelector) {
        raise(NSInvalidArgumentException);
    }

    // "An NSInvocation is an Objective-C message rendered static, that is, it is an action turned into an object"
    // As we know, Objective-C does stuff by sending messages.  Normally, you send those messages in your code
    // by writing stuff like [alienSpaceship shootMissles:14 atEnemy:earth];  Think of that as a verb.
    // An NSInvocation allows you treat the verb of sending the message as a noun.  You can virtually hold it
    // in your hand.  It's like telling your dog to fetch by talking into a tape recorder.  You can hand that
    // tape recorder to your dog sitter and they can replay it whenever they like, over and over.
    //
    // But NSInvocation has a limitation.  It gets set up in a certain format and that format can't change.
    // This format (described by NSMethodSignature) specifies the number and type of the arguments and the return value.
    // For example, the signature "- (BOOL)hasKids:(NSInteger)count;" has one argument, of type NSInteger,
    // and a return value of BOOL.
    //
    // So, we first get our NSMethodSignature using the class method +instanceMethodSignatureForSelector:
    // and we then create an NSInvocation formatted for that particular method signature.
    NSInvocation *invoc = [NSInvocation invocationWithMethodSignature:[[self class] instanceMethodSignatureForSelector:aSelector]];

    // The creators of NSInvocation has big things in mind, so they made it very flexible.  This had the
    // unfortunate consequence of making it complex.  Even though we set the method *signature* when we
    // create the NSInvocation, that doesn't specify the particulars.  We still have to tell the NSInvocation
    // what the message is (ie. the selector) and to whom we should send the message (ie. target)...
    [invoc setTarget:self];
    [invoc setSelector:aSelector];

    // Finally, we need to give the NSInvocation the actual arguments to use.  This is the heart and reason for
    // this category.  Below we give the NSInvocation primitive arguments.  You can only use
    // -performSelector:withObject: with full blown Objective-C objects, can't pass it an int.  But you can
    // give NSInvocation anything you want, baby!  This is the fun part.  But it can be tricky to understand...

    // setArgument:
    //  "This method copies the *contents* of buffer as the argument at index."
    //  In other words, it makes its own copy of whatever you're pointing to.
    //
    //  So, if you're pointing to an object on the heap (ie. MyClass*), then this will copy
    //  the entire object!  You don't want that, so you pass a pointer to a pointer (ie. MyClass**) in that case.
    //  And then this method makes a copy of your MyClass* pointer, so it points to the same MyClass as you do.
    //
    //  But, if you're pointing to a primitive (ie. NSInteger*), then this will copy the primitive.
    //  And that's probably what you want.  Indeed, you don't want to copy a pointer to something on the
    //  stack if there's a chance that it gets poped off the stack.
    //
    //  This all begs the question, how do I make a pointer to something I already have a reference to?
    //  You prefix the pointer with an ampersand to get the pointer's memory address.
    //  So, if you have a pointer to a class (ie. MyClass* p), then &p will be a pointer to the pointer (ie. MyClass **).
    //  However, a reference to a primitive (ie. NSUInteger i) is not a pointer, the value is stored right there.
    //  In that case, &i will be a pointer to the primitive (ie. NSUInteger*).
    // atIndex:
    //  "Indices 0 and 1 indicate the hidden arguments self and _cmd"
    [invoc setArgument:primitive1 atIndex:2];
    if (primitive2) {
        [invoc setArgument:primitive2 atIndex:3];
    }
    return invoc;
}

- (id)performSelector:(SEL)aSelector withPrimitive:(void *)primitive afterDelay:(NSTimeInterval)delay
{
    NSInvocation *invoc = [self createInvocationForSelector:aSelector withPrimitive:primitive withPrimitive:NULL];
    [invoc performSelector:@selector(invoke) withObject:nil afterDelay:delay];
    return self;
}

- (id)performSelector:(SEL)aSelector withPrimitive:(void *)primitive1 withPrimitive:(void *)primitive2 afterDelay:(NSTimeInterval)delay
{
    NSInvocation *invoc = [self createInvocationForSelector:aSelector withPrimitive:primitive1 withPrimitive:primitive2];
    [invoc performSelector:@selector(invoke) withObject:nil afterDelay:delay];
    return self;
}

@end
