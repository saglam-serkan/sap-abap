CLASS zcl_spreadsheet_openxml_reader DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE .

  PUBLIC SECTION.

    TYPES:
      BEGIN OF sheet_metadata,
        name TYPE string, "name
        id   TYPE string, "sheetId
        r_id TYPE string, "r:id (Relationship Id)
      END OF sheet_metadata .
      
    TYPES:
      sheet_metadata_tab TYPE TABLE OF sheet_metadata WITH EMPTY KEY .

    CONSTANTS:
      string_br_unescaped TYPE string VALUE '<br/>' ##NO_TEXT.

    CLASS-METHODS get_instance
      RETURNING
        VALUE(instance) TYPE REF TO zcl_spreadsheet_openxml_reader .
    
    METHODS read_file
      IMPORTING
        !file_name     TYPE string
        !file_location TYPE uc_filelocation DEFAULT '1' .
    
    METHODS get_sheet_data
      IMPORTING
        !sheet_id          TYPE i OPTIONAL
        !sheet_name        TYPE string OPTIONAL
        !skip_first_n_rows TYPE i OPTIONAL
      EXPORTING
        !sheet_data        TYPE STANDARD TABLE .
    
    METHODS get_sheet_list
      RETURNING
        VALUE(sheet_list) TYPE sheet_metadata_tab .
    
  PROTECTED SECTION.

  PRIVATE SECTION.

    CLASS-DATA:
      instance TYPE REF TO zcl_spreadsheet_openxml_reader .
    
    DATA:
      xlsx_document  TYPE REF TO cl_xlsx_document,
      sheet_list     TYPE sheet_metadata_tab,
      shared_strings TYPE stringtab .

    METHODS convert_date_to_internal
      IMPORTING
        !date_ext       TYPE string
      RETURNING
        VALUE(date_int) TYPE dats .
    
    METHODS convert_text_date_to_sap
      IMPORTING
        !date_ext       TYPE string
      RETURNING
        VALUE(date_int) TYPE dats .
    
    METHODS convert_text_time_to_sap
      IMPORTING
        !time_ext       TYPE string
      RETURNING
        VALUE(time_int) TYPE tims .
    
    METHODS convert_time_to_internal
      IMPORTING
        !time_ext       TYPE string
      RETURNING
        VALUE(time_int) TYPE tims .
    
    METHODS convert_xlsx_date_to_sap
      IMPORTING
        !date_int       TYPE string
      RETURNING
        VALUE(date_ext) TYPE dats .
    
    METHODS convert_xlsx_time_to_sap
      IMPORTING
        !time_ext       TYPE string
      RETURNING
        VALUE(time_int) TYPE tims .
    
    METHODS convert_xstring_to_ixml_doc
      IMPORTING
        !xstring             TYPE xstring
      RETURNING
        VALUE(ixml_document) TYPE REF TO if_ixml_document .
    
    METHODS read_file_on_local
      IMPORTING
        !file_name       TYPE string
      RETURNING
        VALUE(file_data) TYPE solix_tab .
    
    METHODS read_file_on_server
      IMPORTING
        !file_name       TYPE string
      RETURNING
        VALUE(file_data) TYPE solix_tab .
    
    METHODS get_shared_strings
      RETURNING
        VALUE(shared_strings) TYPE stringtab .
    
    METHODS get_sheet_rid_by_name
      IMPORTING
        !sheet_name      TYPE string
      RETURNING
        VALUE(sheet_rid) TYPE string .
    
    METHODS get_sheet_rid_by_id
      IMPORTING
        !sheet_id        TYPE i
      RETURNING
        VALUE(sheet_rid) TYPE string .
    
    METHODS get_sheet_data_as_string
      IMPORTING
        !sheet_rid  TYPE string
      RETURNING
        VALUE(data) TYPE string .
    
    METHODS get_table_col_count
      IMPORTING
        !table           TYPE ANY TABLE
      RETURNING
        VALUE(col_count) TYPE i .
    
    METHODS get_next_cell
      IMPORTING
        !cell            TYPE string
      RETURNING
        VALUE(next_cell) TYPE string .
    
    METHODS get_cell_col_id
      IMPORTING
        !cell         TYPE string
      RETURNING
        VALUE(col_id) TYPE string .
    
    METHODS get_cell_row_no
      IMPORTING
        !cell         TYPE string
      RETURNING
        VALUE(row_no) TYPE string .
    
    METHODS convert_col_to_num
      IMPORTING
        !col       TYPE string
      RETURNING
        VALUE(num) TYPE i .
    
    METHODS convert_num_to_col
      IMPORTING
        !num       TYPE i
      RETURNING
        VALUE(col) TYPE string .
    
