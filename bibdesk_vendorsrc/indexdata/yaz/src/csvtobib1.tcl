#!/bin/sh
# the next line restats using tclsh \
exec tclsh "$0" "$@"
#
# This file is part of the YAZ toolkit
# Copyright (c) Index Data 1996-2007
# See the file LICENSE for details.
#
# $Id: csvtobib1.tcl,v 1.4 2007/01/03 08:42:15 adam Exp $
#
# Converts a CSV file with Bib-1 diagnostics to C+H file for easy
# maintenance
#
# $Id: csvtobib1.tcl,v 1.4 2007/01/03 08:42:15 adam Exp $

source [lindex $argv 0]/csvtodiag.tcl

csvtodiag [list [lindex $argv 0]/bib1.csv diagbib1.c [lindex $argv 0]/../include/yaz/diagbib1.h] bib1 diagbib1_str
