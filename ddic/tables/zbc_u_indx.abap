" Transparent Table: ZBC_U_INDX
" Short Description: Generic INDX-style cluster table for utility data
" Delivery Class   : Application table
"
"| Field  | Key | Data Element | Type | Length | Decimals | Description                                         |
"| ------ | --- | ------------ | ---- | ------ | -------- | --------------------------------------------------- |
"| MANDT  |  X  | MANDT        | CLNT | 3      | 0        | Client                                              |
"| RELID  |  X  | INDX_RELID   | CHAR | 2      | 0        | Region in IMPORT/EXPORT Data Table                  |
"| UUID   |  X  | SYSUUID_C32  | CHAR | 32     | 0        | 16 Byte UUID in 32 Characters (Hexadecimal Encoded) |
"| OBJTYP |  X  | OBJ_TYP      | CHAR | 32     | 0        | Object type                                         |
"| OBJKEY |  X  | OBJKEY       | CHAR | 30     | 0        | Object key                                          |
"| SRTF2  |  X  | INDX_SRTF2   | INT4 | 10     | 0        | Next record counter in EXPORT/IMPORT data tables    |
"| CRDATE |     | BALDATE      | DATS | 8      | 0        | Application log: date                               |
"| CRTIME |     | BALTIME      | TIMS | 6      | 0        | Application log: time                               |
"| CRUSER |     | BALUSER      | CHAR | 12     | 0        | Application log: user name                          |
"| CHDATE |     | BALCHDATE    | DATS | 8      | 0        | Application log: date of last change                |
"| CHTIME |     | BALCHTIME    | TIMS | 6      | 0        | Application log: time of last change                |
"| CHUSER |     | BALCHUSER    | CHAR | 12     | 0        | Application log: user that changed the log          |
"| CLUSTR |     | INDX_CLSTR   | INT2 | 5      | 0        | Length field for user data in EXPORT/IMPORT tables  |
"| CLUSTD |     | INDX_CLUST   | LRAW | 2886   | 0        | Data field for IMPORT/EXPORT database tables        |
