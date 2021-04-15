# 맥주
SELECT b.sales_wk, e.mng_area1,e.mng_area2, e.sales_grd, sum(a.sales_amt) sales_amt
FROM dw_pos_dd_sales a, tb_dt_dic b, tb_pos_barcode_mst d
, (SELECT * from dw_store_mst 
   WHERE drim_store_id IN(SELECT DISTINCT drim_store_id from dw_store_mm_sum  
	                       WHERE sales_mm BETWEEN 202102 AND 202103 
								  AND day_cnt > 20 
								  GROUP BY drim_store_id HAVING COUNT(DISTINCT sales_mm)=2)
	) e
WHERE 1=1
AND a.sales_date = b.sales_date
AND A.SALES_DATE=20210101
#AND b.sales_mm BETWEEN 202102 AND 202103
AND a.barcode_no = d.barcode_no
# 한맥 바코드 
# 맥주 카테고리
AND d.category_nm4 IN('맥주')
# AND d.category_nm4 IN('수입맥주')
AND d.valid_yn = 'Y'
AND d.maker_nm > ''
AND a.drim_store_id = e.drim_store_id
AND e.store_type IN ('슈퍼마켓', '편의점')
AND e.pos_co_cd NOT IN ('POS1607')
AND e.mng_area1 > ''
AND e.mng_area2 > ''
AND e.sales_grd > ''
GROUP BY b.sales_wk,e.mng_area1,e.mng_area2, e.sales_grd;

#한맥
SELECT b.sales_wk, e.mng_area1,e.mng_area2, e.sales_grd, d.barcode_no, d.goods_nm, COUNT(DISTINCT a.drim_store_id) store_cnt, sum(a.sales_amt) sales_amt
FROM dw_pos_dd_sales a, tb_dt_dic b, tb_pos_barcode_mst d
, (SELECT * from dw_store_mst 
   WHERE drim_store_id IN(SELECT DISTINCT drim_store_id from dw_store_mm_sum  
	                       WHERE sales_mm BETWEEN 202101 AND 202103 
								  AND day_cnt > 20 
								  GROUP BY drim_store_id HAVING COUNT(DISTINCT sales_mm)=3)
	) e
WHERE 1=1
AND a.sales_date = b.sales_date
AND A.SALES_DATE=20210101
#AND b.sales_wk = 202101
AND a.barcode_no = d.barcode_no
# 한맥 바코드
AND d. barcode_no IN('8801021105598','8801021105604','8801021105833','8801021105833')
# 맥주 카테고리
# AND d.category_nm4 IN('맥주')
# AND d.category_nm4 IN('수입맥주')
AND d.valid_yn = 'Y'
AND d.maker_nm > ''
AND a.drim_store_id = e.drim_store_id
AND e.store_type IN ('슈퍼마켓', '편의점')
AND e.pos_co_cd NOT IN ('POS1607')
AND e.mng_area1 > ''
AND e.mng_area2 > ''
AND e.sales_grd > ''
GROUP BY b.sales_wk,e.mng_area1,e.mng_area2, e.sales_grd, d.barcode_no, d.goods_nm;

# 지역별 전체매장
SELECT b.sales_wk, e.mng_area1,e.mng_area2, e.sales_grd, COUNT(DISTINCT a.drim_store_id) store_cnt
FROM dw_pos_dd_sales a, tb_dt_dic b
, (SELECT * from dw_store_mst 
   WHERE drim_store_id IN(SELECT DISTINCT drim_store_id from dw_store_mm_sum  
	                       WHERE sales_mm BETWEEN 202102 AND 202103 
								  AND day_cnt > 20 
								  GROUP BY drim_store_id HAVING COUNT(DISTINCT sales_mm)=2)
	) e
WHERE 1=1
AND a.sales_date = b.sales_date
AND A.SALES_DATE=20210201
#AND b.sales_mm BETWEEN 202102 AND 202103
AND a.drim_store_id = e.drim_store_id
AND e.store_type IN ('슈퍼마켓', '편의점')
AND e.pos_co_cd NOT IN ('POS1607')
AND e.mng_area1 > ''
AND e.mng_area2 > ''
AND e.sales_grd > ''
GROUP BY b.sales_wk,e.mng_area1,e.mng_area2, e.sales_grd;
