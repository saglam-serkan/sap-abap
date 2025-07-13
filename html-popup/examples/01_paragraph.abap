"--------------------------------------------------------------------*
" Header and Paragraph
"--------------------------------------------------------------------*
REPORT sy-repid.

DATA(html_popup) = NEW zcl_html_popup( ).

html_popup->append_header( header = 'HTML Popup' size = '2' ).
html_popup->append_paragraph( paragraph = 'This is a simple HTML popup with a header and paragraph.' ).

html_popup->display( ).
