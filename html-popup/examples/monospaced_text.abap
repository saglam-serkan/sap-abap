"--------------------------------------------------------------------*
" Monospaced Text Block
"--------------------------------------------------------------------*
REPORT sy-repid.

DATA(html_popup) = NEW zcl_html_popup( ).

DATA(rows) = VALUE string_table(
               ( `SELECT *` )
               ( `  FROM mara` )
               ( `  WHERE matnr = ...` )
             ).

html_popup->append_monospaced_block( caption = 'SQL Code' rows = rows ).
html_popup->display( ).
