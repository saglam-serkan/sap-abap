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
" Class ZCL_U_SYSTEM_CALLSTACK
" Utility class: Callstack
"
" Purpose:
"   Utility class for collecting the call stack. Provides methods to retrieve 
"   and format the stack, with output as a string or table, and includes methods
"   to obtain the immediate and root callers.
"
" Dependencies
" - Interface ZIF_UTILITY
"
" Methods
"   GET_INSTANCE                   | Returns the singleton instance of the class
"   GET_CALLSTACK_ABAP             | Returns call stack in ABAP structure                       
"   GET_CALLSTACK_SYSTEM           | Returns call stack in system structure                     
"   GET_IMMEDIATE_CALLER           | Returns the immediate caller info                          
"   GET_ROOT_CALLER                | Returns the root caller info                               
"   GET_FORMATTED_CALLSTACK_STRING | Builds and returns formatted callstack as a chained string 
"   GET_FORMATTED_CALLSTACK_TABLE  | Builds and returns formatted callstack as a table          
"   FORMAT_STACK_ENTRY             | Formats a single call stack entry as string                
"   GET_CALLSTACK                  | Returns call stack                                         
"   DELETE_INTERNAL_STACK          | Deletes internal calls from the call stack   
"
"--------------------------------------------------------------------*

CLASS zcl_u_system_callstack DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE .

  PUBLIC SECTION.

    INTERFACES zif_utility .

    CLASS-METHODS get_instance
      RETURNING
        VALUE(instance) TYPE REF TO zcl_u_system_callstack .
    
    METHODS get_callstack_abap
      IMPORTING
        !max_level            TYPE i DEFAULT 0
      RETURNING
        VALUE(abap_callstack) TYPE abap_callstack .
    
    METHODS get_callstack_system
      IMPORTING
        !max_level            TYPE i DEFAULT 0
      RETURNING
        VALUE(syst_callstack) TYPE sys_callst .
    
    METHODS get_immediate_caller
      RETURNING
        VALUE(immediate_caller) TYPE abap_callstack_line .
    
    METHODS get_root_caller
      RETURNING
        VALUE(root_caller) TYPE abap_callstack_line .
    
    METHODS get_formatted_callstack_string
      IMPORTING
        !from                      TYPE i OPTIONAL
        !to                        TYPE i OPTIONAL
        !separator                 TYPE char3 DEFAULT '\'
        !with_label                TYPE abap_bool OPTIONAL
      RETURNING
        VALUE(formatted_callstack) TYPE string .
    
    METHODS get_formatted_callstack_table
      IMPORTING
        !from                      TYPE i OPTIONAL
        !to                        TYPE i OPTIONAL
        !separator                 TYPE char3 DEFAULT '\'
        !with_label                TYPE abap_bool OPTIONAL
      RETURNING
        VALUE(formatted_callstack) TYPE string_table .
    
    METHODS format_stack_entry
      IMPORTING
        !abap_callstack_line TYPE abap_callstack_line
        !separator           TYPE char3 DEFAULT '\'
        !with_label          TYPE abap_bool OPTIONAL
      RETURNING
        VALUE(value)         TYPE string .
    
  PROTECTED SECTION.

  PRIVATE SECTION.

    CLASS-DATA instance TYPE REF TO zcl_u_system_callstack .

    METHODS get_callstack
      IMPORTING
        !max_level      TYPE i DEFAULT 0
      EXPORTING
        !abap_callstack TYPE abap_callstack
        !syst_callstack TYPE sys_callst .
    
    METHODS delete_internal_stack
      CHANGING
        !abap_callstack TYPE abap_callstack .

ENDCLASS.



CLASS zcl_u_system_callstack IMPLEMENTATION.


  METHOD delete_internal_stack.

    DELETE abap_callstack WHERE mainprogram CP 'ZCL_U_SYSTEM_CALLSTACK*'.

  ENDMETHOD.


  METHOD format_stack_entry.

    CONSTANTS colon TYPE c LENGTH 1 VALUE `:`.

    IF separator IS NOT INITIAL.
      DATA(separator_) = | { separator } |.
    ELSE.
      separator_ = ` `.
    ENDIF.

    CASE abap_callstack_line-blocktype.

      WHEN 'EVENT'.
        IF with_label = abap_true.
          value = |Program: { abap_callstack_line-mainprogram }{ separator_ }|
               && |Event: { abap_callstack_line-blockname }{ separator_ }|
               && |Line: { abap_callstack_line-line }|.
        ELSE.
          value = |{ abap_callstack_line-mainprogram }{ separator_ }|
               && |{ abap_callstack_line-blockname }{ colon } |
               && |{ abap_callstack_line-line }|.
        ENDIF.

      WHEN 'FORM'.
        IF with_label = abap_true.
          value = |Program: { abap_callstack_line-mainprogram }{ separator_ }|
               && |Subroutine: { abap_callstack_line-blockname }{ separator_ }|
               && |Line: { abap_callstack_line-line }|.
        ELSE.
          value = |{ abap_callstack_line-mainprogram }{ separator_ }|
               && |{ abap_callstack_line-blockname }{ colon } |
               && |{ abap_callstack_line-line }|.
        ENDIF.

      WHEN 'FUNCTION'.
        IF with_label = abap_true.
          value = |Function: { abap_callstack_line-blockname }{ separator_ }|
               && |Line: { abap_callstack_line-line }|.
        ELSE.
          value = |{ abap_callstack_line-blockname }{ colon } |
               && |{ abap_callstack_line-line }|.
        ENDIF.

      WHEN 'METHOD'.
        " Class name without ========CP
        cl_oo_include_naming=>get_instance_by_include(
          EXPORTING progname = abap_callstack_line-mainprogram
          RECEIVING cifref = DATA(cifref)
          EXCEPTIONS OTHERS = 2 ).
        IF cifref IS BOUND.
          DATA(classname) = cifref->cifkey-clsname.
        ELSE.
          classname = abap_callstack_line-mainprogram.
        ENDIF.

        " Method name without interface prefix
        SEARCH abap_callstack_line-blockname FOR '~'.
        IF sy-fdpos GT 0.
          DATA(offset) = sy-fdpos + 1.
          DATA(eventname) = abap_callstack_line-blockname+offset.
        ELSE.
          eventname = abap_callstack_line-blockname.
        ENDIF.

        IF with_label = abap_true.
          value = |Class: { classname }{ separator_ }|
               && |Method: { eventname }{ separator_ }|
               && |Line: { abap_callstack_line-line }|.
        ELSE.
          value = |{ classname }{ separator_ }|
               && |{ eventname }{ colon } |
               && |{ abap_callstack_line-line }|.
        ENDIF.

      WHEN OTHERS.
        IF with_label = abap_true.
          value = |Program: { abap_callstack_line-mainprogram }{ separator_ }|
               && |Blocktype: { abap_callstack_line-blocktype }{ separator_ }|
               && |Block: { abap_callstack_line-blockname }{ separator_ }|
               && |Line: { abap_callstack_line-line }|.
        ELSE.
          value = |{ abap_callstack_line-mainprogram }{ separator_ }|
               && |{ abap_callstack_line-blocktype }{ separator_ }|
               && |{ abap_callstack_line-blockname }{ colon } |
               && |{ abap_callstack_line-line }|.
        ENDIF.
    ENDCASE.

  ENDMETHOD.


  METHOD get_callstack.

    CALL FUNCTION 'SYSTEM_CALLSTACK'
      EXPORTING
        max_level    = max_level
      IMPORTING
        callstack    = abap_callstack
        et_callstack = syst_callstack.

  ENDMETHOD.


  METHOD get_callstack_abap.

    get_callstack( EXPORTING max_level      = max_level
                   IMPORTING abap_callstack = abap_callstack ).

  ENDMETHOD.


  METHOD get_callstack_system.

    get_callstack( EXPORTING max_level      = max_level
                   IMPORTING syst_callstack = syst_callstack ).

  ENDMETHOD.


  METHOD get_formatted_callstack_string.

    DATA(callstack) = get_callstack_abap( max_level = 0 ).
    delete_internal_stack( CHANGING abap_callstack = callstack ).

    IF from <= 0.
      DATA(from_) = 1.
    ELSE.
      from_ = from.
    ENDIF.

    IF to <= 0 OR to > lines( callstack ).
      DATA(to_) = lines( callstack ).
    ELSE.
      to_ = to.
    ENDIF.

    CHECK: callstack IS NOT INITIAL,
           from_ <= to_, to_ <= lines( callstack ).

    " seq_nr: sequence number for call chain display (e.g., (1), (2), (3), …)
    " stack_index: iterates backward through the call stack from 'to_' down to 'from_'

    DATA(seq_nr) = 1.
    DATA(stack_index) = to_.

    DO ( to_ - from_ + 1 ) TIMES.
      READ TABLE callstack ASSIGNING FIELD-SYMBOL(<callstack>) INDEX stack_index.
      IF <callstack> IS ASSIGNED.
        formatted_callstack = formatted_callstack && | ({ seq_nr }) |
                           && format_stack_entry( abap_callstack_line = <callstack>
                                                  separator           = separator
                                                  with_label          = with_label ).
      ENDIF.

      seq_nr = seq_nr + 1.
      stack_index = stack_index - 1.

      IF stack_index = 0.
        EXIT.
      ENDIF.
    ENDDO.

    CONDENSE formatted_callstack.

  ENDMETHOD.


  METHOD get_formatted_callstack_table.

    DATA(callstack) = get_callstack_abap( max_level = 0 ).
    delete_internal_stack( CHANGING abap_callstack = callstack ).

    IF from <= 0.
      DATA(from_) = 1.
    ELSE.
      from_ = from.
    ENDIF.

    IF to <= 0 OR to > lines( callstack ).
      DATA(to_) = lines( callstack ).
    ELSE.
      to_ = to.
    ENDIF.

    CHECK: callstack IS NOT INITIAL,
           from_ <= to_,
           to_ <= lines( callstack ).

    " seq_nr: sequence number for call chain display (e.g., (1), (2), (3), …)
    " stack_index: iterates backward through the call stack from 'to_' down to 'from_'

    DATA(seq_nr) = 1.
    DATA(stack_index) = to_.

    DO ( to_ - from_ + 1 ) TIMES.
      READ TABLE callstack ASSIGNING FIELD-SYMBOL(<callstack>) INDEX stack_index.
      IF <callstack> IS ASSIGNED.
        APPEND |({ seq_nr }) | && format_stack_entry( abap_callstack_line = <callstack>
                                                      separator           = separator
                                                      with_label          = with_label )
            TO formatted_callstack.
      ENDIF.

      seq_nr = seq_nr + 1.
      stack_index = stack_index - 1.

      IF stack_index = 0.
        EXIT.
      ENDIF.
    ENDDO.

  ENDMETHOD.


  METHOD get_immediate_caller.

    " abap_callstack
    " ----------------------------------------------------------------------------------------------------------------------------
    " |INDEX|MAINPROGRAM                     |INCLUDE                            |LINE|BLOCKTYPE|BLOCKNAME           |FLAG_SYSTEM|
    " ----------------------------------------------------------------------------------------------------------------------------
    " |   1 |ZCL_U_SYSTEM_CALLSTACK========CP|ZCL_U_SYSTEM_CALLSTACK========CM004|  3 |METHOD   |GET_CALLSTACK       |           |
    " |   2 |ZCL_U_SYSTEM_CALLSTACK========CP|ZCL_U_SYSTEM_CALLSTACK========CM005|  5 |METHOD   |GET_IMMEDIATE_CALLER|           |
    " |   3 |<immediate caller>              |                                   |    |         |                    |           |
    " |   4 |<previous caller>               |                                   |    |         |                    |           |
    " |   . |<...>                           |                                   |    |         |                    |           |
    " |   n |<root caller>                   |                                   |    |         |                    |           |
    " ----------------------------------------------------------------------------------------------------------------------------

    get_callstack( EXPORTING max_level      = 3
                   IMPORTING abap_callstack = DATA(abap_callstack) ).

    delete_internal_stack( CHANGING abap_callstack = abap_callstack ).

    IF lines( abap_callstack ) > 0.
      READ TABLE abap_callstack ASSIGNING FIELD-SYMBOL(<abap_callstack>) INDEX 1.
      IF <abap_callstack> IS ASSIGNED.
        immediate_caller = <abap_callstack>.
      ENDIF.
    ENDIF.

  ENDMETHOD.


  METHOD get_instance.

    IF zcl_u_system_callstack=>instance IS NOT BOUND.
      zcl_u_system_callstack=>instance = NEW #( ).
    ENDIF.

    instance = zcl_u_system_callstack=>instance.

  ENDMETHOD.


  METHOD get_root_caller.

    " abap_callstack
    " ----------------------------------------------------------------------------------------------------------------------------
    " |INDEX|MAINPROGRAM                     |INCLUDE                            |LINE|BLOCKTYPE|BLOCKNAME           |FLAG_SYSTEM|
    " ----------------------------------------------------------------------------------------------------------------------------
    " |   1 |ZCL_U_SYSTEM_CALLSTACK========CP|ZCL_U_SYSTEM_CALLSTACK========CM004|  3 |METHOD   |GET_CALLSTACK       |           |
    " |   2 |ZCL_U_SYSTEM_CALLSTACK========CP|ZCL_U_SYSTEM_CALLSTACK========CM005|  5 |METHOD   |GET_IMMEDIATE_CALLER|           |
    " |   3 |<immediate caller>              |                                   |    |         |                    |           |
    " |   4 |<previous caller>               |                                   |    |         |                    |           |
    " |   . |<...>                           |                                   |    |         |                    |           |
    " |   n |<root caller>                   |                                   |    |         |                    |           |
    " ----------------------------------------------------------------------------------------------------------------------------

    get_callstack( EXPORTING max_level      = 0
                   IMPORTING abap_callstack = DATA(abap_callstack) ).

    delete_internal_stack( CHANGING abap_callstack = abap_callstack ).

    IF lines( abap_callstack ) > 0.
      READ TABLE abap_callstack ASSIGNING FIELD-SYMBOL(<abap_callstack>) INDEX lines( abap_callstack ).
      IF <abap_callstack> IS ASSIGNED.
        root_caller = <abap_callstack>.
      ENDIF.
    ENDIF.

  ENDMETHOD.
  
ENDCLASS.
