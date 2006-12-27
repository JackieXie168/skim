#!/bin/sh
# the next line restats using tclsh \
exec tclsh "$0" "$@"
#
# This file is part of the YAZ toolkit
# Copyright (c) Index Data 1996-2006
# See the file LICENSE for details.
#
# $Id: csvtosrw.tcl,v 1.3 2006/05/23 20:43:37 adam Exp $
#
# Converts a CSV file with SRW diagnostics to C+H file for easy
# maintenance
#
# $Id: csvtosrw.tcl,v 1.3 2006/05/23 20:43:37 adam Exp $

source [lindex $argv 0]/csvtodiag.tcl

csvtodiag [list [lindex $argv 0]/srw.csv diagsrw.c [lindex $argv 0]/../include/yaz/diagsrw.h] srw {}
