CREATE DEFINER=`drimmart`@`%` PROCEDURE `temp_barcode_qtykwd_insert`()
LANGUAGE SQL
NOT DETERMINISTIC
CONTAINS SQL
SQL SECURITY DEFINER
COMMENT ''
BEGIN

    DECLARE done, done1 INT DEFAULT FALSE;
    DECLARE vg_from INT(8) DEFAULT 20210301;
    DECLARE vg_to INT(8) DEFAULT 20210401;
    DECLARE v_date INT(8) DEFAULT 0;
    
    -- 커서로 만들 데이타 값들
    DECLARE cur1 CURSOR FOR
    SELECT a.sales_date
    FROM   tb_dt_dic a
    WHERE  a.sales_date BETWEEN vg_from AND vg_to 
    ORDER BY a.sales_date;
    
    -- 커서가 마지막에 도착할 때의 상태값
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    -- 커서를 연다.
    OPEN cur1;
    
    -- Loop 가 돌아간다.
    read_loop: LOOP
  
    -- 커서로 만드어진 데이타를 돌린다.
    FETCH cur1 INTO v_date;
    
        -- 커서가 마지막 로우면 Loop를 빠져나간다.
        IF done THEN
        	LEAVE read_loop;
        END IF;

        -- 바코드임시테이블 데이터 삭제
        TRUNCATE TABLE tb_barcode_qtykwd_temp;

        -- 하이포스
        INSERT IGNORE INTO tb_barcode_qtykwd_temp (barcode_no, qtykwd_ptn, goods_nm)
        SELECT t1.barcode_no, t1.qtykwd_ptn, MAX(t1.goods_nm)
        FROM  (SELECT barcode AS barcode_no, goods_nm, FUNC_GET_QTY_KEYWORD(goods_nm) qtykwd_ptn
               FROM  (SELECT DISTINCT barcode, REPLACE(goods_nm, barcode, '') AS goods_nm
                      FROM   hypos_store_barcode
                      WHERE  regi_date = v_date
                      AND    barcode REGEXP '^[0-9]+$' 
                      AND    LENGTH(TRIM(barcode)) > 5
                      ) a1
               ) t1 LEFT OUTER JOIN tb_qty_dic t2 ON t1.barcode_no = t2.barcode_no AND t1.qtykwd_ptn = t2.qty_ptn  
        WHERE t1.qtykwd_ptn > ''
		  AND  (t2.barcode_no IS NULL OR t2.qty_ptn IS NULL)  # tb_qty_dic에 미등록된 바코드별 패턴만  
		  GROUP BY t1.barcode_no, t1.qtykwd_ptn;

        -- 투게더포스
        INSERT IGNORE INTO tb_barcode_qtykwd_temp (barcode_no, qtykwd_ptn, goods_nm)
        SELECT t1.barcode_no, t1.qtykwd_ptn, MAX(t1.goods_nm)
        FROM  (SELECT barcode AS barcode_no, goods_nm, FUNC_GET_QTY_KEYWORD(goods_nm) qtykwd_ptn
               FROM  (SELECT DISTINCT barcode, REPLACE(goods_nm, barcode, '') AS goods_nm
                      FROM   togethers_store_barcode
                      WHERE  regi_date = v_date
                      AND    barcode REGEXP '^[0-9]+$' 
                      AND    LENGTH(TRIM(barcode)) > 5
                      ) a1
               ) t1 LEFT OUTER JOIN tb_qty_dic t2 ON t1.barcode_no = t2.barcode_no AND t1.qtykwd_ptn = t2.qty_ptn
        WHERE t1.qtykwd_ptn > ''
		  AND  (t2.barcode_no IS NULL OR t2.qty_ptn IS NULL)
		  GROUP BY t1.barcode_no, t1.qtykwd_ptn;

        -- 포스매니아
        INSERT IGNORE INTO tb_barcode_qtykwd_temp (barcode_no, qtykwd_ptn, goods_nm)
        SELECT t1.barcode_no, t1.qtykwd_ptn, MAX(t1.goods_nm)
        FROM  (SELECT barcode AS barcode_no, goods_nm, FUNC_GET_QTY_KEYWORD(goods_nm) qtykwd_ptn
               FROM  (SELECT DISTINCT barcode, REPLACE(goods_nm, barcode, '') AS goods_nm
                      FROM   posmania_store_barcode
                      WHERE  regi_date = v_date
                      AND    barcode REGEXP '^[0-9]+$' 
                      AND    LENGTH(TRIM(barcode)) > 5
                      ) a1
               ) t1 LEFT OUTER JOIN tb_qty_dic t2 ON t1.barcode_no = t2.barcode_no AND t1.qtykwd_ptn = t2.qty_ptn
        WHERE t1.qtykwd_ptn > ''
		  AND  (t2.barcode_no IS NULL OR t2.qty_ptn IS NULL)
		  GROUP BY t1.barcode_no, t1.qtykwd_ptn;

        -- 포시스
        INSERT IGNORE INTO tb_barcode_qtykwd_temp (barcode_no, qtykwd_ptn, goods_nm)
        SELECT t1.barcode_no, t1.qtykwd_ptn, MAX(t1.goods_nm)
        FROM  (SELECT barcode AS barcode_no, goods_nm, FUNC_GET_QTY_KEYWORD(goods_nm) qtykwd_ptn
               FROM  (SELECT DISTINCT barcode, REPLACE(goods_nm, barcode, '') AS goods_nm
                      FROM   posys_store_barcode
                      WHERE  regi_date = v_date
                      AND    barcode REGEXP '^[0-9]+$' 
                      AND    LENGTH(TRIM(barcode)) > 5
                      ) a1
               ) t1 LEFT OUTER JOIN tb_qty_dic t2 ON t1.barcode_no = t2.barcode_no AND t1.qtykwd_ptn = t2.qty_ptn
        WHERE t1.qtykwd_ptn > ''
		  AND  (t2.barcode_no IS NULL OR t2.qty_ptn IS NULL)
		  GROUP BY t1.barcode_no, t1.qtykwd_ptn;

        -- 최종적으로 용량키워드사전에 키워드와 용량정보를 등록(tb_qty_dic)
        INSERT IGNORE INTO tb_qty_dic (barcode_no, goods_nm, qty_ptn, unit_qty, unit_nm, pack_qty)
        SELECT barcode_no
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
	     FROM  (SELECT barcode_no, goods_nm, qtykwd_ptn, FUNC_GOODS_QTY_temp(qtykwd_ptn, barcode_no) AS goods_nm2
	            FROM tb_barcode_qtykwd_temp
               ) a1
        WHERE  goods_nm2 > '';

         
    END LOOP;

    -- 커서를 닫는다.
    CLOSE cur1;

END
