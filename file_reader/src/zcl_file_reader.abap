CLASS zcl_file_reader DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    METHODS constructor
      IMPORTING
        !file_path TYPE string .

    METHODS open_file .

    METHODS close_file .

    METHODS read_next_line
      RETURNING
        value(line) TYPE string .

    TYPE-POOLS abap .

    METHODS read_all_lines
      IMPORTING
        !skip_empty_lines TYPE abap_bool
      RETURNING
        value(lines) TYPE string_table .

    METHODS get_line_number
      RETURNING
        value(value) TYPE i .

    METHODS is_file_open
      RETURNING
        value(value) TYPE abap_bool .

    METHODS is_end_of_file
      RETURNING
        value(value) TYPE abap_bool .

  PROTECTED SECTION.

  PRIVATE SECTION.

    DATA _file_path TYPE string .
    DATA _is_file_open TYPE abap_bool .
    DATA _is_end_of_file TYPE abap_bool .
    DATA _line_number TYPE i .

ENDCLASS.


CLASS zcl_file_reader IMPLEMENTATION.

  METHOD close_file.

    "--------------------------------------------------------------------*
    " Closes the file
    "--------------------------------------------------------------------*
    "
    " Notes
    " - If the file is already closed or does not exist, the statement is
    "   ignored and the return code sy-subrc is set to 0.
    "  - An opened file that was not explicitly closed using CLOSE DATASET
    "   is automatically closed when the program is exited.
    " - If a file was opened without the FILTER addition, sy-subrc always
    "   contains the value 0 (if no exception is raised).
    " - If a file was opened using the FILTER addition, sy-subrc contains
    "   the return code of the filter program, which is returned by the
    "   operating system. This value is generally 0 if the statement was
    "   executed with no exceptions.
    "
    " Catchable Exceptions
    "   |-------------------------------|----------------------------------------------|---------------------------|
    "   | Exception                     | Cause                                        | Runtime Error             |
    "   |-------------------------------|----------------------------------------------|---------------------------|
    "   | CX_SY_FILE_CLOSE              | The file could not be closed. Insufficient   | DATASET_CANT_CLOSE        |
    "   |                               | memory space is a possible reason for this.  |                           |
    "   |-------------------------------|----------------------------------------------|---------------------------|
    "--------------------------------------------------------------------*

    CHECK _is_file_open = abap_true.

    DATA: exception TYPE REF TO cx_root,
          message TYPE string.

    TRY.
        CLOSE DATASET _file_path.
        _is_file_open = abap_false.

      CATCH cx_root INTO exception.
        message = exception->get_longtext( ).
    ENDTRY.

  ENDMETHOD.                    "close_file

  METHOD constructor.

    _file_path = file_path.

  ENDMETHOD.                    "constructor

  METHOD get_line_number.

    " Returns the current line number being read
    value = _line_number.

  ENDMETHOD.                    "get_line_number

  METHOD is_end_of_file.

    " Returns abap_true if end of file is reached
    value = _is_end_of_file.

  ENDMETHOD.                    "is_end_of_file

  METHOD is_file_open.

    " Returns abap_true if the file is open
    value = _is_file_open.

  ENDMETHOD.                    "is_file_open

  METHOD open_file.

    "--------------------------------------------------------------------*
    " Opens the file if not already open
    "--------------------------------------------------------------------*
    "
    " Notes
    " - The addition FOR INPUT opens the file for reading. By default,
    "   the file pointer is set at the start of the file. If the file
    "   specified does not exist, sy-subrc is set to 8.
    " - The addition IN TEXT MODE opens the file as a text file.
    " - The addition ENCODING defines how the characters are represented
    "   in the text file.
    "
    " Catchable Exceptions
    "   |-------------------------------|---------------------------|----------------------------------------------|
    "   | Exception                     | Runtime Error             | Cause                                        |
    "   |-------------------------------|---------------------------|----------------------------------------------|
    "   | CX_SY_FILE_OPEN               | DATASET_REOPEN            | The file is already open.                    |
    "   | CX_SY_CODEPAGE_CONVERTER_INIT | CONVT_CODEPAGE_INIT       | The desired conversion is not supported.     |
    "   |                               |                           | (Due to specification of invalid code page   |
    "   |                               |                           | or of language not supported in the          |
    "   |                               |                           | conversion, with SET LOCALE LANGUAGE.)       |
    "   | CX_SY_CONVERSION_CODEPAGE     | CONVT_CODEPAGE            | Internal error in the conversion.            |
    "   | CX_SY_FILE_AUTHORITY          | OPEN_DATASET_NO_AUTHORITY | No authorization for access to file          |
    "   | CX_SY_FILE_AUTHORITY          | OPEN_PIPE_NO_AUTHORITY    | Authorization for access to this file is     |
    "   |                               |                           | missing in OPEN DATASET with addition FILTER.|
    "   | CX_SY_PIPES_NOT_SUPPORTED     | DATASET_NO_PIPE           | The operating system does not support pipes. |
    "   | CX_SY_TOO_MANY_FILES          | DATASET_TOO_MANY_FILES    | Maximum number of open files exceeded.       |
    "   |-------------------------------|---------------------------|----------------------------------------------|
    "--------------------------------------------------------------------*

    CHECK _is_file_open = abap_false.

    DATA: exception TYPE REF TO cx_root,
          message TYPE string.

    TRY.
        OPEN DATASET _file_path FOR INPUT
                                IN TEXT MODE
                                ENCODING DEFAULT.
        CASE sy-subrc.
          WHEN 0.
            " The file was opened.
            _is_file_open   = abap_true.
            _is_end_of_file = abap_false.
          WHEN 8.
            " The operating system could not open the file.
            message = 'The operating system could not open the file.'.
        ENDCASE.

      CATCH cx_root INTO exception.
        message = exception->get_longtext( ).
    ENDTRY.

  ENDMETHOD.                    "open_file

  METHOD read_all_lines.

    "--------------------------------------------------------------------*
    " Reads all lines from the file into a table
    "--------------------------------------------------------------------*

    DATA line TYPE string.

    WHILE is_end_of_file( ) = abap_false.
      line = read_next_line( ).

      IF line IS INITIAL AND skip_empty_lines = abap_true.
        CONTINUE.
      ELSE.
        APPEND line TO lines.
      ENDIF.
    ENDWHILE.

  ENDMETHOD.                    "read_all_lines

  METHOD read_next_line.

    "--------------------------------------------------------------------*
    " Reads the next line from the file
    "--------------------------------------------------------------------*
    "
    " Notes
    " - The data from the text files should be imported solely into
    "   character-like data objects and data from binary files should be
    "   imported solely into byte-like data objects.
    " - To evaluate imported data as numeric data objects or mixed
    "   structures, it is recommended that you export these into binary
    "   containers and then assign these using the CASTING addition of
    "   the ASSIGN statement in accordance with the typed field symbols.
    "
    " Catchable Exceptions
    "   |-------------------------------|---------------------------|----------------------------------------------|
    "   | Exception                     | Runtime Error             | Cause                                        |
    "   |-------------------------------|---------------------------|----------------------------------------------|
    "   | CX_SY_CODEPAGE_CONVERTER_INIT | CONVT_CODEPAGE_INIT       | The desired conversion is not supported.     |
    "   |                               |                           | (For example, because a language not         |
    "   |                               |                           | supported by the conversion was specified    |
    "   |                               |                           | using SET LOCALE LANGUAGE.)                  |
    "   | CX_SY_CONVERSION_CODEPAGE     | CONVT_CODEPAGE            | Conversion is not possible. The data is read |
    "   |                               |                           | as far as possible. Text data where the      |
    "   |                               |                           | conversion has failed is undefined.          |
    "   | CX_SY_FILE_AUTHORITY          | OPEN_DATASET_NO_AUTHORITY | No authorization for access to file          |
    "   | CX_SY_FILE_IO                 | DATASET_READ_ERROR        | When reading the file, an error occurred.    |
    "   | CX_SY_FILE_OPEN               | DATASET_CANT_OPEN         | File cannot be opened.                       |
    "   | CX_SY_FILE_OPEN_MODE          | DATASET_NOT_OPEN          | The file is not open.                        |
    "   | CX_SY_PIPE_REOPEN             | DATASET_PIPE_CLOSED       | The file was opened using the addition       |
    "   |                               |                           | FILTER and since then a switch of the work   |
    "   |                               |                           | process took place.                          |
    "   |-------------------------------|---------------------------|----------------------------------------------|
    "--------------------------------------------------------------------*

    CLEAR line.

    CHECK _is_file_open = abap_true.

    DATA: exception TYPE REF TO cx_root,
          message   TYPE string.

    TRY.
        READ DATASET _file_path INTO line.

        CASE sy-subrc.
          WHEN 0.
            " Data was read without reaching end of file.
            " Increment line counter only if line was read
            ADD 1 TO _line_number.
          WHEN 4.
            " Data was read and the end of the file was reached
            " or there was an attempt to read after the end of the file.
            message = 'The end of the file was reached.'.
            _is_end_of_file = abap_true.
            close_file( ).
        ENDCASE.

      CATCH cx_root INTO exception.
        message = exception->get_longtext( ).
        _is_end_of_file = abap_true.
        close_file( ).
    ENDTRY.

  ENDMETHOD.
  
ENDCLASS.
