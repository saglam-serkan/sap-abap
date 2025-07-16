CLASS zcl_html_popup DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    CLASS cl_abap_browser DEFINITION LOAD .

    TYPES:
      callout_type TYPE c LENGTH 1 .
    
    TYPES:
      list_type TYPE c LENGTH 2 .
    
    TYPES:
      BEGIN OF param_value,
        param TYPE string,
        value TYPE string,
      END OF param_value .
      
    TYPES:
      param_value_tab TYPE TABLE OF param_value WITH EMPTY KEY .

    CONSTANTS:
      BEGIN OF callout_types,
        note     TYPE callout_type VALUE 'N',
        info     TYPE callout_type VALUE 'I',
        success  TYPE callout_type VALUE 'S',
        warning  TYPE callout_type VALUE 'W',
        error    TYPE callout_type VALUE 'E',
        critical TYPE callout_type VALUE 'C',
      END OF callout_types .
      
    CONSTANTS:
      BEGIN OF ol_types,
        decimal              TYPE list_type VALUE 'DE',
        decimal_leading_zero TYPE list_type VALUE 'DZ',
        lower_alpha          TYPE list_type VALUE 'LA',
        lower_roman          TYPE list_type VALUE 'LR',
        upper_alpha          TYPE list_type VALUE 'UA',
        upper_roman          TYPE list_type VALUE 'UR',
      END OF ol_types .
      
    CONSTANTS:
      BEGIN OF ul_types,
        circle TYPE list_type VALUE 'CI',
        disc   TYPE list_type VALUE 'DI',
        square TYPE list_type VALUE 'SQ',
      END OF ul_types .

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
    
    METHODS append_monospaced_text_block
      IMPORTING
        !caption TYPE string OPTIONAL
        !rows    TYPE string_table .
    METHODS append_button
      IMPORTING
        !label  TYPE string
        !action TYPE string
        !params TYPE param_value_tab .
    
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

    METHODS get_style
      RETURNING VALUE(style) TYPE string.

    METHODS on_button_click FOR EVENT sapevent OF cl_abap_browser
      IMPORTING action
                query_table.

ENDCLASS.



