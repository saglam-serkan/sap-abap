"--------------------------------------------------------------------*
"
" Class ZCL_EMAIL_UTIL
" Utility class: Email
"
" Purpose:
"   Utility class for constructing and sending emails.
"   Provides methods for building and sending email using CL_BCS.
"
" Dependencies
" - Interface ZIF_UTILITY
" - Exception Class ZCX_U_EXCEPTION
"
" Methods
"   CREATE_INSTANCE        | Create a new singleton instance of the class
"   GET_INSTANCE           | Return the existing singleton instance
"   ADD_BODY               | Append text to the email body
"   ADD_ATTACHMENT         | Add an attachment to the email
"   ADD_RECIPIENT          | Add a recipient to the email
"   HAS_ATTACHMENTS        | Check if the email contains attachments
"   HAS_RECIPIENTS         | Check if the email contains recipients
"   GET_BODY               | Retrieve the current email body text
"   GET_RECIPIENTS         | Retrieve all recipients added to the email
"   GET_SENDER             | Return the sender (BCS object)
"   GET_SUBJECT            | Retrieve the email subject line
"   RESET                  | Clear all data (body, recipients, attachments)
"   REMOVE_ATTACHMENTS     | Remove all attachments from the email
"   REMOVE_RECIPIENTS      | Remove all recipients from the email
"   SEND                   | Send the composed email
"   SET_BODY               | Set (replace) the email body
"   SET_SENDER             | Define the email sender
"   SET_SUBJECT            | Define the email subject line
"   VALIDATE_EMAIL_ADDRESS | Validate the format of an email address
"   _GET_SENDER            | Retrieve sender data (private helper)
"   _GET_RECIPIENT         | Retrieve recipient data (private helper)
"
"--------------------------------------------------------------------*

CLASS zcl_u_email DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE .

  PUBLIC SECTION.

    INTERFACES zif_utility .

    TYPES:
      BEGIN OF sender,
        email TYPE string,
        name  TYPE string,
        uname TYPE uname,
      END OF sender .

    TYPES:
      BEGIN OF recipient,
        email TYPE string,
        name  TYPE string,
        uname TYPE uname,
        cc    TYPE abap_bool,
        bcc   TYPE abap_bool,
      END OF recipient .

    TYPES:
      recipients TYPE TABLE OF recipient WITH EMPTY KEY .

    TYPES:
      BEGIN OF attachment,
        type        TYPE soodk-objtp,
        subject     TYPE sood-objdes,
        content_hex TYPE solix_tab,
      END OF attachment .

    TYPES:
      attachments TYPE TABLE OF attachment WITH EMPTY KEY .

    TYPES:
      BEGIN OF email,
        sender      TYPE sender,
        recipients  TYPE recipients,
        subject     TYPE string,
        body        TYPE string,
        attachments TYPE attachments,
        "importance  TYPE so_obj_pri,
        "sensitivity TYPE so_obj_sns,
        "priority    TYPE so_snd_pri,
      END OF email .

    CLASS-METHODS create_instance
      RETURNING
        VALUE(instance) TYPE REF TO zcl_u_email .

    CLASS-METHODS get_instance
      RETURNING
        VALUE(instance) TYPE REF TO zcl_u_email .

    METHODS add_attachment
      IMPORTING
        !file_type    TYPE string
        !file_name    TYPE string
        !file_content TYPE any
      RAISING
        cx_bcs .

    METHODS add_body
      IMPORTING
        !text TYPE string .

    METHODS add_recipient
      IMPORTING
        !recipient TYPE recipient .

    METHODS has_attachments
      RETURNING
        VALUE(result) TYPE abap_bool .

    METHODS has_recipients
      RETURNING
        VALUE(result) TYPE abap_bool .

    METHODS get_body
      RETURNING
        VALUE(body) TYPE string .

    METHODS get_recipients
      RETURNING
        VALUE(recipients) TYPE recipients .

    METHODS get_sender
      RETURNING
        VALUE(sender) TYPE sender .

    METHODS get_subject
      RETURNING
        VALUE(subject) TYPE string .

    METHODS reset
      IMPORTING
        !all         TYPE abap_bool OPTIONAL
        !sender      TYPE abap_bool OPTIONAL
        !recipients  TYPE abap_bool OPTIONAL
        !subject     TYPE abap_bool OPTIONAL
        !body        TYPE abap_bool OPTIONAL
        !attachments TYPE abap_bool OPTIONAL .

    METHODS remove_attachments
      RETURNING
        VALUE(count_removed) TYPE i .

    METHODS remove_recipients
      RETURNING
        VALUE(count_removed) TYPE i .

    METHODS send
      IMPORTING
        !send_immediately        TYPE abap_bool OPTIONAL
        !commit_work             TYPE abap_bool OPTIONAL
      RETURNING
        VALUE(send_request_guid) TYPE sysuuid_x
      RAISING
        cx_address_bcs
        cx_document_bcs
        cx_send_req_bcs
        zcx_u_exception .

    METHODS set_body
      IMPORTING
        !text TYPE string .

    METHODS set_sender
      IMPORTING
        !sender TYPE sender .

    METHODS set_subject
      IMPORTING
        !subject TYPE string .

    METHODS validate_email_address
      IMPORTING
        !email_address  TYPE string
      RETURNING
        VALUE(is_valid) TYPE abap_bool .

  PROTECTED SECTION.

  PRIVATE SECTION.

    CLASS-DATA instance TYPE REF TO zcl_u_email .
    DATA _email TYPE email .

    METHODS _get_sender
      IMPORTING
        !sender           TYPE sender
      RETURNING
        VALUE(sender_bcs) TYPE REF TO if_sender_bcs
      RAISING
        cx_address_bcs
        zcx_u_exception .

    METHODS _get_recipient
      IMPORTING
        !recipient       TYPE recipient
      RETURNING
        VALUE(recip_bcs) TYPE recip_bcs
      RAISING
        cx_address_bcs
        zcx_u_exception .

