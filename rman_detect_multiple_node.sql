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




SELECT CASE WHEN
count(DISTINCT a.inst_id)  > 1 THEN 'Multiple'
ELSE 'Ok' END 
FROM 
gv$rman_output a
JOIN (select 'instance='||lower(name)||inst_id as inst_name from gv$database) b
ON a.output LIKE '%'||b.inst_name||'%';




V2
Made the joins stricter to avoid many cartesians
SELECT CASE WHEN
count(DISTINCT a.inst_id)  > 1 THEN 'Multiple'
ELSE 'Ok' END 
FROM 
gv$rman_output a
INNER JOIN (select 'instance='||lower(name)||inst_id as inst_name from gv$database) b
ON a.output LIKE '%'||b.inst_name||'%'
INNER JOIN (select count(*) AS rec_count, session_recid from gv$rman_output 
group by session_recid) c
ON c.session_recid=a.session_recid
WHERE c.rec_count>=15


Verify:This will show the instance backup that was not ran in the local node. 
SELECT 	c.session_recid,b.inst_name,c.rec_count
FROM gv$rman_output a
INNER  JOIN 
	(
	select 'instance='||lower(name)||inst_id AS inst_name FROM gv$database WHERE inst_id NOT IN 
		(
			select instance_number AS inst_id FROM v$instance
		)
	) b
ON a.output LIKE '%'||b.inst_name||'%'
INNER JOIN 
	(
		select count(*) AS rec_count, session_recid FROM gv$rman_output 
		GROUP BY session_recid
	) c
ON c.session_recid=a.session_recid 
WHERE c.rec_count>15



OEM METRIC

select 
	rownum n,
	HOST_NAME,
	TARGET_NAME,
	FULL,
	INCR,
	LEV0,
	LEV1,
	ARCH,
	case 
	when ( not ( nvl(full,1000)<7*24 or nvl(lev0,1000)<7*24 or nvl(incr,1000)<7*24 ) )
	 then 'WARNING no full or lev0 on last 7x24 hours'
	when ( not ( nvl(full,1000)<72 or nvl(lev0,1000)<72 or nvl(lev1,1000)<72 or nvl(incr,1000)<72)  )
	 then 'WARNING no full, incr, lev0 or lev1 on last 72 hours'
	when ( not nvl(arch,1000)<6 )
	 then 'WARNING no backup archive on last 6 hours'
	end INFO
from
(
	select 
	HOST_NAME,
	TARGET_NAME,
	TARGET_GUID,
	max( decode( TYPELEVEL, 'DB FULL', hours, null)                    ) FULL,
	max( decode( TYPELEVEL, 'DB INCR', hours, null)                    ) INCR,
	max( decode( TYPELEVEL, 'DB INCR0', hours, null)                   ) LEV0,
	max( decode( TYPELEVEL, 'DB INCR1', hours, null)                   ) LEV1,
	max( decode( TYPELEVEL, 'ARCHIVELOG', hours, null)                 ) ARCH
	from
	(
		SELECT 
		  T.HOST_NAME,
		  T.TARGET_GUID,
		  upper(T.TARGET_NAME) TARGET_NAME,
		  B.INPUT_TYPE || B.INCREMENTAL_LEVEL TYPELEVEL,
		  ceil((sysdate -  max(END_TIME))*24) hours
		FROM SYSMAN.MGMT$TARGET              T,
			 (select * from SYSMAN.MGMT$DB_BACKUP_HISTORY where status like 'COMPLETED%' )  B
		-- WHERE B.TARGET_GUID (+) = T.TARGET_GUID
		WHERE B.TARGET_GUID = T.TARGET_GUID
		and t.target_type in ('rac_database','oracle_database')
                --and t.HOST_NAME like '%d15pu1dyky2%'
		group by 
		  T.HOST_NAME,
		  T.TARGET_GUID,
		  T.TARGET_NAME,
		  B.INPUT_TYPE || B.INCREMENTAL_LEVEL
	)
	group by HOST_NAME, TARGET_GUID,TARGET_NAME
order by HOST_NAME, TARGET_NAME
)


alter session set nls_date_format='dd/mm/yy hh24:mi:ss';
col input_bytes_display for a20
col output_bytes_display for a20
set lines 399
set pages 500
select start_time,end_time,status,input_type,input_bytes_display,output_bytes_display from V$RMAN_BACKUP_subJOB_DETAILS where 1=1 and start_time > sysdate -1 order by 1;


*/