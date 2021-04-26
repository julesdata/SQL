CREATE DEFINER=`drimmart`@`%` FUNCTION `FUNC_GOODS_QTY_temp`(
	`I_GOODS_NM` VARCHAR(500),
	`I_BARCODE` VARCHAR(50)
)
RETURNS varchar(2000) CHARSET utf8
LANGUAGE SQL
NOT DETERMINISTIC
CONTAINS SQL
SQL SECURITY DEFINER
COMMENT ''
BEGIN

/* ================ 작업 설명 =========================================================================================================
  Step 1. regexp 문자열표현식 생성
  Step 3. 영문자와 숫자가 포함된 단어가 용량표시와 혼동되는 경우를 방지하기 위해 해당하는 문자를 임의의 문자로 치환, 마지막 단계에서 임의의 문자를 원래의 문자로 원상 복구한다
  Step 4. 용량정보 추출(=120gx2개입x2팩=용량x번들x묶음수량)
 ============ End of 작업 설명 ========================================================================================================= */

  DECLARE vg_goods_nm VARCHAR(500) DEFAULT I_GOODS_NM;
  DECLARE vg_barcode VARCHAR(50) DEFAULT I_BARCODE;

  DECLARE vg_unit_nm VARCHAR(20);
  DECLARE vg_unit_qty1, vg_bundle1, vg_pack_qty1, vx_qty DOUBLE DEFAULT 0;
  DECLARE vz_num INT DEFAULT 0;
  DECLARE rg_code1, rg_code2, rg_code3, rg_num, rg_unit,rg_bundle, rg_except, vz_str, vz_return, vz_unit, vx_unit, vx_brand, vx_unit_qty VARCHAR(500);

  -- 리턴값 변수 초기화
    SET vz_return='';

/* ======= Step 1. regexp 문자열표현식 생성 ========= */
  SET rg_code1='(ML|KG|EA|세트|번들|팩입|카톤|개입|묶음|박스|BOX|[개구곽롤매입팩갑GLP장봉병캔T포])';   
  SET rg_code2='([ ]*[x×*][ ]*)';                                                                 ##띄어쓰기 추가 
  SET rg_num='[0-9]+[0-9.]*';
  SET rg_unit='(ML|KG|[LG])';                                                                     ## 용량 100%
  SET rg_bundle = '(세트|번들|카톤|팩입|묶음|박스|BOX|[곽갑])';                                    ## pack 100%
  SET rg_except='(인분|인용|인치|개월|단계|마리|CM|MM|MG|[원호인종%년Y겹%W억곡류도세색])';  ## 용량단위 아닌데 헷갈릴 수 있는 것 추가

  -- 해당바코드가 tb_pos_barcode_mst에 등록되어 있는 경우 용량단위명 가져오기
  -- case4와 같이 용량단위가 없는 경우에 용량단위명으로 사용하거나, 실제 g/ml인데 매장에서는 갯수만 표시하는 경우 해당 갯수는 본입수로 한다. 
  SET vx_unit=''; SET vx_brand=''; SET vx_unit_qty='';
  SELECT IFNULL(unit_nm,''), IFNULL(brand_nm,''), IFNULL(unit_qty,'') INTO vx_unit, vx_brand, vx_unit_qty FROM tb_pos_barcode_mst WHERE barcode_no = vg_barcode;
  -- 브랜드명에서 *,+ 문자 삭제
  SET vx_brand = REGEXP_REPLACE(vx_brand,'[()*#+]','');

  SET vx_qty = 0;
  SET vx_qty = CASE WHEN REGEXP_SUBSTR(vx_unit_qty,rg_num) NOT LIKE '%.%.%' AND REGEXP_INSTR(vx_unit_qty,rg_num) > 0 THEN CONVERT(REGEXP_SUBSTR(vx_unit_qty, rg_num), DOUBLE) ELSE 0 END;
  

  #### 용량단위가 아닌데 숫자 뒤에 쓰여서, 용량으로 인식되는 오류 방지를 위해 공백 처리  ex) 2마리, 담배 3mg, 과자5종, 5900원
  SET vg_goods_nm = CASE WHEN REGEXP_INSTR(vg_goods_nm, concat(rg_num, rg_except))>0 THEN REPLACE(vg_goods_nm, REGEXP_SUBSTR(vg_goods_nm, CONCAT(rg_num,rg_except)),'<&&>') ELSE vg_goods_nm END;
  -- 한국쓰리엠의 3M 상표명이 용량단위로 인식되는 것을 방지
  SET vg_goods_nm = CASE WHEN vg_barcode LIKE '%8806080%' THEN REPLACE(vg_goods_nm,'3M','') ELSE vg_goods_nm END;
  -- 제품명(브랜드명)에 숫자가 포함되어 있는 경우 해당 숫자가 용량으로 잘못 인식되는 것을 방지(예: 비타500100ml)
  SET vg_goods_nm = CASE WHEN vx_brand REGEXP CONCAT(rg_num,'$') AND vg_goods_nm REGEXP RIGHT(vx_brand, CHAR_LENGTH(REGEXP_SUBSTR(vx_brand,CONCAT(rg_num,'$')))+1) THEN 
                              REPLACE(vg_goods_nm, RIGHT(vx_brand, CHAR_LENGTH(REGEXP_SUBSTR(vx_brand,CONCAT(rg_num,'$')))+1),'<&&>')
                         WHEN vx_brand REGEXP CONCAT(rg_num,'$') AND vg_goods_nm REGEXP CONCAT('-',REGEXP_SUBSTR(vx_brand,CONCAT(rg_num,'$'))) THEN 
                              REPLACE(vg_goods_nm, CONCAT('-',REGEXP_SUBSTR(vx_brand,CONCAT(rg_num,'$'))),'<&&>')
                         ELSE vg_goods_nm END;
  
  -- 용량단위 통일 (1.리터 -> L, 2. MI,MML,㎖ -> ML, 3.㎏ -> KG 4. K-> KG )
  SET vg_goods_nm = CASE WHEN vg_goods_nm LIKE '%리터%' THEN REPLACE(vg_goods_nm, '리터', 'L') 
  								 WHEN vg_goods_nm REGEXP CONCAT(rg_num,'(MI|MML|㎖)') THEN REGEXP_REPLACE(regexp_substr(vg_goods_nm,CONCAT(rg_num,'(MI|MML|㎖)')),'MI|MML|㎖','ml')
  								 WHEN vg_goods_nm REGEXP '㎏' THEN REPLACE(vg_goods_nm, '㎏','KG')
  								 WHEN vg_goods_nm REGEXP CONCAT(rg_num,'(K[^a-zA-Z]|K$)') THEN REGEXP_REPLACE(regexp_substr(vg_goods_nm,CONCAT(rg_num,'(K[^a-zA-Z]|K$)')),'K','KG')
  								 ELSE vg_goods_nm
  								 END;
    ## 숫자에 ','가 쓰인 경우 (1. 1,200g ->1200g 2. 1,2KG ->1.2KG 
  SET vg_goods_nm = CASE WHEN vg_goods_nm REGEXP '(\\D|\\s|^)[0-9],[0-9]{3,}(G|ML)' THEN REGEXP_REPLACE(REGEXP_SUBSTR(vg_goods_nm,'(\\D|\\s|^)[0-9]{1},[0-9]{3,}(G|ML)'),',','')
  								 WHEN vg_goods_nm REGEXP '(\\D|\\s|^)[0-9],[0-9]{1,2}(G|ML)' THEN REGEXP_REPLACE(REGEXP_SUBSTR(vg_goods_nm,'(\\D|\\s|^)[0-9]{1},[0-9]{3,}(G|ML)'),',','.')
  								 WHEN vg_goods_nm REGEXP '(\\D|\\s|^)[0-9],[0-9]+(KG|L)' THEN REGEXP_REPLACE(REGEXP_SUBSTR(vg_goods_nm,'(\\D|\\s|^)[0-9],[0-9]+(KG|L)'),',','.')
  								 ELSE vg_goods_nm
  								 END;
  -- 하이포스의 경우 용량표기 시 소수점이 누락되는 경우 다수 발생하여 기존 바코드용량정보를 활용, 강제로 수정
  SET vg_goods_nm = CASE WHEN vg_goods_nm REGEXP CONCAT(REPLACE(vx_qty/1000,'.',''),'(L|KG)') THEN REPLACE(vg_goods_nm, REPLACE(vx_qty/1000,'.',''), vx_qty/1000) 
                         WHEN vg_goods_nm LIKE '%.%' AND vg_goods_nm REGEXP CONCAT(vx_qty*10,rg_unit) THEN REPLACE(vg_goods_nm, vx_qty*10, vx_qty)
                         WHEN vg_goods_nm LIKE '%.%' AND vg_goods_nm REGEXP CONCAT(vx_qty*100,rg_unit) THEN REPLACE(vg_goods_nm, vx_qty*100, vx_qty)
                         WHEN vg_goods_nm LIKE '%.%' AND vg_goods_nm REGEXP CONCAT(vx_qty*1000,rg_unit) THEN REPLACE(vg_goods_nm, vx_qty*1000, vx_qty)
                         ELSE vg_goods_nm
                         END;

  /* ====== Step 3. 영문자와 숫자가 포함된 단어가 용량표시와 혼동되는 경우를 방지하기 위해 해당하는 문자를 임의의 문자로 치환 ==================== */
  -- '절단꽃게2L 480g'와 같이 L이 용량이 아닌 크기를 표시하는 경우 해당 문자 삭제 처리
  IF REGEXP_INSTR(vg_goods_nm,concat(rg_num,'L','.*',rg_num,'(ML|KG|G)'))>0 AND REGEXP_INSTR(vg_goods_nm,concat(rg_num,'L','.*',rg_num,'L'))=0 
                              AND REGEXP_INSTR(vg_goods_nm,concat(rg_num,'L','[ ]*','[*x+]','[ ]*',rg_num,rg_code1))=0 THEN

    SET @STR1=''; SET @str1=REGEXP_SUBSTR(vg_goods_nm,CONCAT(rg_num,'L','.*',rg_num,rg_code1));
    SET @unit1=''; SET @unit1='L';
    SET @str_b=''; SET @str_b=REPLACE(@str1,REGEXP_SUBSTR(@STR1,CONCAT(rg_num,'L')),'');
    SET @unit2=''; SET @unit2=REGEXP_SUBSTR(@str_b,rg_code1); 
    SET vg_goods_nm = REPLACE(vg_goods_nm, REGEXP_SUBSTR(vg_goods_nm,concat(rg_num,'L')),'<&&>');

  END IF;                         

  SET rg_code3=REPLACE(rg_code1, '])', ' x×*-])');  #(ML|KG|EA|팩입|카톤|개입|[개구곽롤매입팩MGLP장x×*-])


  errchk_loop2:
  WHILE REGEXP_INSTR(vg_goods_nm, CONCAT('[a-wyz]+',rg_num, rg_code3,'[a-wyz]+')) > 0 DO

    SET vg_goods_nm = REPLACE(vg_goods_nm, REGEXP_SUBSTR(vg_goods_nm, CONCAT('[a-wyz]+', rg_num, rg_code3,'[a-wyz]+')),'<&&>');

    IF vz_num > 5 THEN
      LEAVE errchk_loop2;
    END IF;

    SET vz_num = vz_num + 1;

  END WHILE errchk_loop2;
  
  
  ## ml/g 외의 단위가 중복일 때 
  IF REGEXP_INSTR(vg_goods_nm, CONCAT(rg_num,rg_unit,'[ ]*',rg_num,rg_code1)) = 0 AND REGEXP_INSTR(vg_goods_nm, CONCAT(rg_num,rg_code1,'[ ]*',rg_num,rg_unit)) = 0
  	AND REGEXP_INSTR(vg_goods_nm, CONCAT(rg_num,rg_code1,'[ ]*',rg_num,rg_code1)) > 0 THEN
  	 SET @STR_QTY=''; SET @STR_QTY=REGEXP_SUBSTR(vg_goods_nm, CONCAT(rg_num,rg_code1,'[ ]*',rg_num,rg_code1));
  	 SET @QTY1=''; SET @QTY1=REGEXP_SUBSTR(@STR_QTY, CONCAT(rg_num,rg_code1));
  	 SET @QTY2=''; SET @QTY2=SUBSTR(@STR_QTY, CHAR_LENGTH(@QTY1)+1);
  	 ## 1) 용량 없이 갯수만 동일하게 중복일 때, 1개 삭제 ex) 15구 15구, 34p 34개
	 SET vg_goods_nm= CASE WHEN REGEXP_SUBSTR(@QTY1, rg_num) = REGEXP_SUBSTR(@QTY2,rg_num) THEN REPLACE(vg_goods_nm, @STR_QTY, @QTY1) 
	 ## 2) 6봉 4입 -> 6봉x4입
	 							  ELSE REPLACE(vg_goods_nm, @STR_QTY, CONCAT(@QTY1,'x',@QTY2)) END ;
  END IF;
