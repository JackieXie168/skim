/** \file ./../include/yaz/diagbib1.h
    \brief Diagnostics: Generated by csvtodiag.tcl from ./bib1.csv */

#include <yaz/yconfig.h>

#ifndef YAZ_DIAG_bib1_H
#define YAZ_DIAG_bib1_H
YAZ_BEGIN_CDECL
YAZ_EXPORT const char *yaz_diag_bib1_str(int code);
YAZ_EXPORT const char *diagbib1_str(int code);
#define YAZ_BIB1_PERMANENT_SYSTEM_ERROR 1
#define YAZ_BIB1_TEMPORARY_SYSTEM_ERROR 2
#define YAZ_BIB1_UNSUPP_SEARCH 3
#define YAZ_BIB1_TERMS_ONLY_EXCLUSION_STOP_WORDS 4
#define YAZ_BIB1_TOO_MANY_ARGUMENT_WORDS 5
#define YAZ_BIB1_TOO_MANY_BOOLEAN_OPERATORS 6
#define YAZ_BIB1_TOO_MANY_TRUNCATED_WORDS 7
#define YAZ_BIB1_TOO_MANY_INCOMPLETE_SUBFIELDS 8
#define YAZ_BIB1_TRUNCATED_WORDS_TOO_SHORT 9
#define YAZ_BIB1_INVALID_FORMAT_FOR_RECORD_NUMBER_SEARCH_TERM_ 10
#define YAZ_BIB1_TOO_MANY_CHARS_IN_SEARCH_STATEMENT 11
#define YAZ_BIB1_TOO_MANY_RECORDS_RETRIEVED 12
#define YAZ_BIB1_PRESENT_REQUEST_OUT_OF_RANGE 13
#define YAZ_BIB1_SYSTEM_ERROR_IN_PRESENTING_RECORDS 14
#define YAZ_BIB1_RECORD_NO_AUTHORIZED_TO_BE_SENT_INTERSYSTEM 15
#define YAZ_BIB1_RECORD_EXCEEDS_PREFERRED_MESSAGE_SIZE 16
#define YAZ_BIB1_RECORD_EXCEEDS_MAXIMUM_RECORD_SIZE 17
#define YAZ_BIB1_RESULT_SET_UNSUPP_AS_A_SEARCH_TERM 18
#define YAZ_BIB1_ONLY_SINGLE_RESULT_SET_AS_SEARCH_TERM_SUPPORTED 19
#define YAZ_BIB1_ONLY_ANDING_OF_A_SINGLE_RESULT_SET_AS_SEARCH_TERM_ 20
#define YAZ_BIB1_RESULT_SET_EXISTS_AND_REPLACE_INDICATOR_OFF 21
#define YAZ_BIB1_RESULT_SET_NAMING_UNSUPP 22
#define YAZ_BIB1_COMBI_OF_SPECIFIED_DATABASES_UNSUPP 23
#define YAZ_BIB1_ELEMENT_SET_NAMES_UNSUPP 24
#define YAZ_BIB1_SPECIFIED_ELEMENT_SET_NAME_NOT_VALID_FOR_SPECIFIED_ 25
#define YAZ_BIB1_ONLY_A_SINGLE_ELEMENT_SET_NAME_SUPPORTED 26
#define YAZ_BIB1_RESULT_SET_NO_LONGER_EXISTS_UNILATERALLY_DELETED_BY_ 27
#define YAZ_BIB1_RESULT_SET_IS_IN_USE 28
#define YAZ_BIB1_ONE_OF_THE_SPECIFIED_DATABASES_IS_LOCKED 29
#define YAZ_BIB1_SPECIFIED_RESULT_SET_DOES_NOT_EXIST 30
#define YAZ_BIB1_RESOURCES_EXHAUSTED_NO_RESULTS_AVAILABLE 31
#define YAZ_BIB1_RESOURCES_EXHAUSTED_UNPREDICTABLE_PARTIAL_RESULTS_ 32
#define YAZ_BIB1_RESOURCES_EXHAUSTED_VALID_SUBSET_OF_RESULTS_AVAILABLE 33
#define YAZ_BIB1_UNSPECIFIED_ERROR 100
#define YAZ_BIB1_ACCESS_CONTROL_FAILURE 101
#define YAZ_BIB1_SEC_CHAL_REQUIRED_BUT_COULDNT_BE_ISSUED_REQUEST_ 102
#define YAZ_BIB1_SEC_CHAL_REQUIRED_BUT_COULDNT_BE_ISSUED_RECORD_NOT_ 103
#define YAZ_BIB1_SEC_CHAL_FAILED_RECORD_NOT_INCLUDED 104
#define YAZ_BIB1_TERMINATED_BY_NEGATIVE_CONTINUE_RESPONSE 105
#define YAZ_BIB1_NO_ABSTRACT_SYNTAXES_AGREED_TO_FOR_THIS_RECORD 106
#define YAZ_BIB1_QUERY_TYPE_UNSUPP 107
#define YAZ_BIB1_MALFORMED_QUERY 108
#define YAZ_BIB1_DATABASE_UNAVAILABLE 109
#define YAZ_BIB1_OPERATOR_UNSUPP 110
#define YAZ_BIB1_TOO_MANY_DATABASES_SPECIFIED 111
#define YAZ_BIB1_TOO_MANY_RESULT_SETS_CREATED 112
#define YAZ_BIB1_UNSUPP_ATTRIBUTE_TYPE 113
#define YAZ_BIB1_UNSUPP_USE_ATTRIBUTE 114
#define YAZ_BIB1_UNSUPP_VALUE_FOR_USE_ATTRIBUTE 115
#define YAZ_BIB1_USE_ATTRIBUTE_REQUIRED_BUT_NOT_SUPPLIED 116
#define YAZ_BIB1_UNSUPP_RELATION_ATTRIBUTE 117
#define YAZ_BIB1_UNSUPP_STRUCTURE_ATTRIBUTE 118
#define YAZ_BIB1_UNSUPP_POSITION_ATTRIBUTE 119
#define YAZ_BIB1_UNSUPP_TRUNCATION_ATTRIBUTE 120
#define YAZ_BIB1_UNSUPP_ATTRIBUTE_SET 121
#define YAZ_BIB1_UNSUPP_COMPLETENESS_ATTRIBUTE 122
#define YAZ_BIB1_UNSUPP_ATTRIBUTE_COMBI 123
#define YAZ_BIB1_UNSUPP_CODED_VALUE_FOR_TERM 124
#define YAZ_BIB1_MALFORMED_SEARCH_TERM 125
#define YAZ_BIB1_ILLEGAL_TERM_VALUE_FOR_ATTRIBUTE 126
#define YAZ_BIB1_UNPARSABLE_FORMAT_FOR_UN_NORMALIZED_VALUE 127
#define YAZ_BIB1_ILLEGAL_RESULT_SET_NAME 128
#define YAZ_BIB1_PROX_SEARCH_OF_SETS_UNSUPP 129
#define YAZ_BIB1_ILLEGAL_RESULT_SET_IN_PROX_SEARCH 130
#define YAZ_BIB1_UNSUPP_PROX_RELATION 131
#define YAZ_BIB1_UNSUPP_PROX_UNIT_CODE 132
#define YAZ_BIB1_PROX_UNSUPP_WITH_THIS_ATTRIBUTE_COMBI 201
#define YAZ_BIB1_UNSUPP_DISTANCE_FOR_PROX 202
#define YAZ_BIB1_ORDERED_FLAG_UNSUPP_FOR_PROX 203
#define YAZ_BIB1_ONLY_ZERO_STEP_SIZE_SUPPORTED_FOR_SCAN 205
#define YAZ_BIB1_SPECIFIED_STEP_SIZE_UNSUPP_FOR_SCAN 206
#define YAZ_BIB1_CANNOT_SORT_ACCORDING_TO_SEQUENCE 207
#define YAZ_BIB1_NO_RESULT_SET_NAME_SUPPLIED_ON_SORT 208
#define YAZ_BIB1_GENERIC_SORT_UNSUPP_DATABASE_SPECIFIC_SORT_ONLY_ 209
#define YAZ_BIB1_DATABASE_SPECIFIC_SORT_UNSUPP 210
#define YAZ_BIB1_TOO_MANY_SORT_KEYS 211
#define YAZ_BIB1_DUP_SORT_KEYS 212
#define YAZ_BIB1_UNSUPP_MISSING_DATA_ACTION 213
#define YAZ_BIB1_ILLEGAL_SORT_RELATION 214
#define YAZ_BIB1_ILLEGAL_CASE_VALUE 215
#define YAZ_BIB1_ILLEGAL_MISSING_DATA_ACTION 216
#define YAZ_BIB1_SEGMENTATION_CANNOT_GUARANTEE_RECORDS_WILL_FIT_IN_ 217
#define YAZ_BIB1_ES_PACKAGE_NAME_ALREADY_IN_USE 218
#define YAZ_BIB1_ES_NO_SUCH_PACKAGE_ON_MODIFY_DELETE 219
#define YAZ_BIB1_ES_QUOTA_EXCEEDED 220
#define YAZ_BIB1_ES_EXTENDED_SERVICE_TYPE_UNSUPP 221
#define YAZ_BIB1_ES_PERMISSION_DENIED_ON_ES_ID_NOT_AUTHORIZED 222
#define YAZ_BIB1_ES_PERMISSION_DENIED_ON_ES_CANNOT_MODIFY_OR_DELETE 223
#define YAZ_BIB1_ES_IMMEDIATE_EXECUTION_FAILED 224
#define YAZ_BIB1_ES_IMMEDIATE_EXECUTION_UNSUPP_FOR_THIS_SERVICE 225
#define YAZ_BIB1_ES_IMMEDIATE_EXECUTION_UNSUPP_FOR_THESE_PARAMETERS 226
#define YAZ_BIB1_NO_DATA_AVAILABLE_IN_REQUESTED_RECORD_SYNTAX 227
#define YAZ_BIB1_SCAN_MALFORMED_SCAN 228
#define YAZ_BIB1_TERM_TYPE_UNSUPP 229
#define YAZ_BIB1_SORT_TOO_MANY_INPUT_RESULTS 230
#define YAZ_BIB1_SORT_INCOMPATIBLE_RECORD_FORMATS 231
#define YAZ_BIB1_SCAN_TERM_LIST_UNSUPP 232
#define YAZ_BIB1_SCAN_UNSUPP_VALUE_OF_POSITION_IN_RESPONSE 233
#define YAZ_BIB1_TOO_MANY_INDEX_TERMS_PROCESSED 234
#define YAZ_BIB1_DATABASE_DOES_NOT_EXIST 235
#define YAZ_BIB1_ACCESS_TO_SPECIFIED_DATABASE_DENIED 236
#define YAZ_BIB1_SORT_ILLEGAL_SORT 237
#define YAZ_BIB1_RECORD_NOT_AVAILABLE_IN_REQUESTED_SYNTAX 238
#define YAZ_BIB1_RECORD_SYNTAX_UNSUPP 239
#define YAZ_BIB1_SCAN_RESOURCES_EXHAUSTED_LOOKING_FOR_SATISFYING_TERMS 240
#define YAZ_BIB1_SCAN_BEGINNING_OR_END_OF_TERM_LIST 241
#define YAZ_BIB1_SEGMENTATION_MAX_SEGMENT_SIZE_TOO_SMALL_TO_SEGMENT_ 242
#define YAZ_BIB1_PRESENT_ADDITIONAL_RANGES_PARAMETER_UNSUPP 243
#define YAZ_BIB1_PRESENT_COMP_SPEC_PARAMETER_UNSUPP 244
#define YAZ_BIB1_TYPE_1_QUERY_RESTRICTION_RESULTATTR_OPERAND_UNSUPP 245
#define YAZ_BIB1_TYPE_1_QUERY_COMPLEX_ATTRIBUTEVALUE_UNSUPP 246
#define YAZ_BIB1_TYPE_1_QUERY_ATTRIBUTESET_AS_PART_OF_ATTRIBUTEELEMENT_ 247
#define YAZ_BIB1_MALFORMED_APDU 1001
#define YAZ_BIB1_ES_EXTERNAL_FORM_OF_ITEM_ORDER_REQUEST_UNSUPP 1002
#define YAZ_BIB1_ES_RESULT_SET_ITEM_FORM_OF_ITEM_ORDER_REQUEST_UNSUPP 1003
#define YAZ_BIB1_ES_EXTENDED_SERVICES_UNSUPP_UNLESS_ACCESS_CONTROL_IS_IN_ 1004
#define YAZ_BIB1_RESPONSE_RECORDS_IN_SEARCH_RESPONSE_UNSUPP 1005
#define YAZ_BIB1_RESPONSE_RECORDS_IN_SEARCH_RESPONSE_NOT_POSSIBLE_FOR_ 1006
#define YAZ_BIB1_NO_EXPLAIN_SERVER_ADDINFO_POINTERS_TO_SERVERS_THAT_HAVE_ 1007
#define YAZ_BIB1_ES_MISSING_MANDATORY_PARAMETER_FOR_SPECIFIED_FUNCTION_ 1008
#define YAZ_BIB1_ES_ITEM_ORDER_UNSUPP_OID_IN_ITEMREQUEST_ADDINFO_OID 1009
#define YAZ_BIB1_INIT_AC_BAD_USERID 1010
#define YAZ_BIB1_INIT_AC_BAD_USERID_AND_OR_PASSWORD 1011
#define YAZ_BIB1_INIT_AC_NO_SEARCHES_REMAINING_PRE_PURCHASED_SEARCHES_ 1012
#define YAZ_BIB1_INIT_AC_INCORRECT_INTERFACE_TYPE_SPECIFIED_ID_VALID_ 1013
#define YAZ_BIB1_INIT_AC_AUTHENTICATION_SYSTEM_ERROR 1014
#define YAZ_BIB1_INIT_AC_MAXIMUM_NUMBER_OF_SIMULTANEOUS_SESSIONS_FOR_ 1015
#define YAZ_BIB1_INIT_AC_BLOCKED_NETWORK_ADDRESS 1016
#define YAZ_BIB1_INIT_AC_NO_DATABASES_AVAILABLE_FOR_SPECIFIED_USERID 1017
#define YAZ_BIB1_INIT_AC_SYSTEM_TEMPORARILY_OUT_OF_RESOURCES 1018
#define YAZ_BIB1_INIT_AC_SYSTEM_NOT_AVAILABLE_DUE_TO_MAINTENANCE 1019
#define YAZ_BIB1_INIT_AC_SYSTEM_TEMPORARILY_UNAVAILABLE_ADDINFO_WHEN_IT_ 1020
#define YAZ_BIB1_INIT_AC_ACCOUNT_HAS_EXPIRED 1021
#define YAZ_BIB1_INIT_AC_PASSWORD_HAS_EXPIRED_SO_A_NEW_ONE_MUST_BE_ 1022
#define YAZ_BIB1_INIT_AC_PASSWORD_HAS_BEEN_CHANGED_BY_AN_ADMINISTRATOR_ 1023
#define YAZ_BIB1_UNSUPP_ATTRIBUTE 1024
#define YAZ_BIB1_SERVICE_UNSUPP_FOR_THIS_DATABASE 1025
#define YAZ_BIB1_RECORD_CANNOT_BE_OPENED_BECAUSE_IT_IS_LOCKED 1026
#define YAZ_BIB1_SQL_ERROR 1027
#define YAZ_BIB1_RECORD_DELETED 1028
#define YAZ_BIB1_SCAN_TOO_MANY_TERMS_REQUESTED_ADDINFO_MAX_TERMS_ 1029
#define YAZ_BIB1_ES_INVALID_FUNCTION 1040
#define YAZ_BIB1_ES_ERROR_IN_RETENTION_TIME 1041
#define YAZ_BIB1_ES_PERMISSIONS_DATA_NOT_UNDERSTOOD 1042
#define YAZ_BIB1_ES_INVALID_OID_FOR_TASK_SPECIFIC_PARAMETERS 1043
#define YAZ_BIB1_ES_INVALID_ACTION 1044
#define YAZ_BIB1_ES_UNKNOWN_SCHEMA 1045
#define YAZ_BIB1_ES_TOO_MANY_RECORDS_IN_PACKAGE 1046
#define YAZ_BIB1_ES_INVALID_WAIT_ACTION 1047
#define YAZ_BIB1_ES_CANNOT_CREATE_TASK_PACKAGE__EXCEEDS_MAXIMUM_ 1048
#define YAZ_BIB1_ES_CANNOT_RETURN_TASK_PACKAGE__EXCEEDS_MAXIMUM_ 1049
#define YAZ_BIB1_ES_EXTENDED_SERVICES_REQUEST_TOO_LARGE 1050
#define YAZ_BIB1_SCAN_ATTRIBUTE_SET_ID_REQUIRED__NOT_SUPPLIED 1051
#define YAZ_BIB1_ES_CANNOT_PROCESS_TASK_PACKAGE_RECORD__EXCEEDS_MAXIMUM_ 1052
#define YAZ_BIB1_ES_CANNOT_RETURN_TASK_PACKAGE_RECORD__EXCEEDS_MAXIMUM_ 1053
#define YAZ_BIB1_INIT_REQUIRED_NEGOTIATION_RECORD_NOT_INCLUDED 1054
#define YAZ_BIB1_INIT_NEGOTIATION_OPTION_REQUIRED 1055
#define YAZ_BIB1_ATTRIBUTE_UNSUPP_FOR_DATABASE 1056
#define YAZ_BIB1_ES_UNSUPP_VALUE_OF_TASK_PACKAGE_PARAMETER 1057
#define YAZ_BIB1_DUP_DETECTION_CANNOT_DEDUP_ON_REQUESTED_RECORD_PORTION 1058
#define YAZ_BIB1_DUP_DETECTION_REQUESTED_DETECTION_CRITERION_UNSUPP 1059
#define YAZ_BIB1_DUP_DETECTION_REQUESTED_LEVEL_OF_MATCH_UNSUPP 1060
#define YAZ_BIB1_DUP_DETECTION_REQUESTED_REGULAR_EXPRESSION_UNSUPP 1061
#define YAZ_BIB1_DUP_DETECTION_CANNOT_DO_CLUSTERING 1062
#define YAZ_BIB1_DUP_DETECTION_RETENTION_CRITERION_UNSUPP 1063
#define YAZ_BIB1_DUP_DETECTION_REQUESTED_NUMBER_OR_PERCENTAGE_OF_ENTRIES_ 1064
#define YAZ_BIB1_DUP_DETECTION_REQUESTED_SORT_CRITERION_UNSUPP 1065
#define YAZ_BIB1_COMPSPEC_UNKNOWN_SCHEMA_OR_SCHEMA_UNSUPP_ 1066
#define YAZ_BIB1_ENCAPSULATION_ENCAPSULATED_SEQUENCE_OF_PDUS_UNSUPP 1067
#define YAZ_BIB1_ENCAPSULATION_BASE_OPERATION_AND_ENCAPSULATED_PDUS_NOT_ 1068
#define YAZ_BIB1_NO_SYNTAXES_AVAILABLE_FOR_THIS_REQUEST 1069
#define YAZ_BIB1_USER_NOT_AUTHORIZED_TO_RECEIVE_RECORD_S_IN_REQUESTED_ 1070
#define YAZ_BIB1_PREFERREDRECORDSYNTAX_NOT_SUPPLIED 1071
#define YAZ_BIB1_QUERY_TERM_INCLUDES_CHARS_THAT_DO_NOT_TRANSLATE_INTO_ 1072

YAZ_END_CDECL
#endif

