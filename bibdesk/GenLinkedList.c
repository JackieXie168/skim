/*
	File:		GenLinkedList.c
	
	Contains:	Linked List utility routines

	Disclaimer:	IMPORTANT:  This Apple software is supplied to you by Apple Computer, Inc.
				("Apple") in consideration of your agreement to the following terms, and your
				use, installation, modification or redistribution of this Apple software
				constitutes acceptance of these terms.  If you do not agree with these terms,
				please do not use, install, modify or redistribute this Apple software.

				In consideration of your agreement to abide by the following terms, and subject
				to these terms, Apple grants you a personal, non-exclusive license, under Apple�s
				copyrights in this original Apple software (the "Apple Software"), to use,
				reproduce, modify and redistribute the Apple Software, with or without
				modifications, in source and/or binary forms; provided that if you redistribute
				the Apple Software in its entirety and without modifications, you must retain
				this notice and the following text and disclaimers in all such redistributions of
				the Apple Software.  Neither the name, trademarks, service marks or logos of
				Apple Computer, Inc. may be used to endorse or promote products derived from the
				Apple Software without specific prior written permission from Apple.  Except as
				expressly stated in this notice, no other rights or licenses, express or implied,
				are granted by Apple herein, including but not limited to any patent rights that
				may be infringed by your derivative works or by other works in which the Apple
				Software may be incorporated.

				The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO
				WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED
				WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A PARTICULAR
				PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN
				COMBINATION WITH YOUR PRODUCTS.

				IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
				CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
				GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
				ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION
				OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY OF CONTRACT, TORT
				(INCLUDING NEGLIGENCE), STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN
				ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

	Copyright � 2003-2004 Apple Computer, Inc., All Rights Reserved
*/

#include "GenLinkedList.h"

#pragma mark --- Data Structures ---

	/* This is the internal data structure for the nodes in the linked list.  		*/
	/*																				*/
	/* Note: The memory pointed to by pNext is owned by the list and is disposed of	*/
	/* in DestroyList.  It should not be disposed of in any other way.				*/
	/*																				*/
	/* Note: The memory pointed to by pData is owned by the caller of the linked	*/
	/* list.  The caller is responsible for disposing of this memory.  This can be	*/
	/* done	by simply implementing a DisposeDataProc that will be called on each	*/
	/* node in the list, giving the caller a chance to dispose of any memory		*/
	/* created.  The DisposeDataProc is called from DestroyList						*/ 
struct GenNode
{
	struct	GenNode				*pNext;	/* Pointer to the next node in the list		*/
			GenDataPtr			 pData;	/* The data for this node, owned by caller	*/
};
typedef struct GenNode GenNode;

#pragma mark --- List Implementation ---

	/* Initializes the given GenLinkedList to an empty list.  This MUST be			*/
	/* called before any operations are performed on the list, otherwise bad things	*/
	/* will	happen.																	*/
void 		InitLinkedList( GenLinkedList *pList, DisposeDataProcPtr disposeProcPtr)
{
	if( pList == NULL )
		return;

	pList->pHead = pList->pTail = NULL;
	pList->NumberOfItems	= 0;
	pList->DisposeProcPtr	= disposeProcPtr;
}

	/* returns the current number of items in the given list.						*/
	/* If pList == NULL, it returns 0												*/
ItemCount	GetNumberOfItems( GenLinkedList *pList )
{
	return (pList) ? pList->NumberOfItems : 0;
}
	
	/* Creates a new node, containing pData, and adds it to the tail of pList.		*/
	/* Note: if an error occurs, pList is unchanged.								*/
