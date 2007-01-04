#!/bin/sh
# $Id: tstmarccol.sh,v 1.2 2006/12/15 19:28:47 adam Exp $
# Tests reading of a bunch of non-roman UTF-8 ISO2709 and see if
# we can encode it in MARC-8
#
# Reads marccol?.u8.marc files , Generates marccol?.u8.{1,2}.lst
srcdir=${srcdir:-.}
ecode=0
for f in ${srcdir}/marccol?.u8.marc; do

    fb=`basename ${f} .marc`

    DIFF=${fb}.1.lst.diff
    NEW=${fb}.1.lst.new
    OLD=${srcdir}/${fb}.1.lst
    ../util/yaz-marcdump -f utf-8 -t utf-8 $f >$NEW
    if test $? != "0"; then
	echo "$f: yaz-marcdump returned error"
	ecode=1
	break
    elif test -f $OLD; then
        if diff $OLD $NEW >$DIFF; then
	    rm $DIFF
	    rm $NEW
	else
	    echo "$f: $NEW and $OLD differ"
	    ecode=1
	fi
    else
	echo "$f: Making test result $OLD for the first time"
	mv $NEW $OLD
    fi

    filem=`echo $fb | sed 's/u8/m8/'`.marc
    ../util/yaz-marcdump -o marc -f utf8 -t marc8 $f >$filem

    DIFF=${fb}.2.lst.diff
    NEW=${fb}.2.lst.new
    OLD=${srcdir}/${fb}.2.lst
    ../util/yaz-marcdump -f marc8 -t utf-8 $filem >$NEW
    if test $? != "0"; then
	echo "$f: yaz-marcdump returned error"
	ecode=1
	break
    elif test -f $OLD; then
        if diff $OLD $NEW >$DIFF; then
	    rm $DIFF
	    rm $NEW
	    rm $filem
	else
	    echo "$f: $NEW and $OLD differ"
	    ecode=1
	fi
    else
	echo "$f: Making test result $OLD for the first time"
	mv $NEW $OLD
	rm $filem
    fi
done
exit $ecode

# Local Variables:
# mode:shell-script
# sh-indentation: 2
# sh-basic-offset: 4
# End:
