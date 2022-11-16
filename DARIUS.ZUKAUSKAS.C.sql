-- 0) Duomenu susikelimas i DB

DROP TABLE IF EXISTS vienas;

CREATE TABLE  vienas
(account_id bigint,
 msisdn bigint,
 activation_date date,
 deletion_date date,
 status varchar(15),
 reason_id varchar(50),
 pos smallint,
 imei_a bigint,
 imei_main bigint,
 device_tac integer,
 device_brand varchar(50),
 device_model varchar(50),
 device_software_os_name varchar(50),
 device_type varchar(50),
 email_address varchar(50)
 );


COPY vienas
FROM 'F:\MySQL\TEST\sandbox_activations.csv' 
DELIMITER ','
CSV Header;

select * from vienas limit 10;
 
-- 1) Query by which you could extract active clients at the 2013-06-19. 

select max(activation_date) from vienas;
/*
kokie paskutiniai duomenys ?
"2014-12-31"
*/
select account_id from vienas
group by account_id;
/*
Total rows: 1000 of 119012
Isvada vienam klientui - vienas irasas
*/

select distinct status , count(vienas.account_id) from vienas
where activation_date <= '2013-06-19' and (deletion_date >'2013-06-19' or deletion_date = '1970-01-01')
group by status;

/*
"ACTIVE"	56151
"DEACTIVATED"	14110
"DELETED"	4317
"DORMANT"	2430
"FROZEN"	135
"PORTEDOUT"	84
"SUSPENDED"	42
"TERMINATED"	4201
*/

--    ATSAKYMAS

select account_id, status, activation_date, deletion_date from vienas
where activation_date <= '2013-06-19' and 
(deletion_date >'2013-06-19' or (deletion_date = '1970-01-01' and status = 'ACTIVE'));

/*
Total rows: 1000 of 74529
Is atsakymo galima pasakyti tik tai kad aktyviu vartotoju nebuvo daugiau 74529,
nes lenteleje saugoma tik paskutinio veiksmo data: deletion_date ir pats veiksmas, 
pries tai galejo buti atlikti kiti veiksmai
jei deletion_date = '1970-01-01' , tai sitas laukas neuzpidytas
ir tada tinka klientai kurie iskart tapo aktyvus
*/

 

/* 2) How many clients were activated and deactivated during June of 2013. Please provide
both numbers as a result of one query. 
*/
-- Ar between vienodai veikia kaip ir MySQL?
select count(account_id) from vienas where activation_date between '2013-06-01' and '2013-07-01';
-- viso irasu: 1607 
select count(account_id) from vienas 
where activation_date >= '2013-06-01' and activation_date < '2013-07-01';
-- viso irasu: 1607, bet! Query complete 00:10:51.882

select account_id, activation_date, deletion_date from vienas
where 
(activation_date between '2013-06-01' and '2013-07-01' and status = 'ACTIVE')
order by deletion_date DESC;

select account_id, activation_date, deletion_date from vienas
where 
(deletion_date between '2013-06-01' and '2013-07-01' and status = 'DEACTIVATED')
order by deletion_date DESC;

select account_id, activation_date, deletion_date, status from vienas
where 
(activation_date between '2013-06-01' and '2013-07-01' and (status = 'ACTIVE' or deletion_date <> '1970-01-01')) 
 or 
(deletion_date between '2013-06-01' and '2013-07-01' and status = 'DEACTIVATED')
order by status desc, deletion_date DESC;

/*
7053680393736	"2013-06-11"	"2014-03-09"	"TERMINATED"
7053896802038	"2013-06-02"	"2014-11-18"	"PORTEDOUT"
7053713763737	"2013-06-27"	"2013-06-27"	"DEACTIVATED"
*/

--    ATSAKYMAS

select 
sum(cast(activation_date between '2013-06-01' and '2013-07-01' and
		 (status = 'ACTIVE' or deletion_date <> '1970-01-01') as integer)) as aktyv,
sum(cast((deletion_date between '2013-06-01' and '2013-07-01' and status = 'DEACTIVATED') as integer)) as deakt
from vienas;
/* 
where 
(activation_date between '2013-06-01' and '2013-07-01' and status = 'ACTIVE') or
(deletion_date between '2013-06-01' and '2013-07-01' and status = 'DEACTIVATED');
*/

/*
3) How many active clients had more than one SIM card on 2013-06-19. Unique client
could be identified by using unique device information (prepaid customers are usually not
identified in the systems). 
*/

select count(imei_a) from vienas;
-- 119012
select count(imei_main) from vienas
where imei_a <> imei_main; -- 0

select imei_a, count(account_id) as kiek from vienas
group by imei_a
order by kiek desc;
/*
1 null	16664
2 0	170
3 355047040343720	57
4 135790246811220	42
5 359568011260190	21
6287 .....			2
6288 ...			1
*/

select imei_a as phone, count(account_id), min(activation_date), max(activation_date),
min(deletion_date), max(deletion_date), min(status), max(status)
from vienas
where (activation_date <= '2013-06-19') and 
(deletion_date >'2013-06-19' or
(deletion_date = '1970-01-01' and status = 'ACTIVE')) and
imei_a is not null and 
imei_a <> 0
group by imei_a
having count(account_id)>1;

