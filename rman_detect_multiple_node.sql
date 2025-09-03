SET SERVEROUTPUT ON

DECLARE

TYPE instance_name IS VARRAY(3) OF VARCHAR2(15); -- Instance names of rac
g_instance_name_list instance_name := instance_name();
tmp_counter INTEGER := 1;

BEGIN

FOR i IN (select instance_name from gv$instance) LOOP
	g_instance_name_list.Extend;
	g_instance_name_list(tmp_counter) := i.instance_name;
	tmp_counter := tmp_counter + 1;
END LOOP;

/*
FOR j IN 1..g_instance_name_list.COUNT LOOP
	dbms_output.put_line('Instance name '||j||':'||g_instance_name_list(j));
END LOOP;
*/


END;

/*
Script for detecting multiple rman backups on rac LEVEL

Simple Check: This will only check any channel ran on other node
Will get the data from v$rman_output, parsing the channel. 

SELECT CASE WHEN
count(DISTINCT a.inst_id)  > 1 THEN 'Multiple'
ELSE 'Ok' END 
FROM 
gv$rman_output a
JOIN (select lower(name)||inst_id as inst_name from gv$database) b
ON a.output LIKE '%'||b.inst_name||'%';


*/