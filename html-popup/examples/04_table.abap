"--------------------------------------------------------------------*
" Table from String Table
"--------------------------------------------------------------------*
REPORT sy-repid.

DATA(html_popup) = NEW zcl_html_popup( ).

DATA(rows) = VALUE string_table(
               ( `lorem|ipsum|dolor` )
               ( `sit|amet|consectetur` )
               ( `adipiscing|elit|sed` )
             ).

html_popup->append_table_from_string_tab(
    caption   = 'Sample Lorem Ipsum Table'
    header    = 'Column 1|Column 2|Column 3'
    rows      = rows
    delimiter = '|'
       ).

html_popup->display( ).
