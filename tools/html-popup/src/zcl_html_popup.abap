CLASS zcl_html_popup DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    CLASS cl_abap_browser DEFINITION LOAD .

    TYPES callout_type TYPE string .
    TYPES list_type TYPE string .
    TYPES progress_color TYPE string .

    CONSTANTS:
      BEGIN OF callout_types,
        note     TYPE string VALUE 'note',
        info     TYPE string VALUE 'info',
        success  TYPE string VALUE 'success',
        warning  TYPE string VALUE 'warning',
        error    TYPE string VALUE 'error',
        critical TYPE string VALUE 'critical',
      END OF callout_types .
      
    CONSTANTS:
      BEGIN OF ol_types,
        decimal              TYPE list_type VALUE 'decimal',
        decimal_leading_zero TYPE list_type VALUE 'decimal-leading-zero',
        lower_alpha          TYPE list_type VALUE 'lower-alpha',
        lower_roman          TYPE list_type VALUE 'lower-roman',
        upper_alpha          TYPE list_type VALUE 'upper-alpha',
        upper_roman          TYPE list_type VALUE 'upper-roman',
      END OF ol_types .
      
    CONSTANTS:
      BEGIN OF ul_types,
        circle TYPE list_type VALUE 'circle',
        disc   TYPE list_type VALUE 'disc',
        square TYPE list_type VALUE 'square',
      END OF ul_types .
      
    CONSTANTS:
      BEGIN OF progress_colors,
        red    TYPE string VALUE 'red',
        blue   TYPE string VALUE 'blue',
        green  TYPE string VALUE 'green',
        orange TYPE string VALUE 'orange',
      END OF progress_colors .

    METHODS clear_content .
    
    METHODS append_header
      IMPORTING
        !header TYPE string
        !size   TYPE numc1 DEFAULT 1 .
    
    METHODS append_paragraph
      IMPORTING
        !paragraph TYPE string OPTIONAL .
    
    METHODS append_ordered_list
      IMPORTING
        !type  TYPE zcl_html_popup=>list_type DEFAULT zcl_html_popup=>ol_types-decimal
        !items TYPE string_table .
    
    METHODS append_unordered_list
      IMPORTING
        !type  TYPE zcl_html_popup=>list_type DEFAULT zcl_html_popup=>ul_types-disc
        !items TYPE string_table .
    
    METHODS append_markdown_table
      IMPORTING
        !caption TYPE string OPTIONAL
        !headers TYPE string_table OPTIONAL
        !rows    TYPE string_table OPTIONAL .
    
    METHODS append_table_from_string_tab
      IMPORTING
        !caption   TYPE string OPTIONAL
        !header    TYPE string OPTIONAL
        !rows      TYPE string_table OPTIONAL
        !delimiter TYPE char1 .
    
    METHODS append_monospaced_block
      IMPORTING
        !caption TYPE string OPTIONAL
        !rows    TYPE string_table .
    
    METHODS append_progress_bar
      IMPORTING
        !value     TYPE i
        !max_value TYPE i
        !color     TYPE zcl_html_popup=>progress_color DEFAULT zcl_html_popup=>progress_colors-green .
    
    METHODS append_button
      IMPORTING
        !label  TYPE string
        !action TYPE string
        !params TYPE tihttpnvp .
    
    METHODS append_element
      IMPORTING
        !element TYPE string .
    
    METHODS append_callout_paragraph
      IMPORTING
        !type      TYPE zcl_html_popup=>callout_type DEFAULT zcl_html_popup=>callout_types-note
        !title     TYPE string OPTIONAL
        !paragraph TYPE string .
    
    METHODS begin_callout
      IMPORTING
        !type  TYPE zcl_html_popup=>callout_type DEFAULT zcl_html_popup=>callout_types-note
        !title TYPE string OPTIONAL .
    
    METHODS end_callout .
    
    METHODS display
      IMPORTING
        !title TYPE cl_abap_browser=>title OPTIONAL
        !size  TYPE string DEFAULT cl_abap_browser=>medium .
    
  PROTECTED SECTION.

  PRIVATE SECTION.

    DATA popup_content TYPE string .

    METHODS append_content
      IMPORTING
        !content TYPE string .
    
    METHODS get_css_style
      RETURNING
        VALUE(style) TYPE string .
    
    METHODS on_button_click
        FOR EVENT sapevent OF cl_abap_browser
      IMPORTING
        !action
        !query_table .
    
