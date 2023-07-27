class ZCL_APPLOG_NOTIF_SERVICES definition
  public
  create private .

public section.

  class-methods GET_INSTANCE
    returning
      value(RO_INSTANCE) type ref to ZCL_APPLOG_NOTIF_SERVICES .
  methods GET_APPLICATION_LOG
    importing
      !IV_NOTIFICATION_ID type /IWNGW/NOTIFICATION_ID
    returning
      value(RS_APP_LOG_HDR) type APL_C_APPL_LOG_OVERVIEW .
protected section.
private section.
ENDCLASS.



CLASS ZCL_APPLOG_NOTIF_SERVICES IMPLEMENTATION.


  METHOD get_application_log.
    DATA: lv_logno TYPE balhdr-lognumber.
    lv_logno = iv_notification_id.
    SELECT SINGLE * FROM apl_c_appl_log_overview INTO @rs_app_log_hdr WHERE lognumber = @lv_logno.
  ENDMETHOD.


  METHOD get_instance.
    CREATE OBJECT ro_instance.
  ENDMETHOD.
ENDCLASS.