/* 하단 번들 범위에서 수정(case2, 6) 아래 식은 일부밖에 수정 못함 
  -- 용량 뒤에 오는 숫자가 가격을 나타내는 경우가 많음. but 본입수로 잘못 인식되는 것을 방지 >> 예:  롯)허쉬라지바밀크100g3100
  -- 용량단위 뒤의 숫자 삭제. 예: 롯)허쉬라지바밀크100g3100 --> 롯)허쉬라지바밀크100g
  IF REGEXP_INSTR(vg_goods_nm, CONCAT('[0-9]+[0-9.]*',rg_code1,'+','[0-9]{3,}$'))>0 THEN
  	 SET @QTY1=''; SET @QTY1=REGEXP_SUBSTR(vg_goods_nm, CONCAT('[0-9]+[0-9.]*',rg_code1,'+','[0-9]{3,}$'));
  	 SET @QTY2=''; SET @QTY2=REGEXP_SUBSTR(@QTY1, CONCAT('[0-9]+[0-9.]*',rg_code1,'+'));
    SET vg_goods_nm = REPLACE(vg_goods_nm, @QTY1, @QTY2);
  END IF;
*/
  -- 용량&본입수가 중복돼 용량계산이 잘못되는 경우. 예:  칭따오대맥640ml12640ml12
  -- 중복되는 용량&본입수를 삭제. 예: 칭따오대맥640ml12640ml12 --> 칭따오대맥640ml12
  IF REGEXP_INSTR(vg_goods_nm, CONCAT('[0-9]+[0-9.]*','(ML|L)+','[0-9.]{3,}','(ML|L)+','[0-9]{1,2}$'))>0 
     OR REGEXP_INSTR(vg_goods_nm, CONCAT('[0-9]+[0-9.]*','(KG|G)+','[0-9.]{3,}','(KG|G)+','[0-9]{1,2}$'))>0 THEN
  	 SET @QTY1=''; SET @QTY1=REGEXP_SUBSTR(vg_goods_nm, CONCAT('[0-9]+[0-9.]*','(ML|KG|[GL])+','[0-9.]{3,}','(ML|KG|[GL])+','[0-9]{1,2}$'));
  	 SET @S_IDX=''; SET @S_IDX=REGEXP_SUBSTR(@QTY1, CONCAT('[0-9]+[0-9.]*','(ML|KG|[GL])+'));
  	 SET @QTY2=''; SET @QTY2=SUBSTRING_INDEX(@QTY1, @S_IDX, 2);
    SET vg_goods_nm = REPLACE(vg_goods_nm, @QTY1, @QTY2);
  END IF;

  -- 콤마(,)로 인한 용량 오류 
  -- KG/L 앞의 콤마는 닷(.)으로 변경(예: 돌파인링(대)3,62kg --> 3.62KG), 나머지는 콤마를 삭제(예: 그린자이언트2,120g --> 2120G)
