#!/bin/sh
# $Id: tstcql.sh,v 1.4 2004/11/16 22:44:31 adam Exp $
srcdir=${srcdir:-.}
oIFS="$IFS"
IFS='
'
secno=0
testno=0
comment=0
ecode=0
test -f ${srcdir}/cqlsample || exit 1
test -d cql || mkdir cql
for f in `cat ${srcdir}/cqlsample`; do
	if echo $f | grep '^#' >/dev/null; then
		comment=1
	else
		if test "$comment" = "1"; then
			secno=`expr $secno + 1`
			testno=0
		fi
		comment=0
		testno=`expr $testno + 1`
		OUT1=${srcdir}/cql/$secno.$testno.out
		ERR1=${srcdir}/cql/$secno.$testno.err
		OUT2=cql/$secno.$testno.out.tmp
		ERR2=cql/$secno.$testno.err.tmp
		DIFF=cql/$secno.$testno.diff
		../util/cql2xcql "$f" >$OUT2 2>$ERR2
		if test -f $OUT1 -a -f $ERR1; then
			if diff $OUT1 $OUT2 >$DIFF; then
				rm $DIFF
				rm $OUT2
			else
				echo "diff out $secno $testno $f"
				cat $DIFF
				ecode=1	
			fi
			if diff $ERR1 $ERR2 >$DIFF; then
				rm $DIFF
				rm $ERR2
			else
				echo "diff err $secno $testno $f"
				cat $DIFF
				ecode=1
			fi
		else
			echo "making test $secno $testno $f"
			mv $OUT2 $OUT1
			mv $ERR2 $ERR1
			ecode=1
		fi	
	fi		
done
IFS="$oIFS"
exit $ecode
