# 1. insert-subquery(join)- on duplicated key update

INSERT INTO tb_qty_dic_modi (barcode_no, qty_ptn, unit_qty, pack_qty)
SELECT barcode_no, qty_ptn, unit_qty2, pack_qty2
FROM (
        SELECT a.*, b.unit_qty unit_qty2, b.pack_qty pack_qty2
        FROM tb_qty_dic_modi a, tb_qty_dic b
        WHERE 1=1
        AND a.barcode_no = b.barcode_no
        AND a.qty_ptn = b.qty_ptn
        AND (a.unit_qty != b.unit_qty OR a.pack_qty != b.pack_qty)
) t
ON DUPLICATE KEY UPDATE unit_qty=t.unit_qty2, pack_qty=t.pack_qty2;


# update - join - set   ## my sql

UPDATE tb_qty_dic_modi a 
INNER JOIN tb_qty_dic b
ON a.barcode_no = b.barcode_no AND a.qty_ptn = b.qty_ptn
SET a.unit_qty = b.unit_qty, a.pack_qty = b.pack_qty 
WHERE (a.unit_qty != b.unit_qty OR a.pack_qty != b.pack_qty)


# 3. update -set - subquery(join) -- oracle
UPDATE tb_qty_dic_modi SET unit_qty, pack_qty = (SELECT b.unit_qty, b.pack_qty 
                                                FROM tb_qty_dic_modi a, tb_qty_dic b
                                                WHERE 1=1
                                                AND a.barcode_no = b.barcode_no
                                                AND a.qty_ptn = b.qty_ptn
                                                AND (a.unit_qty != b.unit_qty OR a.pack_qty != b.pack_qty))