/*  IF REGEXP_INSTR(vg_goods_nm, CONCAT('[0-9]+[,]+[0-9]+',rg_code1,'+'))>0 THEN
  	 SET @STR_QTY=''; SET @STR_QTY=REGEXP_SUBSTR(vg_goods_nm, CONCAT('[0-9]+[,]+[0-9]+',rg_code1,'+'));
    SET @CODE1=''; SET @CODE1=REGEXP_SUBSTR(@STR_QTY,rg_code1);
  	 SET @QTY2=''; SET @QTY2=CASE WHEN @CODE1 IN('KG','L') THEN REPLACE(@STR_QTY,',','.') ELSE REPLACE(@STR_QTY,',','') END;
    SET vg_goods_nm = REPLACE(vg_goods_nm, @STR_QTY, @QTY2);
  END IF;
*/  
  ## 용량*본입이  공란없이 중복되어, 용량이 과다하게 크게 적힌 경우 (ex: 260g*3260g*3 --> 3260g 으로인식) 표기가 중복된 것으로 간주 해 하나를 삭제 
  IF REGEXP_INSTR(vg_goods_nm, CONCAT(rg_num,rg_unit,rg_code2,rg_num,rg_num,rg_unit,rg_code2,rg_num))>0 THEN   
  	 SET @STR_QTY=''; SET @STR_QTY=REGEXP_SUBSTR(vg_goods_nm, CONCAT(rg_num,rg_unit,rg_code2,rg_num,rg_num,rg_unit,rg_code2,rg_num));
  	 SET @QTY1=''; SET @QTY1=REGEXP_SUBSTR(@STR_QTY, CONCAT(rg_num,rg_unit,rg_code2));
  	 SET @QTY2=''; SET @QTY2=SUBSTR(@STR_QTY, CHAR_LENGTH(@QTY1)+1);
  	 SET @QTY3=''; SET @QTY3=SUBSTR(@QTY2,regexp_instr(@QTY2,@QTY1)+CHAR_LENGTH(@QTY1));
	 SET vg_goods_nm = CASE WHEN REGEXP_INSTR(@QTY2, @QTY1) > 0 THEN REPLACE(vg_goods_nm, @STR_QTY, CONCAT(@QTY1,@QTY3)) END;
  END if;

  -- 용량표기가 공란없이 중복된 경우 +가 누락된 것으로 간주(260g260g==>260g+260g)
  -- But, 중간에 공란이 있는 경우 용량표기가 중복된 것으로 간주해 하나를 삭제(260g 260g==>260g)
  -- 260G*3 260G*3
  IF REGEXP_INSTR(vg_goods_nm, CONCAT(rg_num,rg_unit,rg_code2,rg_num,'[ ]+',rg_num,rg_unit,rg_code2,rg_num))>0 THEN 
    SET @STR_QTY=''; SET @STR_QTY=REGEXP_SUBSTR(vg_goods_nm, CONCAT(rg_num,rg_unit,rg_code2,rg_num,'[ ]+',rg_num,rg_unit,rg_code2,rg_num));
    SET @QTY1=''; SET @QTY1=REGEXP_SUBSTR(@STR_QTY, CONCAT(rg_num,rg_unit,rg_code2,rg_num));
    SET @QTY2=''; SET @QTY2=SUBSTR(@STR_QTY, CHAR_LENGTH(@QTY1)+2);
    -- 용량표기가 같은 경우 중복 제거, 용량표기가 다른 경우 +가 누락된 것으로 간주해 + 기호 삽입 
    SET vg_goods_nm = CASE WHEN @QTY1=@QTY2 THEN REPLACE(vg_goods_nm, @STR_QTY, @QTY1) ELSE REPLACE(vg_goods_nm, @STR_QTY, CONCAT(@QTY1,'+',@QTY2)) END;
  -- 260g260g
  ELSEIF REGEXP_INSTR(vg_goods_nm, CONCAT(rg_num,rg_unit,rg_num,rg_unit))>0 THEN 
    SET @STR_QTY=''; SET @STR_QTY=REGEXP_SUBSTR(vg_goods_nm, CONCAT(rg_num,rg_unit,rg_num,rg_unit));
    SET @QTY1=''; SET @QTY1=REGEXP_SUBSTR(@STR_QTY, CONCAT(rg_num,rg_unit));
    SET @QTY2=''; SET @QTY2=SUBSTR(@STR_QTY, CHAR_LENGTH(@QTY1)+1);
    SET vg_goods_nm = REPLACE(vg_goods_nm, @STR_QTY, CONCAT(@QTY1,'+',@QTY2));
  -- 260G260
  ELSEIF REGEXP_INSTR(vg_goods_nm, CONCAT(rg_num,rg_unit,rg_num,rg_code1))=0  # rg_num,rg_unit,rg_num,"rg_unit" -> rg_num,rg_unit,rg_num,"rg_code1"로 수정. 260g80매 가 340으로 계산되는 오류 수정
         AND REGEXP_INSTR(vg_goods_nm, CONCAT(rg_num,rg_unit,rg_num))>0 THEN 
    SET @STR_QTY=''; SET @STR_QTY=REGEXP_SUBSTR(vg_goods_nm, CONCAT(rg_num,rg_unit,rg_num));
    SET @QTY1=''; SET @QTY1=REGEXP_SUBSTR(@STR_QTY, CONCAT(rg_num,rg_unit));
    SET @QTY2=''; SET @QTY2=SUBSTR(@STR_QTY, CHAR_LENGTH(@QTY1)+1);
    ## 같은용량 중복일 경우 + 기호 삽입
    -- 본입수로 추정되는 경우 X, 추가 용량으로 추정되는 경우 +기호 삽입
    -- 본입수 추정은? 50미만,(BUT, 단위용량이 10미만인 경우 숫자 제한 없이 본입수로 추정)
    SET vg_goods_nm = CASE WHEN REGEXP_SUBSTR(@QTY1,rg_num) = REGEXP_SUBSTR(@QTY2,rg_num) THEN REPLACE(vg_goods_nm, @STR_QTY, CONCAT(@QTY1,'+',@QTY2))
	 								WHEN REGEXP_SUBSTR(@QTY2,rg_num) NOT LIKE '%.%.%' AND REGEXP_SUBSTR(@QTY2,rg_num) < 50 THEN REPLACE(vg_goods_nm, @STR_QTY, CONCAT(@QTY1,'x',@QTY2))
                           WHEN (REGEXP_SUBSTR(@QTY1,rg_num) NOT LIKE '%.%.%' AND REGEXP_SUBSTR(@QTY1,rg_num) < 10)
									     AND (REGEXP_SUBSTR(@QTY2,rg_num) NOT LIKE '%.%.%' AND REGEXP_SUBSTR(@QTY2,rg_num) >= 50) THEN
									     REPLACE(vg_goods_nm, @STR_QTY, CONCAT(@QTY1,'x',@QTY2))
									## 100 미만 일 경우 추가용량으로 산입    
									WHEN REGEXP_SUBSTR(@QTY2,rg_num) NOT LIKE '%.%.%' AND REGEXP_SUBSTR(@QTY2,rg_num) < 100 THEN REPLACE(vg_goods_nm, @STR_QTY, CONCAT(@QTY1,'+',@QTY2))
                           ELSE vg_goods_nm END;
  -- 260g 260g OR 260G 260                                                                   ###### 260g 30입을 260g+30으로 오표기하지 않도록 수정
  ELSEIF REGEXP_INSTR(vg_goods_nm, CONCAT(rg_num,rg_unit,'[ ]+',rg_num, rg_code1,'*'))>0 THEN  # rg_code1* 추가
    SET @QTY1=''; SET @QTY2=''; SET @STR_QTY='';
    SET @STR_QTY=REGEXP_SUBSTR(vg_goods_nm, CONCAT(rg_num,rg_unit,'[ ]+',rg_num, rg_code1,'*'));
    SET @QTY1=REGEXP_SUBSTR(@STR_QTY, CONCAT(rg_num,rg_unit));
    SET @QTY2=SUBSTR(@STR_QTY, CHAR_LENGTH(@QTY1)+2);
    -- 용량표기가 같은 경우 중복 제거, 용량표기가 다른 경우 +가 누락된 것으로 간주해 +기호 삽입
    SET vg_goods_nm = CASE WHEN REGEXP_SUBSTR(@QTY1,rg_num)=REGEXP_SUBSTR(@QTY2,rg_num) THEN REPLACE(vg_goods_nm, @STR_QTY, @QTY1) 
    						      WHEN REGEXP_SUBSTR(@QTY1,rg_num)!=REGEXP_SUBSTR(@QTY2,rg_num) AND REGEXP_INSTR(@QTY2, rg_unit) > 0 then  
								        REPLACE(vg_goods_nm, @STR_QTY, CONCAT(@QTY1,'+',TRIM(@QTY2)))    #용량단위가 있는데 용량표기가 다른경우는 + 삽입 ex) 260g 30g, 1L 500ml, 120ml 500g 
									WHEN REGEXP_SUBSTR(@QTY1,rg_num)!=REGEXP_SUBSTR(@QTY2,rg_num) AND REGEXP_INSTR(@QTY2, rg_code1) > 0 then	  
										  REPLACE(vg_goods_nm, @STR_QTY, CONCAT(@QTY1,'x',TRIM(@QTY2)))	     # 260g 5입 -> 260gx5입  
                        	ELSE vg_goods_nm
									END;                                                                # 용량, 본입 단위 없고 숫자만 있는 경우는,추가용량일 경우보다 가격 등 다른 내용일 경우가 더 많아 추가하지 않음.
  END IF;

  -- 340G*3+340G*2 ==> 340G*5
  IF REGEXP_INSTR(vg_goods_nm,CONCAT(rg_num,rg_code1,rg_code2,rg_num,'[ ]*[+][ ]*',rg_num,rg_code1,rg_code2,rg_num)) > 0 THEN
    SET @str1=''; 
    SET @str1=REGEXP_SUBSTR(vg_goods_nm,CONCAT(rg_num,rg_code1,rg_code2,rg_num,'[ ]*[+][ ]*',rg_num,rg_code1,rg_code2,rg_num));
    SET @str_a=''; SET @str_a=SUBSTRING_INDEX(@str1,'+',1);  #340G*3
    SET @str_b=''; SET @str_b=SUBSTRING_INDEX(@str1,'+',-1);  #340G*2
    SET @unit1=''; SET @unit1=REGEXP_SUBSTR(@str_a,rg_code1);  #G
    SET @pack1=''; SET @pack1=REPLACE(@str_a,REGEXP_SUBSTR(@str_a,CONCAT(rg_num,rg_code1,rg_code2)),'');  #3
    SET @pnum1=0; SET @pnum1=CASE WHEN REGEXP_INSTR(@pack1,rg_num)>0 AND REGEXP_SUBSTR(@pack1,rg_num) NOT LIKE '%.%.%' THEN CONVERT(@pack1, DOUBLE) ELSE 0 END; #3
    SET @unit2=''; SET @unit2=REGEXP_SUBSTR(@str_b,rg_code1); 
    SET @pack2=0; SET @pack2=REPLACE(@str_b,REGEXP_SUBSTR(@str_b,CONCAT(rg_num,rg_code1,rg_code2)),'');
    SET @pnum2=0; SET @pnum2=CASE WHEN REGEXP_INSTR(@pack2,rg_num)>0 AND REGEXP_SUBSTR(@pack2,rg_num) NOT LIKE '%.%.%'  THEN CONVERT(@pack2, DOUBLE) ELSE 0 END;

      SET @nsum=0;
      IF REGEXP_SUBSTR(@str_a,rg_num)=REGEXP_SUBSTR(@str_b,rg_num) THEN   ##### 용량단위 같은거 여부는 왜 안봐???
        -- 용량이 같을 경우 (1.5L*1+1.5L*2 ==> 1.5L*3)
        SET vg_goods_nm=REPLACE(vg_goods_nm, @str1, CONCAT(REGEXP_SUBSTR(@str_a,rg_num),@unit1,'*',@pnum1+@pnum2));
      ELSE
        -- 용량이 다를 경우 (500ML*2+200ML*1 ==> 1200ML)
        SET @nsum=0; SET @num1=0; SET @num2=0;
        SET @num1=CASE WHEN REGEXP_INSTR(@str_a,rg_num)>0 AND REGEXP_SUBSTR(@str_a,rg_num) NOT LIKE '%.%.%' THEN CONVERT(REGEXP_SUBSTR(@str_a,rg_num), DOUBLE)*@pnum1 ELSE 0 END;
        SET @num2=CASE WHEN REGEXP_INSTR(@str_b,rg_num)>0 AND REGEXP_SUBSTR(@str_b,rg_num) NOT LIKE '%.%.%' THEN CONVERT(REGEXP_SUBSTR(@str_b,rg_num), DOUBLE)*@pnum2 ELSE 0 END;
		  SET @nsum=@num1+@num2;
        SET vg_goods_nm=REPLACE(vg_goods_nm, @str1, CONCAT(@nsum,@unit1));
      END IF;
  -- 340G*3+340G ==> 340G*4
  ELSEIF REGEXP_INSTR(vg_goods_nm,CONCAT(rg_num,rg_code1,rg_code2,rg_num,'[ ]*[+][ ]*',rg_num)) > 0 THEN
    SET @str1=''; 
    SET @str1=REGEXP_SUBSTR(vg_goods_nm,CONCAT(rg_num,rg_code1,rg_code2,rg_num,'[ ]*[+][ ]*',rg_num));
    SET @str_a=''; SET @str_a=SUBSTRING_INDEX(@str1,'+',1);
    SET @str_b=''; SET @str_b=SUBSTRING_INDEX(@str1,'+',-1);
    SET @unit1=''; SET @unit1=REGEXP_SUBSTR(@str_a,rg_code1); 
    SET @pack1=''; SET @pack1=REPLACE(@str_a,REGEXP_SUBSTR(@str_a,CONCAT(rg_num,rg_code1,rg_code2)),'');
    SET @pnum1=0; SET @pnum1=CASE WHEN REGEXP_INSTR(@pack1,rg_num)>0 AND REGEXP_SUBSTR(@pack1,rg_num) NOT LIKE '%.%.%' THEN CONVERT(@pack1, DOUBLE) ELSE 0 END;
    SET @unit2=''; 
    SET @pnum2=1;

      SET @nsum=0;
      IF REGEXP_SUBSTR(@str_a,rg_num)=REGEXP_SUBSTR(@str_b,rg_num) THEN
        -- 용량이 같을 경우 (1.5L+1.5L ==> 1.5L*2)
        SET vg_goods_nm=REPLACE(vg_goods_nm, @str1, CONCAT(REGEXP_SUBSTR(@str_a,rg_num),@unit1,'*',@pnum1+@pnum2));
      ELSE
        -- 용량이 다를 경우 (500ML+200ML ==> 700ML)
        SET @nsum=0; SET @num1=0; SET @num2=0;
        SET @num1=CASE WHEN REGEXP_INSTR(@str_a,rg_num)>0 AND REGEXP_SUBSTR(@str_a,rg_num) NOT LIKE '%.%.%' THEN CONVERT(REGEXP_SUBSTR(@str_a,rg_num), DOUBLE)*@pnum1 ELSE 0 END;
        SET @num2=CASE WHEN REGEXP_INSTR(@str_b,rg_num)>0 AND REGEXP_SUBSTR(@str_b,rg_num) NOT LIKE '%.%.%' THEN CONVERT(REGEXP_SUBSTR(@str_b,rg_num), DOUBLE)*@pnum2 ELSE 0 END;
        -- +기호 다음 숫자가 본입수인 경우(130gx2+1)
        IF CHAR_LENGTH(@pnum1)=CHAR_LENGTH(@num2) THEN
          SET @nsum=@pnum1+@num2;
          SET vg_goods_nm=REPLACE(vg_goods_nm, @str1, CONCAT(REGEXP_SUBSTR(@str_a,rg_num),@unit1,'x',@nsum));
        ELSE
          SET @nsum=@num1+@num2;
          SET vg_goods_nm=REPLACE(vg_goods_nm, @str1, CONCAT(@nsum,@unit1));
        END IF;
      END IF;
  -- 1.5L+1.5L ==> 1.5L*2,  1.5L+500ml==>2000ml
  ELSEIF REGEXP_INSTR(vg_goods_nm,CONCAT(rg_num,rg_code1,'[ ]*[+][ ]*',rg_num,rg_code1)) > 0 THEN
    SET @str1='';
    SET @str1=REGEXP_SUBSTR(vg_goods_nm,CONCAT(rg_num,rg_code1,'[ ]*[+][ ]*',rg_num,rg_code1));
    SET @unit1=''; SET @unit1=REGEXP_SUBSTR(SUBSTRING_INDEX(@str1,'+',1),rg_code1);
    SET @unit2=''; SET @unit2=REGEXP_SUBSTR(SUBSTRING_INDEX(@str1,'+',-1),rg_code1);
    -- @unit1과 @unit2가 같은 경우에 한해 숫자를 더한다.
    IF (@unit1=@unit2) THEN
      SET @nsum=0;
      IF SUBSTRING_INDEX(REPLACE(@str1, @unit1, ''),'+',1)=SUBSTRING_INDEX(REPLACE(@str1, @unit2, ''),'+',-1) THEN
        -- 용량이 같을 경우 (1.5L+1.5L ==> 1.5L*2)
        SET vg_goods_nm=REPLACE(vg_goods_nm, @str1, CONCAT(SUBSTRING_INDEX(@str1,'+',1),'*2'));
      ELSE
        -- 용량이 다를 경우 (500ML+200ML ==> 700ML)
        SET @nsum=0; SET @num1=0; SET @num2=0;
        SET @num1=SUBSTRING_INDEX(REPLACE(@str1, @unit1, ''),'+',1);
        SET @num2=SUBSTRING_INDEX(REPLACE(@str1, @unit2, ''),'+',-1);
		  SET @nsum=@num1+@num2;
        SET vg_goods_nm=REPLACE(vg_goods_nm, @str1, CONCAT(@nsum,@unit1));
      END IF;
    -- 용량단위가 다른 경우 1.5L+500ml==>2000ml
    ELSE
      SET @nsum=0; SET @num1=0; SET @num2=0;
      SET @num1=CASE WHEN @unit1 in('l','kg') THEN SUBSTRING_INDEX(REPLACE(@str1, @unit1, ''),'+',1)*1000 ELSE SUBSTRING_INDEX(REPLACE(@str1, @unit1, ''),'+',1) END;
      SET @num2=CASE WHEN @unit2 in('l','kg') THEN SUBSTRING_INDEX(REPLACE(@str1, @unit2, ''),'+',-1)*1000 ELSE SUBSTRING_INDEX(REPLACE(@str1, @unit2, ''),'+',-1) END;
      SET @nsum=@num1+@num2;
      SET @unit1=CASE WHEN @unit1 in('l') THEN 'ml' WHEN @unit1 in('kg') THEN 'g' ELSE @unit1 END;
      SET vg_goods_nm=REPLACE(vg_goods_nm, @str1, CONCAT(@nsum,@unit1));
    END IF;
  -- 80+80g ==> 80G*2  햇반4번들(200g*3+200g)
  ELSEIF REGEXP_INSTR(vg_goods_nm,CONCAT(rg_num,rg_code1,'[ ]*[+][ ]*',rg_num,rg_code1)) = 0
         AND REGEXP_INSTR(vg_goods_nm,CONCAT(rg_num,'[ ]*[+][ ]*',rg_num,rg_code1)) > 0 
         AND REGEXP_INSTR(vg_goods_nm,CONCAT(rg_num,rg_code1,rg_code2,rg_num,'[ ]*[+][ ]*',rg_num,rg_code1)) = 0 THEN
    SET @str1='';
    SET @str1=REGEXP_SUBSTR(vg_goods_nm,CONCAT(rg_num,'[ ]*[+][ ]*',rg_num,rg_code1));
    SET @unit1='';
    SET @unit2=''; SET @unit2=REGEXP_SUBSTR(SUBSTRING_INDEX(@str1,'+',-1),rg_code1);
    IF SUBSTRING_INDEX(@str1,'+',1)=SUBSTRING_INDEX(REPLACE(@str1, @unit2, ''),'+',-1) 
       AND CASE WHEN @unit2='l' THEN 'ml' WHEN @unit2='kg' THEN 'g' ELSE @unit2 END=vx_unit THEN
      -- 용량이 같을 경우 (80+80g ==> 80G*2)
      SET vg_goods_nm=REPLACE(vg_goods_nm, @str1, CONCAT(SUBSTRING_INDEX(@str1,'+',-1),'*2'));
    ELSE
      -- 용량이 다를 경우 (80+120g ==> 200g) 
      SET @nsum=0; SET @num1=0; SET @num2=0;
      SET @num1=SUBSTRING_INDEX(@str1,'+',1);
      SET @num2=SUBSTRING_INDEX(REPLACE(@str1, @unit2, ''),'+',-1);
      SET @nsum=CASE WHEN @num1<10 and @num1<@num2/100 THEN @num2 ELSE @num1+@num2 END;
      SET vg_goods_nm=REPLACE(vg_goods_nm, @str1, CONCAT(@nsum,@unit2));
    END IF;
  -- 80g+80 ==> 80G*2
  -- 찰고추장1.2kg+300
  ELSEIF REGEXP_INSTR(vg_goods_nm,CONCAT(rg_num,rg_code1,'[ ]*[+][ ]*',rg_num,rg_code1)) = 0
         AND REGEXP_INSTR(vg_goods_nm,CONCAT(rg_num,'[ ]*[+][ ]*',rg_num,rg_code1)) = 0 
         AND REGEXP_INSTR(vg_goods_nm,CONCAT(rg_num,rg_code1,rg_code2,rg_num,'[ ]*[+][ ]*',rg_num,rg_code1)) = 0 
			AND REGEXP_INSTR(vg_goods_nm,CONCAT(rg_num,rg_code1,'[ ]*[+][ ]*',rg_num)) > 0 THEN
    SET @str1='';
    SET @str1=REGEXP_SUBSTR(vg_goods_nm,CONCAT(rg_num,rg_code1,'[ ]*[+][ ]*',rg_num));
    SET @unit1=''; SET @unit1=REGEXP_SUBSTR(SUBSTRING_INDEX(@str1,'+',1),rg_code1);
    SET @unit2='';
    IF SUBSTRING_INDEX(REPLACE(@str1, @unit1, ''),'+',1)=SUBSTRING_INDEX(@str1,'+',-1) 
       AND CASE WHEN @unit1='l' THEN 'ml' WHEN @unit1='kg' THEN 'g' ELSE @unit1 END=vx_unit THEN
      -- 용량이 같을 경우 (80g+80 ==> 80G*2)
      SET vg_goods_nm=REPLACE(vg_goods_nm, @str1, CONCAT(SUBSTRING_INDEX(@str1,'+',1),'*2'));
    ELSE
      -- 용량이 다를 경우 (80g+120 ==> 200G)
      SET @nsum=0; SET @num1=0; SET @num2=0;
      SET @num1=SUBSTRING_INDEX(REPLACE(@str1, @unit1, ''),'+',1);
      SET @num2=SUBSTRING_INDEX(@str1,'+',-1);
      SET @num2=CASE WHEN @unit1 IN('kg','l') THEN @num2/1000 ELSE @num2 END;
      -- 200G+1, 200G+2와 같이 추가중량이 터무니 없이 작을 경우 생략
      SET @nsum=CASE WHEN @num2<10 and @num2<@num1/100 THEN @num1 ELSE @num1+@num2 END;
      SET vg_goods_nm=REPLACE(vg_goods_nm, @str1, CONCAT(@nsum,@unit1));
    END IF;
  -- 1+1 ==> 2 
  ELSEIF REGEXP_INSTR(vg_goods_nm,CONCAT(rg_num,rg_code1,'[ ]*[+][ ]*',rg_num,rg_code1)) = 0
         AND REGEXP_INSTR(vg_goods_nm,CONCAT(rg_num,'[ ]*[+][ ]*',rg_num,rg_code1)) = 0 
         AND REGEXP_INSTR(vg_goods_nm,CONCAT(rg_num,rg_code1,rg_code2,rg_num,'[ ]*[+][ ]*',rg_num,rg_code1)) = 0 
			AND REGEXP_INSTR(vg_goods_nm,CONCAT(rg_num,rg_code1,'[ ]*[+][ ]*',rg_num)) = 0
			AND REGEXP_INSTR(vg_goods_nm,CONCAT(rg_num,'[ ]*[+][ ]*',rg_num)) > 0 THEN
    SET @str1='';
    SET @str1=REGEXP_SUBSTR(vg_goods_nm,CONCAT(rg_num,'[ ]*[+][ ]*',rg_num));
    SET @nsum=0; SET @num1=0; SET @num2=0;
    SET @num1=SUBSTRING_INDEX(@str1,'+',1);
    SET @num2=SUBSTRING_INDEX(@str1,'+',-1);
    SET @nsum=@num1+@num2;
    SET vg_goods_nm=REPLACE(vg_goods_nm, @str1, @nsum);
  END IF;

