DROP TABLE IF EXISTS city;
CREATE TABLE city
(
    city_name TEXT NOT NULL,
	city_timezone TEXT NOT NULL, 
	
    PRIMARY KEY (city_name)
);

DROP TABLE IF EXISTS aircraft;
CREATE TABLE aircraft
(
	aircraft_code NUMERIC(3) UNIQUE NOT NULL,
    aircraft_name VARCHAR(20) UNIQUE NOT NULL,
    aircraft_capacity INTEGER NOT NULL check(aircraft_capacity >= 50 and aircraft_capacity <= 300),
    aircraft_range INTEGER NOT NULL check(aircraft_range >= 7000 and aircraft_range <= 10000),
	
    PRIMARY KEY (aircraft_code)
);

DROP TABLE IF EXISTS airport;
CREATE TABLE airport
(
    airport_code CHAR(3) UNIQUE NOT NULL,
    airport_name TEXT UNIQUE NOT NULL,
    airport_city_name TEXT NOT NULL,
	
    PRIMARY KEY (airport_code),
	FOREIGN KEY (airport_city_name) REFERENCES city(city_name)
);

DROP TABLE IF EXISTS passenger;
CREATE TABLE passenger
(
	passenger_id CHAR(10) UNIQUE NOT NULL,
    passenger_firstname VARCHAR(20) NOT NULL,
    passenger_lastname VARCHAR(20) NOT NULL,
    passenger_phone NUMERIC(10) UNIQUE NOT NULL,
    passenger_email VARCHAR(50) UNIQUE NOT NULL,
	
    PRIMARY KEY (passenger_id)
);

DROP TABLE IF EXISTS flight;
CREATE TABLE flight
(
    flight_code CHAR(6) NOT NULL,
	departure_date DATE NOT NULL, 
    departure_airport CHAR(3),
    arrival_airport CHAR(3),
    distance INTEGER NOT NULL,
    scheduled_departure_time TIME NOT NULL,
    scheduled_arrival_time TIME NOT NULL,
	scheduled_duration INTEGER NOT NULL,
    actual_departure_time TIME,
    actual_arrival_time TIME,
    flight_status TEXT NOT NULL,
    aircraft_code NUMERIC(3),
	
    PRIMARY KEY (flight_code , departure_date),
	
	FOREIGN KEY (departure_airport) REFERENCES airport(airport_code),
	FOREIGN KEY (arrival_airport) REFERENCES airport(airport_code),
	FOREIGN KEY (aircraft_code) REFERENCES aircraft(aircraft_code),
	
	CHECK(departure_airport != arrival_airport),
	CHECK(distance >= 1000 and distance <= 7000),
	CHECK(flight_status= 'Scheduled' OR flight_status='On Time'OR flight_status='Delayed' OR flight_status='Departed' OR flight_status='Arrived' OR flight_status='Cancelled' )
);

DROP TABLE IF EXISTS booking;
CREATE TABLE booking
(
    book_ref CHAR(6) NOT NULL,
    total_amount INTEGER NOT NULL, 
    book_date DATE NOT NULL,
	flight_code VARCHAR(6) NOT NULL,
	departure_date DATE NOT NULL,
	
    PRIMARY KEY (book_ref),
	
	FOREIGN KEY (flight_code, departure_date) REFERENCES flight(flight_code, departure_date) ON UPDATE CASCADE ON DELETE CASCADE,
	
	CHECK(total_amount > 0),
	CHECK(book_date >= departure_date - INTERVAL '1' MONTH) -- yyyy-mm-dd
);

DROP TABLE IF EXISTS ticket;
CREATE TABLE ticket
(
    ticket_no NUMERIC(13)  NOT NULL,
	passenger_id VARCHAR(10),
    book_ref VARCHAR(6),
    PRIMARY KEY (ticket_no),
	
	FOREIGN KEY (passenger_id) REFERENCES passenger(passenger_id),
	FOREIGN KEY (book_ref) REFERENCES booking(book_ref) ON UPDATE CASCADE ON DELETE CASCADE
); 


DROP TABLE IF EXISTS more_flights;
CREATE TABLE more_flights
(
    ticket_no NUMERIC(13),
    flight_code CHAR(6) NOT NULL,
    departure_date DATE NOT NULL ,
    amount INTEGER NOT NULL,
    fare TEXT NOT NULL,
	
    PRIMARY KEY (flight_code , departure_date , ticket_no),
	
    FOREIGN KEY (flight_code, departure_date) REFERENCES flight(flight_code, departure_date) ON UPDATE CASCADE ON DELETE CASCADE,
	FOREIGN KEY (ticket_no) REFERENCES  ticket(ticket_no) ON UPDATE CASCADE ON DELETE CASCADE,
	
	CHECK(amount > 0),
	CHECK(fare ='Economy' OR fare = 'Business' OR fare = 'First Class') 
);

DROP TABLE IF EXISTS boarding_pass;
CREATE TABLE boarding_pass
(
    seat_no CHAR(3) NOT NULL,
    flight_code CHAR(6) NOT NULL,
	departure_date DATE NOT NULL,
    ticket_no NUMERIC(13),
    boarding_no INTEGER NOT NULL,
    PRIMARY KEY (seat_no, flight_code , departure_date ),
	
	FOREIGN KEY (flight_code, departure_date) REFERENCES flight(flight_code, departure_date) ON UPDATE CASCADE ON DELETE CASCADE,
	FOREIGN KEY (ticket_no) REFERENCES ticket(ticket_no) ON UPDATE CASCADE ON DELETE CASCADE
);
