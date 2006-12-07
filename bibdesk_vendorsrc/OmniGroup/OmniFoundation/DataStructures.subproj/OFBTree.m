// Copyright 2001-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "OFBTree.h"

#import <Foundation/Foundation.h>
#import <OmniBase/rcsid.h>

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/DataStructures.subproj/OFBTree.m 68913 2005-10-03 19:36:19Z kc $")


/*"
Each node in the btree has some non-zero number of elements (depending upon whether it is the root node or not different constraints apply).  If there are N elements, there are always N+1 pointers to children nodes.
"*/
typedef struct _OFBTreeNode {
    unsigned int elementCount;
    struct _OFBTreeNode *childZero;
    unsigned char contents[0];
} OFBTreeNode;


// Given a element count and size, how many bytes of the node have been used:
//    Size of the header
//  + Size of each element * number of elements
//  + Size of child pointer * (number of elements)
#define OFBT_SPACE_USED(elementSize,elementCount) \
( \
    sizeof(OFBTreeNode) + \
    (elementSize) * (elementCount) + \
    sizeof(OFBTreeNode *) * ((elementCount)) \
)


void OFBTreeInit(OFBTree *tree,
                 size_t nodeSize,
                 size_t elementSize,
                 OFBTreeNodeAllocator allocator,
                 OFBTreeNodeDeallocator deallocator,
                 OFBTreeElementComparator compare)
{    
    memset(tree, 0, sizeof(*tree));
    tree->nodeSize = nodeSize;
    tree->elementSize = elementSize;
    
    // Compute the elements per node.  Take the node size and subtract the space for the header and the extra child pointer.  Finally, divide by the space per element (the element size itself and the pointer for children after it).
    tree->elementsPerNode = (nodeSize - sizeof(OFBTreeNode) - sizeof(OFBTreeNode *)) / (elementSize + sizeof(OFBTreeNode *));
    
    tree->nodeAllocator = allocator;
    tree->nodeDeallocator = deallocator;
    tree->elementCompare = compare;
    
    // We always have at least one node
    tree->root = allocator(tree);
    tree->root->elementCount = 0;
    tree->root->childZero = NULL;
    tree->nodeStackDepth = 0;
}

static void _OFBTreeDestroyNode(OFBTree *tree, OFBTreeNode *node)
{
    // UNDONE
    // for (each child in this node) {
    //   _OFBTreeDestroyNode(tree, the child);
    // }
    tree->nodeDeallocator(tree, node);
}

void OFBTreeDestroy(OFBTree *tree)
{
    _OFBTreeDestroyNode(tree, tree->root);
}

static inline void *_OFBTreeElementAtIndex(OFBTree *btree, OFBTreeNode *node, unsigned int index)
{
    return node->contents + index * (btree->elementSize + sizeof(OFBTreeNode *));
}

static inline OFBTreeNode *_OFBTreeValueLesserChildNode(OFBTree *btree, void *value)
{
    return *(OFBTreeNode **)(value - sizeof(OFBTreeNode *));
}

static inline OFBTreeNode *_OFBTreeValueGreaterChildNode(OFBTree *btree, void *value)
{
    return *(OFBTreeNode **)(value + btree->elementSize);
}


/*" Scan a node for the closest match greater than or equal to a value.
"*/
static BOOL _OFBTreeScan(OFBTree *btree, void *value)
{
    unsigned int low = 0;
    unsigned int range = 1;
    unsigned int test = 0;
    OFBTreeNode *node;
    void *testValue;
    int testResult;
    
    node = btree->nodeStack[btree->nodeStackDepth];
    while(node->elementCount >= range) // range is the lowest power of 2 > count
        range <<= 1;

    while(range) {
        test = low + (range >>= 1);
        if (test >= node->elementCount)
            continue;
        testValue = _OFBTreeElementAtIndex(btree, node, test);
        testResult = btree->elementCompare(btree, value, testValue);
        if (!testResult) {
            btree->selectionStack[btree->nodeStackDepth] = testValue;
            return YES;
        } else if (testResult > 0) {
            low = test + 1;
        }
    }
    btree->selectionStack[btree->nodeStackDepth] = _OFBTreeElementAtIndex(btree, node, low);
    return NO;
}

/*" Internal find method.
"*/
static BOOL _OFBTreeFind(OFBTree *btree, void *value)
{
    OFBTreeNode *childNode;
    
    btree->nodeStack[0] = btree->root;
    btree->nodeStackDepth = 0;
    while(1) {
        if (_OFBTreeScan(btree, value)) {
            return YES;
        } else if ((childNode = _OFBTreeValueLesserChildNode(btree, btree->selectionStack[btree->nodeStackDepth]))) {
            btree->nodeStack[++btree->nodeStackDepth] = childNode;
        } else {
            return NO;
        }
    }
}

