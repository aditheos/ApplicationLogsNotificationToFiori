class ZCL_APPLOG_NOTIF_PROVIDER definition
  public
  final
  create public .

public section.

  interfaces /IWNGW/IF_NOTIF_PROVIDER .

  class-methods GET_NAVIGATION_PARAMETERS
    importing
      !IV_LOGNUMBER type BALOGNR
    exporting
      !ET_NAV_PARAMS type /IWNGW/IF_NOTIF_PROVIDER=>TY_T_NAVIGATION_PARAMETER .
  PROTECTED SECTION.
private section.

  class-data MO_INSTANCE type ref to ZCL_APPLOG_NOTIF_PROVIDER .
  data MO_SERVICE type ref to ZCL_APPLOG_NOTIF_SERVICES .

  methods _GET_NOTIFICATION_PARAMETERS default fail
    importing
      !IV_NOTIFICATION_ID type /IWNGW/IF_NOTIF_PROVIDER=>TY_S_NOTIFICATION-ID
      !IV_TYPE_KEY type /IWNGW/IF_NOTIF_PROVIDER=>TY_S_NOTIFICATION_TYPE_ID-TYPE_KEY
      !IV_TYPE_VERSION type /IWNGW/IF_NOTIF_PROVIDER=>TY_S_NOTIFICATION_TYPE_ID-VERSION
      !IV_LANGUAGE type SPRAS
    exporting
      !ET_PARAMETER type /IWNGW/IF_NOTIF_PROVIDER=>TY_T_NOTIFICATION_PARAMETER
    raising
      /IWNGW/CX_NOTIF_PROVIDER .
  class-methods _GET_INSTANCE
    returning
      value(RO_INSTANCE) type ref to ZCL_APPLOG_NOTIF_PROVIDER .
ENDCLASS.



