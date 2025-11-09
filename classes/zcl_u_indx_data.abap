"--------------------------------------------------------------------*
" MIT License
"
" Copyright (c) 2025 Serkan Saglam
"
" Permission is hereby granted, free of charge, to any person obtaining a copy
" of this software and associated documentation files (the "Software"), to deal
" in the Software without restriction, including without limitation the rights
" to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
" copies of the Software, and to permit persons to whom the Software is
" furnished to do so, subject to the following conditions:
"
" The above copyright notice and this permission notice shall be included in all
" copies or substantial portions of the Software.
"
" THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
" IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
" FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
" AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
" LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
" OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
" SOFTWARE.
"
"--------------------------------------------------------------------*
"
" Class ZCL_U_INDX_DATA
" Utility class for generic INDX-style data storage
"
" Purpose: 
"   Utility class for storing, retrieving, updating, and managing data objects
"   in the generic INDX-style cluster table ZBC_U_INDX. Objects are identified
"   by OBJTYP and OBJKEY and include metadata (creation and modification).
"   This class (and the underlying INDX table) can be used to store data such 
"   as call stacks, traces, logs, settings, additional info for documents, 
"   images, and other custom objects.
"
" Dependencies
" - Interface ZIF_UTILITY
" - Database table ZBC_U_INDX
"
" Methods
"   GET_INSTANCE   | Returns the singleton instance of the class                
"   INSERT         | Store a new data object in the cluster table               
"   UPDATE         | Update an existing data object in the cluster table        
"   READ           | Read a data object from the cluster table                  
"   DELETE         | Delete a data object from the cluster table                
"   GET_LIST       | Return a list of entries (UUID + metadata)                 
"   GET_LENGTH     | Return the size of stored data in bytes                    
"   _CREATE_UUID   | Generate a unique 32-character identifier for a new entry  
"   _BUILD_INDX_ID | Concatenate UUID + OBJTYP + OBJKEY to generate the INDX ID 
"   _EXPORT        | Write data to the cluster table                            
"   _IMPORT        | Read data from the cluster table                           
"   _READ_METADATA | Read only metadata of a stored data object  
"
"--------------------------------------------------------------------*