ENDCLASS.


CLASS zcl_spreadsheet_openxml_reader IMPLEMENTATION.

  METHOD convert_col_to_num.

    DO strlen( col ) TIMES.
      DATA(offset) = sy-index - 1.
      DATA(char) = col+offset(1).
      SEARCH sy-abcde FOR char.
      num = num * 26 + ( sy-fdpos + 1 ).
    ENDDO.

  ENDMETHOD.

  METHOD convert_date_to_internal.

    IF date_ext CO '0123456789'.
      date_int = convert_xlsx_date_to_sap( date_ext ).
    ELSE.
      date_int = convert_text_date_to_sap( date_ext ).
    ENDIF.

  ENDMETHOD.

  METHOD convert_num_to_col.

    DATA(_num) = num.
    WHILE _num > 0.
      _num = _num - 1.
      DATA(mod) = _num MOD 26.
      col = sy-abcde+mod(1) && col.
      _num = _num DIV 26.
    ENDWHILE.

  ENDMETHOD.

  METHOD convert_text_date_to_sap.

    CALL FUNCTION 'CONVERT_DATE_TO_INTERNAL'
      EXPORTING
        date_external = date_ext
      IMPORTING
        date_internal = date_int
      EXCEPTIONS
        OTHERS        = 2.

  ENDMETHOD.

  METHOD convert_text_time_to_sap.

    CALL FUNCTION 'CONVERT_TIME_INPUT'
      EXPORTING
        input  = time_ext
      IMPORTING
        output = time_int
      EXCEPTIONS
        OTHERS = 3.

  ENDMETHOD.

  METHOD convert_time_to_internal.

    IF time_ext CO '0123456789' AND time_ext CS '.'.
      time_int = convert_xlsx_time_to_sap( time_ext ).
    ELSE.
      time_int = convert_text_time_to_sap( time_ext ).
    ENDIF.

  ENDMETHOD.

  METHOD convert_xlsx_date_to_sap.

    DATA offset TYPE i.

    CALL FUNCTION 'CONVERT_STRING_TO_INTEGER'
      EXPORTING
        p_string = date_int
      IMPORTING
        p_int    = offset
      EXCEPTIONS
        OTHERS   = 3.

    CHECK sy-subrc EQ 0.
    CHECK offset   NE 0.

    date_ext = '18991230'.
    ADD offset TO date_ext.

  ENDMETHOD.

  METHOD convert_xlsx_time_to_sap.

    DATA: float TYPE f,
          hh    TYPE numc2,
          mm    TYPE numc2,
          ss    TYPE numc2.

    float = time_ext.

    hh = floor( ( 86400 * float ) / 3600 ).
    mm = floor( ( ( 86400 * float ) / 60 ) MOD 60 ).
    ss = ( 86400 * float ) MOD 100.

    CONCATENATE hh mm ss INTO time_int.

  ENDMETHOD.

  METHOD convert_xstring_to_ixml_doc.

    DATA string TYPE string.

    TRY.
        cl_abap_conv_in_ce=>create( input = xstring )->read( IMPORTING data = string ).
        DATA(ixml) = cl_ixml=>create( ).
        DATA(stream_factory) = ixml->create_stream_factory( ).
        DATA(istream) = stream_factory->create_istream_string( string ).
        ixml_document = ixml->create_document( ).
        DATA(parser) = ixml->create_parser( document       = ixml_document 
                                            istream        = istream
                                            stream_factory = stream_factory ).
        parser->set_normalizing( ).
        parser->set_validating( if_ixml_parser=>co_no_validation ).
        parser->parse( ).
        istream->close( ).

      CATCH cx_root.
    ENDTRY.

  ENDMETHOD.

  METHOD get_cell_col_id.

    " Split column letters and row numbers (e.g. A1 => A + 1)
    FIND FIRST OCCURRENCE OF REGEX '[0-9]' IN cell MATCH OFFSET DATA(index).
    IF index > 0.
      col_id = cell+0(index).
      "DATA(row_no) = cell+index.
    ENDIF.

  ENDMETHOD.

  METHOD get_cell_row_no.

    " Split column letters and row numbers (e.g. A1 => A + 1)
    FIND FIRST OCCURRENCE OF REGEX '[0-9]' IN cell MATCH OFFSET DATA(index).
    IF index > 0.
      "DATA(col_id) = cell+0(index).
      row_no = cell+index.
    ENDIF.

  ENDMETHOD.

  METHOD get_instance.

    IF instance IS NOT BOUND.
      zcl_spreadsheet_openxml_reader=>instance = NEW #( ).
    ENDIF.

    instance = zcl_spreadsheet_openxml_reader=>instance.

  ENDMETHOD.

  METHOD get_next_cell.

    DATA(cell_col_num) = convert_col_to_num( get_cell_col_id( cell ) ).
    DATA(next_cell_col) = convert_num_to_col( cell_col_num + 1 ).
    next_cell = next_cell_col && get_cell_row_no( cell ).

  ENDMETHOD.

  METHOD get_shared_strings.

    TRY.
        DATA(sharedstrings) = xlsx_document->get_workbookpart( )->get_sharedstringspart( ).
        DATA(xmldoc) = convert_xstring_to_ixml_doc( sharedstrings->get_data( ) ).
        DATA(nodes) = xmldoc->create_iterator_filtered( xmldoc->create_filter_name_ns( 'si' ) ). "sharedString
        DATA(node) = nodes->get_next( ).

        IF node IS INITIAL.
          nodes = xmldoc->create_iterator_filtered( xmldoc->create_filter_name( 'si' ) ). "sharedString
          node = nodes->get_next( ).
        ENDIF.

        WHILE node IS NOT INITIAL.
          APPEND node->get_value( ) TO shared_strings.
          node = nodes->get_next( ).
        ENDWHILE.

      CATCH cx_root.
    ENDTRY.

  ENDMETHOD.

  METHOD get_sheet_data.

    " <worksheet xmlns="...">
    "   <sheetData>
    "     <row>
    "       <c>
    "         <v>1234</v>
    "       </c>
    "     </row>
    "   </sheetData>
    " </worksheet>

    DATA(col_count) = get_table_col_count( sheet_data ).

    "--------------------------------------------------------------------*
    " Find Sheet r:id (Relationship Id)
    "--------------------------------------------------------------------*
    DATA(sheet_rid) = COND string( WHEN sheet_id   IS NOT INITIAL THEN get_sheet_rid_by_id( sheet_id )
                                   WHEN sheet_name IS NOT INITIAL THEN get_sheet_rid_by_name( sheet_name ) ).

    CHECK: sheet_rid IS NOT INITIAL.

    "--------------------------------------------------------------------*
    " Read Sheet data as string
    "--------------------------------------------------------------------*
    DATA(sheet_data_as_string) = get_sheet_data_as_string( sheet_rid ). "r:id (Relationship Id)

    "--------------------------------------------------------------------*
    " Convert string to table
    "--------------------------------------------------------------------*
    SPLIT sheet_data_as_string AT cl_abap_char_utilities=>cr_lf INTO TABLE DATA(sheet_data_lines).

    LOOP AT sheet_data_lines ASSIGNING FIELD-SYMBOL(<sheet_data_line>) FROM ( skip_first_n_rows + 1 ).

      REPLACE ALL OCCURRENCES OF string_br_unescaped IN <sheet_data_line> WITH cl_abap_char_utilities=>cr_lf.

      APPEND INITIAL LINE TO sheet_data ASSIGNING FIELD-SYMBOL(<sheet_data>).
      IF <sheet_data> IS ASSIGNED.

        DATA(iterator) = 1.

        DO col_count TIMES. "component_count TIMES.
          ASSIGN COMPONENT iterator OF STRUCTURE <sheet_data> TO FIELD-SYMBOL(<field>).

          IF <field> IS ASSIGNED.
            DESCRIBE FIELD <field> TYPE DATA(type).

            " also rotates, use loop at segments instead?
            SPLIT <sheet_data_line> AT cl_abap_char_utilities=>horizontal_tab INTO DATA(cell_value) <sheet_data_line>.

            TRY.
                CASE type.
                  WHEN cl_abap_datadescr=>typekind_date.
                    <field> = convert_date_to_internal( cell_value ).
                  WHEN cl_abap_datadescr=>typekind_time.
                    <field> = convert_time_to_internal( cell_value ).
                  WHEN cl_abap_datadescr=>typekind_any        "Internal Type (Data Object or Object)
                    OR cl_abap_datadescr=>typekind_class      "Internal Type (Class)
                    OR cl_abap_datadescr=>typekind_data       "Internal Type (Data Object)
                    OR cl_abap_datadescr=>typekind_dref       "Internal Type l (Data Object Reference)
                    OR cl_abap_datadescr=>typekind_intf       "Internal Type (Interface)
                    OR cl_abap_datadescr=>typekind_iref       "Internal Type m (Instance Reference)
                    OR cl_abap_datadescr=>typekind_oref       "Internal type r (object reference)
                    OR cl_abap_datadescr=>typekind_simple     "Internal Type (Data Object)
                    OR cl_abap_datadescr=>typekind_struct2    "Internal type v (deep structure)
                    OR cl_abap_datadescr=>typekind_table      "Internal Type h (Internal Table)
                    OR cl_abap_datadescr=>typekind_w          "Internal type w (wide character)
                    OR cl_abap_datadescr=>typekind_bref.      "Internal Type for Boxed Components/Attributes
                    " Not supported
                  WHEN OTHERS.
                    " TYPEKIND_CHAR.       "Internal type C
                    " TYPEKIND_CLIKE.      "Internal Type (Data Object)
                    " TYPEKIND_CSEQUENCE.  "Internal Type (Data Object)
                    " TYPEKIND_DATE.       "Internal type D
                    " TYPEKIND_DECFLOAT.   "Internal Type (Generic Decimal Floating Point Type)
                    " TYPEKIND_DECFLOAT16. "Internal Type a (Decimal Floating Point, 16 Decimal Places)
                    " TYPEKIND_DECFLOAT34. "Internal Type e (Decimal Floating Point, 34 Decimal Places)
                    " TYPEKIND_FLOAT.      "Internal type F
                    " TYPEKIND_HEX.        "Internal type X
                    " TYPEKIND_INT.        "Internal Type I (4 Byte Integer)
                    " TYPEKIND_INT1.       "Internal Type b (1 Byte Integer)
                    " TYPEKIND_INT8.       "Internal type 8 (8 byte integer)
                    " TYPEKIND_INT2.       "Internal Type s (2 Byte Integer)
                    " TYPEKIND_NUM.        "Internal type N
                    " TYPEKIND_NUMERIC.    "Internal Type (Data Object)
                    " TYPEKIND_PACKED.     "Internal type P
                    " TYPEKIND_STRING.     "Internal type g (character string)
                    " TYPEKIND_STRUCT1.    "Internal type u (flat structure)
                    " TYPEKIND_TIME.       "Internal type T
                    " TYPEKIND_XSEQUENCE.  "Internal Type (Data Object)
                    " TYPEKIND_XSTRING.    "Internal type y (byte string)
                    <field> = cell_value.
                ENDCASE.
              CATCH cx_root.
            ENDTRY.

            UNASSIGN <field>.
          ENDIF.

          ADD 1 TO iterator.
        ENDDO.

        UNASSIGN <sheet_data>.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD get_sheet_data_as_string.

    " <worksheet xmlns="...">
    "   <sheetData>
    "     <row>
    "       <c>
    "         <v>1234</v>
    "       </c>
    "     </row>
    "   </sheetData>
    " </worksheet>

    TYPES: BEGIN OF cell,
             ref   TYPE string, " Cell reference (e.g. A1, B2, C3)
             type  TYPE string, " Cell type (e.g. 's' for sharedString, empty for numeric)
             value TYPE string, " Cell value or sharedString index
           END OF cell.

    TYPES: BEGIN OF values,
             row   TYPE i,
             cells TYPE SORTED TABLE OF cell WITH NON-UNIQUE KEY ref,
           END OF values.

    DATA: cell     TYPE cell,
          si_index TYPE i,
          values   TYPE TABLE OF values.

    "--------------------------------------------------------------------*
    "--------------------------------------------------------------------*
    TRY.
        DATA(worksheet) = xlsx_document->get_workbookpart( )->get_part_by_id( sheet_rid ). "r:id (Relationship Id)

        DATA(xmldoc) = convert_xstring_to_ixml_doc( worksheet->get_data( ) ).
        DATA(nodes) = xmldoc->create_iterator_filtered( xmldoc->create_filter_or(
                                 filter1 = xmldoc->create_filter_name_ns( 'row' )
                                 filter2 = xmldoc->create_filter_name_ns( 'c' ) ) ). "cell
        DATA(node) = nodes->get_next( ).

        IF node IS NOT BOUND.
          nodes = xmldoc->create_iterator_filtered( xmldoc->create_filter_or(
                             filter1 = xmldoc->create_filter_name( 'row' )
                             filter2 = xmldoc->create_filter_name( 'c' ) ) ). "cell
          node = nodes->get_next( ).
        ENDIF.

        WHILE node IS BOUND.
          DATA(attributes) = node->get_attributes( ).
          DATA(node_name) = node->get_name( ).

          CASE node_name.
            WHEN 'row'.
              " E.g. <row r="1" ...>

              APPEND INITIAL LINE TO values ASSIGNING FIELD-SYMBOL(<values>).
              IF <values> IS ASSIGNED.
                <values>-row = attributes->get_named_item_ns( 'r' )->get_value( ). " Row number (e.g. 1, 2, 3)
              ENDIF.

            WHEN 'c'. "cell.
              " E.g.
              " <c r="A2"><v>lorem ipsum</v></c>  " Has direct value
              " <c r="C2" t="s"><v>4</v></c>      " Has value from sharedStrings

              CLEAR cell.

              IF <values> IS ASSIGNED.
                cell-ref = attributes->get_named_item_ns( 'r' )->get_value( )."e.g. B3
                cell-value = node->get_value( ). "value or sharedString index

                TRY.
                    cell-type = attributes->get_named_item_ns( name = 't' )->get_value( ).
                    IF cell-type EQ 's'. "type: sharedString
                      " Get value from shared strings by index (0-based in Excel, 1-based in ABAP)
                      si_index = cell-value.
                      ADD 1 TO si_index.
                      READ TABLE shared_strings INDEX si_index INTO cell-value.
                    ENDIF.

                  CATCH cx_sy_ref_is_initial.
                ENDTRY.

                " Replace carriage return & line feed with '<br/>'.
                REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>cr_lf IN cell-value WITH string_br_unescaped.

                APPEND cell TO <values>-cells.
              ENDIF.

          ENDCASE.

          node = nodes->get_next( ).
        ENDWHILE.

      CATCH cx_root.
    ENDTRY.

    "--------------------------------------------------------------------*
    " Add missing cells between the first (An) and the last filled cell
    "--------------------------------------------------------------------*
    DATA: next_cell TYPE string,
          last_cell TYPE string.

    LOOP AT values ASSIGNING <values> WHERE cells IS NOT INITIAL.
      CLEAR: next_cell, last_cell.

      " Read the first cell and generate the initial next_cell value based on its row number
      " E.g. A1, A2, ...
      READ TABLE <values>-cells ASSIGNING FIELD-SYMBOL(<cell>) INDEX 1.
      IF <cell> IS ASSIGNED.
        next_cell = |A{ get_cell_row_no( <cell>-ref ) }|. "E.g. A1, A2, ...
        UNASSIGN <cell>.
      ENDIF.

      " Get last filled cell
      READ TABLE <values>-cells ASSIGNING <cell> INDEX lines( <values>-cells ).
      IF <cell> IS ASSIGNED.
        last_cell = <cell>-ref.
        UNASSIGN <cell>.
      ENDIF.

      " Add missing cells between the first (An) and the last filled cell
      IF next_cell NE last_cell.
        DO.
          IF next_cell EQ last_cell.
            EXIT. "do
          ENDIF.
          READ TABLE <values>-cells ASSIGNING <cell> WITH KEY ref = next_cell.
          IF <cell> IS NOT ASSIGNED.
            INSERT VALUE cell( ref = next_cell ) INTO TABLE <values>-cells.
          ENDIF.
          next_cell = get_next_cell( next_cell ).
          UNASSIGN <cell>.
        ENDDO.
      ENDIF.
    ENDLOOP.

    "--------------------------------------------------------------------*
    " Concatenate rows with horizontal tabs into data string
    "--------------------------------------------------------------------*
    LOOP AT values ASSIGNING <values>.
      LOOP AT <values>-cells ASSIGNING <cell>.
        data = |{ data }{ <cell>-value }{ cl_abap_char_utilities=>horizontal_tab }|.
      ENDLOOP.
      data = |{ data }{ cl_abap_char_utilities=>cr_lf }|.
    ENDLOOP.

  ENDMETHOD.

  METHOD get_sheet_list.

    " Excel file:
    "   | Sheet41 | Sheet1 | Sheet33 | Sheet55 | Sheet100 | Sheet101 |
    "
    " Sheet list:
    "   <sheets>
    "     <sheet name="Sheet41" sheetId="41" r:id="rId1"/>
    "     <sheet name="Sheet1" sheetId="1" r:id="rId2"/>
    "     <sheet name="Sheet33" sheetId="33" r:id="rId3"/>
    "     <sheet name="Sheet55" sheetId="55" r:id="rId4"/>
    "     <sheet name="Sheet100" sheetId="10" r:id="rId5"/>
    "     <sheet name="Sheet101" sheetId="101" r:id="rId6"/>
    "   </sheets>

    TRY.
        DATA(xmldoc) = convert_xstring_to_ixml_doc( xlsx_document->get_workbookpart( )->get_data( ) ).
        DATA(nodes) = xmldoc->create_iterator_filtered( xmldoc->create_filter_name_ns( 'sheet' ) ).
        DATA(node) = nodes->get_next( ).

        IF node IS INITIAL.
          nodes = xmldoc->create_iterator_filtered( xmldoc->create_filter_name( 'sheet' ) ).
          node = nodes->get_next( ).
        ENDIF.

        WHILE node IS NOT INITIAL.
          DATA(attributes) = node->get_attributes( )->create_iterator( ).
          DATA(attribute) = attributes->get_next( ).

          APPEND INITIAL LINE TO sheet_list ASSIGNING FIELD-SYMBOL(<sheet>).

          IF <sheet> IS ASSIGNED.
            WHILE attribute IS NOT INITIAL.
              CASE attribute->get_name( ).
                WHEN 'name'.
                  <sheet>-name = attribute->get_value( ).
                WHEN 'sheetId'.
                  <sheet>-id = attribute->get_value( ).
                WHEN 'id'. "r:id (Relationship Id)
                  <sheet>-r_id = attribute->get_value( ).
              ENDCASE.

              attribute = attributes->get_next( ).
            ENDWHILE.

            UNASSIGN <sheet>.
          ENDIF.

          node = nodes->get_next( ).
        ENDWHILE.

      CATCH cx_root.
    ENDTRY.

    "--------------------------------------------------------------------*
    " Alternative
    "--------------------------------------------------------------------*
    " TRY .
    "     DATA(workbook) = m_xlsx_document->get_workbookpart( )->get_data( ).
    "     CALL TRANSFORMATION xl_get_worksheets SOURCE XML workbook
    "                                           RESULT worksheets = sheet_list.
    "   CATCH cx_root.
    " ENDTRY.

  ENDMETHOD.

  METHOD get_sheet_rid_by_id.

    CHECK sheet_id IS NOT INITIAL.
    READ TABLE sheet_list ASSIGNING FIELD-SYMBOL(<sheet>) INDEX sheet_id.
    CHECK <sheet> IS ASSIGNED.
    sheet_rid = <sheet>-r_id.

  ENDMETHOD.

  METHOD get_sheet_rid_by_name.

    CHECK sheet_name IS NOT INITIAL.
    READ TABLE sheet_list ASSIGNING FIELD-SYMBOL(<sheet>) WITH KEY name = sheet_name.
    CHECK <sheet> IS ASSIGNED.
    sheet_rid = <sheet>-r_id.

  ENDMETHOD.

  METHOD get_table_col_count.

    TRY.
        col_count = lines( CAST cl_abap_structdescr(
                             CAST cl_abap_tabledescr(
                               cl_abap_tabledescr=>describe_by_data( table )
                                 )->get_table_line_type( )
                                 )->components ).

      CATCH cx_root INTO DATA(exception).
        "DATA(exception_text) = exception->get_longtext( ).
    ENDTRY.

  ENDMETHOD.

  METHOD read_file.

    CLEAR: xlsx_document, sheet_list, shared_strings.

    TRY.
        xlsx_document = cl_xlsx_document=>load_document(
                          cl_bcs_convert=>solix_to_xstring(
                            SWITCH solix_tab( file_location
                              WHEN '0' THEN read_file_on_server( file_name )
                              WHEN '1' THEN read_file_on_local( file_name ) ) ) ).

        sheet_list = get_sheet_list( ).
        shared_strings = get_shared_strings( ).

      CATCH cx_root.
    ENDTRY.

  ENDMETHOD.

  METHOD read_file_on_local.

    CHECK cl_gui_frontend_services=>file_exist( file_name ) EQ abap_true.

    cl_gui_frontend_services=>gui_upload(
      EXPORTING
        filename                = file_name
        filetype                = 'BIN'
      CHANGING
        data_tab                = file_data
      EXCEPTIONS
        file_open_error         = 1
        file_read_error         = 2
        no_batch                = 3
        gui_refuse_filetransfer = 4
        invalid_type            = 5
        no_authority            = 6
        unknown_error           = 7
        bad_data_format         = 8
        header_not_allowed      = 9
        separator_not_allowed   = 10
        header_too_long         = 11
        unknown_dp_error        = 12
        access_denied           = 13
        dp_out_of_memory        = 14
        disk_full               = 15
        dp_timeout              = 16
        not_supported_by_gui    = 17
        error_no_gui            = 18
        OTHERS                  = 19 ).

  ENDMETHOD.

  METHOD read_file_on_server.

    CLEAR file_data.
    DATA line TYPE solix.

    TRY.
        OPEN DATASET file_name FOR INPUT IN BINARY MODE.
        IF sy-subrc EQ 0.
          DO.
            READ DATASET file_name INTO line. "ACTUAL LENGTH DATA(size).
            IF sy-subrc EQ 0.
              APPEND line TO file_data.
              "ADD size TO file_size.
            ELSE.
              EXIT. "do
            ENDIF.
          ENDDO.
        ENDIF.
      CATCH cx_root.
    ENDTRY.

    CLOSE DATASET file_name.

  ENDMETHOD.
  
ENDCLASS.