CLASS ZCL_APPLOG_NOTIF_PROVIDER IMPLEMENTATION.


  METHOD /iwngw/if_notif_provider~get_notification_parameters.
    CLEAR:et_parameter.

    DATA lo_instance  TYPE REF TO zcl_applog_notif_provider.
    lo_instance = _get_instance( ).

    lo_instance->_get_notification_parameters(
      EXPORTING
        iv_notification_id = iv_notification_id
        iv_type_key        = iv_type_key
        iv_type_version    = iv_type_version
        iv_language        = iv_language
      IMPORTING
        et_parameter       = et_parameter
    ).

  ENDMETHOD.


  METHOD /iwngw/if_notif_provider~get_notification_type.
    DATA ls_naction LIKE LINE OF et_notification_action.

    CLEAR: es_notification_type,et_notification_action.

    IF ( iv_type_key = 'ApplicationLogKey' ).
      es_notification_type-version  = iv_type_version.
      es_notification_type-type_key = iv_type_key.
      es_notification_type-is_groupable = abap_true.

      ls_naction-action_key = 'ReviewLog'.
      ls_naction-nature = /iwngw/if_notif_provider=>gcs_action_natures-positive.
      APPEND ls_naction TO et_notification_action.
    ELSE.
      " TODO: raise error, unexpected notification type/version
    ENDIF.
  ENDMETHOD.


  METHOD /iwngw/if_notif_provider~get_notification_type_text.
    DATA ls_naction_t LIKE LINE OF et_action_text.
    DATA lv_tmptext TYPE string.
    DATA lv_tmpattr TYPE string.
    DATA lv_st_text TYPE string.
    DATA lv_st_text_temp TYPE string.
    DATA lv_lang TYPE spras.

    CLEAR:es_type_text,et_action_text.

    lv_lang = sy-langu.
    SET LANGUAGE iv_language.

    IF ( iv_type_key = 'ApplicationLogKey' ).
      es_type_text-template_public    = TEXT-001. " An application log requires your attention

      lv_tmptext = TEXT-002.                      " Please review Application Log with Object ID: &1, Subobject: &2, External ID: &3
      REPLACE '&1' WITH '{LogObjectId}' INTO lv_tmptext.
      REPLACE '&2' WITH '{LogObjectSubId}' INTO lv_tmptext.
      REPLACE '&3' WITH '{LogExternalId}' INTO lv_tmptext.
      es_type_text-template_sensitive = lv_tmptext.
      es_type_text-description = TEXT-022.

      lv_st_text = TEXT-024.                      " Log was generated on &1 by user &3
      REPLACE '&1' WITH '{LogCreatedOn}' INTO lv_st_text.
      REPLACE '&2' WITH '{LogCreatedBy}' INTO lv_st_text.
      es_type_text-subtitle = lv_st_text.

      lv_tmptext   = TEXT-003.                    " You have &1 Application logs requiring your review
      CONCATENATE '{' /iwngw/if_notif_provider=>gcs_parameter_reserved_names-group_count '}' INTO lv_tmpattr.
      REPLACE '&1' WITH lv_tmpattr INTO lv_tmptext.
      es_type_text-template_grouped = lv_tmptext.

      ls_naction_t-action_key = 'ReviewLog'.
      ls_naction_t-display_text = TEXT-004.         " Reiew Log
      ls_naction_t-display_text_grouped = TEXT-005. " Review Logs
      APPEND ls_naction_t TO et_action_text.

    ELSE.
      " TODO: raise error, unexpected notification type/version
    ENDIF.

    SET LANGUAGE lv_lang.

  ENDMETHOD.


  METHOD /iwngw/if_notif_provider~handle_action.

    CLEAR:es_result.

    " For now always return success if ids are set, since no persistence in this test provider
    IF iv_notification_id IS INITIAL.
      es_result-success = abap_false.
      es_result-action_msg_txt = TEXT-021.
    ELSEIF iv_action_key IS INITIAL.
      es_result-success = abap_false.
      es_result-action_msg_txt = TEXT-020.
    ELSE.
      CASE iv_action_key.
        WHEN 'ReviewLog'.
          es_result-action_msg_txt = TEXT-018.
        WHEN OTHERS.
      ENDCASE.
      es_result-success = abap_true.
      es_result-delete_on_return = abap_true.
    ENDIF.
    " &/ShowMsg/%252FApplicationLogOverviewSet('0YozTia27kwBWGVV%25257BdpgVm')/default
    " |showList&/ShowMsg/%252FApplicationLogOverviewSet('{ ls_loghdr-log_handle }')/default|.
  ENDMETHOD.


  METHOD /IWNGW/IF_NOTIF_PROVIDER~HANDLE_BULK_ACTION.
    DATA: ls_bulk_notif   LIKE LINE OF it_bulk_notif,
          ls_notif_result LIKE LINE OF et_notif_result.

    CLEAR:et_notif_result.
    LOOP AT it_bulk_notif INTO ls_bulk_notif.
      IF ls_bulk_notif-id IS INITIAL.
        ls_notif_result-id = space.
        ls_notif_result-success = abap_false.
        ls_notif_result-delete_on_return = abap_false.
        APPEND ls_notif_result TO et_notif_result.
        CLEAR ls_notif_result.
        CONTINUE.
      ENDIF.
      CASE ls_bulk_notif-action_key.
        WHEN 'ReviewLog'.
          ls_notif_result-id                = ls_bulk_notif-id .
          ls_notif_result-type_key          = ls_bulk_notif-type_key.
          ls_notif_result-type_version      = ls_bulk_notif-type_version.
          ls_notif_result-success           = abap_true.
          ls_notif_result-delete_on_return  = abap_true.
          APPEND ls_notif_result TO et_notif_result.
          CLEAR ls_notif_result.
        WHEN OTHERS.
          ls_notif_result-id                = ls_bulk_notif-id .
          ls_notif_result-type_key          = ls_bulk_notif-type_key.
          ls_notif_result-type_version      = ls_bulk_notif-type_version.
          ls_notif_result-success           = abap_false.
          ls_notif_result-delete_on_return  = abap_false.
          APPEND ls_notif_result TO et_notif_result.
          CLEAR ls_notif_result.
      ENDCASE.
    ENDLOOP.

  ENDMETHOD.


  METHOD get_navigation_parameters.
    DATA ls_parameter LIKE LINE OF et_nav_params.

    "#CAApplicationLog-showList
    "/PersKey/default/LogObjectId//LogObjectSubId//LogExternalId//DateFrom//DateTo//Feature
    CLEAR:et_nav_params.

    ls_parameter-name         = 'PersKey'.
    ls_parameter-value        = 'default'.
    APPEND ls_parameter TO et_nav_params.

    IF NOT iv_lognumber IS INITIAL.
      CLEAR ls_parameter.
      ls_parameter-name         = 'LogNumber'.
      ls_parameter-value        = iv_lognumber.
      APPEND ls_parameter TO et_nav_params.
    ENDIF.

  ENDMETHOD.


  METHOD _get_instance.
    IF mo_instance IS NOT BOUND.
      CREATE OBJECT mo_instance.
      mo_instance->mo_service = zcl_applog_notif_services=>get_instance( ).
    ENDIF.
    ro_instance = mo_instance.
  ENDMETHOD.


  METHOD _get_notification_parameters.
    DATA ls_parameter LIKE LINE OF et_parameter.
    DATA lv_ldatc TYPE char10.

    DATA(lv_log_hdr) = mo_instance->mo_service->get_application_log( iv_notification_id = iv_notification_id ).
    "#CAApplicationLog-showList
    "/PersKey/default/LogObjectId//LogObjectSubId//LogExternalId//DateFrom//DateTo//Feature
    CLEAR:et_parameter.

    DATA lo_instance  TYPE REF TO zcl_applog_notif_provider.
    lo_instance = _get_instance( ).

    DATA(ls_log) = lo_instance->mo_service->get_application_log( iv_notification_id = iv_notification_id ).

    DATA(lv_lang) = sy-langu.
    SET LANGUAGE iv_language.

    " Don't specify a specific ID, since it will be generated, put all parameters in the "context"
    "if iv_notification_id = '001'.

    ls_parameter-name         = 'LogObjectId'.
    ls_parameter-value   = ls_log-obj_txt.
    ls_parameter-type         = /iwngw/if_notif_provider=>gcs_parameter_types-type_string.
    ls_parameter-is_sensitive = abap_false.
    APPEND ls_parameter TO et_parameter.

    ls_parameter-name         = 'LogObjectSubId'.
    ls_parameter-value        = ls_log-subobj_txt.
    ls_parameter-type         = /iwngw/if_notif_provider=>gcs_parameter_types-type_string.
    ls_parameter-is_sensitive = abap_false.
    APPEND ls_parameter TO et_parameter.

    ls_parameter-name         = 'LogExternalId'.
    CALL FUNCTION 'CONVERSION_EXIT_ALPHA_OUTPUT'
      EXPORTING
        input  = ls_log-extnumber
      IMPORTING
        output = ls_parameter-value.

    ls_parameter-value        = ls_log-extnumber.
    ls_parameter-type         = /iwngw/if_notif_provider=>gcs_parameter_types-type_string.
    ls_parameter-is_sensitive = abap_false.
    APPEND ls_parameter TO et_parameter.

    ls_parameter-name         = 'LogCreatedOn'.
    WRITE ls_log-aldate TO lv_ldatc.
    ls_parameter-value = lv_ldatc.
    ls_parameter-type         = /iwngw/if_notif_provider=>gcs_parameter_types-type_string.
    ls_parameter-is_sensitive = abap_false.
    APPEND ls_parameter TO et_parameter.

    ls_parameter-name         = 'LogCreatedBy'.
    ls_parameter-value        = ls_log-log_created_by_formatted_name.
    ls_parameter-type         = /iwngw/if_notif_provider=>gcs_parameter_types-type_string.
    ls_parameter-is_sensitive = abap_false.
    APPEND ls_parameter TO et_parameter.

    SET LANGUAGE lv_lang.

  ENDMETHOD.
ENDCLASS.