/* ======= Step 4. 용량정보 추출(=120gx2=용량x번들) ========= */
  SET @tt=CASE WHEN REGEXP_INSTR(vg_goods_nm, CONCAT(rg_num, rg_code1, rg_code2))>0 THEN REGEXP_SUBSTR(vg_goods_nm, CONCAT(rg_num, rg_code1, rg_code2)) ELSE '' END;
  SET vg_goods_nm=CASE WHEN @tt>'' THEN REPLACE(vg_goods_nm,@tt,regexp_replace(@tt,rg_code2,'x')) ELSE vg_goods_nm END; 
  SET vg_goods_nm=CASE WHEN REGEXP_INSTR(vg_goods_nm,CONCAT(rg_num,rg_code2,rg_num))>0 THEN REGEXP_REPLACE(REGEXP_SUBSTR(vg_goods_nm,CONCAT(rg_num,rg_code2,rg_num)),rg_code2,'x') ELSE vg_goods_nm END; 
  SET vg_goods_nm=CASE WHEN REGEXP_INSTR(vg_goods_nm,CONCAT(rg_num,' ',rg_num,rg_code1))>0 THEN REPLACE(vg_goods_nm,REGEXP_SUBSTR(vg_goods_nm,concat(rg_num,' ')),'') ELSE vg_goods_nm END;
  SET vg_goods_nm=REPLACE(vg_goods_nm, ' ', '');

  -- 용량단위의 우선순위 : CASE1=260gx3, CASE2=260g, CASE3=260g3, CASE4=260x20P, CASE5=20Px3, CASE6=20P
  -- CASE1=260gx3
  IF REGEXP_INSTR(vg_goods_nm, CONCAT(rg_num,rg_unit,'[x]',rg_num)) > 0 THEN

     SET @IF_VAL2='1';
    SET vz_str = REGEXP_SUBSTR(vg_goods_nm, CONCAT(rg_num,rg_unit,'[x]',rg_num));
    SET vz_unit = REGEXP_SUBSTR(vz_str, rg_unit);
    -- 단위용량 계산
    SET vg_unit_nm = CASE WHEN vz_unit in('ml','l') THEN 'ml' WHEN vz_unit in('g','kg') THEN 'g' ELSE vz_unit END;
    SET vg_unit_qty1 = CASE WHEN regexp_substr(vz_str,rg_num) NOT LIKE '%.%.%' THEN CONVERT(regexp_substr(vz_str,rg_num), DOUBLE) ELSE 0 END;
    SET vg_unit_qty1 = CASE WHEN vz_unit in('l','kg') THEN ROUND(vg_unit_qty1*1000) WHEN vz_unit not in('l','kg') THEN vg_unit_qty1 ELSE vg_unit_qty1 END;
    SET vz_return = CONCAT(vz_return, vg_unit_qty1, '>>', vg_unit_nm, '>>');
    -- 본입수량 계산
    SET vz_str = TRIM(REPLACE(vz_str, REGEXP_SUBSTR(vz_str, CONCAT(rg_num,rg_unit,'[x]')), ''));
    SET vg_bundle1 = CASE WHEN regexp_substr(vz_str,rg_num) NOT LIKE '%.%.%' THEN CONVERT(regexp_substr(vz_str,rg_num), DOUBLE) ELSE 1 END;
    -- 본입수량이 소수점이 있으면 안됨. 이 경우 1로 강제 수정
    SET vg_bundle1 = CASE WHEN MOD(vg_bundle1,1)<>0 THEN 1 
                          WHEN vg_bundle1=vg_unit_qty1 AND vg_bundle1>1000 THEN 1 
                          WHEN vg_bundle1>10000 THEN 1 
                          ELSE vg_bundle1 END;
    SET vz_return = CONCAT(vz_return, vg_bundle1, '>>');

  -- CASE2=260g3
  ELSEIF REGEXP_INSTR(vg_goods_nm, CONCAT(rg_num,rg_unit,'[x]',rg_num)) = 0
         AND REGEXP_INSTR(vg_goods_nm, CONCAT(rg_num,rg_unit,rg_num)) > 0 THEN

    SET @IF_VAL2='2';
    SET vz_str = REGEXP_SUBSTR(vg_goods_nm, CONCAT(rg_num,rg_unit,rg_num,rg_bundle,'*'));
    SET vz_unit = REGEXP_SUBSTR(vz_str, rg_unit);
    -- 단위용량 계산
    SET vg_unit_nm = CASE WHEN vz_unit in('ml','l') THEN 'ml' WHEN vz_unit in('g','kg') THEN 'g' ELSE vz_unit END;
    SET vg_unit_qty1 = CASE WHEN regexp_substr(vz_str,rg_num) NOT LIKE '%.%.%' THEN CONVERT(regexp_substr(vz_str,rg_num), DOUBLE) ELSE 0 END;
    SET vg_unit_qty1 = CASE WHEN vz_unit in('l','kg') THEN ROUND(vg_unit_qty1*1000) WHEN vz_unit not in('l','kg') THEN vg_unit_qty1 ELSE vg_unit_qty1 END;
    SET vz_return = CONCAT(vz_return, vg_unit_qty1, '>>', vg_unit_nm, '>>');
    -- 본입수량 계산
    SET vz_str = TRIM(REPLACE(vz_str, REGEXP_SUBSTR(vz_str, CONCAT(rg_num, rg_unit)), ''));
    SET vg_bundle1 = CASE WHEN regexp_instr(vz_str,CONCAT(rg_num,rg_bundle))>0 THEN CONVERT(regexp_substr(vz_str,rg_num), DOUBLE) 
	 							  WHEN regexp_substr(vz_str,rg_num) NOT LIKE '%.%.%' THEN CONVERT(regexp_substr(vz_str,rg_num), DOUBLE) ELSE 1 END;
    -- 본입수량이 소수점이 있으면 안됨. 이 경우 1로 강제 수정
    SET vg_bundle1 = CASE WHEN MOD(vg_bundle1,1)<>0 THEN 1  
                          WHEN regexp_instr(vz_str,CONCAT(rg_num,rg_bundle))=0 and vg_bundle1>100 THEN 1 
                          ELSE vg_bundle1 END;
    SET vz_return = CONCAT(vz_return, vg_bundle1, '>>');

  -- CASE3=260g
  ELSEIF REGEXP_INSTR(vg_goods_nm, CONCAT(rg_num,rg_unit,'[x]',rg_num)) = 0
         AND REGEXP_INSTR(vg_goods_nm, CONCAT(rg_num,rg_unit,rg_num)) = 0
			AND REGEXP_INSTR(vg_goods_nm, CONCAT(rg_num,rg_unit)) > 0 THEN

    SET @IF_VAL2='3';
    SET vz_str = REGEXP_SUBSTR(vg_goods_nm, CONCAT(rg_num,rg_unit));
    SET vz_unit = REGEXP_SUBSTR(vz_str, rg_unit);
    -- 단위용량 계산
    SET vg_unit_nm = CASE WHEN vz_unit in('ml','l') THEN 'ml' WHEN vz_unit in('g','kg') THEN 'g' ELSE vz_unit END;
    SET vg_unit_qty1 = CASE WHEN regexp_substr(vz_str,rg_num) NOT LIKE '%.%.%' THEN CONVERT(regexp_substr(vz_str,rg_num), DOUBLE) ELSE 0 END;
    SET vg_unit_qty1 = CASE WHEN vz_unit in('l','kg') THEN ROUND(vg_unit_qty1*1000) WHEN vz_unit not in('l','kg') THEN vg_unit_qty1 ELSE vg_unit_qty1 END;
    SET vz_return = CONCAT(vz_return, vg_unit_qty1, '>>', vg_unit_nm, '>>');

  -- CASE4=260x20
  ELSEIF REGEXP_INSTR(vg_goods_nm, CONCAT(rg_num,rg_unit,'[x]',rg_num)) = 0
         AND REGEXP_INSTR(vg_goods_nm, CONCAT(rg_num,rg_unit,rg_num)) = 0
			AND REGEXP_INSTR(vg_goods_nm, CONCAT(rg_num,rg_unit)) = 0
			AND REGEXP_INSTR(vg_goods_nm, CONCAT(rg_num,'[x]',rg_num)) > 0 THEN

    SET @IF_VAL2='4';
    SET vz_str = REGEXP_SUBSTR(vg_goods_nm, CONCAT(rg_num,'[x]',rg_num));
    SET vz_unit = vx_unit;
    -- 단위용량 계산
    SET vg_unit_nm = CASE WHEN vz_unit in('매','m','롤','구','g','ml') THEN vz_unit ELSE '개' END;
    SET vg_unit_qty1 = CASE WHEN regexp_substr(vz_str,rg_num) NOT LIKE '%.%.%' THEN CONVERT(regexp_substr(vz_str,rg_num), DOUBLE) ELSE 0 END;
    SET vz_return = CONCAT(vz_return, vg_unit_qty1, '>>', vg_unit_nm, '>>');
    -- 본입수량 계산
    SET vz_str = TRIM(REPLACE(vz_str, REGEXP_SUBSTR(vz_str, CONCAT(rg_num,'[x]')), ''));
    SET vg_bundle1 = CASE WHEN regexp_substr(vz_str,rg_num) NOT LIKE '%.%.%' THEN CONVERT(regexp_substr(vz_str,rg_num), DOUBLE) ELSE 1 END;
    -- 본입수량이 소수점이 있으면 안됨. 이 경우 1로 강제 수정
    SET vg_bundle1 = CASE WHEN MOD(vg_bundle1,1)<>0 THEN 1 
                          WHEN vg_bundle1=vg_unit_qty1 AND vg_bundle1>1000 THEN 1 
                          WHEN vg_bundle1>10000 THEN 1 
                          ELSE vg_bundle1 END;
    SET vz_return = CONCAT(vz_return, vg_bundle1, '>>');

  -- CASE5=20Px3
