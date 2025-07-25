"--------------------------------------------------------------------*
" Lists
"--------------------------------------------------------------------*
REPORT sy-repid.

DATA(html_popup) = NEW zcl_html_popup( ).

DATA(items) = VALUE string_table( ( `First` ) ( `Second` ) ( `Third` ) ).

html_popup->append_header( header = 'Steps to Follow' size = '4' ).
html_popup->append_ordered_list( type = zcl_html_popup=>ol_types-decimal items = items ).
html_popup->append_header( header = 'Notes' size = '4' ).
html_popup->append_unordered_list( type = zcl_html_popup=>ul_types-disc items = items ).
html_popup->display( ).