/*" Copies wordCount words from source to dest starting with the first word and working forwards.
"*/
static inline void
OFWordCopyForward(void *s, void *d, unsigned int wordCount)
{
    unsigned long *source = s;
    unsigned long *dest = d;
    unsigned long *end = source + wordCount;

    while(source != end)
        *dest++ = *source++;
}

/*" Copies wordCount words from source to dest starting with the wordCount-1'th word and working backwards.
"*/
static inline void
OFWordCopyBackward(void *s, void *d, unsigned int wordCount)
{
    unsigned long *source = s;
    unsigned long *dest = d;
    unsigned long *end = source + wordCount - 1;

    dest += wordCount - 1;
    source--;
    while(source != end)
        *dest-- = *end--;
}

static void _OFBTreeSimpleAdd(OFBTree *btree, OFBTreeNode *node, void *insertionPoint, void *value)
{
    void *end;
    
    end = (void *)node->contents + (btree->elementSize + sizeof(OFBTreeNode *)) * node->elementCount;
    OFWordCopyBackward(insertionPoint, insertionPoint + btree->elementSize + sizeof(OFBTreeNode *), (end - insertionPoint) / sizeof(int));
    OFWordCopyForward(value, insertionPoint, (btree->elementSize + sizeof(OFBTreeNode *)) / sizeof(int));
    node->elementCount++;
}

/*" Split the current node and promote the center.
"*/
static void _OFBTreeSplitAdd(OFBTree *btree, void *value)
{
    OFBTreeNode *node;
    void *insertionPoint;
    OFBTreeNode *right;
    unsigned int insertionIndex;
    BOOL needsPromotion;

    node = btree->nodeStack[btree->nodeStackDepth];
    insertionPoint = btree->selectionStack[btree->nodeStackDepth];
    insertionIndex = (insertionPoint - (void *)node->contents) / (btree->elementSize + sizeof(OFBTreeNode *));
    
    // build the new right hand side
    right = btree->nodeAllocator(btree);
    right->elementCount = node->elementCount / 2;
    node->elementCount -= right->elementCount;

    if (insertionIndex <= node->elementCount) {
        // the insertion point is in the center or left so just copy over the whole right side
        OFWordCopyForward(_OFBTreeElementAtIndex(btree, node, node->elementCount), right->contents, right->elementCount * (btree->elementSize + sizeof(OFBTreeNode *)) / sizeof(unsigned int));
        
        if (insertionIndex == node->elementCount) {
            needsPromotion = NO;
        } else {
            // the insertion point isn't in the center so the value needs to be copied into the left side
            _OFBTreeSimpleAdd(btree, node, insertionPoint, value);
            needsPromotion = YES;
        }
    } else {
        // the insertion point is in the right side so copy before insertion, then new value, then after insertion
        OFWordCopyForward(_OFBTreeElementAtIndex(btree, node, node->elementCount), right->contents, (insertionIndex - node->elementCount) * (btree->elementSize + sizeof(OFBTreeNode *)) / sizeof(unsigned int));
        insertionPoint = _OFBTreeElementAtIndex(btree, right, insertionIndex - node->elementCount);
        OFWordCopyForward(value, insertionPoint, (btree->elementSize + sizeof(OFBTreeNode *)) / sizeof(int));
        OFWordCopyForward(_OFBTreeElementAtIndex(btree, node, insertionIndex), insertionPoint + btree->elementSize + sizeof(OFBTreeNode *), (node->elementCount + right->elementCount - insertionIndex) * (btree->elementSize + sizeof(OFBTreeNode *)) / sizeof(unsigned int));
        right->elementCount++;
        needsPromotion = YES;
    }
    
    if (needsPromotion) {
        // the insertion point isn't in the center so the new promoted value needs to go into the buffer
        void *promotion = _OFBTreeElementAtIndex(btree, node, node->elementCount - 1);
        
        OFWordCopyForward(promotion, value, (btree->elementSize + sizeof(OFBTreeNode *)) / sizeof(int));
        node->elementCount--;
    }
    
    // child zero on the right hand side is the greater side of the promoted value
    right->childZero = *(OFBTreeNode **)(value + btree->elementSize);
    // set the greater child on the promoted value to be the new right-hand side node
    *(OFBTreeNode **)(value + btree->elementSize) = right;
}

