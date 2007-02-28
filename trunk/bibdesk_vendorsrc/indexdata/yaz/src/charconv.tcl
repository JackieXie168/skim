#!/bin/sh
# the next line restarts using tclsh \
if [ -f /usr/local/bin/tclsh8.4 ]; then exec tclsh8.4 "$0" "$@"; else exec tclsh "$0" "$@"; fi
#
# $Id: charconv.tcl,v 1.18 2006/12/17 15:34:11 adam Exp $

proc usage {} {
    puts {charconv.tcl: [-p prefix] [-s split] [-o ofile] file ... }
    exit 1
}

proc preamble_trie {ofilehandle ifiles ofile} {
    set f $ofilehandle

    set totype {unsigned }

    puts $f "/** \\file $ofile"
    puts $f "    \\brief Character conversion, generated from [lindex $ifiles 0]"
    puts $f ""
    puts $f "    Generated automatically by charconv.tcl"
    puts $f "*/"
    puts $f "\#include <string.h>"
    puts $f "
        struct yaz_iconv_trie_flat {
            char from\[6\];
            unsigned combining : 1;
            $totype to : 24;
        };
        struct yaz_iconv_trie_dir {
            int ptr : 15;
            unsigned combining : 1;
            $totype to : 24;
        };
        
        struct yaz_iconv_trie {
            struct yaz_iconv_trie_flat *flat;
            struct yaz_iconv_trie_dir *dir;
        };
    "
    puts $f {
        static unsigned long lookup(struct yaz_iconv_trie **ptrs, int ptr, unsigned char *inp,
                                    size_t inbytesleft, size_t *no_read, int *combining)
        {
            struct yaz_iconv_trie *t = (ptr > 0) ? ptrs[ptr-1] : 0;
            if (!t || inbytesleft < 1)
                return 0;
            if (t->dir)
            {
                size_t ch = inp[0] & 0xff;
                unsigned long code =
                lookup(ptrs, t->dir[ch].ptr, inp+1, inbytesleft-1, no_read, combining);
                if (code)
                {
                    (*no_read)++;
                    return code;
                }
                if (t->dir[ch].to)
                {
                    code = t->dir[ch].to;
		    *combining = t->dir[ch].combining;
                    *no_read = 1;
                    return code;
                }
            }
            else
            {
                struct yaz_iconv_trie_flat *flat = t->flat;
                while (flat->to)
                {
                    size_t len = strlen(flat->from);
                    if (len <= inbytesleft)
                    {
                        if (memcmp(flat->from, inp, len) == 0)
                        {
                            *no_read = len;
			    *combining = flat->combining;
                            return flat->to;
                        }
                    }
                    flat++;
                }
            }
            return 0;
        }
    }
}

proc reset_trie {} {
    global trie

    foreach x [array names trie] {
	unset trie($x)
    }

    set trie(no) 1
    set trie(size) 0
    set trie(max) 0
    set trie(split) 50
    set trie(prefix) {}
}

proc ins_trie {from to combining codename} {
    global trie
    if {![info exists trie(no)]} {
        set trie(no) 1
        set trie(size) 0
	set trie(max) 0
    }
    if {$trie(max) < $to} {
	set trie(max) $to
    }
    incr trie(size)
    ins_trie_r [split $from] $to $combining $codename 0
}

proc split_trie {this} {
    global trie
    set trie($this,type) d
    foreach e $trie($this,content) {
        set from [lindex $e 0]
        set to [lindex $e 1]
	set combining [lindex $e 2]
	set codename [lindex $e 3]
        
        set ch [lindex $from 0]
        set rest [lrange $from 1 end]
        
        if {[llength $rest]} {
            if {![info exist trie($this,ptr,$ch)]} {
                set trie($this,ptr,$ch) $trie(no)
                incr trie(no)
            }
            ins_trie_r $rest $to $combining $codename $trie($this,ptr,$ch)
        } else {
            set trie($this,to,$ch) $to
            set trie($this,combining,$ch) $combining
            set trie($this,codename,$ch) $codename
        }
    }
    set trie($this,content) missing
}

