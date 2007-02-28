# Config File for ILL
# $Id: ill.tcl,v 1.1 2003/10/27 12:21:30 adam Exp $
# ----------------------------------------------------------
# Prefix Specifications
#  
#    1: C function prefix
#    2: C type prefix
#    3: C preprocessor prefix

# Default prefix
set default-prefix {ill_ ILL_ ILL_}

# ----------------------------------------------------------
set m ISO-10161-ILL-1

# Filename
set filename($m) ill-core

# Header initialization code
set init($m,h) "
"

# Header body code
set body($m,h) "
#ifdef __cplusplus
extern \"C\" \{
#endif

#ifdef __cplusplus
\}
#endif
"

# C body code
set body($m,c) "
"

# Some mappings - that map ill_ILL_<name> to ill_<name>
set map($m,ILL-APDU) APDU
set map($m,ILL-Request) Request
set map($m,ILL-Answer) Answer
set map($m,ILL-String) String
set map($m,ILL-APDU-Type) APDU_Type
set map($m,ILL-Service-Type) Service_Type
set map($m,Service_Date_Time_0) Service_Date_this
set map($m,Service_Date_Time_1) Service_Date_original
set map($m,Overdue_0) Overdue_ExtensionS
set membermap($m,APDU,ILL-Request) {APDU_ILL_Request illRequest}
set membermap($m,APDU,ILL-Answer) {APDU_ILL_Answer illAnswer}

# ----------------------------------------------------------
set m Z39.50-extendedService-ItemOrder-ItemRequest-1
# Filename
set filename($m) item-req

# Mappings of a few basic types
proc asnBasicPrintableString {} {
    return {odr_visiblestring char}
}

proc asnBasicANY {} {
    return {odr_any Odr_any}
}