static BOOL _OFBTreeAdd(OFBTree *btree, void *value)
{
    OFBTreeNode *node;
    
    node = btree->nodeStack[btree->nodeStackDepth];

    if (node->elementCount < btree->elementsPerNode) {
        // Simple addition - add to the current node
        _OFBTreeSimpleAdd(btree, node, btree->selectionStack[btree->nodeStackDepth], value);
        return NO;
    } 
    
    // Otherwise split and return YES to tell the caller there is more work to do 
    _OFBTreeSplitAdd(btree, value);
    return YES;
}

/*"
Copies the bytes pointed to by value and puts them in the tree.
"*/
void OFBTreeInsert(OFBTree *btree, void *value)
{
    void *promotionBuffer;

    if (_OFBTreeFind(btree, value))
        return; // the value is already in the tree
    
    promotionBuffer = alloca(btree->elementSize + sizeof(OFBTreeNode *));
    OFWordCopyForward(value, promotionBuffer, btree->elementSize / sizeof(unsigned int));
    *(OFBTreeNode **)(promotionBuffer + btree->elementSize) = NULL;
    
    while(_OFBTreeAdd(btree, promotionBuffer)) {
        if (btree->nodeStackDepth) {
            // if we're deep in the tree go up to the next higher level and try again
            btree->nodeStackDepth--;
        } else {
            // otherwise we need a new root
            OFBTreeNode *newRoot;
            
            newRoot = btree->nodeAllocator(btree);
            newRoot->elementCount = 1;
            newRoot->childZero = btree->root;
            OFWordCopyForward(promotionBuffer, newRoot->contents, (btree->elementSize + sizeof(OFBTreeNode *)) / sizeof(int));
            
            btree->root = newRoot;
            break;
        }
    }
}


/*"
Finds the element in the tree that compares the same to the given bytes and deletes it.  Returns YES if the element is found and deleted, NO otherwise.
"*/

BOOL OFBTreeDelete(OFBTree *btree, void *value)
{
    OFBTreeNode *node, *childNode;
    unsigned int fullLength;
    BOOL replacePointerWithGreaterChild;
    
    if (!_OFBTreeFind(btree, value))
        return NO;
        
    node = btree->nodeStack[btree->nodeStackDepth];
    value = btree->selectionStack[btree->nodeStackDepth];

    // if there is a lesser child
    if ((childNode = _OFBTreeValueLesserChildNode(btree, value))) {
        void *replacement;

        // walk down the right-most subtree to find the greatest value less than the original
        do {
            node = btree->nodeStack[++btree->nodeStackDepth] = childNode;
            replacement = _OFBTreeElementAtIndex(btree, node, node->elementCount - 1);
            btree->selectionStack[btree->nodeStackDepth] = replacement + btree->elementSize + sizeof(OFBTreeNode *);
        } while ((childNode = _OFBTreeValueGreaterChildNode(btree, replacement)));
        
        // Replace original with greater value
        OFWordCopyForward(replacement, value, btree->elementSize / sizeof(int));
        replacePointerWithGreaterChild = NO;
    } else {
        // Simple removal
        fullLength = (btree->elementSize + sizeof(OFBTreeNode *)) * node->elementCount;
        OFWordCopyForward(value + btree->elementSize, value - sizeof(OFBTreeNode *), (((void *)node->contents + fullLength) - (value + btree->elementSize)) / sizeof(int));
        replacePointerWithGreaterChild = YES;
    }
    
    if (--node->elementCount == 0) {
        if (btree->nodeStackDepth) {
            // if we removed the last element in this node and it isn't the root, deallocate it
            value = btree->selectionStack[--btree->nodeStackDepth];
            if (replacePointerWithGreaterChild)
                *(OFBTreeNode **)(value - sizeof(OFBTreeNode *)) = *(OFBTreeNode **)((void *)node->contents + btree->elementSize);
            else
                *(OFBTreeNode **)(value - sizeof(OFBTreeNode *)) = node->childZero;
        } else if (node->childZero) {
            // the root is now empty, but there is content farther down, so move the root down
            btree->root = node->childZero;
            btree->nodeDeallocator(btree, node);
        } 
    }
    return YES;
}

/*"
Returns a pointer to the element in the tree that compares equal to the given value.  Any data in the returned pointer that is used in the element comparison function should not be modified (since that would invalidate its position in the tree).
"*/
void *OFBTreeFind(OFBTree *btree, void *value)
{
    if (_OFBTreeFind(btree, value))
        return btree->selectionStack[btree->nodeStackDepth];
    else
        return NULL;
}

