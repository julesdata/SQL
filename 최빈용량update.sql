	TRUNCATE TABLE dw_store_barcode_his_temp; 
	
	INSERT INTO dw_store_barcode_his_temp 
	( barcode_no
	, goods_nm
	, qty
	, store_cnt
	, goods_len
	)
	SELECT 
	  barcode_no
	, goods_nm
	, CONCAT(unit_qty, unit_nm, '*', pack_qty) QTY, COUNT(DISTINCT store_id) store_cnt, LENGTH(REPLACE(goods_nm,' ','')) goods_len
	FROM dw_store_barcode_his_test 
	WHERE unit_qty > 0 
	AND barcode_no IN (SELECT DISTINCT barcode_no FROM tb_qty_dic_modi WHERE result_yn = 'Y')
   AND regi_date >= DATE_FORMAT(DATE_ADD('20210609', INTERVAL -90 DAY), '%Y%m%d')
	GROUP BY barcode_no, CONCAT(unit_qty, unit_nm, '*', pack_qty)
	;
	
	;

  -- 보관구분 임시테이블에 저장(2021.3.18 수정) 
	TRUNCATE TABLE dw_store_barcode_his_temp_rtype;

	INSERT INTO dw_store_barcode_his_temp_rtype
	( barcode_no
	, r_type
	, r_cnt
	)
  SELECT *
  FROM (SELECT barcode_no
           	 , CASE WHEN goods_nm REGEXP '냉장' AND goods_nm NOT REGEXP '냉장고' THEN '냉장'
                    WHEN goods_nm REGEXP '냉동' THEN '냉동'
                    WHEN goods_nm REGEXP '(상온|실온)' THEN '실온' END r_type
           	 , COUNT(*) r_cnt
        FROM dw_store_barcode_his_test
	     where barcode_no IN (SELECT DISTINCT barcode_no FROM tb_qty_dic_modi WHERE result_yn = 'Y')
	     AND regi_date >= DATE_FORMAT(DATE_ADD('20210609', INTERVAL -90 DAY), '%Y%m%d')
        GROUP BY barcode_no
             , CASE WHEN goods_nm REGEXP '냉장' AND goods_nm NOT REGEXP '냉장고' THEN '냉장'
                    WHEN goods_nm REGEXP '냉동' THEN '냉동'
                    WHEN goods_nm REGEXP '(상온|실온)' THEN '실온' END) a
	WHERE r_type IS NOT NULL
	;
	
	-- STEP 3
	-- 제일 많이 사용하는 용량정보와 제품명, 냉장/냉동여부 UPDATE
	REPLACE INTO dw_store_barcode_uniq_test  # dw_store_barcode_uniq => dw_store_barcode_uniq_test
	( barcode_no
	, goods_nm
	, r_type
	, unit_qty
	, unit_nm
	, pack_qty
	, store_cnt
	)
	SELECT 
	  T11.barcode_no
	, T11.goods_nm
	, IFNULL(r_type,'') r_type
	, REGEXP_SUBSTR(SUBSTRING_INDEX(QTY,'*',1),'[0-9]+[0-9.]*') unit_qty
	, REGEXP_SUBSTR(SUBSTRING_INDEX(QTY,'*',1),'(ML|KG|EA|세트|팩입|카톤|개입|[개구곽롤매입팩GLP장])') unit_nm # 단위명  확인 필요 
	, SUBSTRING_INDEX(QTY,'*',-1) pack_qty
	, max_cnt AS store_cnt
	FROM (SELECT 
	        t1.barcode_no
			, T1.QTY
			, goods_nm
			, max_cnt
	      FROM -- MAX_STORE_CNT인 용량  
	           (SELECT 
				     a1.barcode_no
				   , MIN(A1.QTY) QTY
					, max_cnt
	            FROM dw_store_barcode_his_temp A1
					   , (SELECT barcode_no, MAX(store_cnt) max_cnt 
	                  FROM dw_store_barcode_his_temp 
							GROUP BY barcode_no
						  ) A2 
	   			WHERE A1.BARCODE_NO=A2.BARCODE_NO 
					AND A1.STORE_CNT=A2.MAX_CNT
	   			GROUP BY A1.BARCODE_NO) t1
	         -- max_length인 제품명 
	         , (SELECT 
				     a1.barcode_no
				   , A1.QTY
					, MAX(a1.goods_nm) goods_nm
	            FROM dw_store_barcode_his_temp A1
					   , (SELECT barcode_no, QTY, MAX(goods_len) max_len
	                  FROM   dw_store_barcode_his_temp 
	                  GROUP BY barcode_no, QTY
						  ) A2 
	            WHERE A1.BARCODE_NO=A2.BARCODE_NO 
			      AND A1.QTY=A2.QTY 
			      AND A1.goods_len=A2.max_len
			      GROUP BY a1.barcode_no, a1.QTY
		        ) t2
	      WHERE t1.barcode_no=t2.barcode_no 
	      AND t1.QTY=T2.QTY) T11
	      LEFT OUTER JOIN
	         -- 냉장/냉동/실온 여부 
	      (SELECT 
      	     a1.barcode_no
			   , MAX(a1.r_type) r_type
	       FROM dw_store_barcode_his_temp_rtype A1
			   , (SELECT barcode_no, MAX(r_cnt) max_cnt
	            FROM   dw_store_barcode_his_temp_rtype 
	            GROUP BY barcode_no
				   ) A2 
	       WHERE A1.BARCODE_NO=A2.BARCODE_NO 
			 AND A1.r_cnt=A2.max_cnt
			 GROUP BY a1.barcode_no
		    ) T12 ON T11.barcode_no=T12.barcode_no
	;
