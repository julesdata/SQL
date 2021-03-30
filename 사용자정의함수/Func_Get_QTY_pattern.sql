# 바코드에서 추출한 상품명 정보에서 , 용량/본입 단위를 나타내는 표현을 모두 추출하는 사용자 정의 함수 생성 

BEGIN

  DECLARE vg_goods_nm VARCHAR(500) DEFAULT I_GOODS_NM;
  DECLARE vz_num INT DEFAULT 0;
  DECLARE rg_code1, rg_code2, rg_code3, rg_num,rg_pattern, vz_str, vz_return VARCHAR(500);

  -- 리턴값 변수 초기화
   SET vz_return='';

  -- regexp 문자열표현식 생성 
  SET rg_code1='(ML|KG|EA|세트|팩입|리터|카톤|개입|[개구곽롤매입팩MGLP장봉])'; #좌측용량 표현 글자중 아무거나 
  SET rg_code2='([ ]*[x×*+][ ]*)';                                                  # x,×,*중 아무거나
  SET rg_num='([0-9]+[0-9.]*)';                                        # 숫자 1글자 이상 반복 + 숫자or'.' 0회 이상 반복
  SET rg_pattern= CONCAT('(',rg_num,'*',rg_code1,'*',rg_code2,'*',')*'); # 숫자,단위,기호패턴 반복
  
	
  
  SET @STR='';
  SET @pt_num='0';
  -- 용량표시로 추정되는 문자열 추출 (용량 단위나 본입 기호(*,x,+) 없이 숫자만 있는 경우 제외 (ex 콜라 500, 세트 2호 ) 
  get_qty_word_loop: 
  while REGEXP_INSTR(vg_goods_nm, rg_num) > 0 Do
  	# 패턴 1: 숫자+단위~ 인 패턴 (ex: 100ml, 100ml 3입, 100ml*3,100ml*3+50ml, 100g 2+1입 등 ) 
	get_pattern_loop1:
	while REGEXP_INSTR(vg_goods_nm, concat(rg_num,rg_code1)) > 0 DO
		#패턴 앞에 다른 패턴(숫자+기호)이 없는지 화인 
		SET @PSN = 0; SET @PSN = REGEXP_INSTR(vg_goods_nm, concat(rg_num,rg_code1)); 
	  	IF regexp_instr(LEFT(vg_goods_nm, @PSN-1),CONCAT(rg_num,rg_code2))>0 THEN 
			Leave get_pattern_loop1;   
			END IF; 
			
		# 패턴 추출 
		SET @STR = REGEXP_SUBSTR(vg_goods_nm, concat(rg_num,rg_code1,rg_pattern));
		SET VZ_RETURN = CONCAT(VZ_RETURN,' ', @STR); -- 추출한 패턴을 계속 이어붙혀라
		 	
		SET vz_num='0';
		IF vz_num > 5 THEN
	      		LEAVE get_pattern_loop1;
	    	END IF;
	    	SET vz_num = vz_num + 1;
	    	
	    	#제품명을 추출한 패턴 이후의 문자열로 대체 
		SET VG_GOODS_NM = SUBSTR(VG_GOODS_NM, @PSN+CHAR_LENGTH(@STR));
		
		END WHILE get_pattern_loop1;
		
		
	# 패턴 2: 숫자+기호+숫자~ 인 패턴 (ex: 2+1, 100+100ml, 100*3입,100*3+50ml 등 ) 
	get_pattern_loop2:
	while REGEXP_INSTR(vg_goods_nm, concat(rg_num,rg_code2,rg_num)) > 0 Do 
		#패턴 앞에 다른 패턴(숫자+단위)이 없는지 화인
		SET @PSN = 0; SET @PSN = REGEXP_INSTR(vg_goods_nm, concat(rg_num,rg_code2,rg_num)); 
	  	IF regexp_instr(LEFT(vg_goods_nm, @PSN-1),CONCAT(rg_num,rg_code1))>0 THEN 
			Leave get_pattern_loop2;   
			END IF;
			 
		SET @STR = REGEXP_SUBSTR(vg_goods_nm, concat(rg_num,rg_code2,rg_num,rg_pattern));
		SET VZ_RETURN = CONCAT(VZ_RETURN,' ', @STR); -- 추출한 숫자들을 계속 이어붙혀라
		 	
		SET vz_num='0';
		IF vz_num > 5 THEN
	      		LEAVE get_pattern_loop2;
	    	END IF;
	    	SET vz_num = vz_num + 1;
	    	
	    	SET VG_GOODS_NM = SUBSTR(VG_GOODS_NM, @PSN+CHAR_LENGTH(@STR));
		
	END WHILE get_pattern_loop2;
								      
  	IF @pt_num > 5 THEN
  		LEAVE get_qty_word_loop;
  	END IF;
  	SET @pt_num = @pt_num + 1;
		
  END WHILE get_qty_word_loop;		
	
  RETURN vz_return;
  
END