/*"
Calls the supplied callback once for each element in the tree, passing the element and the argument passed to OFBTreeEnumerator().  Currently, this only does a forward enumeration of the tree.
"*/
// TODO:  Later we could have a version of this that takes a min element, max element (either of which can be NULL) and a direction.  We'd then find the path to the two elements that don't break the range (i.e., the given min/max elements might not actually be in the tree) and start the enumeration from the starting path, continuing until we hit the ending element.

static void _OFBTreeEnumerateNode(OFBTree *tree, OFBTreeNode *node, OFBTreeEnumeratorCallback callback, void *arg)
{
    unsigned int elementIndex;
    
    if (node->childZero)
        _OFBTreeEnumerateNode(tree, node->childZero, callback, arg);
    
    for (elementIndex = 0; elementIndex < node->elementCount; elementIndex++) {
        void *value;
        OFBTreeNode *child;
        
        value = _OFBTreeElementAtIndex(tree, node, elementIndex);
        callback(tree, value, arg);
        
        // This should be non-NULL for all but possibliy the last child, or if we are a leaf
        child = _OFBTreeValueGreaterChildNode(tree, value);
        if (child)
            _OFBTreeEnumerateNode(tree, child, callback, arg);
    }
}

void OFBTreeEnumerate(OFBTree *tree, OFBTreeEnumeratorCallback callback, void *arg)
{
    _OFBTreeEnumerateNode(tree, tree->root, callback, arg);
}


/*"
Finds the element in the tree that compares the same to the given bytes and returns a pointer to the closest element that compares less than the given value.  If there is no such element, NULL is returned.  Any data in the returned pointer that is used in the element comparison function should not be modified (since that would invalidate its position in the tree).
"*/
void *OFBTreePrevious(OFBTree *btree, void *value)
{
    OFBTreeNode *node, *childNode;
    int depth;
    
    if (!_OFBTreeFind(btree, value))
        return NULL;

    node = btree->nodeStack[btree->nodeStackDepth];
    value = btree->selectionStack[btree->nodeStackDepth];
    
    if ((childNode = _OFBTreeValueLesserChildNode(btree, value))) {
        // if there is a lesser child node, get the greatest value in that subtree
        do {
            node = childNode;
            value = _OFBTreeElementAtIndex(btree, node, node->elementCount - 1);
        } while((childNode = _OFBTreeValueGreaterChildNode(btree, value)));
        
        return value;
    } else {
        // else if there is a parent node and this is the first element in this node, walk up the tree
        depth = btree->nodeStackDepth;
        while (depth && value == (void *)node->contents) {
            node = btree->nodeStack[--depth];
            value = btree->selectionStack[depth];
        }
        
        // if we found a node that has a predecessor, it's the next highest value
        if (value != (void *)node->contents)
            return value - btree->elementSize - sizeof(OFBTreeNode *);
        
        // otherwise we reached the root and there was never a predecessor so there is no next
        return NULL; 
    }
}

/*"
Finds the element in the tree that compares the same to the given bytes and returns a pointer to the closest element that compares greater than the given value.  If there is no such element, NULL is returned.  Any data in the returned pointer that is used in the element comparison function should not be modified (since that would invalidate its position in the tree).
"*/
void *OFBTreeNext(OFBTree *btree, void *value)
{
    OFBTreeNode *node, *childNode;
    int depth;

    if (!_OFBTreeFind(btree, value))
        return NULL;

    node = btree->nodeStack[btree->nodeStackDepth];
    value = btree->selectionStack[btree->nodeStackDepth];
    
    if ((childNode = _OFBTreeValueGreaterChildNode(btree, value))) {
        // if there is a greater child node, get the least value in that subtree
        do {
            node = childNode;
            value = (void *)node->contents;
        } while((childNode = _OFBTreeValueLesserChildNode(btree, value)));
        
        return value;
    } else if (value < _OFBTreeElementAtIndex(btree, node, node->elementCount - 1)) {
        return value + btree->elementSize + sizeof(OFBTreeNode *);
    } else if (!btree->nodeStackDepth) {
        return NULL;
    } else {
        // else if there is a parent node and this is past the last element in this node, walk up the tree
        depth = btree->nodeStackDepth;
        do { 
            node = btree->nodeStack[--depth];
            value = btree->selectionStack[depth];
        } while (depth && value > _OFBTreeElementAtIndex(btree, node, node->elementCount - 1));

        // if we were always past the end of the node there's no successor
        if (value > _OFBTreeElementAtIndex(btree, node, node->elementCount - 1))
            return NULL;
        
        return value; 
    }
}



