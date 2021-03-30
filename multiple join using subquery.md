```sql
SELECT a.barcode_no, a.goods_nm, a.qty_ptn, a.unit_qty, a.unit_nm, a.pack_qty, b.valid_yn,b.goods_nm, b.unit_qty, b.unit_nm, b.pack_qty, b.category_nm1, b.category_nm2, b.category_nm3, b.category_nm4
FROM tb_qty_dic a, tb_pos_barcode_mst b, tb_barcode_category c, (SELECT DISTINCT maker_nm from dw_barcode_maker WHERE main_yn = 'Y') d
WHERE 1=1
AND a.barcode_no = b.barcode_no
AND b.category_nm4= c.category_nm4
AND b.maker_nm = d.maker_nm
AND c.main_yn = 'Y' 
```
