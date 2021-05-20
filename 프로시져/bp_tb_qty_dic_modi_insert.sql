CREATE DEFINER=`drimmart`@`%` PROCEDURE `bp_tb_qty_dic_modi_insert`(
	IN `I_DATE` VARCHAR(8)
)
LANGUAGE SQL
NOT DETERMINISTIC
CONTAINS SQL
SQL SECURITY DEFINER
COMMENT '용량사전 수정예측 바코드처리'
BEGIN
	DECLARE V_BATCH_ID 		VARCHAR(50) 	DEFAULT 'bp_tb_qty_dic_modi_insert';
	DECLARE V_DSC 				VARCHAR(1000)	DEFAULT 'START';
	DECLARE V_BATCH_STAT 	VARCHAR(1) 		DEFAULT '0';
	DECLARE V_CND1 			VARCHAR(50) 	DEFAULT I_DATE;
	DECLARE V_CND2 			VARCHAR(50) 	DEFAULT '';
	DECLARE V_BATCH_LOG_SEQ INT 				DEFAULT 0;
	DECLARE V_DATE_YMD 		VARCHAR(8) 		DEFAULT '';
	DECLARE V_DATE_PRE_YM 	VARCHAR(6) 		DEFAULT '';
	DECLARE V_DATE_YM 		VARCHAR(6) 		DEFAULT '';
	DECLARE V_DATE_DD 		VARCHAR(2) 		DEFAULT '';	
	DECLARE V_RESULT 			VARCHAR(1) 		DEFAULT '';
   DECLARE rg_code1, rg_code2, rg_except, rg_num,rg_pattern, vz_str, vz_return VARCHAR(500);
	DECLARE ERR INT DEFAULT 0;
	DECLARE ERR_CNT INT DEFAULT 0;
	
	IF I_DATE IS NULL THEN 
		SET V_DATE_YMD = DATE_FORMAT(NOW(), '%Y%m%d');
	ELSE
		SET V_DATE_YMD = I_DATE;
	END IF;
	
	SET V_CND2 = V_DATE_YMD;
	
	/* SELECT MAX BATCH_LOG_SEQ */
	SELECT IFNULL(MAX(batch_log_seq),0)+1 INTO V_BATCH_LOG_SEQ
	  FROM tb_dr_batch_log
	;

	/* INSERT step2_batch_log */
   INSERT INTO tb_dr_batch_log
   (BATCH_LOG_SEQ, BATCH_ID, DSC, BATCH_STAT, CND1, CND2, ST_DTM)
   VALUES
   (V_BATCH_LOG_SEQ, V_BATCH_ID, V_DSC, V_BATCH_STAT, V_CND1, V_CND2, NOW())
   ;

    /*-------------------------------------------------------------------------------------------------------------*/   
  BEGIN		
    DECLARE EXIT  HANDLER FOR SQLEXCEPTION SET ERR = -1;
	 DECLARE CONTINUE HANDLER FOR NOT FOUND SET ERR = 1;   
   /*-------------------------------------------------------------------------------------------------------------*/

		SET @rg_code1='(ML|MI|MML|㎖|KG|㎏|K\\W|M\\W|M$|K$|리터|EA|세트|번들|팩입|카톤|개입|묶음|보루|박스|BOX|[줄개미구곽롤매입팩갑GLP장봉병캔T포])'; # 용량,본입단위:글자중 아무거나    
		SET @rg_unit='(ML|KG|[GL])';       																				# 용량, 본입 단위: 좌측용량 표현 글자중 아무거나 
		SET @rg_code2='([ ]*[x×*+/()_][ ]*)';                                                       	# 기호: x,×,*중 아무거나 
		SET @rg_num='([0-9]+[0-9.]*)';                                                              	# 숫자 1글자 이상 반복 + 숫자or'.' 0회 이상 반복  
		SET @rg_except='(인분|인용|인치|개월|단계|마리|CM|MM|MG|[원호인종T포%년Y겹%W억곡류도세색])';   # 용량과 관계 없는 숫자단위 (ex. 3호, 2인, 15.4%)
		
		
		-- 1. 단위명 없는 수량x수량. 규격표시이거나 단위명이 누락된 경우. 1.8*12
		INSERT IGNORE INTO tb_qty_dic_modi 
		(barcode_no, qty_ptn, goods_nm, unit_qty, unit_nm, pack_qty, regexp_cd, regi_dt)
		SELECT 
		  barcode_no
		, qty_ptn
		, goods_nm
		, unit_qty
		, unit_nm
		, pack_qty
		, '단위명없는 수량x수량' AS regexp_cd
		, DATE_FORMAT(NOW(), '%Y%m%d') AS regi_dt
		FROM tb_qty_dic 
		WHERE regi_dt = V_DATE_YMD
		AND REGEXP_INSTR(qty_ptn, CONCAT(@rg_num,@rg_code2,@rg_num,@rg_code1)) = 0
		AND REGEXP_INSTR(qty_ptn, CONCAT(@rg_num,@rg_code2,@rg_num)) > 0
		AND CONCAT(barcode_no, qty_ptn) NOT IN (SELECT CONCAT(barcode_no, qty_ptn) FROM tb_qty_dic_modi)
		;

		-- 2. 단위용량 또는 총용량이 지나치게 큰 바코드 ==> 1)총용량(=unit_qty*pack_qty) 40,000보다 큰 경우, 2)본입수량이 200 이상인 경우, 3) g/ml아닌 용량이 300 이상인 경우
		INSERT IGNORE INTO tb_qty_dic_modi 
		(barcode_no, qty_ptn, goods_nm, unit_qty, unit_nm, pack_qty, regexp_cd, regi_dt)
		SELECT 
		  barcode_no
		, qty_ptn
		, goods_nm
		, unit_qty
		, unit_nm
		, pack_qty
		, '용량초과' AS regexp_cd
		, DATE_FORMAT(NOW(), '%Y%m%d') AS regi_dt
		FROM tb_qty_dic 
		WHERE regi_dt = V_DATE_YMD
		AND (unit_qty * pack_qty > 40000 OR pack_qty > 200 OR (unit_qty>=300 AND unit_nm NOT IN ('g','ml')))
		AND CONCAT(barcode_no, qty_ptn) NOT IN (SELECT CONCAT(barcode_no, qty_ptn) FROM tb_qty_dic_modi)
		;
		
		-- 3. 수량 사이 (+,X,*) 외 기타문자 ex) 광동) 소문난광천김(5g/3입), 쌍화골드100ml(5+5입), 깨끗한나페퍼민트캡형60+10매(3+1)
		INSERT IGNORE INTO tb_qty_dic_modi 
		(barcode_no, qty_ptn, goods_nm, unit_qty, unit_nm, pack_qty, regexp_cd, regi_dt)
		SELECT 
		  barcode_no
		, qty_ptn
		, goods_nm
		, unit_qty
		, unit_nm
		, pack_qty
		, '수량 사이 기타문자' AS regexp_cd
		, DATE_FORMAT(NOW(), '%Y%m%d') AS regi_dt
		FROM tb_qty_dic 
		WHERE regi_dt = V_DATE_YMD
		AND (REGEXP_INSTR(qty_ptn,CONCAT(@rg_num,@rg_code1,'[ ]*[-_(),.&/~\\[\\]a-wyz가-힣]+[ ]*',@rg_num,@rg_code1))>0
			OR REGEXP_INSTR(qty_ptn,CONCAT(@rg_num,@rg_code1,'[ ]*[-_(),.&/~\\[\\]a-wyz가-힣]+[ ]*',@rg_num,'[ ]*[x×*+][ ]*',@rg_num))>0
			OR REGEXP_INSTR(a.qty_ptn,CONCAT(@rg_num,'[ ]*[x×*+][ ]*',@rg_num,'[ ]*[-_(),.&/~\\[\\]a-wyz가-힣]+[ ]*',@rg_num))>0)
		AND CONCAT(barcode_no, qty_ptn) NOT IN (SELECT CONCAT(barcode_no, qty_ptn) FROM tb_qty_dic_modi)
		;

	/*	-- 2. 숫자 사이의 특수문자(_). 비비고포기김치3_3kg   해태호두마루7000_540ML  : func_goods_qty_temp함수로 수정함. 
		INSERT IGNORE INTO tb_qty_dic_modi 
		(barcode_no, qty_ptn, goods_nm, unit_qty, unit_nm, pack_qty, regexp_cd, regi_dt)
		SELECT 
		  barcode_no
		, qty_ptn
		, goods_nm
		, unit_qty
		, unit_nm
		, pack_qty
		, '숫자사이특수문자' AS regexp_cd
		, DATE_FORMAT(NOW(), '%Y%m%d') AS regi_dt
		FROM tb_qty_dic 
		WHERE regi_dt = V_DATE_YMD
		AND goods_nm regexp CONCAT('[0-9]+[_]+[0-9]+',@rg_unit,'+')
		AND CONCAT(barcode_no, qty_ptn) NOT IN (SELECT CONCAT(barcode_no, qty_ptn) FROM tb_qty_dic_modi)
		;
	*/	
			-- 4. 멀티제품 기획/증정  (광천재래8봉+파래8봉기획, 콜라1.5L + 환타1.5L)
		INSERT IGNORE INTO tb_qty_dic_modi 
		(barcode_no, qty_ptn, goods_nm, unit_qty, unit_nm, pack_qty, regexp_cd, regi_dt)
		SELECT 
		  barcode_no
		, qty_ptn
		, goods_nm
		, unit_qty
		, unit_nm
		, pack_qty
		, '멀티제품량' AS regexp_cd
		, DATE_FORMAT(NOW(), '%Y%m%d') AS regi_dt
		FROM tb_qty_dic 
		WHERE regi_dt = V_DATE_YMD
		AND qty_ptn regexp CONCAT(@rg_num,@rg_code1,'[ ]*[-_(),.&/~\\[\\]]*[x×*+]+[ ]*[가-힣]+',@rg_num)
		AND CONCAT(barcode_no, qty_ptn) NOT IN (SELECT CONCAT(barcode_no, qty_ptn) FROM tb_qty_dic_modi)
		;	

			-- 5. 'X수량' 2개이상   . 광동)한라봉과유자과즙 70ml*15*2
		INSERT IGNORE INTO tb_qty_dic_modi 
		(barcode_no, qty_ptn, goods_nm, unit_qty, unit_nm, pack_qty, regexp_cd, regi_dt)
		SELECT 
		  barcode_no
		, qty_ptn
		, goods_nm
		, unit_qty
		, unit_nm
		, pack_qty
		, '곱하기 2개 이상' AS regexp_cd
		, DATE_FORMAT(NOW(), '%Y%m%d') AS regi_dt
		FROM tb_qty_dic 
		WHERE regi_dt = V_DATE_YMD
		AND REGEXP_INSTR(qty_ptn,'[+]')=0
		AND CHAR_LENGTH(qty_ptn) - CHAR_LENGTH(REGEXP_REPLACE(qty_ptn,'[x×*]',''))>=2
		AND CONCAT(barcode_no, qty_ptn) NOT IN (SELECT CONCAT(barcode_no, qty_ptn) FROM tb_qty_dic_modi)
		;	
		
			-- 6. '+수량' 2개이상   . 깨끗한나라)물티슈60매+10매 3+1
		INSERT IGNORE INTO tb_qty_dic_modi 
		(barcode_no, qty_ptn, goods_nm, unit_qty, unit_nm, pack_qty, regexp_cd, regi_dt)
		SELECT 
		  barcode_no
		, qty_ptn
		, goods_nm
		, unit_qty
		, unit_nm
		, pack_qty
		, '더하기 2개 이상' AS regexp_cd
		, DATE_FORMAT(NOW(), '%Y%m%d') AS regi_dt
		FROM tb_qty_dic 
		WHERE regi_dt = V_DATE_YMD
		AND REGEXP_INSTR(qty_ptn,'[x×*]')=0
		AND CHAR_LENGTH(qty_ptn) - CHAR_LENGTH(REGEXP_REPLACE(qty_ptn,'[+]',''))>=2
		AND CONCAT(barcode_no, qty_ptn) NOT IN (SELECT CONCAT(barcode_no, qty_ptn) FROM tb_qty_dic_modi)
		;			
			
		-- 7. 추가용량&본입.  농심짜왕8멀티-1박스(기획팩) 134g*4+1*8
		INSERT IGNORE INTO tb_qty_dic_modi 
		(barcode_no, qty_ptn, goods_nm, unit_qty, unit_nm, pack_qty, regexp_cd, regi_dt)
		SELECT 
		  barcode_no
		, qty_ptn
		, goods_nm
		, unit_qty
		, unit_nm
		, pack_qty
		, '추가용량&본입' AS regexp_cd
		, DATE_FORMAT(NOW(), '%Y%m%d') AS regi_dt
		FROM tb_qty_dic 
		WHERE regi_dt = V_DATE_YMD
		AND REGEXP_INSTR(qty_ptn,'[x×*]')>0
		AND REGEXP_INSTR(qty_ptn,'[+]')>0
		AND CHAR_LENGTH(qty_ptn) - CHAR_LENGTH(REGEXP_REPLACE(qty_ptn,'[x×*+]',''))>=3
		AND CONCAT(barcode_no, qty_ptn) NOT IN (SELECT CONCAT(barcode_no, qty_ptn) FROM tb_qty_dic_modi)
		;



  END; /* BEGIN */

/*==============================================================================
   분석기준UPDATE
 ==============================================================================*/
    /* SQLEXCEPTION 발생으로 인해 ERR 값이 -1로 SETTING이 되어 ROLLBACK이 수행된다. */
	IF ERR < 0 THEN
		UPDATE tb_dr_batch_log SET
		       BATCH_STAT = '2'
		     , DSC = CONCAT('FAIL[',V_CND2,'=', ERR, ']')
		     , ED_DTM = NOW()
       WHERE BATCH_LOG_SEQ = V_BATCH_LOG_SEQ
		;
	ELSE
		UPDATE tb_dr_batch_log SET
             BATCH_STAT = '1'
           , DSC = CONCAT('OK[',V_CND2,']')
           , ED_DTM = NOW()
       WHERE BATCH_LOG_SEQ = V_BATCH_LOG_SEQ
		;
	END IF;
        
END
