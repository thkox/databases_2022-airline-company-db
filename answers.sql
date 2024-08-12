1.c)
FLIGHTS_VIEW

WITH deair AS
(SELECT airport_code AS departure_airport_code, airport_name AS departure_airport_name, airport_city_name AS departure_airport_city, city_timezone AS departure_airport_timezone
FROM airport INNER JOIN city ON airport_city_name = city_name),
arair AS
(SELECT airport_code AS arrival_airport_code, airport_name AS arrival_airport_name, airport_city_name AS arrival_airport_city, city_timezone AS arrival_airport_timezone
FROM airport INNER JOIN city ON airport_city_name = city_name),
fl AS
(SELECT flight_code,departure_airport, arrival_airport, departure_date, scheduled_departure_time, actual_departure_time, scheduled_arrival_time, actual_arrival_time, scheduled_duration
FROM flight WHERE departure_date = '2022-06-16')

SELECT flight_code,
departure_airport_code, departure_airport_name, departure_airport_city, 
arrival_airport_code, arrival_airport_name, arrival_airport_city,
DATE(departure_date AT TIME ZONE departure_airport_timezone) AS departure_date,
actual_departure_time AT TIME ZONE departure_airport_timezone AS actual_departure_time, 
(DATE(departure_date AT TIME ZONE arrival_airport_timezone ) + make_interval(0,0,0,0,0,scheduled_duration)) AS arrival_date,
scheduled_arrival_time AT TIME ZONE arrival_airport_timezone AS scheduled_arrival_time,
actual_arrival_time AT TIME ZONE arrival_airport_timezone AS actual_arrival_time,
make_interval(0,0,0,0,0,scheduled_duration) AS scheduled_duration,
(actual_arrival_time - actual_departure_time) AS actual_duration
FROM  (fl INNER JOIN deair ON departure_airport = departure_airport_code) INNER JOIN arair ON arrival_airport = arrival_airport_code;

ROUTES_VIEW

WITH deair AS
(SELECT airport_code AS departure_airport_code, airport_name AS departure_airport_name, airport_city_name AS departure_airport_city
FROM airport INNER JOIN city ON airport_city_name = city_name),
arair AS
(SELECT airport_code AS arrival_airport_code, airport_name AS arrival_airport_name, airport_city_name AS arrival_airport_city
FROM airport INNER JOIN city ON airport_city_name = city_name),
fl_air AS
(SELECT flight_code,departure_airport, arrival_airport, aircraft.aircraft_code, scheduled_duration, aircraft_name, departure_date
FROM flight INNER JOIN aircraft ON aircraft.aircraft_code = flight.aircraft_code WHERE departure_date BETWEEN '2022-05-30' AND '2022-06-05')

SELECT flight_code,
departure_airport_code, departure_airport_name, departure_airport_city,
arrival_airport_code, arrival_airport_name, arrival_airport_city,
aircraft_name AS aircraft_code,
make_interval(0,0,0,0,0,scheduled_duration) AS scheduled_duration
--days_of_week--
FROM (fl_air INNER JOIN deair ON departure_airport = departure_airport_code) INNER JOIN arair ON arrival_airport = arrival_airport_code ORDER BY departure_date ASC;

2a)
(είχαμε ξεχάσει το book_date)

SELECT t.passenger_id, passenger_firstname, passenger_lastname, seat_no, bk.book_date AS ticket_book_date
FROM ((ticket AS t INNER JOIN passenger AS p ON t.passenger_id = p.passenger_id)
INNER JOIN boarding_pass AS b ON t.ticket_no = b.ticket_no)
INNER JOIN flight AS f ON b.departure_date = f.departure_date
INNER JOIN booking AS bk ON f.departure_date = bk.departure_date
WHERE f.flight_code = /*1*/ AND seat_no = /*2*/ AND f.departure_date= CURRENT_DATE - INTERVAL '1 DAY';

/*1. Αριθμός πτήσης που πραγματοποιήθηκε την προηγούμενη μέρα*/
/*2. Θέση αεροπλάνου σε αυτή την συγκεκριμένη πτήση*/

2b)
(δείχνουμε αναλυτικά τι παίζει)

WITH ts AS
(SELECT aircraft_capacity AS total_seats_no
FROM flight AS f INNER JOIN aircraft AS air ON f.aircraft_code = air.aircraft_code
WHERE f.flight_code = /*1*/ AND f.departure_date = CURRENT_DATE - INTERVAL '1 DAY'),
bs AS
(SELECT COUNT(seat_no) AS booked_seats_no
FROM ((flight AS fl INNER JOIN boarding_pass AS bp ON fl.flight_code = bp.flight_code AND fl.departure_date = bp.departure_date)
INNER JOIN ticket AS t ON bp.ticket_no = t.ticket_no)
INNER JOIN booking AS b ON b.book_ref = t.book_ref
WHERE fl.flight_code = /*1*/ AND fl.departure_date = CURRENT_DATE - INTERVAL '1 DAY')

SELECT ts.total_seats_no AS total_aircraft_seats, bs.booked_seats_no AS total_booked_seats, (ts.total_seats_no - bs.booked_seats_no) AS free_seats
FROM ts, bs;

/*1. Αριθμός πτήσης που πραγματοποιήθηκε την προηγούμενη μέρα*/

2c)

