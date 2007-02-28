#!/bin/sh
# the next line restats using tclsh \
exec tclsh "$0" "$@"
#
# This file is part of the YAZ toolkit
# Copyright (c) Index Data 1996-2007
# See the file LICENSE for details.
#
# $Id: csvtosru_update.tcl,v 1.2 2007/01/03 08:42:15 adam Exp $
#
# Converts a CSV file with SRU update diagnostics to C+H file for easy
# maintenance
#
# $Id: csvtosru_update.tcl,v 1.2 2007/01/03 08:42:15 adam Exp $

source [lindex $argv 0]/csvtodiag.tcl

csvtodiag [list [lindex $argv 0]/sru_update.csv diagsru_update.c [lindex $argv 0]/../include/yaz/diagsru_update.h] sru_update {}
