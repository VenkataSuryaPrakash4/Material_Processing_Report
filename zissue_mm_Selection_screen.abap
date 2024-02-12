*&---------------------------------------------------------------------*
*& Include          ZISSUE_MM_SS
*&---------------------------------------------------------------------*

TABLES: mara.
SELECTION-SCREEN BEGIN OF BLOCK blk_1 WITH FRAME TITLE TEXT-001.
  SELECT-OPTIONS: s_matnr FOR mara-matnr.
SELECTION-SCREEN END OF BLOCK blk_1.
