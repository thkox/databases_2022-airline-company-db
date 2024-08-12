import psycopg2
import sys
from prettytable import PrettyTable


def connect():
    try:
        con = psycopg2.connect(dbname='airline', host='localhost', port='5432', user='postgres',password='password') #import login information
        return con
    except:
        sys.exit('Connection not established,exiting...')


def select(query ,inputt):

    try:
        cur = connect().cursor()
    except:
        sys.exit('Cursor not created , exiting...')

    try:
        cur.execute(query)
    except Exception as e:
        print(e)
    else:
        if(inputt == 'a'):
            t = PrettyTable(['Passenger_ID','Firstname','Lastname','seat_no','ticket_book_date'])
            data = cur.fetchall()
            for item in data:
                t.add_row([item[0],item[1],item[2],item[3],item[4]])
            print(t)
        if(inputt == 'b'):
            t = PrettyTable(['Total_aircraft_seats','total_booked_seats','free_seats'])
            data = cur.fetchall()
            for item in data:
                t.add_row([item[0],item[1],item[2]])
            print(t)
        if (inputt == 'c'):
            t = PrettyTable(['Flight_code', 'departure_date' , 'Delay'])
            data = cur.fetchall()
            for item in data:
                t.add_row([item[0],item[1],item[2]])
                #print(item)
            print(t)

        if (inputt == 'd'):
            t1 = PrettyTable(['Passenger_ID','Firstname','Lastname'])
            data = cur.fetchall()
            for item in data:
                t1.add_row([item[0],item[1],item[2]])
            print(t1)

        if (inputt == 'e'):
            t = PrettyTable(['popular_destinations_in_2022'])
            data = cur.fetchall()
            for item in data:
                t.add_row([item[0]])
                #print(item)
            print(t)
        if (inputt == 'f'):
            t = PrettyTable(['Passenger_ID', 'Firstname' , 'Lastname'])
            data = cur.fetchall()
            for item in data:
                t.add_row([item[0],item[1],item[2]])
                #print(item)
            print(t)
                    
    cur.close()

again = 'y' 
print("Please Choose A Query: ")
print("1)2a")
print("2)2b")
print("3)2c")
print("4)2d")
print("5)2e")
print("6)2f")
while (again == 'Y' or again == 'y'):

    choice = input("Query: ")
    if (int(choice)==1):
            flight_code = input("Flight_code: ")
            seat_no = input("Seat: ")
            a = """ SELECT t.passenger_id, passenger_firstname, passenger_lastname, seat_no, bk.book_date AS ticket_book_date
            FROM ((ticket AS t INNER JOIN passenger AS p ON t.passenger_id = p.passenger_id)
            INNER JOIN boarding_pass AS b ON t.ticket_no = b.ticket_no)
            INNER JOIN flight AS f ON b.departure_date = f.departure_date
            INNER JOIN booking AS bk ON f.departure_date = bk.departure_date
            WHERE f.flight_code = '{}' AND seat_no = '{}' AND f.departure_date= CURRENT_DATE - INTERVAL '1 DAY';""".format(flight_code,seat_no)
            print("--QUERY-A--")
            select(a,'a')
    if (int(choice)==2):
            flight_code = input("Flight_code:")
            b = """ 
                WITH ts AS
                (SELECT aircraft_capacity AS total_seats_no
                FROM flight AS f INNER JOIN aircraft AS air ON f.aircraft_code = air.aircraft_code
                WHERE f.flight_code =  '{}' AND f.departure_date = CURRENT_DATE - INTERVAL '1 DAY'),
                bs AS
                (SELECT COUNT(seat_no) AS booked_seats_no
                FROM ((flight AS fl INNER JOIN boarding_pass AS bp ON fl.flight_code = bp.flight_code AND fl.departure_date = bp.departure_date)
                INNER JOIN ticket AS t ON bp.ticket_no = t.ticket_no)
                INNER JOIN booking AS b ON b.book_ref = t.book_ref
                WHERE fl.flight_code =  '{}' AND fl.departure_date = CURRENT_DATE - INTERVAL '1 DAY')
                SELECT ts.total_seats_no AS total_aircraft_seats, bs.booked_seats_no AS total_booked_seats, (ts.total_seats_no - bs.booked_seats_no) AS free_seats
                FROM ts, bs;""".format(flight_code,flight_code)
            print("--QUERY-B--")
            select(b,'b')
    if (int(choice)==3):
            c = """ 
                SELECT flight_code, departure_date, actual_departure_time - scheduled_departure_time AS delay
                FROM flight 
                WHERE departure_date >= '2022-01-01' and departure_date <= '2022-12-31' AND flight_status = 'Arrived'
                ORDER BY delay DESC
                LIMIT 5;"""

            print("--QUERY-C--")
            select(c,'c')
    if (int(choice)==4):
            d="""
                SELECT pa.passenger_id AS passenger_id, pa.passenger_firstname AS firstname, pa.passenger_lastname AS lastname
                FROM flight AS f INNER JOIN more_flights AS mf ON (f.flight_code = mf.flight_code AND f.departure_date = mf.departure_date)
                INNER JOIN ticket AS ti ON mf.ticket_no = ti.ticket_no
                INNER JOIN passenger AS pa ON pa.passenger_id = ti.passenger_id
                WHERE flight_status = 'Arrived' AND (f.departure_date >= '2022-01-01' AND f.departure_date <= '2022-12-31')
                GROUP BY pa.passenger_id ORDER BY SUM(f.distance) DESC LIMIT 5;
            """
            print("--QUERY-D--")
            select(d,'d')

    if (int(choice)==5):
            e = """ SELECT city_name AS popular_destinations_in_2022, COUNT(f.arrival_airport) AS hierarchy
            FROM flight AS f INNER JOIN airport AS a ON f.arrival_airport = a.airport_code
            INNER JOIN city AS c ON  a.airport_city_name = c.city_name
            WHERE f.flight_status = 'Arrived' AND (f.departure_date >= '2022-01-01' AND f.departure_date <= '2022-12-31')
            GROUP BY city_name ORDER BY hierarchy DESC LIMIT 5;"""
            print("--QUERY-E--")
            select(e,'e')
    if (int(choice)==6): 
            f =""" WITH fp AS
            (SELECT pa.passenger_id AS passenger_id, pa.passenger_firstname AS firstname, pa.passenger_lastname AS lastname, COUNT(fl.flight_code) AS times
            FROM passenger AS pa INNER JOIN ticket as ti ON pa.passenger_id = ti.passenger_id
            INNER JOIN boarding_pass AS bp ON ti.ticket_no = bp.ticket_no
            INNER JOIN flight AS fl ON bp.departure_date = fl.departure_date AND bp.flight_code = fl.flight_code
            INNER JOIN more_flights AS mf ON fl.departure_date = mf.departure_date AND fl.flight_code = mf.flight_code
            WHERE flight_status != 'Scheduled'
            GROUP BY pa.passenger_id)
            SELECT passenger_id, firstname, lastname FROM fp WHERE times >= 2 ORDER BY times DESC LIMIT 5;"""
            print("--QUERY-F--")
            select(f,'f')           

    again = input("Do you want to choose another query? Y/N ")    

print("PROGRAM TERMINATED")
