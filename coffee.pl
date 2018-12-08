:- use_module(library(http/thread_httpd)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(date)).
:- use_module(library(http/json)).

:- http_handler(/, hello, [prefix]).

% Start datetime thread and server
init :-
	thread_create(datetime, _, []),
	http_server(http_dispatch, [port(3000)]).

% Handle request
hello(Request) :-
	member(path_info(Path), Request),
	atom_number(Path, Water),
	get_coffee(Coffee, Water),
	atom_json_dict(Atom, _{coffee:Coffee, water:Water}, []),
    format('Content-type: application/json~n~n'),
    format('~a~n',[Atom]).
    
% Get coffee recipe depending on time of day and day of week
get_coffee(Coffee, Water) :-
    coffee(Ratio, ExtraSpoon, DayOfWeek, TimeOfDay),
	day_of_week(DayOfWeek),
	time_of_day(TimeOfDay),
	Coffee is Water * Ratio + ExtraSpoon.
get_coffee(1, 1).


% Assert time of day and day of week including null values
datetime() :- 
	datetime(null).
datetime(Hour) :-
	get_time(TimeStamp),
	stamp_date_time(TimeStamp, date(_, _, _, Hour1, _, _, _, _, _), local),
	\+ Hour1 = Hour,
	date(Date),
	day_of_the_week(Date, DayOfWeek),
	time(Hour1, TimeOfDay),
	retractall(time_of_day(_)),
	retractall(day_of_week(_)),
	asserta(time_of_day(null)), 
	asserta(day_of_week(null)),
	asserta(time_of_day(TimeOfDay)),
	asserta(day_of_week(DayOfWeek)),
	!, fail.
datetime(Hour) :- time_out(datetime(Hour), 30000, _).

% Get time of day depending on hour
time(H, morning) :-  H < 11.
time(H, midday) :- H < 14.
time(H, afternoon) :- H < 18.
time(_, evening).

