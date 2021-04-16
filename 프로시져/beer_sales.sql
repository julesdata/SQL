CREATE DEFINER=`drimmart`@`%` PROCEDURE `temp_hanmac_ms_insert`(
	IN `I_FROM` INT,
	IN `I_TO` INT
)
LANGUAGE SQL
NOT DETERMINISTIC
CONTAINS SQL
SQL SECURITY DEFINER
COMMENT ''
BEGIN
	DECLARE done INT DEFAULT FALSE;
	DECLARE vFrom INT DEFAULT I_FROM; #yyyymmdd
	DECLARE vTo INT DEFAULT I_TO; #yyyymmdd
	DECLARE vg_week, vg_from, vg_to INT DEFAULT 0;
	
	DECLARE cur1 CURSOR for
	SELECT sales_wk, MIN(sales_date), MAX(sales_date)
	FROM tb_dt_dic
	WHERE sales_date BETWEEN vFrom AND vTo
	GROUP BY sales_wk
	ORDER BY sales_wk;
	
	DECLARE CONTINUE handler FOR NOT FOUND SET done = TRUE;
	
	TRUNCATE TABLE temp_hanmac_weekly_ms;
	
	OPEN cur1;
	
	read_loop : Loop
	
		FETCH cur1 INTO vg_week, vg_from, vg_to;
		
		IF done THEN
			LEAVE read_loop;
		END IF;
		
		INSERT INTO temp_hanmac_weekly_ms (sales_wk, mng_area1, mng_area2, sales_grd, barcode_no, goods_nm, store_cnt, sales_amt, all_store_cnt, beer_amt_local, beer_amt_import)  
		SELECT *
		FROM (#한맥
			SELECT vg_week, e.mng_area1,e.mng_area2, e.sales_grd, d.barcode_no, d.goods_nm, COUNT(DISTINCT a.drim_store_id) store_cnt, sum(a.sales_amt) sales_amt
			FROM temp_pos_dd_sales a, tb_pos_barcode_mst d
					, (SELECT * from dw_store_mst 
					   WHERE drim_store_id IN(SELECT DISTINCT drim_store_id from dw_store_mm_sum  
						                       WHERE sales_mm BETWEEN 202102 AND 202103
													  AND day_cnt > 20 
													  GROUP BY drim_store_id HAVING COUNT(DISTINCT sales_mm)=2)
						) e #연속거래매장
			WHERE 1=1
			AND a.sales_date BETWEEN vg_from AND vg_to
			AND a.barcode_no = d.barcode_no
			# 한맥 바코드
			AND d. barcode_no IN('8801021105598','8801021105604','8801021105833','8801021105833')
			AND d.valid_yn = 'Y'
			AND d.maker_nm > ''
			AND a.drim_store_id = e.drim_store_id
			AND e.store_type IN ('슈퍼마켓', '편의점')
			AND e.pos_co_cd NOT IN ('POS1607')
			AND e.mng_area1 > ''
			AND e.mng_area2 > ''
			AND e.sales_grd > ''
			GROUP BY e.mng_area1,e.mng_area2, e.sales_grd, d.barcode_no, d.goods_nm
			) x1
		JOIN 
			# 맥주
			(SELECT vg_week, e.mng_area1,e.mng_area2, e.sales_grd,
						COUNT(DISTINCT a.drim_store_id) all_store_cnt,
						sum(case when d.category_nm4 IN ('맥주') then a.sales_amt end) beer_amt_local,
						sum(case when d.category_nm4 IN ('수입맥주') then a.sales_amt end) beer_amt_import
			FROM temp_pos_dd_sales a, tb_pos_barcode_mst d
					, (SELECT * from dw_store_mst 
					   WHERE drim_store_id IN(SELECT DISTINCT drim_store_id from dw_store_mm_sum  
						                       WHERE sales_mm BETWEEN 202102 AND 202103
													  AND day_cnt > 20 
													  GROUP BY drim_store_id HAVING COUNT(DISTINCT sales_mm)=2)
						) e #연속거래매장
			WHERE 1=1
			AND a.sales_date BETWEEN vg_from AND vg_to
			AND a.barcode_no = d.barcode_no
			# 맥주 카테고리
			AND d.category_nm4 IN('맥주', '수입맥주')
			AND d.valid_yn = 'Y'
			AND d.maker_nm > ''
			AND a.drim_store_id = e.drim_store_id
			AND e.store_type IN ('슈퍼마켓', '편의점')
			AND e.pos_co_cd NOT IN ('POS1607')
			AND e.mng_area1 > ''
			AND e.mng_area2 > ''
			AND e.sales_grd > ''
			GROUP BY e.mng_area1,e.mng_area2, e.sales_grd
			) x2
		USING (vg_week, mng_area1, mng_area2, sales_grd);
		
	END LOOP;
	
	CLOSE cur1;
	
END

