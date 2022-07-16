class ZCL_IM_WRKC_UI_AFTER_SAVE definition
  public
  final
  create public .

public section.

  interfaces /SCWM/IF_EX_WRKC_UI_AFTER_SAVE .
  interfaces IF_BADI_INTERFACE .
protected section.
private section.
ENDCLASS.



CLASS ZCL_IM_WRKC_UI_AFTER_SAVE IMPLEMENTATION.


  METHOD /scwm/if_ex_wrkc_ui_after_save~after_save.

    BREAK-POINT ID zewmdevbook_365.

*Note, with this implementation the standard implementation is switched off
    DATA: lv_qname  TYPE trfcqnam.

    "1. Your own logic for follow-up WTs
    DATA(lt_movehu) = it_movehu.
    LOOP AT lt_movehu ASSIGNING FIELD-SYMBOL(<ls_movehu>).
      "Immediate conf. WT when Work Center = ”1234”
      IF is_workstation-workstation = 'ZBD1'.
        <ls_movehu>-squit = abap_true.
      ENDIF.
    ENDLOOP.
    "2. Call standard impl. to switch on follow-up WT creation
    IF is_workstation-lgpla <> '831.00.20'.
      DATA(lo_std) = NEW /scwm/cl_ei_wrkc_ui_after_save( ).
      lo_std->/scwm/if_ex_wrkc_ui_after_save~after_save(
        EXPORTING
          it_movehu      = lt_movehu
          it_closedhu    = it_closedhu
          is_workstation = is_workstation
        IMPORTING
          ev_save        = ev_save ).
    ELSE.
      "3. Change queue-name to BIN (instead of HU)
      IF it_movehu IS NOT INITIAL.
        LOOP AT it_movehu INTO DATA(ls_movehu).
          CLEAR: lt_movehu, lv_qname.
          "Prepare rfc queue
          MOVE: wmegc_qrfc_hu_prcs   TO lv_qname,
                is_workstation-lgpla TO lv_qname+4.

          DATA(ls_rfc_queue) = VALUE /scwm/s_rfc_queue(
            mandt = sy-mandt
            queue = lv_qname ).
          CALL FUNCTION 'GUID_CREATE'
            IMPORTING
              ev_guid_16 = ls_rfc_queue-guid.

          CALL FUNCTION 'TRFC_SET_QIN_PROPERTIES'
            EXPORTING
              qin_name = lv_qname.
          APPEND ls_movehu TO lt_movehu.
* call process-oriented storage control for each HU
          CALL FUNCTION '/SCWM/TO_CREATE_MOVE_HU'
            IN BACKGROUND TASK
            AS SEPARATE UNIT
            EXPORTING
              iv_lgnum       = is_workstation-lgnum
              iv_commit_work = abap_false
              iv_bname       = sy-uname
              is_rfc_queue   = ls_rfc_queue
              iv_wtcode      = wmegc_wtcode_procs
              it_create_hu   = lt_movehu.
        ENDLOOP.
        ev_save = abap_true.
        CLEAR: ls_rfc_queue.
      ENDIF.
    ENDIF.

  ENDMETHOD.
ENDCLASS.
