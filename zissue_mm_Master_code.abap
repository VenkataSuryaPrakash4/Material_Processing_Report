*&---------------------------------------------------------------------*
*& Report ZISSUE_MM
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zissue_mm.

INCLUDE zissue_mm_dd.
INCLUDE zissue_mm_ss.
INCLUDE zissue_mm_validation.

START-OF-SELECTION.
  PERFORM get_data.
