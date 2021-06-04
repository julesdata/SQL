CREATE DEFINER=`drimmart`@`%` PROCEDURE `temp_barcode_qtykwd_insert`(
	IN `i_from` INT,
	IN `i_to` INT
)
LANGUAGE SQL
NOT DETERMINISTIC
CONTAINS SQL
SQL SECURITY DEFINER
COMMENT ''
BEGIN

    DECLARE done, done1 INT DEFAULT FALSE;
    DECLARE vg_from INT(8) DEFAULT i_from; #20160101
    DECLARE vg_to INT(8) DEFAULT i_to; #20210420
    DECLARE v_date INT(8) DEFAULT 0;
    DECLARE rg_code1, rg_code2, rg_except, rg_num,rg_pattern, vz_str, vz_return VARCHAR(500);
    
    -- 커서로 만들 데이타 값들
    DECLARE cur1 CURSOR FOR
    SELECT DISTINCT regi_date
    FROM (SELECT DISTINCT regi_date FROM HYPOS_STORE_BARCODE
          UNION ALL SELECT DISTINCT regi_date FROM togethers_store_barcode
          UNION ALL SELECT DISTINCT regi_date FROM posmania_store_barcode
          UNION ALL SELECT DISTINCT regi_date FROM posys_store_barcode) T1
	 WHERE  regi_date BETWEEN vg_from AND vg_to
    ORDER BY regi_date;
    
    -- 커서가 마지막에 도착할 때의 상태값
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    -- 커서를 연다.
    OPEN cur1;

    SET rg_code1='(ML|MI|MML|㎖|미리|KG|㎏|K\\W|M\\W|M$|K$|리터|EA|세트|번들|팩입|카톤|개입|묶음|보루|박스|BOX|[줄개미구곽롤매입팩갑GLP장봉병캔T포])';       # 용량, 본입 단위: 좌측용량 표현 글자중 아무거나 
    SET rg_code2='([ ]*[x×*+/()\\-_,.&~\\[\\]][ ]*)';                                                       # 기호: x,×,*중 아무거나
    SET rg_num='([0-9]+[0-9.]*)';                                                              # 숫자 1글자 이상 반복 + 숫자or'.' 0회 이상 반복
    SET rg_except='(인분|인용|인치|개월|단계|마리|CM|MM|MG|세(?!트)|[원호인종%년Y겹%W억곡류도색])';                        # 용량과 관계 없는 숫자단위 (ex. 3호, 2인, 15.4%)
    SET rg_pattern= CONCAT('([(]*',rg_num,'+',rg_except,'*',rg_code1,'*',rg_code2,'*',')+(.*',rg_num,'+',rg_except,'*',rg_code1,'*','[ ]*[x×*+/()\\-_,.&~\\[\\]]*[ ]*)*');   # 숫자,단위,기호패턴 반복
                    
    -- Loop 가 돌아간다.
    read_loop: LOOP
  
    -- 커서로 만드어진 데이타를 돌린다.
    FETCH cur1 INTO v_date;
    
        -- 커서가 마지막 로우면 Loop를 빠져나간다.
        IF done THEN
        	LEAVE read_loop;
        END IF;

        INSERT INTO temp_proc_log (in_str,out_str,regi_dt)
        VALUES (v_date, 'tb_barcode_qtykwd_temp', NOW());

        -- 바코드임시테이블 데이터 삭제
        TRUNCATE TABLE tb_barcode_qtykwd_temp;

        -- 하이포스
        INSERT IGNORE INTO tb_barcode_qtykwd_temp (barcode_no, sales_date, qtykwd_ptn, goods_nm)
		  SELECT barcode AS barcode_no, regi_date AS sales_date, REGEXP_SUBSTR(REGEXP_REPLACE(goods_nm, CONCAT(barcode,'|[\r]'), ''),rg_pattern) qtykwd_ptn, REGEXP_REPLACE(goods_nm, CONCAT(barcode,'|[\r]'), '') AS goods_nm
        FROM   hypos_store_barcode
        WHERE  regi_date = v_date
        AND    barcode REGEXP '^[0-9]+$' 
        AND    LENGTH(TRIM(barcode)) > 5
        AND    REGEXP_INSTR(goods_nm,'[^0-9]+') > 0
        AND    REGEXP_INSTR(goods_nm,'[0-9]+') > 0
		  GROUP BY barcode_no, qtykwd_ptn;

        -- 투게더포스
        INSERT IGNORE INTO tb_barcode_qtykwd_temp (barcode_no, sales_date, qtykwd_ptn, goods_nm)
		  SELECT barcode AS barcode_no, regi_date AS sales_date, REGEXP_SUBSTR(REGEXP_REPLACE(goods_nm, CONCAT(barcode,'|[\r]'), ''),rg_pattern) qtykwd_ptn, REGEXP_REPLACE(goods_nm, CONCAT(barcode,'|[\r]'), '') AS goods_nm
        FROM   togethers_store_barcode
        WHERE  regi_date = v_date
        AND    barcode REGEXP '^[0-9]+$' 
        AND    LENGTH(TRIM(barcode)) > 5
        AND    REGEXP_INSTR(goods_nm,'[^0-9]+') > 0
        AND    REGEXP_INSTR(goods_nm,'[0-9]+') > 0
		  GROUP BY barcode_no, qtykwd_ptn;

        -- 포스매니아
        INSERT IGNORE INTO tb_barcode_qtykwd_temp (barcode_no, sales_date, qtykwd_ptn, goods_nm)
		  SELECT a.barcode AS barcode_no, a.regi_date AS sales_date, REGEXP_SUBSTR(REGEXP_REPLACE(a.goods_nm, CONCAT(a.barcode,'|[\r]'), ''),rg_pattern) qtykwd_ptn, REGEXP_REPLACE(a.goods_nm, CONCAT(a.barcode,'|[\r]'), '') AS goods_nm
        FROM   posmania_store_barcode a, pos_mm_barcode b
        WHERE  a.barcode = b.barcode_no
		  AND    a.regi_date = v_date
        AND    a.barcode REGEXP '^[0-9]+$' 
        AND    LENGTH(TRIM(a.barcode)) > 5
        AND    REGEXP_INSTR(a.goods_nm,'[^0-9]+') > 0
        AND    REGEXP_INSTR(a.goods_nm,'[0-9]+') > 0
        AND    b.max_mm >= 202101
		  GROUP BY barcode_no, qtykwd_ptn;

        -- 포시스
        INSERT IGNORE INTO tb_barcode_qtykwd_temp (barcode_no, sales_date, qtykwd_ptn, goods_nm)
		  SELECT a.barcode AS barcode_no, a.regi_date AS sales_date, REGEXP_SUBSTR(REGEXP_REPLACE(a.goods_nm, CONCAT(a.barcode,'|[\r]'), ''),rg_pattern) qtykwd_ptn, REGEXP_REPLACE(a.goods_nm, CONCAT(a.barcode,'|[\r]'), '') AS goods_nm
        FROM   posys_store_barcode a, pos_mm_barcode b
        WHERE  a.barcode = b.barcode_no
		  AND    a.regi_date = v_date
        AND    a.barcode REGEXP '^[0-9]+$' 
        AND    LENGTH(TRIM(a.barcode)) > 5
        AND    REGEXP_INSTR(a.goods_nm,'[^0-9]+') > 0
        AND    REGEXP_INSTR(a.goods_nm,'[0-9]+') > 0
        AND    b.max_mm >= 202101
		  GROUP BY barcode_no, qtykwd_ptn;
		  
        INSERT INTO temp_proc_log (in_str,out_str,regi_dt)
        VALUES (v_date, 'tb_barcode_qtykwd_temp', NOW());

        -- 최종적으로 용량키워드사전에 키워드와 용량정보를 등록(tb_qty_dic)
        INSERT IGNORE INTO tb_qty_dic (barcode_no, sales_date, goods_nm, qty_ptn, unit_qty, unit_nm, pack_qty, regi_dt)
        SELECT barcode_no
        		 , sales_date
             , goods_nm
             , qtykwd_ptn
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
             , DATE_FORMAT(NOW(), '%Y%m%d')
	     FROM  (SELECT t1.barcode_no, t1.sales_date, t1.goods_nm, t1.qtykwd_ptn, FUNC_GOODS_QTY_temp(t1.goods_nm, t1.barcode_no) AS goods_nm2
	            FROM tb_barcode_qtykwd_temp t1 LEFT OUTER JOIN tb_qty_dic t2 ON t1.barcode_no = t2.barcode_no AND t1.qtykwd_ptn = t2.qty_ptn
	            WHERE t1.qtykwd_ptn > ''
               AND  (t2.barcode_no IS NULL OR t2.qty_ptn IS NULL)
               ) a1
        WHERE  goods_nm2 > '';
         
        INSERT INTO temp_proc_log (in_str,out_str,regi_dt)
        VALUES (v_date, 'tb_qty_dic', NOW());

    END LOOP;

    -- 커서를 닫는다.
    CLOSE cur1;

END
