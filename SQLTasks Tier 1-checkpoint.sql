/* Welcome to the SQL mini project. You will carry out this project partly in
the PHPMyAdmin interface, and partly in Jupyter via a Python connection.

This is Tier 1 of the case study, which means that there'll be more guidance for you about how to 
setup your local SQLite connection in PART 2 of the case study. 

The questions in the case study are exactly the same as with Tier 2. 

PART 1: PHPMyAdmin
You will complete questions 1-9 below in the PHPMyAdmin interface. 
Log in by pasting the following URL into your browser, and
using the following Username and Password:

URL: https://sql.springboard.com/
Username: student
Password: learn_sql@springboard

The data you need is in the "country_club" database. This database
contains 3 tables:
    i) the "Bookings" table,
    ii) the "Facilities" table, and
    iii) the "Members" table.

In this case study, you'll be asked a series of questions. You can
solve them using the platform, but for the final deliverable,
paste the code for each solution into this script, and upload it
to your GitHub.

Before starting with the questions, feel free to take your time,
exploring the data, and getting acquainted with the 3 tables. */


/* QUESTIONS 
/* Q1: Some of the facilities charge a fee to members, but some do not.
Write a SQL query to produce a list of the names of the facilities that do. */

SELECT name
FROM Facilities
WHERE membercost > 0;


/* Q2: How many facilities do not charge a fee to members? */

SELECT COUNT(*)
FROM Facilities
WHERE membercost = 0;


/* Q3: Write an SQL query to show a list of facilities that charge a fee to members,
where the fee is less than 20% of the facility's monthly maintenance cost.
Return the facid, facility name, member cost, and monthly maintenance of the
facilities in question. */

SELECT facid, name, membercost, monthlymaintenance
FROM Facilities
WHERE membercost > 0 AND membercost < (monthlymaintenance * 0.2);

/* Q4: Write an SQL query to retrieve the details of facilities with ID 1 and 5.
Try writing the query without using the OR operator. */

SELECT facid, name, membercost, guestcost, initialoutlay, monthlymaintenance
FROM Facilities
WHERE facid IN (1, 5);

/* Q5: Produce a list of facilities, with each labelled as
'cheap' or 'expensive', depending on if their monthly maintenance cost is
more than $100. Return the name and monthly maintenance of the facilities
in question. */

SELECT name, monthlymaintenance,
    CASE
        WHEN monthlymaintenance > 100 THEN 'expensive'
        ELSE 'cheap'
    END AS cost_label
FROM Facilities;


/* Q6: You'd like to get the first and last name of the last member(s)
who signed up. Try not to use the LIMIT clause for your solution. */

SELECT firstname, surname
FROM Members
WHERE joindate = (
    SELECT MAX(joindate)
    FROM Members);

/* Q7: Produce a list of all members who have used a tennis court.
Include in your output the name of the court, and the name of the member
formatted as a single column. Ensure no duplicate data, and order by
the member name. */

SELECT DISTINCT f.name AS facility_name, CONCAT_WS( ' ', m.firstname, m.surname ) AS member_name

FROM Bookings AS b
JOIN Facilities AS f ON b.facid = f.facid
JOIN Members AS m ON b.memid = m.memid
WHERE f.name LIKE 'Tennis Court%'
AND b.memid !=0
ORDER BY member_name


/* Q8: Produce a list of bookings on the day of 2012-09-14 which
will cost the member (or guest) more than $30. Remember that guests have
different costs to members (the listed costs are per half-hour 'slot'), and
the guest user's ID is always 0. Include in your output the name of the
facility, the name of the member formatted as a single column, and the cost.
Order by descending cost, and do not use any subqueries. */

SELECT f.name AS facility_name,
CASE
WHEN b.memid =0
THEN 'Guest'
ELSE CONCAT_WS( ' ', m.firstname, m.surname )

END AS member_name,
CASE
WHEN b.memid =0
THEN b.slots * f.guestcost
ELSE b.slots * f.membercost
END AS calculated_cost
FROM Bookings AS b
LEFT JOIN Facilities AS f ON b.facid = f.facid
LEFT JOIN Members AS m ON b.memid = m.memid
WHERE b.starttime LIKE '2012-09-14%'
HAVING calculated_cost >30
ORDER BY calculated_cost DESC