-- 코카)몬스터파라다이스355캔x24/@IF_VAL2=5/vz_str=24/VZ_UNIT=캔/vg_unit_qty1=355/vg_unit_nm=개/vg_bundle1=24
  ELSEIF REGEXP_INSTR(vg_goods_nm, CONCAT(rg_num,rg_unit,'[x]',rg_num)) = 0
         AND REGEXP_INSTR(vg_goods_nm, CONCAT(rg_num,rg_unit,rg_num)) = 0
			AND REGEXP_INSTR(vg_goods_nm, CONCAT(rg_num,rg_unit)) = 0
			AND REGEXP_INSTR(vg_goods_nm, CONCAT(rg_num,'[x]',rg_num)) = 0
			AND REGEXP_INSTR(vg_goods_nm, CONCAT(rg_num,rg_code1,'[x]',rg_num)) > 0 THEN

    SET @IF_VAL2='5';
    SET vz_str = REGEXP_SUBSTR(vg_goods_nm, CONCAT(rg_num,rg_code1,'[x]',rg_num));
    SET vz_unit = REGEXP_SUBSTR(vz_str, rg_code1);  
    -- 단위용량 계산
    SET vg_unit_nm = CASE WHEN vx_unit IN ('g','ml') THEN vx_unit
	 							  WHEN vz_unit in('매','m','롤','구') THEN vz_unit ELSE '개' END;
    SET vg_unit_qty1 = CASE WHEN regexp_substr(vz_str,rg_num) NOT LIKE '%.%.%' THEN CONVERT(regexp_substr(vz_str,rg_num), DOUBLE) ELSE 0 END;
    SET vz_return = CONCAT(vz_return, vg_unit_qty1, '>>', vg_unit_nm, '>>');
    -- 본입수량 계산
    SET vz_str = TRIM(REPLACE(vz_str, REGEXP_SUBSTR(vz_str, CONCAT(rg_num, rg_code1,'[x]')), ''));
    SET vg_bundle1 = CASE WHEN regexp_substr(vz_str,rg_num) NOT LIKE '%.%.%' THEN CONVERT(regexp_substr(vz_str,rg_num), DOUBLE) ELSE 1 END;
    -- 본입수량이 소수점이 있으면 안됨. 이 경우 1로 강제 수정
    SET vg_bundle1 = CASE WHEN MOD(vg_bundle1,1)<>0 THEN 1 
                          WHEN vg_bundle1=vg_unit_qty1 AND vg_bundle1>1000 THEN 1 
                          WHEN vg_bundle1>10000 THEN 1 
                          ELSE vg_bundle1 END;
    SET vz_return = CONCAT(vz_return, vg_bundle1, '>>');

  -- CASE6=20P3, 20p3세트 
  ELSEIF REGEXP_INSTR(vg_goods_nm, CONCAT(rg_num,rg_unit,'[x]',rg_num)) = 0
         AND REGEXP_INSTR(vg_goods_nm, CONCAT(rg_num,rg_unit,rg_num)) = 0
			AND REGEXP_INSTR(vg_goods_nm, CONCAT(rg_num,rg_unit)) = 0
			AND REGEXP_INSTR(vg_goods_nm, CONCAT(rg_num,'[x]',rg_num)) = 0
			AND REGEXP_INSTR(vg_goods_nm, CONCAT(rg_num,rg_code1,'[x]',rg_num)) = 0
			AND REGEXP_INSTR(vg_goods_nm, CONCAT(rg_num,rg_code1,rg_num)) > 0 THEN

    SET @IF_VAL2='6';
    SET vz_str = REGEXP_SUBSTR(vg_goods_nm, CONCAT(rg_num,rg_code1,rg_num,rg_bundle,'*'));
    SET @qty1 = REGEXP_SUBSTR(vz_str, CONCAT(rg_num,rg_code1));
    SET vz_unit = REGEXP_SUBSTR(@qty1, rg_code1);
    -- 단위용량 계산 ## g / ml로 등록된 경우 단위 변환 
     -- tb_pos_barcode_mst에 용량단위가 g/ml로 등록되어있을 경우, 현 단위용량은 본입수량으로 간주한다.
    IF vx_unit IN ('g','ml') THEN 
      SET vg_unit_nm = ''; SET vg_unit_qty1=0;
      IF REGEXP_INSTR(vx_unit_qty,rg_num)>0 AND REGEXP_INSTR(@qty1, vx_unit_qty)>0 THEN  #기존 등록된 용량과 같은 용량이 제품명에 표기 되어 있으면, 
        SET vg_unit_nm = vx_unit;
        SET vg_unit_qty1 = CASE WHEN @qty1 NOT LIKE '%.%.%' THEN CONVERT(vx_unit_qty, DOUBLE) ELSE 0 END;
        SET vz_return = CONCAT(vz_return, vg_unit_qty1, '>>', vg_unit_nm, '>>');  #용량, 단위표기 기등록 정보와 통일 
        SET vz_str = SUBSTR(vz_str, INSTR(vz_str, @qty1)+CHAR_LENGTH(@qty1)); #제품명에서 용량 이후의 문자열 추출  
        SET vg_bundle1 = CASE WHEN regexp_substr(vz_str,rg_num) NOT LIKE '%.%.%' AND regexp_instr(vz_str,rg_num)>0 THEN CONVERT(regexp_substr(vz_str,rg_num), DOUBLE) ELSE 1 END;
        -- 본입수량이 소수점이 있으면 안됨. 이 경우 1로 강제 수정
        SET vg_bundle1 = CASE WHEN MOD(vg_bundle1,1)<>0 THEN 1 
                              WHEN regexp_instr(vz_str,CONCAT(rg_num,rg_bundle))=0 and vg_bundle1>100 THEN 1 
                              ELSE vg_bundle1 END;
        SET vz_return = CONCAT(vz_return, vg_bundle1, '>>');
      ELSE                                                                                          #다른 숫자표기되어 있을 시, 20p를 본입수량으로 등록, 후의 숫자 3은 생략
        SET vg_bundle1 = CASE WHEN regexp_substr(@qty1,rg_num) NOT LIKE '%.%.%' THEN CONVERT(regexp_substr(@qty1,rg_num), DOUBLE) ELSE 0 END;
        -- 본입수량이 소수점이 있으면 안됨. 이 경우 1로 강제 수정
        SET vg_bundle1 = CASE WHEN MOD(vg_bundle1,1)<>0 THEN 1 
                              WHEN regexp_instr(vz_str,CONCAT(rg_num,rg_bundle))=0 and vg_bundle1>100 THEN 1 
                              ELSE vg_bundle1 END;
        SET vz_return = CONCAT(vz_return, vg_unit_qty1, '>>', vg_unit_nm, '>>', vg_bundle1, '>>');
      END IF;
     
    ELSE  #등록되 용량단위 g/ml 아닐 경우 
      ## 명백한 본입 단위를 보유한 케이스는 본입수량으로 등록한다. 
    	IF REGEXP_INSTR (vz_str, CONCAT(rg_num,rg_bundle)) > 0 THEN 
    		SET @vz_bundle = REGEXP_SUBSTR(vz_str, CONCAT(rg_num,rg_bundle));
			SET vg_bundle1 = CASE WHEN regexp_substr(@vz_bundle,rg_num) NOT LIKE '%.%.%' AND regexp_instr(@vz_bundle,rg_num)>0 THEN CONVERT(regexp_substr(@vz_bundle,rg_num), DOUBLE) ELSE 1 END;		
			SET vz_str = REGEXP_REPLACE(vz_str, @vz_bundle, ''); 
			SET vz_unit = REGEXP_SUBSTR(vz_str, rg_code1);
			SET vg_unit_nm = CASE WHEN vz_unit > '' AND vz_unit in('매','m','롤','구') THEN vz_unit
										 WHEN vz_unit > '' THEN '개' 
										 ELSE '' END;
			SET vg_unit_qty1 = CASE WHEN regexp_substr(vz_str,rg_num) NOT LIKE '%.%.%' THEN CONVERT(regexp_substr(vz_str,rg_num), DOUBLE) ELSE 0 END;
     		SET vz_return = CONCAT(vz_return, vg_unit_qty1, '>>', vg_unit_nm, '>>', vg_bundle1, '>>');  										    
		
		## rg unit, rg bundel이 아닌 기타 단위는 용량으로 등록 
		ELSE 
			## 1p, 1입 등 1단위는 본입으로, 1 이상을 용량으로 등록
			SET vg_unit_qty1 = CASE WHEN regexp_substr(@qty1,rg_num) NOT LIKE '%.%.%' and regexp_substr(@qty1,rg_num) != 1 THEN CONVERT(regexp_substr(@qty1,rg_num), DOUBLE) ELSE 0 END;
			SET vg_unit_nm = CASE WHEN vz_unit > '' AND vz_unit in('매','m','롤','구') THEN vz_unit 
										 WHEN vz_unit > '' THEN '개' 
										 ELSE '' END;			
     		SET vz_return = CONCAT(vz_return, vg_unit_qty1, '>>', vg_unit_nm, '>>');  #20p는 용량으로 등록, 뒤의 숫자는 생략 
     	END IF;
   END IF;


  -- CASE7=20P  
  ELSEIF REGEXP_INSTR(vg_goods_nm, CONCAT(rg_num,rg_unit,'[x]',rg_num)) = 0
         AND REGEXP_INSTR(vg_goods_nm, CONCAT(rg_num,rg_unit,rg_num)) = 0
			AND REGEXP_INSTR(vg_goods_nm, CONCAT(rg_num,rg_unit)) = 0
			AND REGEXP_INSTR(vg_goods_nm, CONCAT(rg_num,'[x]',rg_num)) = 0
			AND REGEXP_INSTR(vg_goods_nm, CONCAT(rg_num,rg_code1,'[x]',rg_num)) = 0
			AND REGEXP_INSTR(vg_goods_nm, CONCAT(rg_num,rg_code1,rg_num)) = 0
			AND REGEXP_INSTR(vg_goods_nm, CONCAT(rg_num,rg_code1)) > 0 THEN

    SET @IF_VAL2='7';
    SET vz_str = REGEXP_SUBSTR(vg_goods_nm, CONCAT(rg_num,rg_code1));
    SET vz_unit = REGEXP_SUBSTR(vz_str, rg_code1);
    -- 단위용량 계산
    -- tb_pos_barcode_mst에 용량단위가 g/ml로 등록되어있을 경우, 현 단위용량은 본입수량으로 간주한다.
    IF vx_unit IN ('g','ml') THEN 
      SET vg_unit_nm = ''; SET vg_unit_qty1=0;
      SET vx_unit_qty = REGEXP_SUBSTR(vx_unit_qty,rg_num);
      IF REGEXP_INSTR(vx_unit_qty,rg_num)>0 AND vz_str REGEXP REGEXP_SUBSTR(vx_unit_qty,rg_num) THEN  #기존 등록된 용량과 같은 용량이 제품명에 표기 되어 있으면, 
        SET vg_unit_nm = vx_unit;
        SET vg_unit_qty1 = CASE WHEN vz_str NOT LIKE '%.%.%' THEN CONVERT(vx_unit_qty, DOUBLE) ELSE 0 END;
        SET vz_return = CONCAT(vz_return, vg_unit_qty1, '>>', vg_unit_nm, '>>');  #용량, 단위표기 기등록 정보와 통일 
      ELSE                                           #다른 숫자표기되어 있을 시, 본입수량으로 등록
        SET vg_bundle1 = CASE WHEN regexp_substr(vz_str,rg_num) NOT LIKE '%.%.%' THEN CONVERT(regexp_substr(vz_str,rg_num), DOUBLE) ELSE 0 END;
        -- 본입수량이 소수점이 있으면 안됨. 이 경우 1로 강제 수정
        SET vg_bundle1 = CASE WHEN MOD(vg_bundle1,1)<>0 THEN 1 
                              WHEN vg_bundle1=vg_unit_qty1 AND vg_bundle1>1000 THEN 1 
                              WHEN vg_bundle1>10000 THEN 1 
                              ELSE vg_bundle1 END;
        SET vz_return = CONCAT(vz_return, vg_unit_qty1, '>>', vg_unit_nm, '>>', vg_bundle1, '>>');
      END IF;
      
    ELSE  #등록되 용량단위 g/ml 아닐 경우 
      ## 명백한 본입 단위를 보유한 케이스는 본입수량으로 등록한다. 
    	IF REGEXP_INSTR (vz_str, CONCAT(rg_num,rg_bundle)) > 0 THEN 
			SET vg_bundle1 = CASE WHEN regexp_substr(vz_str,rg_num) NOT LIKE '%.%.%' AND regexp_instr(vz_str,rg_num)>0 THEN CONVERT(regexp_substr(vz_str,rg_num), DOUBLE) ELSE 1 END;		
			SET vg_unit_qty1 = 0;
			SET vg_unit_nm = '';
     		SET vz_return = CONCAT(vz_return, vg_unit_qty1, '>>', vg_unit_nm, '>>', vg_bundle1, '>>');  										    
		
		## rg unit, rg bundel이 아닌 기타 단위는 용량으로 등록 
		ELSE 
			## 1p, 1입 등 1단위는 본입으로, 1 이상을 용량으로 등록
			SET vg_unit_qty1 = CASE WHEN regexp_substr(vz_str,rg_num) NOT LIKE '%.%.%' and regexp_substr(vz_str,rg_num) != 1 THEN CONVERT(regexp_substr(vz_str,rg_num), DOUBLE) ELSE 0 END;
			SET vg_unit_nm = CASE WHEN vz_unit > '' AND vz_unit in('매','m','롤','구') THEN vz_unit 
										 WHEN vz_unit > '' THEN '개' 
										 ELSE '' END;			
     		SET vz_return = CONCAT(vz_return, vg_unit_qty1, '>>', vg_unit_nm, '>>');    	
 				
		END IF;

    END IF;

  ELSE
    SET @IF_VAL2='8';
    SET vz_return = '';
  END IF;

 #RETURN CONCAT(vg_goods_nm,'/@IF_VAL2=',@IF_VAL2,'/vz_str=',vz_str,'/VZ_UNIT=',VZ_UNIT,'/vg_unit_qty1=',vg_unit_qty1,'/vg_unit_nm=',vg_unit_nm,'/vg_bundle1=',vg_bundle1);
 RETURN IFNULL(vz_return,'');
  
END