CLASS zcl_u_indx_data DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE .

  PUBLIC SECTION.

    INTERFACES zif_utility .

    TYPES:
      indx_id TYPE c LENGTH 94 . "uuid + objtyp + objkey
    
    TYPES:
      BEGIN OF indx_entry,
        uuid   TYPE zbc_u_indx-uuid,
        objtyp TYPE zbc_u_indx-objtyp,
        objkey TYPE zbc_u_indx-objkey,
        srtf2  TYPE zbc_u_indx-srtf2,
        crdate TYPE zbc_u_indx-crdate,
        crtime TYPE zbc_u_indx-crtime,
        cruser TYPE zbc_u_indx-cruser,
        chdate TYPE zbc_u_indx-chdate,
        chtime TYPE zbc_u_indx-chtime,
        chuser TYPE zbc_u_indx-chuser,
      END OF indx_entry .
      
    TYPES:
      indx_entries TYPE TABLE OF indx_entry WITH EMPTY KEY .

    CLASS-METHODS get_instance
      RETURNING
        VALUE(instance) TYPE REF TO zcl_u_indx_data .
    
    METHODS insert
      IMPORTING
        !objtyp     TYPE zbc_u_indx-objtyp
        !objkey     TYPE zbc_u_indx-objkey
        !data       TYPE any
      RETURNING
        VALUE(uuid) TYPE zbc_u_indx-uuid .
    
    METHODS update
      IMPORTING
        !uuid   TYPE zbc_u_indx-uuid
        !objtyp TYPE zbc_u_indx-objtyp
        !objkey TYPE zbc_u_indx-objkey
        !data   TYPE any .
    
    METHODS read
      IMPORTING
        !uuid   TYPE zbc_u_indx-uuid
        !objtyp TYPE zbc_u_indx-objtyp
        !objkey TYPE zbc_u_indx-objkey
      EXPORTING
        !data   TYPE any .
    
    METHODS delete
      IMPORTING
        !uuid   TYPE zbc_u_indx-uuid
        !objtyp TYPE zbc_u_indx-objtyp
        !objkey TYPE zbc_u_indx-objkey .
    
    METHODS get_list
      IMPORTING
        !objtyp             TYPE zbc_u_indx-objtyp
        !objkey             TYPE zbc_u_indx-objkey OPTIONAL
      RETURNING
        VALUE(indx_entries) TYPE indx_entries .
    
    METHODS get_length
      IMPORTING
        !uuid         TYPE zbc_u_indx-uuid
        !objtyp       TYPE zbc_u_indx-objtyp
        !objkey       TYPE zbc_u_indx-objkey
      RETURNING
        VALUE(length) TYPE zbc_u_indx-clustr .
    
  PRIVATE SECTION.

    CLASS-DATA instance TYPE REF TO zcl_u_indx_data .

    METHODS _create_uuid
      RETURNING
        VALUE(uuid) TYPE sysuuid_c32 .
    
    METHODS _build_indx_id
      IMPORTING
        !uuid          TYPE zbc_u_indx-uuid
        !objtyp        TYPE zbc_u_indx-objtyp
        !objkey        TYPE zbc_u_indx-objkey
      RETURNING
        VALUE(indx_id) TYPE indx_id .
    
    METHODS _export
      IMPORTING
        !indx      TYPE zbc_u_indx
        !data      TYPE any
        !db_commit TYPE abap_bool OPTIONAL .
    
    METHODS _import
      IMPORTING
        !uuid   TYPE zbc_u_indx-uuid
        !objtyp TYPE zbc_u_indx-objtyp
        !objkey TYPE zbc_u_indx-objkey
      EXPORTING
        !data   TYPE any .
    
    METHODS _read_metadata
      IMPORTING
        !uuid       TYPE zbc_u_indx-uuid
        !objtyp     TYPE zbc_u_indx-objtyp
        !objkey     TYPE zbc_u_indx-objkey
      RETURNING
        VALUE(indx) TYPE zbc_u_indx .

ENDCLASS.



