CREATE  FUNCTION `FUNC_GET_QTY_KEYWORD`(
	`I_GOODS_NM` VARCHAR(500)
)
RETURNS varchar(500) 

BEGIN

  DECLARE vg_goods_nm VARCHAR(500) DEFAULT I_GOODS_NM;
  DECLARE vz_num, vz_psn INT DEFAULT 0;
  DECLARE rg_code1, rg_code2, rg_exept, rg_num,rg_pattern, vz_str, vz_return VARCHAR(500);

  -- 리턴값 변수 초기화
	SET vz_return='';

  -- regexp 문자열표현식 생성 
  SET rg_code1='(ML|KG|㎏|EA|세트|번들|팩입|리터|카톤|개입|[개구곽롤매입팩MKGLP장봉])';       # 용량, 본입 단위: 좌측용량 표현 글자중 아무거나 
  SET rg_code2='([ ]*[x×*+/()_][ ]*)';                                                       # 기호: x,×,*중 아무거나
  SET rg_num='([0-9]+[0-9.]*)';                                                              # 숫자 1글자 이상 반복 + 숫자or'.' 0회 이상 반복
  SET rg_exept='(인분|인용|개월|단계|마리|CM|[호인종T포%년겹%W억곡])*';                        # 용량과 관계 없는 숫자단위 (ex. 3호, 2인, 15.4%)
  SET rg_pattern= CONCAT('([(]*',rg_num,'+',rg_exept, rg_code1,'*',rg_code2,'*',')+');   # 숫자,단위,기호패턴 반복
  

  -- 용량표시로 추정되는 문자열 추출 (용량 단위나 본입 기호(*,x,+) 없이 숫자만 있는 경우 제외 (ex 콜라 500, 세트 2호 ) 
  get_qty_word_loop: 
  while REGEXP_INSTR(vg_goods_nm, rg_num) > 0 Do
  	# 패턴 추출 
  	SET vz_str='';
	SET vz_str = REGEXP_SUBSTR(vg_goods_nm, concat(rg_pattern));
	
	IF VZ_RETURN = '' then
		SET VZ_RETURN = vz_str;
		ELSE SET VZ_RETURN = CONCAT(VZ_RETURN,' ', vz_str); -- 추출한 패턴을 계속 이어붙혀라
	END if;
		 	
	IF vz_num > 5 THEN
		LEAVE get_qty_word_loop;
	END IF;
	SET vz_num = vz_num + 1;
	    	
	#제품명을 추출한 패턴 이후의 문자열로 대체 
	SET vz_psn=0; SET vz_psn=REGEXP_INSTR(vg_goods_nm, concat(rg_pattern));
	SET VG_GOODS_NM = SUBSTR(VG_GOODS_NM, vz_psn+CHAR_LENGTH(vz_str));
		
  END WHILE get_qty_word_loop;
					
  RETURN vz_return;

  
END