proc ins_trie_r {from to combining codename this} {
    global trie

    if {![info exist trie($this,type)]} {
        set trie($this,type) f
    }
    if {$trie($this,type) == "f"} {
        lappend trie($this,content) [list $from $to $combining $codename]
        
        # split ?
        if {[llength $trie($this,content)] > $trie(split)} {
            split_trie $this
            return [ins_trie_r $from $to $combining $codename $this]
        }
    } else {
        set ch [lindex $from 0]
        set rest [lrange $from 1 end]

        if {[llength $rest]} {
            if {![info exist trie($this,ptr,$ch)]} {
                set trie($this,ptr,$ch) $trie(no)
                incr trie(no)
            }
            ins_trie_r $rest $to $combining $codename $trie($this,ptr,$ch)
        } else {
	    if {![info exist trie($this,to,$ch)]} {
                set trie($this,to,$ch) $to
                set trie($this,combining,$ch) $combining
                set trie($this,codename,$ch) $codename
	    }
        }
    }
}

proc dump_trie {ofilehandle} {
    global trie

    set f $ofilehandle

    puts $f "/* TRIE: size $trie(size) */"

    set this $trie(no)
    while { [incr this -1] >= 0 } {
        puts $f "/* PAGE $this */"
        if {$trie($this,type) == "f"} {
            puts $f "struct yaz_iconv_trie_flat $trie(prefix)page${this}_flat\[\] = \{"
            foreach m $trie($this,content) {
                puts -nonewline $f "  \{\""
                foreach d [lindex $m 0] {
                    puts -nonewline $f "\\x$d"
                }
                puts -nonewline $f "\", [lindex $m 2], 0x[lindex $m 1]"
		set v [lindex $m 3]
                puts $f "\}, /* $v */"
            }
            puts $f "  \{\"\", 0\}"
            puts $f "\};"
            puts $f "struct yaz_iconv_trie $trie(prefix)page${this} = \{"
            puts $f "  $trie(prefix)page${this}_flat, 0"
            puts $f "\};"
        } else {
            puts $f "struct yaz_iconv_trie_dir $trie(prefix)page${this}_dir\[256\] = \{"
            for {set i 0} {$i < 256} {incr i} {
                puts -nonewline $f "  \{"
                set ch [format %02X $i]
                set null 1
                if {[info exist trie($this,ptr,$ch)]} {
                    puts -nonewline $f "[expr $trie($this,ptr,$ch)+1], "
                    set null 0
                } else {
                    puts -nonewline $f "0, "
                }
                if {[info exist trie($this,combining,$ch)]} {
                    puts -nonewline $f "$trie($this,combining,$ch), "
                } else {
                    puts -nonewline $f "0, "
                }
                if {[info exist trie($this,to,$ch)]} {
                    puts -nonewline $f "0x$trie($this,to,$ch)\}"
                    set null 0
                } else {
                    puts -nonewline $f "0\}"
                }
		if {[info exist trie($this,codename,$ch)]} {
		    set v $trie($this,codename,$ch)
                    puts -nonewline $f " /* $v */"
                }
                if {$i < 255} {
                    puts $f ","
                } else {
                    puts $f ""
                }
            }
            puts $f "\};"
            puts $f "struct yaz_iconv_trie $trie(prefix)page${this} = \{"
            puts $f "  0, $trie(prefix)page${this}_dir"
            puts $f "\};"
        }
    }

    puts $f "struct yaz_iconv_trie *$trie(prefix)ptrs \[\] = {"
    for {set this 0} {$this < $trie(no)} {incr this} {
	puts $f " &$trie(prefix)page$this,"
    }
    puts $f "0, };"
    puts $f ""

    puts $f "unsigned long yaz_$trie(prefix)_conv
            (unsigned char *inp, size_t inbytesleft, size_t *no_read, int *combining)
        {
            unsigned long code;
            
            code = lookup($trie(prefix)ptrs, 1, inp, inbytesleft, no_read, combining);
            if (!code)
            {
                *no_read = 1;
            }
            return code;
        }
    "
}

