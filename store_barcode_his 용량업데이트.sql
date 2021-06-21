SET @rg_code1='(ML|MI|MML|㎖|KG|㎏|K\\W|M\\W|M$|K$|리터|EA|세트|번들|팩입|카톤|개입|묶음|보루|박스|BOX|[줄개미구곽롤매입팩갑GLP장봉병캔T포])';       # 용량, 본입 단위: 좌측용량 표현 글자중 아무거나 
SET @rg_code2='([ ]*[x×*+/()\\-_,.&~\\[\\]][ ]*)';                                                       # 기호: x,×,*중 아무거나
SET @rg_num='([0-9]+[0-9.]*)';                                                              # 숫자 1글자 이상 반복 + 숫자or'.' 0회 이상 반복
SET @rg_except='(인분|인용|인치|개월|단계|마리|CM|MM|MG|세(?!트)|[원호인종%년Y겹%W억곡류도색])';                          # 용량과 관계 없는 숫자단위 (ex. 3호, 2인, 15.4%)
SET @rg_pattern= CONCAT('([(]*',@rg_num,'+',@rg_except,'*',@rg_code1,'*',@rg_code2,'*',')+(.*',@rg_num,'+',@rg_except,'*',@rg_code1,'*','[ ]*[x×*+/()\\-_,.&~\\[\\]]*[ ]*)*');   # 숫자,단위,기호패턴 반복

delete from dw_store_barcode_his_summary
where barcode_no IN( SELECT distinct barcode_no
                      FROM dw_store_barcode_his_test a, tb_qty_dic b
                      WHERE a.barcode_no = b.barcode_no
                      AND REGEXP_SUBSTR(REGEXP_REPLACE(a.goods_nm, CONCAT(a.barcode_no,'|[\r]'), ''),@rg_pattern) = b.qty_ptn
                      AND (a.unit_qty!=b.unit_qty OR a.pack_qty!=b.pack_qty)); 


update dw_store_barcode_his_test a join tb_qty_dic b
on a.barcode_no = b.barcode_no and REGEXP_SUBSTR(REGEXP_REPLACE(a.goods_nm, CONCAT(a.barcode_no,'|[\r]'), ''),@rg_pattern) = b.qty_ptn
set a.unit_qty=b.unit_qty,a.unit_nm = b.unit_nm, a.pack_qty=b.pack_qty
where (a.unit_qty!=b.unit_qty OR a.pack_qty!=b.pack_qty); 

