"--------------------------------------------------------------------*
" Callouts
"--------------------------------------------------------------------*
REPORT sy-repid.

DATA(html_popup) = NEW zcl_html_popup( ).

html_popup->append_callout_paragraph(
    type      = zcl_html_popup=>callout_types-note
    title     = 'Note'
    paragraph = 'Please ensure that all mandatory fields in the form are'
             && ' filled correctly before proceeding with the submission.'
             && ' Missing or incorrect data may result in processing delays'
             && ' or rejection of your request. If you are unsure about any'
             && ' field, hover over the field label for more information or'
             && ' consult the user guide.' ).

html_popup->append_callout_paragraph(
    type      = zcl_html_popup=>callout_types-info
    title     = 'Information'
    paragraph = 'The system is scheduled to perform an automatic data'
             && ' synchronization overnight between 12:00 AM and 3:00 AM.'
             && ' During this time, certain functions may be temporarily'
             && ' unavailable. No user action is required during this'
             && ' maintenance window, but please plan your work accordingly'
             && ' to avoid interruptions.' ).

html_popup->append_callout_paragraph(
    type      = zcl_html_popup=>callout_types-success
    title     = 'Success'
    paragraph = 'The operation you initiated has completed successfully.'
             && ' All data has been saved, and the changes will be reflected'
             && ' in the system immediately. If you encounter any issues'
             && ' with the updated information, please report them to the'
             && ' IT support team for further assistance.' ).

html_popup->append_callout_paragraph(
    type      = zcl_html_popup=>callout_types-warning
    title     = 'Warning'
    paragraph = 'This operation may take several minutes to complete'
             && ' depending on the size of the data and the current system'
             && ' load. Please do not close this window or navigate away'
             && ' while the process is running, as this may interrupt the'
             && ' operation and cause incomplete data updates. Ensure you'
             && ' have a stable internet connection before proceeding.' ).

html_popup->append_callout_paragraph(
    type      = zcl_html_popup=>callout_types-error
    title     = 'Error'
    paragraph = 'An unexpected error has occurred while processing your'
             && ' request. The system was unable to complete the operation'
             && ' due to a temporary issue. Please try again after a few'
             && ' minutes. If the problem persists, contact the IT support'
             && ' team and provide the following error code: 12345.' ).

html_popup->append_callout_paragraph(
    type      = zcl_html_popup=>callout_types-critical
    title     = 'Critical'
    paragraph = 'System resources have reached a critically low threshold,'
             && ' which may result in performance degradation or service'
             && ' outages. Immediate action is required to free up resources'
             && ' or increase capacity. Please notify the system administrator'
             && ' immediately and avoid running any large or non-essential'
             && ' processes until the issue has been resolved.' ).

html_popup->display( ).
