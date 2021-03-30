# 사용자정의함수 통해 추출한 값을 저장할 테이블 Insert 문. Cursor을 사용하여 분할 실행 

DROP PROCEDURE if EXISTS temp_barcode_qtyKeyword_insrert;
DELIMITER $$
CREATE PROCEDURE temp_barcode_qtyKeyword_insrert()
BEGIN
	DECLARE store_num VARCHAR(20)
	DECLARE endOFRow BOOLEAN DEFAULT FALSE;
	
	DECLARE storeCur CURSOR FOR
		SELECT DISTINCT store_id FROM dw_store_barcode_his
	
	DECLARE CONTINUE handler FOR NOT FOUND SET endOfRow = TRUE;
	
	OPEN storeCur;
	
	cursor_loop: LOOP
		FETCH storeCur INTO store_num;
		
		IF endOfRow THEN
			LEAVE cursor_loop;
		END IF;
		
		REPLACE INTO tb_qty_dic (barcode_no, goods_nm, qty_ptn, unit_qty, unit_nm, pack_qty)
		SELECT BARCODE_NO, GOODS_NM, FUNC_GET_QTY_KEYWORD(GOODS_NM) AS qty_ptn, UNIT_QTY, UNIT_NM, PACK_QTY
		from dw_store_barcode_his
		WHERE FUNC_GET_QTY_KEYWORD(GOODS_NM) IS NOT NULL
		AND store_id = store_num
		;
	END LOOP cursor_loop;
	
	CLOSE storeCur;
	
END $$
DELIMITER ;

CALL temp_barcode_qtyKeyword_insrert();
