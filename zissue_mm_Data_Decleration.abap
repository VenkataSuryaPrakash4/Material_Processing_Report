*&---------------------------------------------------------------------*
*& Include          ZISSUE_MM_DD
*&---------------------------------------------------------------------*

TYPES: BEGIN OF ty_final,
         light,
         matnr    TYPE matnr,
         maktx    TYPE maktx,
         aufnr    TYPE aufnr,
         check(1) TYPE c,
       END OF ty_final,

       BEGIN OF ty_sf_final,
         matnr TYPE matnr,
         maktx TYPE maktx,
         aufnr TYPE aufnr,
       END OF ty_sf_final.

DATA: gt_final  TYPE TABLE OF ty_final,
      gwa_final TYPE ty_final.
