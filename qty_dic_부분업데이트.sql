  SET @rg_code1='(ML|MI|MML|㎖|미리|KG|㎏|K\\W|M\\W|M$|K$|리터|EA|세트|번들|팩입|카톤|개입|묶음|보루|박스|BOX|[줄개미구곽롤매입팩갑GLP장봉병캔T포])'; 
  SET @rg_code2='([ ]*[x×*][ ]*)';                                                                 ##띄어쓰기 추가 
  SET @rg_num='[0-9]+[0-9.]*';
  SET @rg_unit='(ML|MI|MML|㎖|미리|KG|㎏|K\\W|리터|[LG])';  
  SET @rg_unit2='(EA|세트|번들|팩입|카톤|개입|묶음|보루|박스|BOX|[줄개미구곽롤매입팩갑P장봉병캔T포])';                                                                   ## 용량 100%
  SET @rg_bundle = '(세트|번들|카톤|팩입|묶음|박스|BOX|[곽갑])';                                    ## pack 100%
  SET @rg_except='(인분|인용|인치|개월|단계|마리|CM|MM|MG|세(?!트)|[원호인종%년Y겹%W억곡류도색])'; 


insert into tb_qty_dic (barcode_no, qty_ptn, goods_nm, unit_qty, unit_nm, pack_qty)
select * from (
select barcode_no, qty_ptn, goods_nm
             , CASE WHEN goods_nm2 > '' AND SUBSTRING_INDEX(goods_nm2,'>>',1) NOT LIKE '%.%.%' 
                         THEN CONVERT(SUBSTRING_INDEX(goods_nm2,'>>',1), DOUBLE) 
                    ELSE 0 END unit_qty
             , CASE WHEN goods_nm2 > '' 
                         THEN REPLACE(REPLACE(SUBSTRING_INDEX(goods_nm2,'>>',2), SUBSTRING_INDEX(goods_nm2,'>>',1),''),'>>','') 
                    ELSE '' END unit_nm
             , CASE WHEN goods_nm2 > '' AND CHAR_LENGTH(goods_nm2)-CHAR_LENGTH(REPLACE(goods_nm2,'>>','')) > 4 
                         AND REPLACE(REPLACE(SUBSTRING_INDEX(goods_nm2,'>>',3), SUBSTRING_INDEX(goods_nm2,'>>',2),''),'>>','') NOT LIKE '%.%.%' 
                         THEN CONVERT(REPLACE(REPLACE(SUBSTRING_INDEX(goods_nm2,'>>',3), SUBSTRING_INDEX(goods_nm2,'>>',2),''),'>>',''), DOUBLE) 
                    ELSE 1 END pack_qty
from (
SELECT barcode_no, qty_ptn, goods_nm, FUNC_GOODS_QTY_temp(goods_nm,barcode_no) goods_nm2, unit_qty, unit_nm, pack_qty
FROM   tb_qty_dic 
WHERE 1=1
AND qty_ptn REGEXP CONCAT(@rg_num,@rg_unit,'[ ]*',@rg_num,@rg_unit,@rg_code2, @rg_num,@rg_unit) 
) xx) t1
on duplicate key update goods_nm=t1.goods_nm, unit_qty=t1.unit_qty, unit_nm=t1.unit_nm, pack_qty=t1.pack_qty; 
