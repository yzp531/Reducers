//  Copyright (c) 2014 Rob Rix. All rights reserved.

#import "REDMap.h"
#import "REDReducer.h"

#pragma mark Map

id<REDIterable, REDReducible> REDMap(id<REDIterable, REDReducible> collection, REDMapBlock map) {
	return [REDReducer reducerWithReducible:collection transformer:^(REDReducingBlock reduce) {
		// Map each object before reducing.
		return ^(id into, id each) {
			return reduce(into, map(each));
		};
	}];
}

l3_addTestSubjectTypeWithFunction(REDMap)
l3_test(&REDMap) {
	id<REDIterable, REDReducible> collection = @[ @"a", @"b", @"c" ];
	REDReducingBlock append = ^(NSArray *into, id each) {
		return [into arrayByAddingObject:each];
	};
	NSArray *into = @[];
	l3_expect([REDMap(collection, REDIdentityMapBlock) red_reduce:into usingBlock:append]).to.equal(collection);
	
	__block NSInteger effects = 0;
	REDMapBlock withEffects = ^(id each) {
		++effects;
		return [each stringByAppendingString:each];
	};
	l3_expect(REDMap(collection, withEffects)).not.to.equal(nil);
	l3_expect(effects).to.equal(@0);
	
	NSArray *transformed = @[@"aa", @"bb", @"cc"];
	l3_expect([REDMap(collection, withEffects) red_reduce:into usingBlock:append]).to.equal(transformed);
	l3_expect(effects).to.equal(@3);
}


#pragma mark Flatten map

id<REDIterable, REDReducible> REDFlattenMap(id<REDIterable, REDReducible> collection, REDFlattenMapBlock map) {
	return [REDReducer reducerWithReducible:collection transformer:^REDReducingBlock(REDReducingBlock reduce) {
		// Reduce into each mapped object.
		return ^(id into, id each) {
			return [map(each) red_reduce:into usingBlock:reduce];
		};
	}];
}

l3_test(&REDFlattenMap) {
	id<REDIterable, REDReducible> nestedCollection = @[ @[ @4, @3 ], @[ @2, @1 ] ];
	REDReducingBlock append = ^(NSArray *into, id each) {
		return [into arrayByAddingObject:each];
	};
	NSArray *into = @[];
	id<REDIterable, REDReducible> flattened = @[ @4, @3, @2, @1 ];
	l3_expect([REDFlattenMap(nestedCollection, REDIdentityMapBlock) red_reduce:into usingBlock:append]).to.equal(flattened);
	
	REDFlattenMapBlock wrap = ^(id each) { return @[ each ]; };
	l3_expect([REDFlattenMap(flattened, wrap) red_reduce:into usingBlock:append]).to.equal(flattened);
}


#pragma mark Identity

REDMapBlock const REDIdentityMapBlock = ^(id x) {
	return x;
};

l3_test(REDIdentityMapBlock) {
	id specific = [NSObject new];
	l3_expect(REDIdentityMapBlock(specific)).to.equal(specific);
}
