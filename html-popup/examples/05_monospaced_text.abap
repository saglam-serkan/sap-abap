"--------------------------------------------------------------------*
" Monospaced Text Block
"--------------------------------------------------------------------*
REPORT sy-repid.

DATA(html_popup) = NEW zcl_html_popup( ).

DATA pre TYPE string_table.
APPEND 'SELECT *' TO pre.
APPEND '  FROM mara' TO pre.
APPEND '  WHERE matnr = ...' TO pre.

html_popup->append_monospaced_text_block( caption = 'SQL Code' rows = pre ).

html_popup->display( ).
