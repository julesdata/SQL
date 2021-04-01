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
## 용량 패턴과 입력 정보가 일치하는지 확인하기  (case when 응용)

```sql
SELECT *, case when unit_qty != 0 AND instr(qty_ptn,unit_qty) > 0      #  qty_ptn안에 unit qty가 정확히 포함되어있으면
						then substr(qty_ptn,instr(qty_ptn,unit_qty),length(unit_qty))  # unit qty를 가져오고
					when unit_qty != 0 AND instr(qty_ptn,unit_qty) = 0 AND REGEXP_SUBSTR(qty_ptn,'[0-9]+[0-9.]*[KL]') IN (unit_qty/1000, unit_qty/100, unit_qty/10) # 못가져오는데, unit qty가 1000이상인 것 중에
						then REGEXP_SUBSTR(REGEXP_SUBSTR(qty_ptn,'[0-9]+[0-9.]*[KL]'),'[0-9]+[0-9.]*')
					when unit_qty != 0 AND instr(qty_ptn,unit_qty) = 0 AND REGEXP_SUBSTR(qty_ptn,'[0-9]+(G|ML)') IN (unit_qty*100, unit_qty*10)
						then REGEXP_SUBSTR(qty_ptn,'[0-9]+(G|ML)')
					when unit_qty = 0 then 'N'                                                                                                         
					ELSE 'check' 
					END as 'tf'
FROM tb_qty_dic
WHERE 1=1
-- and barcode_no IN(SELECT barcode_no FROM tb_pos_barcode_mst WHERE maker_nm='농심' AND valid_yn='Y')
-- AND barcode_no = '7500435126069'
-- AND unit_qty > substr(qty_ptn,instr(qty_ptn,unit_qty),length(unit_qty))
AND qty_ptn not LIKE '%+%'
-- AND unit_qty>1000
-- AND unit_qty!=0
AND (case when unit_qty != 0 AND instr(qty_ptn,unit_qty) > 0      #  qty_ptn안에 unit qty가 정확히 포함되어있으면
						then substr(qty_ptn,instr(qty_ptn,unit_qty),length(unit_qty))  # unit qty를 가져오고
					when unit_qty != 0 AND instr(qty_ptn,unit_qty) = 0 AND REGEXP_SUBSTR(qty_ptn,'[0-9]+[0-9.]*[KL]') IN (unit_qty/1000, unit_qty/100, unit_qty/10) # 못가져오는데, unit qty가 1000이상인 것 중에
						then REGEXP_SUBSTR(REGEXP_SUBSTR(qty_ptn,'[0-9]+[0-9.]*[KL]'),'[0-9]+[0-9.]*')
					when unit_qty != 0 AND instr(qty_ptn,unit_qty) = 0 AND REGEXP_SUBSTR(qty_ptn,'[0-9]+(G|ML)') IN (unit_qty*100, unit_qty*10)
						then REGEXP_SUBSTR(qty_ptn,'[0-9]+(G|ML)')
					when unit_qty = 0 then 'N'                                                                                                         
					ELSE 'check' 
					END ) = 'check'
ORDER BY barcode_no;
```