ENDCLASS.



CLASS zcl_u_email IMPLEMENTATION.


  METHOD add_body.

    _email-body = _email-body && text.

  ENDMETHOD.


  METHOD add_attachment.

    CHECK: file_name    IS NOT INITIAL,
           file_content IS NOT INITIAL.

    DATA file_content_hex TYPE solix_tab.

    CASE cl_abap_tabledescr=>describe_by_data( file_content )->absolute_name.
      WHEN '\TYPE=XSTRING'.
        cl_bcs_convert=>xstring_to_xtab(
          EXPORTING iv_xstring = file_content
          IMPORTING et_xtab    = file_content_hex
            ).
      WHEN '\TYPE=SOLI_TAB'.
        cl_bcs_convert=>raw_to_solix(
          EXPORTING it_soli  = file_content
          IMPORTING et_solix = file_content_hex
            ).
      WHEN '\TYPE=SOLIX_TAB'.
        file_content_hex = file_content.
      WHEN OTHERS.
        " Not supported
        RETURN.
    ENDCASE.

    APPEND VALUE #(
        type        = file_type
        subject     = file_name
        content_hex = file_content_hex )
      TO _email-attachments.

  ENDMETHOD.


  METHOD add_recipient.

    APPEND recipient TO _email-recipients.

  ENDMETHOD.


  METHOD create_instance.

    instance = NEW #( ).

  ENDMETHOD.


  METHOD get_body.

    body = _email-body.

  ENDMETHOD.


  METHOD get_instance.

    IF zcl_u_email=>instance IS NOT BOUND.
      zcl_u_email=>instance = NEW #( ).
    ENDIF.

    instance = zcl_u_email=>instance.

  ENDMETHOD.


  METHOD get_recipients.

    recipients = _email-recipients.

  ENDMETHOD.


  METHOD get_sender.

    sender = _email-sender.

  ENDMETHOD.


  METHOD get_subject.

    subject = _email-subject.

  ENDMETHOD.


  METHOD has_attachments.

    result = xsdbool( lines( _email-attachments ) > 0 ).

  ENDMETHOD.


  METHOD has_recipients.

    result = xsdbool( lines( _email-recipients ) > 0 ).

  ENDMETHOD.


  METHOD remove_attachments.

    count_removed = lines( _email-attachments ).
    CLEAR _email-attachments.

  ENDMETHOD.


  METHOD remove_recipients.

    count_removed = lines( _email-recipients ).
    CLEAR _email-recipients.

  ENDMETHOD.


  METHOD reset.

    IF all = abap_true.
      CLEAR _email.
    ENDIF.

    IF sender = abap_true.
      CLEAR _email-sender.
    ENDIF.

    IF recipients = abap_true.
      CLEAR _email-recipients.
    ENDIF.

    IF subject = abap_true.
      CLEAR _email-subject.
    ENDIF.

    IF body = abap_true.
      CLEAR _email-body.
    ENDIF.

    IF attachments = abap_true.
      CLEAR _email-attachments.
    ENDIF.

  ENDMETHOD.


  METHOD send.

    DATA(send_request) = cl_bcs=>create_persistent( ).

    " <subject>
    send_request->set_message_subject( _email-subject ).

    " <sender>
    send_request->set_sender( _get_sender( _email-sender ) ).

    " <recipients>
    LOOP AT _email-recipients ASSIGNING FIELD-SYMBOL(<recipient>).
      DATA(recipient) = _get_recipient( <recipient> ).
      send_request->add_recipient( i_recipient  = recipient-recipient
                                   i_copy       = recipient-sndcp
                                   i_blind_copy = recipient-sndbc ).
    ENDLOOP.

    " <body>
    send_request->set_document(
      cl_document_bcs=>create_document(
        i_type    = 'HTM'
        i_subject = CONV so_obj_des( _email-subject )
        i_text    = cl_document_bcs=>string_to_soli( _email-body ) ) ).

    " <attachments>
    LOOP AT _email-attachments REFERENCE INTO DATA(attachment).
      CAST cl_document_bcs( send_request->document( )
               )->add_attachment( i_attachment_type    = attachment->*-type
                                  i_attachment_subject = attachment->*-subject
                                  i_att_content_hex    = attachment->*-content_hex ).
    ENDLOOP.

    " <send>
    IF send_immediately IS NOT INITIAL.
      send_request->set_send_immediately( send_immediately ).
    ENDIF.

    send_request->send( ).
    send_request_guid = send_request->oid( ).

    IF commit_work EQ abap_true AND send_request_guid IS NOT INITIAL.
      COMMIT WORK.
    ENDIF.

  ENDMETHOD.


  METHOD set_body.

    _email-body = text.

  ENDMETHOD.


  METHOD set_sender.

    _email-sender = sender.

  ENDMETHOD.


  METHOD set_subject.

    _email-subject = subject.

  ENDMETHOD.


  METHOD validate_email_address.

    is_valid = abap_false.
    CHECK email_address IS NOT INITIAL.

    IF matches( val   = email_address
                regex = `\w+(\.\w+)*@(\w+\.)+((\l|\u){2,4})` ).
      is_valid = abap_true.
    ELSEIF matches( val   = email_address
                    regex = `[[:alnum:],!#\$%&'\*\+/=\?\^_``\{\|}~-]+`
                          & `(\.[[:alnum:],!#\$%&'\*\+/=\?\^_``\{\|}~-]+)*`
                          & `@[[:alnum:]-]+(\.[[:alnum:]-]+)*`
                          & `\.([[:alpha:]]{2,})` ).
      " OK but unusual
      is_valid = abap_true.
    ENDIF.

  ENDMETHOD.


  METHOD _get_recipient.

    IF recipient-email IS NOT INITIAL.
      IF validate_email_address( recipient-email ) EQ abap_false.
        RAISE EXCEPTION TYPE zcx_u_exception MESSAGE e456(so).
      ENDIF.

      recip_bcs-recipient = cl_cam_address_bcs=>create_internet_address(
                                i_address_string = CONV adr6-smtp_addr( recipient-email )
                                i_address_name   = CONV adr6-smtp_addr( recipient-name ) ).

    ELSEIF recipient-uname IS NOT INITIAL.
      recip_bcs-recipient = cl_sapuser_bcs=>create( recipient-uname ).
    ENDIF.

    IF recip_bcs-recipient IS BOUND.
      recip_bcs-sndcp = recipient-cc.
      recip_bcs-sndbc = recipient-bcc.
    ENDIF.

  ENDMETHOD.


  METHOD _get_sender.

    IF sender-email IS NOT INITIAL.
      IF validate_email_address( sender-email ) EQ abap_false.
        RAISE EXCEPTION TYPE zcx_u_exception MESSAGE e456(so).
      ENDIF.

      sender_bcs = cl_cam_address_bcs=>create_internet_address(
                       i_address_string = CONV adr6-smtp_addr( sender-email )
                       i_address_name   = CONV adr6-smtp_addr( sender-name ) ).

    ELSEIF sender-uname IS NOT INITIAL.
      sender_bcs = cl_sapuser_bcs=>create( sender-uname ).
    ENDIF.

  ENDMETHOD.

ENDCLASS.