OSErr		AddToTail( GenLinkedList *pList, void *pData )
{
	OSErr		err			= paramErr;
	GenNode		*tmpNode	= NULL;
	
	if( pList == NULL || pData == NULL )
		return err;

		/* create memory for new node, if this fails we _must_ bail	*/
	err = ( ( tmpNode = (GenNode*) NewPtr( sizeof( GenNode ) ) ) != NULL ) ? noErr : MemError();
	if( err == noErr )
	{
		tmpNode->pData = pData;									/* Setup new node				*/
		tmpNode->pNext = NULL;
		
		if( pList->pTail != NULL )								/* more then one item already	*/
			((GenNode*) pList->pTail)->pNext = (void*) tmpNode;	/* so append to tail			*/
		else
			pList->pHead = (void*) tmpNode; 					/* no items, so adjust head		*/
		
		pList->pTail			= (void*) tmpNode;
		pList->NumberOfItems	+= 1;
	}	
	
	return err;
}

	/* Takes pSrcList and inserts it into pDestList at the location pIter points to.			*/
	/* The lists must have the same DisposeProcPtr, but the Data can be different.  If pSrcList	*/
	/* is empty, it does nothing and just returns												*/
	/*																							*/
	/* If pIter == NULL, insert pSrcList before the head										*/
	/* else If pIter == pTail, append pSrcList to the tail										*/
	/* else insert pSrcList in the middle somewhere 											*/
	/* On return: pSrcList is cleared and is an empty list.										*/
	/*            The data that was owned by pSrcList is now owned by pDestList					*/
void		InsertList( GenLinkedList *pDestList, GenLinkedList *pSrcList, GenIteratorPtr pIter )
{
	if( pDestList		== NULL || pSrcList			== NULL ||
		pSrcList->pHead	== NULL || pSrcList->pTail	== NULL ||
		pDestList->DisposeProcPtr != pSrcList->DisposeProcPtr )
		return;
		
	if( pDestList->pHead == NULL && pDestList->pTail == NULL )	/* empty list					*/
	{
		pDestList->pHead = pSrcList->pHead;
		pDestList->pTail = pSrcList->pTail;
	}
	else if( pIter == NULL )									/* insert before head			*/
	{				
			/* attach the list	*/
		((GenNode*)pSrcList->pTail)->pNext = pDestList->pHead;
			/* fix up head		*/
		pDestList->pHead = pSrcList->pHead;
	}
	else if( pIter == pDestList->pTail )						/* append to tail				*/
	{
			/* attach the list	*/
		((GenNode*)pDestList->pTail)->pNext = pSrcList->pHead;
			/* fix up tail		*/
		pDestList->pTail = pSrcList->pTail;
	}
	else														/* insert in middle somewhere	*/
	{
		GenNode	*tmpNode = ((GenNode*)pIter)->pNext;
		((GenNode*)pIter)->pNext = pSrcList->pHead;
		((GenNode*)pSrcList->pTail)->pNext = tmpNode;
	}

	pDestList->NumberOfItems += pSrcList->NumberOfItems;		/* sync up NumberOfItems		*/
	
	InitLinkedList( pSrcList, NULL);							/* reset the source list		*/
}

	/* Goes through the list and disposes of any memory we allocated.  Calls the DisposeProcPtr,*/
	/* if it exists, to give the caller a chance to free up their memory						*/
void		DestroyList( GenLinkedList	*pList )
{
	GenIteratorPtr	pIter		= NULL,
					pNextIter	= NULL;

	if( pList == NULL )
		return;
	
	for( InitIterator( pList, &pIter ), pNextIter = pIter; pIter != NULL; pIter = pNextIter )
	{
		Next( &pNextIter );	/* get the next node before we blow away the link */
		
		if( pList->DisposeProcPtr != NULL )
			CallDisposeDataProc( pList->DisposeProcPtr, GetData( pIter ) );
		DisposePtr( (char*) pIter );
	}
	
	InitLinkedList( pList, NULL);		
}

/*#############################################*/
/*#############################################*/
/*#############################################*/

#pragma mark -
#pragma mark --- Iterator Implementation ---

	/* Initializes pIter to point at the head of pList							*/
	/* This must be called before performing any operations with pIter			*/
void		InitIterator( GenLinkedList *pList, GenIteratorPtr *pIter )
{
	if( pList != NULL && pIter != NULL )
		*pIter = pList->pHead;
}

	/* On return, pIter points to the next node in the list.  NULL if its gone	*/
	/* past the end of the list													*/
void		Next( GenIteratorPtr *pIter )
{
	if( pIter != NULL )
		*pIter = ((GenNode*)*pIter)->pNext;
}

	/* Returns the data of the current node that pIter points to				*/
GenDataPtr	GetData( GenIteratorPtr pIter )
{
	return ( pIter != NULL ) ? ((GenNode*)pIter)->pData : NULL;
}