--  ATSAKYMAS

select count(phone)
from
(select imei_a as phone
from vienas
where (activation_date <= '2013-06-19') and 
(deletion_date >'2013-06-19' or
(deletion_date = '1970-01-01' and status = 'ACTIVE')) and
imei_a is not null and 
imei_a <> 0
group by imei_a
having count(account_id)>1) as foo;

-- 2851 Query complete 00:02:40.589

/*
 4) Select currently active clients and pick up TOP5 device brands by each phone type.
Please provide the result in one single query. 
*/

select device_type, device_brand, count(imei_a) as kiek
from vienas
where status = 'ACTIVE'
group by device_type, device_brand
order by device_type, kiek desc;

--    ATSAKYMAS

select
    x1.device_type,
    x1.device_brand,
	x1.kiek
from (select device_type, device_brand, count(imei_a) as kiek
	   from vienas
	   where status = 'ACTIVE'
	   group by device_type, device_brand
       order by device_type, kiek desc) as x1
where
    (
    select count(*)
    from (select device_type, device_brand, count(imei_a) as kiek
		  	from vienas
		  	where status = 'ACTIVE'
		  	group by device_type, device_brand
	      	order by device_type, kiek desc) as x2
    	where COALESCE(x2.device_type, 'nul') = COALESCE(x1.device_type, 'nul')
    	and COALESCE(x2.device_brand, 'nul') <= COALESCE(x1.device_brand, 'nul')
          ) <= 5
order by device_type, kiek desc, device_brand;

/*
5) Request is to provide a new column for currently active clients. New column should have
the value of IMEI if the client is the first who used this IMEI (you can check by the client TABLE
activation date). If the client is not the first one, then column value should be 'Multi SIM'. 
*/

ALTER TABLE vienas
ADD act_IMEI varchar(20);

select * from vienas limit 10;

select min(activation_date) as mdate from vienas
 		where imei_a <> 0 and status = 'ACTIVE' group by imei_a;
		
select imei_a as imeia from vienas
 	where imei_a <> 0 and status = 'ACTIVE'
 	group by imei_a;		
		
update vienas
set act_imei =
CASE 
 when vienas.activation_date = (select min(activation_date) as mdate from vienas
 		where imei_a <> 0 and status = 'ACTIVE' group by imei_a) then cast(vienas.imei_a as varchar(20))
 when vienas.activation_date > (select min(activation_date) as mdate from vienas
 		where imei_a <> 0 and status = 'ACTIVE' group by imei_a) then 'Multi SIM'
end
where vienas.imei_a = (select imei_a as imeia from vienas
 	where imei_a <> 0 and status = 'ACTIVE'
 	group by imei_a) 
	and vienas.activation_date >= (select min(activation_date) as mdate from vienas
    where imei_a <> 0 and status = 'ACTIVE' group by imei_a) 
 and status = 'ACTIVE';
 
 -- order by vienas.imei_a, vienas.account_id, vienas.activation_date;



-- ATSAKYUMAS

select vienas.account_id, vienas.imei_a, vienas.activation_date, vienas.act_IMEI,
CASE 
 when vienas.activation_date = x1.mdate then cast(vienas.imei_a as varchar(20))
 when vienas.activation_date > x1.mdate then 'Multi SIM'
end as jis
INTO temp table kuri
from vienas join 
(select min(activation_date) as mdate, imei_a from vienas
 where imei_a <> 0 and status = 'ACTIVE'
 group by imei_a) as x1
on vienas.imei_a = x1.imei_a
where vienas.activation_date >= x1.mdate and status = 'ACTIVE'
order by vienas.imei_a, vienas.account_id, vienas.activation_date;

select * from kuri;

UPDATE vienas 
SET act_imei = kuri.jis
From kuri 
where vienas.account_id = kuri.account_id 
and vienas.imei_a = kuri.imei_a
and vienas.activation_date = kuri.activation_date;


/*
-- 6) Rebuild the table into an IMEI history query where you could track the history of the
reuse of the device. This table/query should have the columns:
-- imei
-- msisdn
-- device_brand
-- device_model
-- imei_eff_dt - the date when msisdn is used with the IMEI
-- imei_end_dt - the date when new other msisdn reused the phone. 
*/

SELECT imei_a as imei, msisdn, device_brand, device_model, activation_date as imei_eff_dt,
      (SELECT activation_date FROM vienas as e3
       WHERE e3.activation_date > vienas.activation_date
	   and e3.imei_a = vienas.imei_a
       ORDER BY activation_date ASC LIMIT 1) as imei_end_dt
FROM vienas 
where 
 vienas.act_imei is not null
order by imei_a, activation_date; 

/*
....
11612009175910	7052330053723	"Apple"	"iPhone 3G"	"2011-09-23"	"2013-03-24"
11612009175910	7053704973737	"Apple"	"iPhone 3G"	"2013-03-24"	
.....ABORT*/



