*&---------------------------------------------------------------------*
*& Include          ZISSUE_MM_VALIDATION
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Form get_data
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM get_data.

************************************************************************
**************Material data from MARA table*************
************************************************************************
  SELECT matnr
    INTO TABLE @DATA(lt_mara)
    FROM mara
    WHERE matnr IN @s_matnr.

************************************************************************
*****Material Description data from MAKT table**********
************************************************************************
  IF lt_mara[] IS NOT INITIAL.
    SELECT matnr,maktx
      INTO TABLE @DATA(lt_makt)
      FROM makt
      FOR ALL ENTRIES IN @lt_mara
      WHERE matnr = @lt_mara-matnr.
  ENDIF.

************************************************************************
*****Material Process Order data from AFKO table********
************************************************************************
  IF lt_mara[] IS NOT INITIAL.
    SELECT aufnr,plnbez
      INTO TABLE @DATA(lt_afko)
      FROM afko
      FOR ALL ENTRIES IN @lt_mara
      WHERE plnbez = @lt_mara-matnr.
  ENDIF.

  SORT lt_afko BY plnbez.
****Looping on Material description table.
  LOOP AT lt_makt INTO DATA(wa1).
    gwa_final-matnr = wa1-matnr.
    gwa_final-maktx = wa1-maktx.

****Looping Proccess Order data based on Material Number.
    LOOP AT lt_afko INTO DATA(wa2) WHERE plnbez = wa1-matnr.
      DATA(flag) = abap_true.
      gwa_final-light = '3'.
      gwa_final-aufnr = wa2-aufnr.

****Appending to final Internal Table.
      APPEND gwa_final TO gt_final.
      CLEAR:wa2.
    ENDLOOP.

    IF flag EQ abap_false.
      gwa_final-light = '1'.
      gwa_final-aufnr = wa2-aufnr.

****Appending to final Internal Table.
      APPEND gwa_final TO gt_final.
      CLEAR:wa2.
    ENDIF.

****Clearing Work area and Internal Table.
    CLEAR:wa1,gwa_final.
  ENDLOOP.

****Layout.
  DATA:  wa_layout TYPE slis_layout_alv.

  wa_layout-lights_fieldname = 'LIGHT'.
  wa_layout-zebra = 'X'.
  wa_layout-colwidth_optimize = 'X'.

****Field catalogue.
  DATA: lv_pos1  TYPE i VALUE 0,
        it_fcat1 TYPE TABLE OF slis_fieldcat_alv.

  ADD 1 TO lv_pos1.
  APPEND VALUE #( col_pos = lv_pos1 fieldname = 'LIGHT' seltext_m = 'Exception') TO it_fcat1.
  ADD 1 TO lv_pos1.
  APPEND VALUE #( col_pos = lv_pos1 fieldname = 'MATNR' seltext_m = 'Materail Number') TO it_fcat1.
  ADD 1 TO lv_pos1.
  APPEND VALUE #( col_pos = lv_pos1 fieldname = 'MAKTX' seltext_m = 'Materail Description') TO it_fcat1.
  ADD 1 TO lv_pos1.
  APPEND VALUE #( col_pos = lv_pos1 fieldname = 'AUFNR' seltext_m = 'Process Order') TO it_fcat1.
  ADD 1 TO lv_pos1.
  APPEND VALUE #( col_pos = lv_pos1 fieldname = 'CHECK' seltext_m = 'CHECK' checkbox = 'X' edit = 'X') TO it_fcat1.


****Call function for ALV Report.
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_callback_program       = sy-repid
      i_callback_pf_status_set = 'ZPF_MM'      "-----> PF Status.
      i_callback_user_command  = 'UCOMM'       "-----> User Command by End User.
      i_callback_top_of_page   = 'TOP_OF_PAGE' "-----> Top Of Page (Heading)
      is_layout                = wa_layout
      it_fieldcat              = it_fcat1      "-----> Field Catalogue.
    TABLES
      t_outtab                 = gt_final
    EXCEPTIONS
      program_error            = 1
      OTHERS                   = 2.

ENDFORM.


************************************************************************
****************PF Status for ALV report.*****************
************************************************************************
FORM zpf_mm USING rt_extab TYPE slis_t_extab.

  SET PF-STATUS 'ZPF_MM'.

ENDFORM.


************************************************************************
******************User command for PF Status*******************
************************************************************************
FORM ucomm  USING action LIKE sy-ucomm
                                   index TYPE slis_selfield.

  CASE action.
****Function code for Printing Material Processing data as Smart form.
    WHEN '&ABA'.
      DATA: r_grid TYPE REF TO cl_gui_alv_grid.


      CALL FUNCTION 'GET_GLOBALS_FROM_SLVC_FULLSCR'
        IMPORTING
          e_grid = r_grid.

      IF sy-subrc = 0.
        CALL METHOD r_grid->check_changed_data.
        IF sy-subrc = 0.
          DATA: lt_sf_final  TYPE TABLE OF ty_sf_final,
                lwa_sf_final TYPE ty_sf_final.

          LOOP AT gt_final INTO DATA(wa3) WHERE check = 'X'.
            lwa_sf_final-matnr  = wa3-matnr.
            lwa_sf_final-maktx = wa3-maktx.
            lwa_sf_final-aufnr = wa3-aufnr.

            APPEND lwa_sf_final TO lt_sf_final.
            CLEAR:wa3,lwa_sf_final.
          ENDLOOP.

****************************************************
*************Calling Smart form*********************
****************************************************
          DATA: lv_fm_name TYPE rs38l_fnam.

          CALL FUNCTION 'SSF_FUNCTION_MODULE_NAME'
            EXPORTING
              formname           = 'ZSF_MM'
            IMPORTING
              fm_name            = lv_fm_name
            EXCEPTIONS
              no_form            = 1
              no_function_module = 2
              OTHERS             = 3.

          IF sy-subrc = 0.
            CALL FUNCTION lv_fm_name "'/1BCDWB/SF00001304'
              TABLES
                lt_inface        = lt_sf_final
              EXCEPTIONS
                formatting_error = 1
                internal_error   = 2
                send_error       = 3
                user_canceled    = 4
                OTHERS           = 5.

          ENDIF.

        ENDIF.
      ENDIF.

****Function code for calling MM03 Tcode.
    WHEN '&IC1'.

      READ TABLE gt_final INTO DATA(wa4) INDEX index-tabindex.
      IF sy-subrc = 0.
        DATA(lv_matnr) = wa4-matnr.
        SET PARAMETER ID 'MAT' FIELD lv_matnr.
        CALL TRANSACTION 'MM03'.
      ENDIF.
      CLEAR:wa4.
  ENDCASE.

ENDFORM.


************************************************************************
****************Top Of Page for Report*******************
************************************************************************
FORM top_of_page.
  DATA: lt_comlist TYPE TABLE OF slis_listheader.

  APPEND VALUE #( typ = 'H' info = 'Material Processing' ) TO lt_comlist.
  APPEND VALUE #( typ = 'S' key = 'Username: ' info = sy-uname ) TO lt_comlist.

  DATA(lv_year) = sy-datum+0(4).
  DATA(lv_month) = sy-datum+4(2).
  DATA(lv_day) = sy-datum+6(2).
  DATA(lv_concat) = |{ lv_day }| & |/| & |{ lv_month }| & |/| & |{ lv_year }|.
  APPEND VALUE #( typ = 'S' key = 'Date :' info = lv_concat ) TO lt_comlist.

****Commentry write for Heading.
  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
    EXPORTING
      it_list_commentary = lt_comlist.

  CLEAR: lv_day,lv_month,lv_year.
ENDFORM.
