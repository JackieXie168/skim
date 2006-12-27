#!/bin/sh
# the next line restats using tclsh \
exec tclsh "$0" "$@"
#
# This file is part of the YAZ toolkit
# Copyright (c) Index Data 1996-2006
# See the file LICENSE for details.
#
# $Id: csvtosru_update.tcl,v 1.1 2006/10/27 11:22:09 adam Exp $
#
# Converts a CSV file with SRU update diagnostics to C+H file for easy
# maintenance
#
# $Id: csvtosru_update.tcl,v 1.1 2006/10/27 11:22:09 adam Exp $

source [lindex $argv 0]/csvtodiag.tcl

csvtodiag [list [lindex $argv 0]/sru_update.csv diagsru_update.c [lindex $argv 0]/../include/yaz/diagsru_update.h] sru_update {}