/* Q9: This time, produce the same result as in Q8, but using a subquery. */

SELECT
    f.name AS facility_name,
    CASE
        WHEN sub.memid = 0 THEN 'Guest'
        ELSE CONCAT_WS(' ', m.firstname, m.surname) 
    END AS member_name,
    sub.calculated_cost
FROM (
    SELECT
        bookid,
        facid,
        memid,
        slots,
        starttime,
        CASE
            WHEN memid = 0 THEN slots * (SELECT guestcost FROM Facilities WHERE facid = b.facid)
            ELSE slots * (SELECT membercost FROM Facilities WHERE facid = b.facid)
        END AS calculated_cost
    FROM Bookings AS b
    WHERE starttime LIKE '2012-09-14%'
) AS sub
LEFT JOIN Facilities AS f
    ON sub.facid = f.facid
LEFT JOIN Members AS m
    ON sub.memid = m.memid
WHERE sub.calculated_cost > 30
ORDER BY sub.calculated_cost DESC;


/* PART 2: SQLite
/* We now want you to jump over to a local instance of the database on your machine. 

Copy and paste the LocalSQLConnection.py script into an empty Jupyter notebook, and run it. 

Make sure that the SQLFiles folder containing thes files is in your working directory, and
that you haven't changed the name of the .db file from 'sqlite\db\pythonsqlite'.

You should see the output from the initial query 'SELECT * FROM FACILITIES'.

Complete the remaining tasks in the Jupyter interface. If you struggle, feel free to go back
to the PHPMyAdmin interface as and when you need to. 

You'll need to paste your query into value of the 'query1' variable and run the code block again to get an output.
 
QUESTIONS:
/* Q10: Produce a list of facilities with a total revenue less than 1000.
The output of facility name and total revenue, sorted by revenue. Remember
that there's a different cost for guests and members! */

SELECT
    f.name AS facility_name,
    SUM(CASE
        WHEN b.memid = 0 THEN f.guestcost * b.slots
        ELSE f.membercost * b.slots
    END) AS total_revenue
FROM Bookings AS b
JOIN Facilities AS f
    ON b.facid = f.facid
GROUP BY f.name
HAVING total_revenue < 1000
ORDER BY total_revenue;

/* Q11: Produce a report of members and who recommended them in alphabetic surname,firstname order */

SELECT
    m1.surname || ', ' || m1.firstname AS member_full_name, -- Member's name: Surname, Firstname
    CASE
        WHEN m1.recommendedby = 0 THEN NULL
        ELSE m2.surname || ', ' || m2.firstname -- Recommender's name: Surname, Firstname
    END AS recommender_full_name
FROM Members AS m1
LEFT JOIN Members AS m2
    ON m1.recommendedby = m2.memid
ORDER BY member_full_name;

/* Q12: Find the facilities with their usage by member, but not guests */

SELECT
    f.name AS facility_name,
    m.firstname || ' ' || m.surname AS member_full_name, -- Combined member name for readability
    COUNT(b.bookid) AS usage_count -- Counts how many times a member booked this facility
FROM Bookings AS b
JOIN Facilities AS f
    ON b.facid = f.facid
JOIN Members AS m
    ON b.memid = m.memid
WHERE b.memid != 0 -- Exclude guests (memid = 0)
GROUP BY f.name, member_full_name -- Group by facility and the combined member name
ORDER BY facility_name, member_full_name;


/* Q13: Find the facilities usage by month, but not guests */

SELECT
    strftime('%Y-%m', b.starttime) AS booking_month, -- Extracts year and month (e.g., '2012-07')
    f.name AS facility_name,
    SUM(b.slots) AS total_slots_used -- Sums the 'slots' for each booking to get total usage
FROM Bookings AS b
JOIN Facilities AS f
    ON b.facid = f.facid
WHERE b.memid != 0 -- Exclude guests (memid = 0)
GROUP BY booking_month, f.name
ORDER BY booking_month, facility_name;

