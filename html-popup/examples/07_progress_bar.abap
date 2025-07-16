"--------------------------------------------------------------------*
" Progress Bar
"--------------------------------------------------------------------*
REPORT sy-repid.

DATA(html_popup) = NEW zcl_html_popup( ).

html_popup->append_header( header = 'Progress Bar' size = '4' ).

html_popup->append_progress_bar( value = 25 max_value = 100 color = zcl_html_popup=>progress_colors-green ).
html_popup->append_progress_bar( value = 50 max_value = 100 color = zcl_html_popup=>progress_colors-blue ).
html_popup->append_progress_bar( value = 75 max_value = 100 color = zcl_html_popup=>progress_colors-orange ).
html_popup->append_progress_bar( value = 100 max_value = 100 color = zcl_html_popup=>progress_colors-red ).

html_popup->display( ).