ENDCLASS.



CLASS zcl_html_popup IMPLEMENTATION.


  METHOD append_button.

    append_content(:
      |<form method=post action=SAPEVENT:{ action }?{ cl_http_utility=>if_http_utility~fields_to_string( params ) }>| ),
      |<input type=submit class="button" value="{ label }"></form>| ).

  ENDMETHOD.


  METHOD append_callout_paragraph.

    CHECK paragraph IS NOT INITIAL.

    begin_callout( type = type title = title ).
    append_paragraph( paragraph ).
    end_callout( ).

  ENDMETHOD.


  METHOD append_content.

    popup_content = popup_content && content.

  ENDMETHOD.


  METHOD append_element.

    append_content( element ).

  ENDMETHOD.


  METHOD append_header.

    CHECK: header IS NOT INITIAL,
           size   BETWEEN 1 AND 6.

    append_content( |<h{ size }>{ header }</h{ size }>| ).

  ENDMETHOD.


  METHOD append_markdown_table.

    IF caption IS INITIAL AND headers IS INITIAL AND rows IS INITIAL.
      RETURN.
    ENDIF.

    DATA: header TYPE string,
          row    TYPE string,
          cell   TYPE string,
          cells  TYPE string_table.

    append_content( |<table>| ).

    IF caption IS NOT INITIAL.
      append_content( |<caption>{ caption }</caption>| ).
    ENDIF.

    IF headers IS NOT INITIAL.
      append_content( |<thead><tr>| ).
      LOOP AT headers INTO header.
        append_content( |<th>{ header }</th>| ).
      ENDLOOP.
      append_content( |</tr></thead>| ).
    ENDIF.

    IF rows IS NOT INITIAL.
      append_content( |<tbody>| ).
      LOOP AT rows INTO row.
        append_content( |<tr>| ).
        SPLIT row AT '|' INTO TABLE cells.
        LOOP AT cells INTO cell.
          append_content( |<td>{ cell }</td>| ).
        ENDLOOP.
        append_content( |</tr>| ).
      ENDLOOP.
      append_content( |</tbody>| ).
    ENDIF.

    append_content( |</table>| ).

  ENDMETHOD.


  METHOD append_monospaced_block.

    "Appends a block of text in monospaced font, preserving whitespace formatting.

    CHECK rows IS NOT INITIAL.

    DATA row TYPE string.

    IF caption IS NOT INITIAL.
      append_content( |<strong>{ caption }</strong>| ).
    ENDIF.

    append_content( |<pre>| ).

    LOOP AT rows INTO row.
      REPLACE ALL OCCURRENCES OF ` ` IN row WITH `&nbsp;`.
      append_content( |{ row }<br>| ).
    ENDLOOP.

    append_content( |</pre>| ).

  ENDMETHOD.


  METHOD append_ordered_list.

    CHECK items IS NOT INITIAL.

    append_content( |<ol class="{ type }">| ).

    LOOP AT items ASSIGNING FIELD-SYMBOL(<item>).
      append_content( |<li>{ <item> }</li>| ).
    ENDLOOP.

    append_content( |</ol>| ).

  ENDMETHOD.


  METHOD append_paragraph.

    append_content( |<p>{ paragraph }</p>| ).

  ENDMETHOD.


  METHOD append_progress_bar.

    CHECK: value    >= 0,
           max_value > 0.

    append_content( |<progress value="{ value }" max="{ max_value }" class="{ color }"></progress><br>| ).

  ENDMETHOD.


  METHOD append_table_from_string_tab.

    CHECK delimiter IS NOT INITIAL.

    IF header IS INITIAL AND rows IS INITIAL.
      RETURN.
    ENDIF.

    DATA: headers TYPE string_table,
          row     TYPE string,
          cell    TYPE string,
          cells   TYPE string_table.

    append_content( |<table>| ).

    IF caption IS NOT INITIAL.
      append_content( |<caption>{ caption }</caption>| ).
    ENDIF.

    IF header IS NOT INITIAL.
      SPLIT header AT delimiter INTO TABLE headers.
      IF headers IS NOT INITIAL.
        append_content( |<thead><tr>| ).
        LOOP AT headers ASSIGNING FIELD-SYMBOL(<header>).
          append_content( |<th>{ <header> }</th>| ).
        ENDLOOP.
        append_content( |</tr></thead>| ).
      ENDIF.
    ENDIF.

    IF rows IS NOT INITIAL.
      append_content( |<tbody>| ).
      LOOP AT rows INTO row.
        append_content( |<tr>| ).
        SPLIT row AT delimiter INTO TABLE cells.
        LOOP AT cells INTO cell.
          append_content( |<td>{ cell }</td>| ).
        ENDLOOP.
        append_content( |</tr>| ).
      ENDLOOP.
      append_content( |</tbody>| ).
    ENDIF.

    append_content( |</table>| ).

  ENDMETHOD.


  METHOD append_unordered_list.

    CHECK items IS NOT INITIAL.

    append_content( |<ul class="{ type }">| ).

    LOOP AT items ASSIGNING FIELD-SYMBOL(<item>).
      append_content( |<li>{ <item> }</li>| ).
    ENDLOOP.

    append_content( |</ul>| ).

  ENDMETHOD.


  METHOD begin_callout.

    append_content( |<div class="callout { type }">| ).
    append_content( |<div class="callout-icon"></div><div>| ).

    IF title IS NOT INITIAL.
      append_content( |<strong>{ title }:</strong>| ).
    ENDIF.

  ENDMETHOD.


  METHOD clear_content.

    CLEAR popup_content.

  ENDMETHOD.


  METHOD display.

    SET HANDLER on_button_click.

    cl_abap_browser=>show_html(
      title       = title
      size        = size
      html_string = |<!DOCTYPE html>|
                 && |<html lang="en">|
                 && |  <head>|
                 && |    <meta charset="UTF-8" />|
                 && |    <style>{ get_css_style( ) }</style>|
                 && |  </head>|
                 && |  <body>|
                 && |    <div class="popup">{ popup_content }</div>|
                 && |  </body>|
                 && |</html>| ).

  ENDMETHOD.


  METHOD end_callout.

    append_content( |</div></div>| ).

  ENDMETHOD.


  METHOD get_css_style.

    CONCATENATE
      `/* ------------------------------------------------------------------ */`
      `/* body                                                               */`
      `/* ------------------------------------------------------------------ */`
      `body {`
      `  font-family: Arial, sans-serif;`
      `  font-size: 13px;`
      `  background-color: #fafafa;`
      `}`
      `/* ------------------------------------------------------------------ */`
      `/* header                                                             */`
      `/* ------------------------------------------------------------------ */`
      `h1 {`
      `  font-size: 20px;`
      `  margin: 10px 0px 10px 0px;`
      `}`
      `h2 {`
      `  font-size: 18px;`
      `  margin: 10px 0px 10px 0px;`
      `}`
      `h3 {`
      `  font-size: 16px;`
      `  margin: 10px 0px 10px 0px;`
      `}`
      `h4 {`
      `  font-size: 15px;`
      `  margin: 10px 0px 10px 0px;`
      `}`
      `h5 {`
      `  font-size: 14px;`
      `  margin: 10px 0px 10px 0px;`
      `}`
      `h6 {`
      `  font-size: 13px;`
      `  margin: 10px 0px 10px 0px;`
      `}`
      `/* ------------------------------------------------------------------ */`
      `/* pre                                                                */`
      `/* ------------------------------------------------------------------ */`
      `pre {`
      `  font-family: "Lucida Console", "Courier New", monospace;`
      `  font-size: 12px;`
      `  width: 95%;`
      `  padding: 5px 5px 5px 5px;`
      `  border: 1px solid #ccc;`
      `  background-color: #f9f9f9;`
      `}`
      `/* ------------------------------------------------------------------ */`
      `/* list                                                               */`
      `/* ------------------------------------------------------------------ */`
      `ul.circle {list-style-type: circle;}`
      `ul.disc {list-style-type: disc;}`
      `ul.square {list-style-type: square;}`
      `ol.decimal {list-style-type: decimal;}`
      `ol.decimal-leading-zero {list-style-type: decimal-leading-zero;}`
      `ol.lower-alpha {list-style-type: lower-alpha;}`
      `ol.lower-roman {list-style-type: lower-roman;}`
      `ol.upper-alpha {list-style-type: upper-alpha;}`
      `ol.upper-roman {list-style-type: upper-roman;}`
      ``
      `/* ------------------------------------------------------------------ */`
      `/* table                                                              */`
      `/* ------------------------------------------------------------------ */`
      `table {`
      `  font-size: 12px;`
      `  width: 95%;`
      `  margin: 0px 0px 10px 0px;`
      `  background-color: #ffffff;`
      `  border-collapse: collapse;`
      `}`
      `th, td {`
      `  border: 1px solid #ccc;`
      `  padding: 5px 9px;`
      `  text-align: left;`
      `}`
      `th {`
      `  font-size: 12px;`
      `  font-weight: bold;`
      `  background-color: #f0f0f0;`
      `}`
      `caption {`
      `  font-size: 12px;`
      `  font-weight: bold;`
      `  text-align: left;`
      `  margin: 15px 0px 7px 0px;`
      `}`
      `/* ------------------------------------------------------------------ */`
      `/* popup div (headers, lists)                                         */`
      `/* ------------------------------------------------------------------ */`
      `.popup {`
      `  width: 95%;`
      `  max-width: 99%;`
      `  padding: 10px;`
      `  background-color: #fcfcfc;`
      `  border-radius: 9px;`
      `  box-shadow: 0 3px 9px rgba(0, 0, 0, 0.15);`
      `  margin: auto;`
      `}`
      `/* ------------------------------------------------------------------ */`
      `/* callouts                                                           */`
      `/* ------------------------------------------------------------------ */`
      `.callout {`
      `  font-family: sans-serif;`
      `  font-size: 13px;`
      `  line-height: 1.5;`
      `  display: flex;`
      "`  gap: 1px;`
      `  padding: 10px 10px;`
      `  margin: 14px 0px 0px 0px;`
      `  border-radius: 9px;`
      `  border-left: 4px solid;`
      "` box-shadow: 0 1px 1px rgba(0, 0, 0, 0.5);`
      `}`
      `.callout-icon {`
      `  margin: 0px 3px 0px 1px;`
      `}`
      `.note     { background: #ede7f6; border-color: #7e57c2; color: #4527a0; }`
      `.info     { background: #e7f0ff; border-color: #2979ff; color: #0d47a1; }`
      `.success  { background: #e8f5e9; border-color: #4caf50; color: #1b5e20; }`
      `.warning  { background: #fff8e1; border-color: #ff9800; color: #e65100; }`
      `.error    { background: #fce4ec; border-color: #e91e63; color: #880e4f; }`
      `.critical { background: #fce4ec; border-color: #e91e63; color: #880e4f; }`
      `.quote    { background: #f5f5f5; border-color: #9e9e9e; color: #424242; }`
      `/* ------------------------------------------------------------------ */`
      `/* progress bar                                                       */`
      `/* ------------------------------------------------------------------ */`
      `/* unfilled part */`
      `progress {`
      `  background: #e0e0e0; /* Gray 300 */`
      `  height: 10px;`
      `  border-radius: 10px;`
      `}`
      `/* unfilled part (Chrome/Safari) */`
      `progress::-webkit-progress-bar {`
      `  background: #e0e0e0; /* Gray 300 */`
      `  height: 10px;`
      `  border-radius: 10px;`
      `}`
      `/* filled part (Chrome/Safari) */`
      `progress::-webkit-progress-value {`
      `  background: currentColor;`
      `  border-radius: 10px;`
      `}`
      `/* filled part (Firefox) */`
      `progress::-moz-progress-bar {`
      `  background: currentColor`
      `  border-radius: 10px;`
      `}`
      `/* filled part */`
      `progress.red { color: #f44336; } /* Red 500 */`
      `progress.blue { color: #2196f3; } /* Blue 500 */`
      `progress.green { color: #4caf50; } /* Green 500 */`
      `progress.orange { color: #ff9800; } /* Orange 500 */`
      INTO style.

  ENDMETHOD.


  METHOD on_button_click.

    cl_demo_output=>write( action ).
    cl_demo_output=>write( query_table ).
    cl_demo_output=>display( ).

    "cl_http_utility=>if_http_utility~fields_to_string(
    "cl_http_utility=>if_http_utility~string_to_fields(

  ENDMETHOD.

ENDCLASS.
