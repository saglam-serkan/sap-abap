"--------------------------------------------------------------------*
" Markdown-like Table
"--------------------------------------------------------------------*
REPORT sy-repid.

DATA(html_popup) = NEW zcl_html_popup( ).

DATA headers TYPE string_table.
APPEND 'Name' TO headers.
APPEND 'Status' TO headers.

DATA rows TYPE string_table.
APPEND 'Server A|Running' TO rows.
APPEND 'Server B|Stopped' TO rows.
APPEND 'Server C|Restarting' TO rows.

html_popup->append_markdown_table( caption = 'System Status' headers = headers rows = rows ).

html_popup->display( ).
