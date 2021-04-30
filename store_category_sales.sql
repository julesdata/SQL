SELECT *, SUM(sales_amt) over(PARTITION BY drim_store_id) total_sales
FROM(
SELECT a.drim_store_id, b.ns_store_id, c.sales_mm,  d.category_nm1, d.category_nm2, sum(c.sales_amt) sales_amt
FROM dw_svc_client_store a, dw_store_mst b, dw_pos_mm_sales c, tb_pos_barcode_mst d 
WHERE 1=1
AND a.maker_nm = '광동제약'
AND a.valid_yn = 'Y'
AND a.drim_store_id = b.drim_store_id
AND a.drim_store_id = c.drim_store_id
AND c.sales_mm = 202104
AND c.barcode_no = d.barcode_no
AND d.category_nm2>''
AND d.maker_nm>''
AND d.valid_yn = 'Y'
group by a.drim_store_id, b.ns_store_id, c.sales_mm,  d.category_nm1, d.category_nm2
) t1;



SELECT b.ns_store_id, b.store_nm
, SUM(case when d.category_nm2='음료류' then c.sales_amt END) '음료류'
, sum(case when d.category_nm3='아이스크림류' then c.sales_amt end) '아이스크림류'
, sum(case when d.category_nm2='과자류' then c.sales_amt END) '과자류'
, sum(c.sales_amt) sales_amt
FROM dw_svc_client_store a, dw_store_mst b, dw_pos_mm_sales c, tb_pos_barcode_mst d 
WHERE 1=1
AND a.maker_nm = '광동제약'
AND a.valid_yn = 'Y'
AND a.drim_store_id = b.drim_store_id
AND a.drim_store_id = c.drim_store_id
AND c.sales_mm = 202104
AND c.barcode_no = d.barcode_no
AND d.category_nm1='가공식품'
AND d.maker_nm>''
AND d.valid_yn = 'Y'
group by a.drim_store_id, b.ns_store_id, c.sales_mm;
