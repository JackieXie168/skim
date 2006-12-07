
/* stack.c - code that implements a stack to handle braces and recursive calls
	         created by environments, and open and closing-braces

Copyright (C) 1994-2002 The Free Software Foundation

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

This file is available from http://sourceforge.net/projects/latex2rtf/

Authors:
    1994-1997 Ralf Schlatterbeck
    1998-2000 Georg Lehner
    2001-2002 Scott Prahl
*/

#include <stdlib.h>
#include "main.h"
#include "stack.h"

#define STACKSIZE 1000

static int stack[STACKSIZE];
static int top = 0;
int BraceLevel = 0;

int BasicPush(int lev, int brack);
int BasicPop(int *lev, int *brack);
int getStackRecursionLevel(void);

void myprintStack(void)
{
    int i, lev, brack;

    fprintf(stderr, "\nStack Status top=%d\n", top);
    i = 0;
    while (2 * i < top) {
        lev = stack[2 * i + 1];
        brack = stack[2 * i + 2];
        i++;

        fprintf(stderr, " #%d lev=%d bracket=%d\n", i, lev, brack);
    }
}

void InitializeStack(void)

/******************************************************************************
  purpose: pushes 0,1 and 1,1 on the stack to start things out
 ******************************************************************************/
{
    BraceLevel = 0;
    RecursionLevel = 1;
    PushLevels();
    BraceLevel = 1;
}

int BasicPush(int lev, int brack)

/******************************************************************************
  purpose: pushes the parameters lev and brack on the stack
   return: top of stack
 ******************************************************************************/
{

/*	diagnostics(5,"pushing rec=%d and bra=%d on  stack",lev,brack);*/
    ++top;
    stack[top] = lev;
    ++top;
    stack[top] = brack;

    if (top >= STACKSIZE)
        diagnostics(ERROR, "Nesting too deep.  latex2rtf bug, if file TeXs properly");

    return top;
}

int BasicPop(int *lev, int *brack)

/******************************************************************************
  purpose: pops the parameters lev and brack from the stack
  return: top of stack
 ******************************************************************************/
{
    *brack = stack[top];
    --top;
    *lev = stack[top];
    --top;

    if (top < 0)
        diagnostics(ERROR, "Nesting problem.  latex2rtf bug, if file TeXs properly");

/*	diagnostics(5,"popped rec=%d and bra=%d off stack",*lev,*brack); */
    return top;
}

void PushLevels(void)

/******************************************************************************
  purpose: wrapper to hide BraceLevel from rest of program 
 ******************************************************************************/
{
    diagnostics(5, "PushLevels");
    CleanStack();
    (void) BasicPush(RecursionLevel, BraceLevel);
    /* myprintStack(); */
}

int PopLevels(void)

/******************************************************************************
  purpose: wrapper to hide BraceLevel from rest of program 
 ******************************************************************************/
{
    int level;

    (void) BasicPop(&level, &BraceLevel);
    return level;
}

int getStackRecursionLevel(void)

/******************************************************************************
  purpose: returns the recursion level for the current BraceLevel
 ******************************************************************************/
{
    int PopLevel, PopBrack, PPopLevel, PPopBrack, size;

    PPopLevel = RecursionLevel;
    PPopBrack = BraceLevel;
    size = BasicPop(&PopLevel, &PopBrack);
    while ((size = BasicPop(&PopLevel, &PopBrack)) >= 0) {
        if (PopBrack < BraceLevel) {
            break;
        }
        PPopLevel = PopLevel;
        PPopBrack = PopBrack;
    }                           /* while */
    (void) BasicPush(PopLevel, PopBrack);   /* push back */
    (void) BasicPush(PPopLevel, BraceLevel);
    return PPopLevel;
}

void CleanStack(void)

/******************************************************************************
  purpose: removes multiple identical copies on top of stack
 ******************************************************************************/
{
    int PopLevel, PopBrack, PPopLevel, PPopBrack;

    diagnostics(5, "Cleaning Stack");

    if (top < 4)
        return;

    BasicPop(&PPopLevel, &PPopBrack);
    BasicPop(&PopLevel, &PopBrack);

    while (PPopLevel == PopLevel && PPopBrack == PopBrack && top > 0)
        BasicPop(&PopLevel, &PopBrack);

    BasicPush(PopLevel, PopBrack);
    if (PPopLevel != PopLevel || PPopBrack != PopBrack)
        BasicPush(PPopLevel, PPopBrack);

    /* myprintStack(); */
}

void PushBrace(void)

/******************************************************************************
  purpose: sets up the stack so that a closing brace will cause all commands
           enclosed by the braces to be completed
 ******************************************************************************/
{

/*	diagnostics(5,"Pushing Brace Level");*/
    BasicPush(RecursionLevel, BraceLevel);
    ++BraceLevel;
}

int PopBrace(void)

/******************************************************************************
  purpose: to return the recursion level of the matching open brace
           search down through the stack for the lowest recursionlevel
           that matches the current bracelevel-1.  
 ******************************************************************************/
{
    int PopLevel, PopBrack, PPopLevel;

    diagnostics(6, "Popping Brace Level");
    BraceLevel--;
    PPopLevel = RecursionLevel;

    BasicPop(&PopLevel, &PopBrack);
    while (PopBrack >= BraceLevel) {
        if (PopLevel < PPopLevel)
            PPopLevel = PopLevel;
        BasicPop(&PopLevel, &PopBrack);
    }

    BasicPush(PopLevel, PopBrack);  /* push back */
    BasicPush(PPopLevel, BraceLevel);

    return PPopLevel;
}

/* 
The stack keeps track of the RecursionLevel and BraceLevel for each command.

   RecursionLevel is the number of recursive calls to Convert()
   BraceLevel     is the number of open braces '{'
   
The top of stack has the current values of RecursionLevel and BraceLevel.

The initial value of RecusionLevel is 1 
The initial value of BraceLevel is 0

Before each command and before each opening brace the current values
of RecursionLevel and BraceLevel are pushed on the stack.  

Each closing brace triggers a search of the stack to find
the RecursionLevel for the matching open brace.

It is the lowest
RecursionLevel with the same BraceLevel as now (after subtract of the 1
closing brace found). The initial values for the RecursionLevel and
BraceLevel (1,0) always remain on the stack.  

The begin document command Pushes 1,1

For example:

{ Text {\em Text} Text }
1      2 3	    4      5

1 Push 12
2 Push 13
3 Push 23
4 Bracket 3->2 Pop 23 Pop 13 Pop 12 Pop 11 -found- Push back 11
  return to level 1
5 Bracket 2->1
  return to level 1 = current -> no return

\mbox{\em Text}
1    2 3      4
1 Push 11  RecursionLevel+1
2 Push 22
3 Push 32
4 Bracket 2->1 Pop 32 Pop 22 Pop 11 -found-
  return to level 1 from level 3 -> double return from convert

The necessary Push before every command increases the stack size. If the
commands don't include a recursive call the stack is not cleaned up.
After every TranslateCommand-function the stack is cleaned

For example:

\ldots \LaTeX \today \TeX
 1	2      3      4
1 Push 11
2 Push 11
3 Push 11
4 Push 11
The clean-up loop pops till the values are not identical and pushes back the last
Therefore 11 will only occur once on the stack.
*/
