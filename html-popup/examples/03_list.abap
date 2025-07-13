"--------------------------------------------------------------------*
" Ordered & Unordered Lists
"--------------------------------------------------------------------*
REPORT sy-repid.

DATA(html_popup) = NEW zcl_html_popup( ).

DATA items TYPE string_table.
APPEND 'First' TO items.
APPEND 'Second' TO items.
APPEND 'Third' TO items.

html_popup->append_header( header = 'Steps to Follow' size = '4' ).
html_popup->append_ordered_list( items = items ).

html_popup->append_header( header = 'Notes' size = '4' ).
html_popup->append_unordered_list( items = items ).

html_popup->display( ).