CLASS zcl_u_indx_data IMPLEMENTATION.


  METHOD delete.

    CHECK: uuid   IS NOT INITIAL,
           objtyp IS NOT INITIAL,
           objkey IS NOT INITIAL.

    DELETE FROM zbc_u_indx
          WHERE relid  = 'ZZ'
            AND uuid   = @uuid
            AND objtyp = @objtyp
            AND objkey = @objkey.

  ENDMETHOD.


  METHOD get_instance.

    IF zcl_u_indx_data=>instance IS NOT BOUND.
      zcl_u_indx_data=>instance = NEW #( ).
    ENDIF.

    instance = zcl_u_indx_data=>instance.

  ENDMETHOD.


  METHOD get_length.

    CHECK: uuid   IS NOT INITIAL,
           objtyp IS NOT INITIAL,
           objkey IS NOT INITIAL.

    SELECT SUM( clustr )
          INTO @length
          FROM zbc_u_indx
         WHERE relid  = 'ZZ'
           AND uuid   = @uuid
           AND objtyp = @objtyp
           AND objkey = @objkey.

  ENDMETHOD.


  METHOD get_list.

    CHECK objtyp IS NOT INITIAL.

    DATA(where_clause) = |relid = 'ZZ' AND objtyp = objtyp|.

    IF objkey IS NOT INITIAL.
      where_clause = |{ where_clause } AND objkey = objkey|.
    ENDIF.

    TRY.
        SELECT
            uuid objtyp objkey
            srtf2
            crdate crtime cruser
            chdate chtime chuser
          FROM
            zbc_u_indx
          INTO
            CORRESPONDING FIELDS OF TABLE indx_entries
          WHERE (where_clause).

      CATCH cx_root INTO DATA(exception) ##NEEDED.
        DATA(exception_text) = exception->get_text( ).
    ENDTRY.

  ENDMETHOD.


  METHOD insert.

    CHECK: objtyp IS NOT INITIAL,
           objkey IS NOT INITIAL.

    DATA indx TYPE zbc_u_indx.

    indx-uuid   = _create_uuid( ).
    indx-objtyp = objtyp.
    indx-objkey = objkey.
    indx-crdate = sy-datum.
    indx-crtime = sy-uzeit.
    indx-cruser = sy-uname.

    _export( indx      = indx
             data      = data
             db_commit = abap_false ).

    uuid = indx-uuid.

  ENDMETHOD.


  METHOD read.

    CHECK: uuid   IS NOT INITIAL,
           objtyp IS NOT INITIAL,
           objkey IS NOT INITIAL.

    _import( EXPORTING uuid   = uuid
                       objtyp = objtyp
                       objkey = objkey
             IMPORTING data   = data ).

  ENDMETHOD.


  METHOD update.

    CHECK: uuid   IS NOT INITIAL,
           objtyp IS NOT INITIAL,
           objkey IS NOT INITIAL.

    DATA indx TYPE zbc_u_indx.

    indx = _read_metadata( uuid   = uuid
                           objtyp = objtyp
                           objkey = objkey ).

    IF indx-uuid IS INITIAL.
      RETURN.
    ENDIF.

    indx-chdate = sy-datum.
    indx-chtime = sy-uzeit.
    indx-chuser = sy-uname.

    _export( indx      = indx
             data      = data
             db_commit = abap_false ).

  ENDMETHOD.


  METHOD _build_indx_id.

    indx_id = |{ uuid WIDTH = 32 }{ objtyp WIDTH = 32 }{ objkey WIDTH = 30 }|.

  ENDMETHOD.


  METHOD _create_uuid.

    TRY.
        uuid = cl_system_uuid=>create_uuid_c32_static( ).

      CATCH cx_root.
        DATA tstmpl TYPE timestampl.
        GET TIME STAMP FIELD tstmpl. "YYYYMMDDhhmmss.mmmuuun
        uuid = tstmpl.
    ENDTRY.

  ENDMETHOD.


  METHOD _export.

    DATA(indx_id) = _build_indx_id( uuid   = indx-uuid
                                    objtyp = indx-objtyp
                                    objkey = indx-objkey ).

    IF indx_id IS INITIAL.
      RETURN.
    ENDIF.

    TRY.
        EXPORT data = data
            TO DATABASE zbc_u_indx(zz)
          FROM indx
            ID indx_id.

        IF db_commit = abap_true.
          CALL FUNCTION 'DB_COMMIT'.
        ENDIF.

      CATCH cx_sy_expimp_db_sql_error INTO DATA(exception) ##NEEDED.
        DATA(exception_text) = exception->get_text( ).
    ENDTRY.

  ENDMETHOD.


  METHOD _import.

    CHECK: uuid   IS NOT INITIAL,
           objtyp IS NOT INITIAL,
           objkey IS NOT INITIAL.

    DATA(indx_id) = _build_indx_id( uuid   = uuid
                                    objtyp = objtyp
                                    objkey = objkey ).

    IF indx_id IS INITIAL.
      RETURN.
    ENDIF.

    TRY.
        IMPORT data = data
          FROM DATABASE zbc_u_indx(zz)
            ID indx_id.

      CATCH cx_sy_expimp_db_sql_error INTO DATA(exception) ##NEEDED.
        DATA(exception_text) = exception->get_text( ).
    ENDTRY.

  ENDMETHOD.


  METHOD _read_metadata.

    CHECK: uuid   IS NOT INITIAL,
           objtyp IS NOT INITIAL,
           objkey IS NOT INITIAL.

    SELECT SINGLE
        uuid
        objtyp
        objkey
        srtf2
        crdate
        crtime
        cruser
        chdate
        chtime
        chuser
      FROM
        zbc_u_indx
      INTO
        CORRESPONDING FIELDS OF indx
      WHERE relid  = 'ZZ'
        AND uuid   = uuid
        AND objtyp = objtyp
        AND objkey = objkey
        AND srtf2  = 0.

  ENDMETHOD.
  
ENDCLASS.
