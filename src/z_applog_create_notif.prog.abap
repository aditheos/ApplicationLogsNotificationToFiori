*&---------------------------------------------------------------------*
*& Report Z_APPLOG_CREATE_NOTIF
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT z_applog_create_notif.
DATA: gs_loghdr   TYPE apl_v_appl_log_overview,
      gs_user     TYPE usr01,
      gv_severity TYPE zapl_de_log_severity.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
  SELECT-OPTIONS:
    s_objct FOR gs_loghdr-object    NO INTERVALS,
    s_subob FOR gs_loghdr-subobject NO INTERVALS,
    s_extid FOR gs_loghdr-extnumber NO INTERVALS,
    s_logdt FOR gs_loghdr-aldate    NO INTERVALS DEFAULT sy-datum,
    s_sevrt FOR gv_severity         NO INTERVALS.
SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-002.
  PARAMETERS:
  p_pr_id TYPE /iwngw/notif_provider_id DEFAULT 'ZAPPLICATIONLOGS'.
SELECTION-SCREEN END OF BLOCK b2.

SELECTION-SCREEN BEGIN OF BLOCK b3 WITH FRAME TITLE TEXT-003.
  SELECT-OPTIONS s_user FOR gs_user-bname DEFAULT sy-uname.
SELECTION-SCREEN END OF BLOCK b3.


INITIALIZATION.
  s_sevrt-sign = 'I'.
  s_sevrt-option = 'EQ'.
  s_Sevrt-low = 'A'. " Cancelled
  APPEND s_sevrt.

  s_Sevrt-low = 'E'. " Error
  APPEND s_sevrt.

START-OF-SELECTION.

  TRY.
      /iwngw/cl_cos_provider_reg_cof=>assert_provider_id( p_pr_id ).
    CATCH /iwngw/cx_cos_provider_reg.
      MESSAGE TEXT-004 TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
  ENDTRY.

  " Get Logs with Only Errors
  SELECT * FROM apl_c_appl_log_overview
   WHERE object    IN @s_objct
     AND subobject IN @s_subob
     AND extnumber IN @s_extid
     AND aldate    IN @s_logdt
     AND severity  IN @s_sevrt
  INTO TABLE @DATA(lt_loghdr).

  DATA lt_notif TYPE /iwngw/if_notif_provider=>ty_t_notification.
  DATA ls_notif LIKE LINE OF lt_notif.
  DATA lt_recipient TYPE /iwngw/if_notif_provider=>ty_t_notification_recipient.
  DATA ls_recipient LIKE LINE OF lt_recipient.

  LOOP AT s_user.
    IF s_user-option = 'EQ'.
      CLEAR ls_recipient.
      ls_recipient-id = s_user-low.
      APPEND ls_recipient TO lt_recipient.
    ENDIF.
  ENDLOOP.

  CLEAR lt_notif.
  LOOP AT lt_loghdr INTO DATA(ls_loghdr).
    CLEAR: ls_notif, lt_notif.
    ls_notif-id                       = ls_loghdr-lognumber..
    ls_notif-type_key                 = 'ApplicationLogKey'.
    ls_notif-type_version             = '0001'.
    ls_notif-priority                 = /iwngw/if_notif_provider=>gcs_priorities-high.
    ls_notif-actor_id                 = ls_loghdr-aluser.
    ls_notif-actor_type               = ''.
    ls_notif-actor_display_text       = ls_loghdr-aluser.
    ls_notif-recipients               = lt_recipient.
    ls_notif-navigation_target_object = 'CAApplicationLog'.
    ls_notif-navigation_target_action = 'showList'.

    " Navigation Parameters
    zcl_applog_notif_provider=>get_navigation_parameters(
      EXPORTING
        iv_lognumber    = ls_loghdr-lognumber               " Application log: Number
      IMPORTING
        et_nav_params   =  DATA(lt_parameters)
    ).
    ls_notif-navigation_parameters    = lt_parameters.
    APPEND ls_notif TO lt_notif.
  ENDLOOP.

  TRY.
      /iwngw/cl_notification_api=>create_notifications(
        EXPORTING
          iv_provider_id  = p_pr_id
          it_notification = lt_notif ).

      COMMIT WORK.
    CATCH /iwngw/cx_notification_api INTO DATA(lo_api_error).
  ENDTRY.