CLASS zcl_html_popup IMPLEMENTATION.


  METHOD append_button.

    DATA query_string TYPE string.

    LOOP AT params ASSIGNING FIELD-SYMBOL(<params>).
      query_string = |{ query_string }{ <params>-param }={ <params>-value }&|.
    ENDLOOP.

    popup_content &&=: |<form method=post action=SAPEVENT:{ action }?{ query_string }>|,
                       |<input type=submit class="button" value="{ label }"></form>|.

  ENDMETHOD.


  METHOD append_callout_paragraph.

    CHECK paragraph IS NOT INITIAL.

    begin_callout( type = type title = title ).
    append_paragraph( paragraph ).
    end_callout( ).

  ENDMETHOD.


  METHOD append_header.

    CHECK: header IS NOT INITIAL,
           size   BETWEEN 1 AND 6.

    popup_content &&= |<h{ size }>{ header }</h{ size }>|.

  ENDMETHOD.


  METHOD append_markdown_table.

    IF caption IS INITIAL AND headers IS INITIAL AND rows IS INITIAL.
      RETURN.
    ENDIF.

    DATA: header TYPE string,
          row    TYPE string,
          cell   TYPE string,
          cells  TYPE string_table.

    popup_content &&= |<table>|.

    IF caption IS NOT INITIAL.
      popup_content &&= |<caption>{ caption }</caption>|.
    ENDIF.

    IF headers IS NOT INITIAL.
      popup_content &&= |<thead><tr>|.
      LOOP AT headers INTO header.
        popup_content &&= |<th>{ header }</th>|.
      ENDLOOP.
      popup_content &&= |</tr></thead>|.
    ENDIF.

    IF rows IS NOT INITIAL.
      popup_content &&= |<tbody>|.
      LOOP AT rows INTO row.
        popup_content &&= |<tr>|.
        SPLIT row AT '|' INTO TABLE cells.
        LOOP AT cells INTO cell.
          popup_content &&= |<td>{ cell }</td>|.
        ENDLOOP.
        popup_content &&= |</tr>|.
      ENDLOOP.
      popup_content &&= |</tbody>|.
    ENDIF.

    popup_content &&= |</table>|.

  ENDMETHOD.


  METHOD append_monospaced_text_block.
    "preformatted text

    CHECK rows IS NOT INITIAL.

    DATA row TYPE string.

    IF caption IS NOT INITIAL.
      popup_content &&= |<strong>{ caption }</strong>|.
    ENDIF.

    popup_content &&= |<pre>|.

    LOOP AT rows INTO row.
      REPLACE ALL OCCURRENCES OF ` ` IN row WITH `&nbsp;`.
      popup_content &&= |{ row }<br>|.
    ENDLOOP.

    popup_content &&= |</pre>|.

  ENDMETHOD.


  METHOD append_ordered_list.

    CHECK: 'DE,DZ,LA,LR,UA,UR' CS type,
           items IS NOT INITIAL.

    DATA(list_type) = SWITCH string( type WHEN ol_types-decimal              THEN 'decimal'
                                          WHEN ol_types-decimal_leading_zero THEN 'decimal-leading-zero'
                                          WHEN ol_types-lower_alpha          THEN 'lower-alpha'
                                          WHEN ol_types-lower_roman          THEN 'lower-roman'
                                          WHEN ol_types-upper_alpha          THEN 'upper-alpha'
                                          WHEN ol_types-upper_roman          THEN 'upper-roman'
                                          ELSE                                    'decimal' ).

    popup_content &&= |<ol class="{ list_type }">|.

    LOOP AT items ASSIGNING FIELD-SYMBOL(<item>).
      popup_content &&= |<li>{ <item> }</li>|.
    ENDLOOP.

    popup_content &&= |</ol>|.

  ENDMETHOD.


  METHOD append_paragraph.

    popup_content &&= |<p>{ paragraph }</p>|.

  ENDMETHOD.


  METHOD append_unordered_list.

    CHECK: 'CI,DI,SQ' CS type,
           items IS NOT INITIAL.

    DATA(list_type) = SWITCH string( type WHEN ul_types-circle THEN 'circle'
                                          WHEN ul_types-disc   THEN 'disc'
                                          WHEN ul_types-square THEN 'square'
                                          ELSE                      'disc' ).

    popup_content &&= |<ul class="{ list_type }">|.

    LOOP AT items ASSIGNING FIELD-SYMBOL(<item>).
      popup_content &&= |<li>{ <item> }</li>|.
    ENDLOOP.

    popup_content &&= |</ul>|.

  ENDMETHOD.


  METHOD begin_callout.

    DATA(callout_type) = SWITCH string( type WHEN callout_types-note     THEN 'note'
                                             WHEN callout_types-info     THEN 'info'
                                             WHEN callout_types-success  THEN 'success'
                                             WHEN callout_types-warning  THEN 'warning'
                                             WHEN callout_types-error    THEN 'error'
                                             WHEN callout_types-critical THEN 'critical'
                                             ELSE                             'none' ).

    popup_content &&= |<div class="callout { callout_type }">|.
    popup_content &&= |<div class="callout-icon"></div><div>|.

    IF title IS NOT INITIAL.
      popup_content &&= |<strong>{ title }:</strong>|.
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
                 && |    <style>{ get_style( ) }</style>|
                 && |  </head>|
                 && |  <body>|
                 && |    <div class="popup">{ popup_content }</div>|
                 && |  </body>|
                 && |</html>| ).

  ENDMETHOD.


  METHOD end_callout.

    popup_content &&= |</div></div>|.

  ENDMETHOD.


  METHOD get_style.

    CONCATENATE
      `/* --------------------------------- */`
      `/* body                              */`
      `/* --------------------------------- */`
      `body {`
      `  font-family: Arial, sans-serif;`
      `  font-size: 13px;`
      `  background-color: #fafafa;`
      `}`
      `/* --------------------------------- */`
      `/* header                            */`
      `/* --------------------------------- */`
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
      `/* --------------------------------- */`
      `/* pre                               */`
      `/* --------------------------------- */`
      `pre {`
      `  font-family: "Lucida Console", "Courier New", monospace;`
      `  font-size: 12px;`
      `  width: 95%;`
      `  padding: 5px 5px 5px 5px;`
      `  border: 1px solid #ccc;`
      `  background-color: #f9f9f9;`
      `}`
      `/* --------------------------------- */`
      `/* list                              */`
      `/* --------------------------------- */`
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
      `/* --------------------------------- */`
      `/* table                             */`
      `/* --------------------------------- */`
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
      `/* --------------------------------- */`
      `/* popup div (headers, lists)        */`
      `/* --------------------------------- */`
      `.popup {`
      `  width: 95%;`
      `  max-width: 99%;`
      `  padding: 10px;`
      `  background-color: #fcfcfc;`
      `  border-radius: 9px;`
      `  box-shadow: 0 3px 9px rgba(0, 0, 0, 0.15);`
      `  margin: auto;`
      `}`
      `/* --------------------------------- */`
      `/* callouts                          */`
      `/* --------------------------------- */`
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
      INTO style.

  ENDMETHOD.


  METHOD on_button_click.

    cl_demo_output=>write( action ).
    cl_demo_output=>write( query_table ).
    cl_demo_output=>display( ).

  ENDMETHOD.
  
ENDCLASS.