SELECT flight_code, departure_date, actual_departure_time - scheduled_departure_time AS delay
FROM flight 
WHERE departure_date >= '2022-01-01' and departure_date <= '2022-12-31' AND flight_status = 'Arrived'
ORDER BY delay DESC
LIMIT 5;

2d)

SELECT pa.passenger_id AS passenger_id, pa.passenger_firstname AS firstname, pa.passenger_lastname AS lastname
FROM flight AS f INNER JOIN more_flights AS mf ON (f.flight_code = mf.flight_code AND f.departure_date = mf.departure_date)
INNER JOIN ticket AS ti ON mf.ticket_no = ti.ticket_no
INNER JOIN passenger AS pa ON pa.passenger_id = ti.passenger_id
WHERE flight_status = 'Arrived' AND (f.departure_date >= '2022-01-01' AND f.departure_date <= '2022-12-31')
GROUP BY pa.passenger_id ORDER BY SUM(f.distance) DESC LIMIT 5;

2e)

SELECT city_name AS popular_destinations_in_2022
FROM flight AS f INNER JOIN airport AS a ON f.arrival_airport = a.airport_code
INNER JOIN city AS c ON  a.airport_city_name = c.city_name
WHERE f.flight_status = 'Arrived' AND (f.departure_date >= '2022-01-01' AND f.departure_date <= '2022-12-31')
GROUP BY city_name ORDER BY COUNT(f.arrival_airport) DESC LIMIT 5;

2f)

WITH fp AS
(SELECT pa.passenger_id AS passenger_id, pa.passenger_firstname AS firstname, pa.passenger_lastname AS lastname, COUNT(fl.flight_code) AS times
FROM passenger AS pa INNER JOIN ticket as ti ON pa.passenger_id = ti.passenger_id
INNER JOIN boarding_pass AS bp ON ti.ticket_no = bp.ticket_no
INNER JOIN flight AS fl ON bp.departure_date = fl.departure_date AND bp.flight_code = fl.flight_code
INNER JOIN more_flights AS mf ON fl.departure_date = mf.departure_date AND fl.flight_code = mf.flight_code
WHERE flight_status != 'Scheduled'
GROUP BY pa.passenger_id)

SELECT passenger_id, firstname, lastname FROM fp WHERE times >= 2 ORDER BY times DESC LIMIT 5;

3a)

CREATE OR REPLACE FUNCTION backup_booking() 
RETURNS TRIGGER AS $edit_booking$
    BEGIN
        CREATE TABLE IF NOT EXISTS booking_log
        (
            id SERIAL PRIMARY KEY,
			book_ref CHAR(6) NOT NULL,
            total_amount INTEGER NOT NULL, 
            book_date DATE NOT NULL,
            flight_code VARCHAR(6) NOT NULL,
            departure_date DATE NOT NULL,
            delete_time TIMESTAMP NOT NULL,
            function_type CHAR(1) NOT NULL
        );
		
        IF (TG_OP = 'DELETE') THEN
            INSERT INTO booking_log(book_ref,total_amount,book_date,flight_code,departure_date, delete_time, function_type) VALUES (OLD.book_ref, OLD.total_amount, OLD.book_date, OLD.flight_code, OLD.departure_date, current_timestamp, 'd');
            RETURN OLD;
        ELSIF (TG_OP = 'UPDATE') THEN
		    INSERT INTO booking_log(book_ref,total_amount,book_date,flight_code,departure_date, delete_time, function_type) VALUES (OLD.book_ref, OLD.total_amount, OLD.book_date, OLD.flight_code, OLD.departure_date, current_timestamp, 'u');
			RETURN NEW;
		END IF;
    END;
    $edit_booking$ LANGUAGE plpgsql;
	
CREATE TRIGGER edit_booking
BEFORE DELETE OR UPDATE ON booking
FOR EACH ROW
EXECUTE PROCEDURE backup_booking();

3b)
---------------Μόνο το query-------------------------------------------------
WITH deair AS
(SELECT airport_code AS departure_airport_code, airport_name AS departure_airport_name, city_timezone AS departure_airport_timezone
FROM airport INNER JOIN city ON airport_city_name = city_name),
arair AS
(SELECT airport_code AS arrival_airport_code, airport_name AS arrival_airport_name, city_timezone AS arrival_airport_timezone
FROM airport INNER JOIN city ON airport_city_name = city_name),
fl_pass AS
(SELECT fl.flight_code, fl.departure_date,  fl.scheduled_duration, fl.departure_airport, fl.arrival_airport, pa.passenger_firstname, pa.passenger_lastname
FROM flight AS fl INNER JOIN more_flights AS mf ON (fl.flight_code = mf.flight_code AND fl.departure_date = mf.departure_date)
INNER JOIN ticket AS ti ON mf.ticket_no = ti.ticket_no
INNER JOIN passenger AS pa ON ti.passenger_id = pa.passenger_id),
all_data AS
(SELECT departure_date,
date(departure_date  + make_interval(0,0,0,0,0,scheduled_duration)) AS arrival_date,
departure_airport_name, arrival_airport_name,
flight_code,
passenger_firstname, passenger_lastname
FROM (fl_pass INNER JOIN deair ON departure_airport = departure_airport_code) INNER JOIN arair ON arrival_airport = arrival_airport_code 
GROUP BY passenger_lastname, passenger_firstname, departure_date, scheduled_duration, departure_airport_name, arrival_airport_name, flight_code, passenger_firstname, passenger_lastname)

SELECT * FROM all_data;
----------------------------------------------------------------------------
