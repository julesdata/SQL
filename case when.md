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
