### 메인 제조사, 메인 카테고리의 제품 정보만 가져오기 
```sql
SELECT a.barcode_no, a.goods_nm, a.qty_ptn, a.unit_qty, a.unit_nm, a.pack_qty, b.valid_yn,b.goods_nm, b.unit_qty, b.unit_nm, b.pack_qty, b.category_nm1, b.category_nm2, b.category_nm3, b.category_nm4
FROM tb_qty_dic a, tb_pos_barcode_mst b, tb_barcode_category c, (SELECT DISTINCT maker_nm from dw_barcode_maker WHERE main_yn = 'Y') d
WHERE 1=1
AND a.barcode_no = b.barcode_no
AND b.category_nm4= c.category_nm4
AND b.maker_nm = d.maker_nm
AND c.main_yn = 'Y' 
```
  
### 제품 월별 판매현황 
```sql
# 판매년월, 지역1, 바코드번호, 제조사, 전체 매장수, 취급 매장수, 취급률, 판매금액, 판매수량, 판매단가 
SELECT x1.sales_mm, x1.mng_area1, x1.barcode_no, x3.goods_nm, x3.maker_nm, all_store_cnt, store_cnt, store_cnt/all_store_cnt, mm_amt, mm_cnt, mm_amt/mm_cnt
FROM  (SELECT a.sales_mm                                                                        #월-지역-제품별 취급 매장수, 판매금액, 판매 수량
               , c.mng_area1
               , a.barcode_no
               , COUNT(DISTINCT c.drim_store_id) store_cnt
               , SUM(a.sales_amt) mm_amt
               , SUM(a.sales_cnt) mm_cnt
          FROM  dw_pos_mm_sales a, tb_pos_barcode_mst b, dw_store_mst c
          WHERE a.sales_mm = 202103
          AND   a.barcode_no = b.barcode_no
          AND   b.category_nm4 in('두유')
          AND   b.valid_yn = 'Y'
          AND   b.maker_nm > ''
          AND   a.drim_store_id = c.drim_store_id
          AND   c.store_type in('슈퍼마켓','편의점')
          AND   c.provide_yn = 'Y'
          AND   c.mng_area1 > ''
          AND   c.sales_grd > ''
          GROUP BY a.sales_mm
               , c.mng_area1
               , a.barcode_no
   ) x1
  , (SELECT a.mng_area1, COUNT(DISTINCT a.drim_store_id) all_store_cnt                           #지역별 전체 매장 수 
        FROM   dw_store_mst a 
        WHERE  store_type in('슈퍼마켓','편의점')
        AND    provide_yn = 'Y'
        AND    mng_area1 > ''
        AND    sales_grd > ''
        GROUP BY a.mng_area1
	) x2
  , tb_pos_barcode_mst x3
  WHERE x1.mng_area1 = x2.mng_area1
  AND   x1.barcode_no = x3.barcode_no;
  ```
