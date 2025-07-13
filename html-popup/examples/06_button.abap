"--------------------------------------------------------------------*
" Button with Parameters
"--------------------------------------------------------------------*
REPORT sy-repid.

DATA(html_popup) = NEW zcl_html_popup( ).

DATA(params) = VALUE zcl_html_popup=>param_value_tab( ( param = 'ID' value = '123' )
                                                      ( param = 'ACTION' value = 'RUN' ) ).

html_popup->append_header( header = 'Execute Action' size = '4' ).
html_popup->append_paragraph( paragraph = 'Click the button to proceed.' ).
html_popup->append_button( label = 'Execute' action = 'EXECUTE' params = params ).

html_popup->display( ).
