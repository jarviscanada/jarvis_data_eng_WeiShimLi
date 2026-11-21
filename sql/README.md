# Introduction

#### SQL Query Practice

My solutions to the [PostgreSQL Exercises](https://pgexercises.com/) questions, run against the `clubdata` sample database (a country club with members, facilities and bookings).

## Table of Contents

- [Setup](#setup)
- [Table Setup (DDL)](#table-setup-ddl)
- [Solutions](#solutions)
    - [Modifying Data](#modifying-data)
    - [Basics](#basics)
    - [Join](#join)
    - [Aggregation](#aggregation)
    - [String](#string)

## Setup

Start a PostgreSQL instance with Docker:

```bash
docker run --name sql-practice \
  -e POSTGRES_PASSWORD=password \
  -p 5432:5432 \
  -d postgres
```

Load the sample data:

```bash
psql -h localhost -U postgres -f clubdata.sql -d postgres -x -q
```

Then connect with `psql` or a SQL IDE such as [DBeaver](https://dbeaver.io/download/) or [pgAdmin](https://www.pgadmin.org/download/).

## Table Setup (DDL)

```sql
CREATE SCHEMA IF NOT EXISTS cd;

CREATE TABLE cd.members (
    memid         INTEGER      NOT NULL,
    surname       VARCHAR(200) NOT NULL,
    firstname     VARCHAR(200) NOT NULL,
    address       VARCHAR(300) NOT NULL,
    zipcode       INTEGER      NOT NULL,
    telephone     VARCHAR(20)  NOT NULL,
    recommendedby INTEGER,
    joindate      TIMESTAMP    NOT NULL,
    CONSTRAINT members_pk PRIMARY KEY (memid),
    CONSTRAINT fk_members_recommendedby FOREIGN KEY (recommendedby)
        REFERENCES cd.members (memid) ON DELETE SET NULL
);

CREATE TABLE cd.facilities (
    facid              INTEGER      NOT NULL,
    name               VARCHAR(100) NOT NULL,
    membercost         NUMERIC      NOT NULL,
    guestcost          NUMERIC      NOT NULL,
    initialoutlay      NUMERIC      NOT NULL,
    monthlymaintenance NUMERIC      NOT NULL,
    CONSTRAINT facilities_pk PRIMARY KEY (facid)
);

CREATE TABLE cd.bookings (
    bookid    INTEGER   NOT NULL,
    facid     INTEGER   NOT NULL,
    memid     INTEGER   NOT NULL,
    starttime TIMESTAMP NOT NULL,
    slots     INTEGER   NOT NULL,
    CONSTRAINT bookings_pk PRIMARY KEY (bookid),
    CONSTRAINT fk_bookings_facid FOREIGN KEY (facid) REFERENCES cd.facilities (facid),
    CONSTRAINT fk_bookings_memid FOREIGN KEY (memid) REFERENCES cd.members (memid)
);
```

## Solutions

All queries are also stored in [`queries.sql`](./queries.sql).

## Modifying Data

### [insert](https://pgexercises.com/questions/updates/insert.html)
```sql
insert into cd.facilities
    (facid, name, membercost, guestcost, initialoutlay, monthlymaintenance)
    values (9, 'Spa', 20, 30, 100000, 800);
```

### [insert3](https://pgexercises.com/questions/updates/insert3.html) — select in insert
```sql
insert into cd.facilities
    (facid, name, membercost, guestcost, initialoutlay, monthlymaintenance)
    select (select max(facid) from cd.facilities)+1, 'Spa', 20, 30, 100000, 800;   
```

### [update](https://pgexercises.com/questions/updates/update.html)
```sql
UPDATE cd.facilities
SET initialoutlay = 10000
WHERE facid = 1;
```

### [updatecalculated](https://pgexercises.com/questions/updates/updatecalculated.html) — update with calculation
```sql
UPDATE cd.facilities
SET membercost = (SELECT membercost FROM cd.facilities WHERE facid = 0) * 1.1,
    guestcost  = (SELECT guestcost  FROM cd.facilities WHERE facid = 0) * 1.1
WHERE facid = 1;
```

### [delete](https://pgexercises.com/questions/updates/delete.html) — delete all
```sql
DELETE FROM cd.bookings;
```

### [deletewh](https://pgexercises.com/questions/updates/deletewh.html) — delete with condition
```sql
DELETE FROM cd.members
WHERE memid = 37;
```

## Basics

### [where2](https://pgexercises.com/questions/basic/where2.html)
```sql
SELECT facid, name, membercost, monthlymaintenance
FROM cd.facilities
WHERE membercost < (monthlymaintenance / 50.0)
  AND membercost > 0;
```

### [where3](https://pgexercises.com/questions/basic/where3.html)
```sql
SELECT *
FROM cd.facilities
WHERE name LIKE '%Tennis%';
```

### [where4](https://pgexercises.com/questions/basic/where4.html)
```sql
SELECT *
FROM cd.facilities
WHERE facid IN (1, 5);
```

### [date](https://pgexercises.com/questions/basic/date.html)
```sql
SELECT memid, surname, firstname, joindate
FROM cd.members
WHERE joindate > '2012-09-01 00:00:00';
```

### [union](https://pgexercises.com/questions/basic/union.html)
```sql
select surname 
	from cd.members
union
select name
	from cd.facilities;    
```

## Join

### [simplejoin](https://pgexercises.com/questions/joins/simplejoin.html)
```sql
SELECT starttime
FROM cd.bookings AS bookings
INNER JOIN cd.members AS mem ON bookings.memid = mem.memid
WHERE mem.firstname = 'David'
  AND mem.surname = 'Farrell';
```

### [simplejoin2](https://pgexercises.com/questions/joins/simplejoin2.html)
```sql
SELECT b.starttime AS start, f.name
FROM cd.facilities AS f
INNER JOIN cd.bookings AS b ON f.facid = b.facid
WHERE f.name LIKE '%Tennis Court%'
  AND b.starttime > '2012-09-21 00:00:00'
  AND b.starttime < '2012-09-22 00:00:00'
ORDER BY b.starttime;
```

### [self2](https://pgexercises.com/questions/joins/self2.html)
```sql
SELECT mem1.firstname AS memfname,
       mem1.surname   AS memsname,
       mem2.firstname AS recfname,
       mem2.surname   AS recsname
FROM cd.members AS mem1
LEFT OUTER JOIN cd.members AS mem2 ON mem2.memid = mem1.recommendedby
ORDER BY memsname, memfname;
```

### [self](https://pgexercises.com/questions/joins/self.html)
```sql
SELECT DISTINCT mem2.firstname AS firstname, mem2.surname AS surname
FROM cd.members AS mem1
INNER JOIN cd.members AS mem2 ON mem2.memid = mem1.recommendedby
ORDER BY mem2.surname, mem2.firstname;
```

### [sub](https://pgexercises.com/questions/joins/sub.html) — subquery and join
```sql
SELECT DISTINCT mems.firstname || ' ' || mems.surname AS member,
       (SELECT recs.firstname || ' ' || recs.surname AS recommender
        FROM cd.members recs
        WHERE recs.memid = mems.recommendedby)
FROM cd.members mems
ORDER BY member;
```

## Aggregation

### [count3](https://pgexercises.com/questions/aggregates/count3.html)
```sql
SELECT recommendedby, COUNT(recommendedby)
FROM cd.members
WHERE recommendedby IS NOT NULL
GROUP BY recommendedby
ORDER BY recommendedby;
```

### [fachours](https://pgexercises.com/questions/aggregates/fachours.html)
```sql
SELECT facid, SUM(slots) AS "Total Slots"
FROM cd.bookings
GROUP BY facid
ORDER BY facid;
```

### [fachoursbymonth](https://pgexercises.com/questions/aggregates/fachoursbymonth.html)
```sql
SELECT facid, SUM(slots) AS "Total Slots"
FROM cd.bookings
WHERE starttime > '2012-09-01 00:00:00'
  AND starttime < '2012-10-01 00:00:00'
GROUP BY facid
ORDER BY "Total Slots";
```

### [fachoursbymonth2](https://pgexercises.com/questions/aggregates/fachoursbymonth2.html)
```sql
SELECT facid, EXTRACT(MONTH FROM starttime) AS month, SUM(slots) AS "Total Slots"
FROM cd.bookings
WHERE EXTRACT(YEAR FROM starttime) = 2012
GROUP BY facid, month
ORDER BY facid, month;
```

### [members1](https://pgexercises.com/questions/aggregates/members1.html)
```sql
SELECT COUNT(DISTINCT memid)
FROM cd.bookings;
```

### [nbooking](https://pgexercises.com/questions/aggregates/nbooking.html)
```sql
SELECT mems.surname, mems.firstname, mems.memid, MIN(bks.starttime) AS starttime
FROM cd.bookings bks
INNER JOIN cd.members mems ON mems.memid = bks.memid
WHERE starttime >= '2012-09-01'
GROUP BY mems.surname, mems.firstname, mems.memid
ORDER BY mems.memid;
```

### [countmembers](https://pgexercises.com/questions/aggregates/countmembers.html)
```sql
SELECT (SELECT COUNT(*) FROM cd.members) AS count, firstname, surname
FROM cd.members
ORDER BY joindate;
```

### [nummembers](https://pgexercises.com/questions/aggregates/nummembers.html)
```sql
SELECT ROW_NUMBER() OVER (ORDER BY joindate), firstname, surname
FROM cd.members
ORDER BY joindate;
```

### [fachours4](https://pgexercises.com/questions/aggregates/fachours4.html)
```sql
SELECT facid, total
FROM (
    SELECT facid,
           SUM(slots) AS total,
           RANK() OVER (ORDER BY SUM(slots) DESC) AS rank
    FROM cd.bookings
    GROUP BY facid
) AS ranked
WHERE rank = 1;
```

## String

### [concat](https://pgexercises.com/questions/string/concat.html)
```sql
SELECT surname || ', ' || firstname AS name
FROM cd.members;
```

### [reg](https://pgexercises.com/questions/string/reg.html)
```sql
SELECT memid, telephone
FROM cd.members
WHERE telephone ~ '[()]';
```

### [substr](https://pgexercises.com/questions/string/substr.html)
```sql
SELECT SUBSTR(mems.surname, 1, 1) AS letter, COUNT(*) AS count
FROM cd.members mems
GROUP BY letter
ORDER BY letter;
```

EOF