proc readfile {fname ofilehandle prefix omits reverse} {
    global trie

    set marc_lines 0
    set ucs_lines 0
    set utf_lines 0
    set altutf_lines 0
    set codename_lines 0
    set lineno 0
    set f [open $fname r]
    set tablenumber x
    set combining 0
    set codename {}
    set altutf {}
    while {1} {
        incr lineno
        set cnt [gets $f line]
        if {$cnt < 0} {
            break
        }
	if {[regexp {<entitymap>} $line s]} {
	    reset_trie
	    set trie(prefix) "${prefix}"
	} elseif {[regexp {</entitymap>} $line s]} {
	    dump_trie $ofilehandle
	} elseif {[regexp {<character hex="([^\"]*)".*<unientity>([0-9A-Fa-f]*)</unientity>} $line s hex ucs]} {
	    ins_trie $hex $ucs $combining {}
	    unset hex
	} elseif {[regexp {<codeTable .*number="([0-9]+)"} $line s tablenumber]} {
	    reset_trie
	    set trie(prefix) "${prefix}_$tablenumber"
	    set combining 0
	} elseif {[regexp {</codeTable>} $line s]} {
	    if {[lsearch $omits $tablenumber] == -1} {
		dump_trie $ofilehandle
	    }
	} elseif {[regexp {</code>} $line s]} {
	    if {[string length $ucs]} {
		if {$reverse} {
		    for {set i 0} {$i < [string length $utf]} {incr i 2} {
			lappend hex [string range $utf $i [expr $i+1]]
		    }
		    # puts "ins_trie $hex $marc
		    ins_trie $hex $marc $combining $codename
		    unset hex

		} else {
		    for {set i 0} {$i < [string length $marc]} {incr i 2} {
			lappend hex [string range $marc $i [expr $i+1]]
		    }
		    # puts "ins_trie $hex $ucs"
		    ins_trie $hex $ucs $combining $codename
		    unset hex
		}
	    }
	    if {$reverse && [string length $marc]} {
		for {set i 0} {$i < [string length $altutf]} {incr i 2} {
		    lappend hex [string range $altutf $i [expr $i+1]]
		}
		if {[info exists hex]} {
		    ins_trie $hex $marc $combining $codename
		    unset hex
		}
	    }
	    set marc {}
	    set uni {}
	    set codename {}
	    set combining 0
	    set altutf {}
	} elseif {[regexp {<marc>([0-9A-Fa-f]*)</marc>} $line s marc]} {
	    incr marc_lines
	} elseif {[regexp {<name>(.*)</name>} $line s codename]} {
	    incr codename_lines
	} elseif {[regexp {<name>(.*)} $line s codename]} {
	    incr codename_lines
	    incr lineno
	    set cnt [gets $f line]
	    if {$cnt < 0} {
		break
	    }
	    if {[regexp {(.*)</name>} $line s codename_ex]} {
		set codename "${codename} ${codename_ex}"
	    }
	} elseif {[regexp {<isCombining>true</isCombining>} $line s]} {
	    set combining 1
	} elseif {[regexp {<ucs>([0-9A-Fa-f]*)</ucs>} $line s ucs]} {
	    incr ucs_lines
	} elseif {[regexp {<utf-8>([0-9A-Fa-f]*)</utf-8>} $line s utf]} {
	    incr utf_lines
	} elseif {[regexp {<altutf-8>([0-9A-Fa-f]*)</altutf-8>} $line s altutf]} {
	    incr altutf_lines
	}
    }
    close $f
}

set verbose 0
set ifile {}
set ofile out.c
set prefix {c}
set reverse_map 0
# Parse command line
set l [llength $argv]
set i 0
set omits {}
while {$i < $l} {
    set arg [lindex $argv $i]
    switch -glob -- $arg {
        -v {
            incr verbose
        }
        -s {
            if {[string length $arg]} {
                set arg [lindex $argv [incr i]]
            }
            set trie(split) $arg
        }
        -p {
            if {[string length $arg]} {
                set arg [lindex $argv [incr i]]
            }
            set prefix $arg
        }
	-o {
            if {[string length $arg]} {
                set arg [lindex $argv [incr i]]
            }
            set ofile $arg
	}
	-O {
            if {[string length $arg]} {
                set arg [lindex $argv [incr i]]
            }
            lappend omits $arg
	}
	-r {
	    set reverse_map 1
	}
        default {
	    lappend ifiles $arg
        }
    }
    incr i
}
if {![info exists ifiles]} {
    puts "charconv.tcl: missing input file(s)"
    usage
}

set ofilehandle [open $ofile w]
preamble_trie $ofilehandle $ifiles $ofile

foreach ifile $ifiles {
    readfile $ifile $ofilehandle $prefix $omits $reverse_map
}
close $ofilehandle


