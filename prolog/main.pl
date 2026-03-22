:- use_module(library(readutil)).
:- use_module('controller.pl').

% student(ID, Entry, Exit)
% Exit = none when the student is still inside

file_path('data/University.txt').

load_students(File, Students) :-
    open(File, read, Stream),
    read_lines(Stream, Students),
    close(Stream).

read_lines(Stream, []) :-
    at_end_of_stream(Stream).

read_lines(Stream, [student(ID,E,X)|Rest]) :-
    \+ at_end_of_stream(Stream),
    read_line_to_string(Stream, Line),
    split_string(Line, ",", "", [IDStr, EStr, XStr]),
    number_string(E, EStr),
    ( XStr = "null" -> X = none ; number_string(X, XStr) ),
    ID = IDStr,
    read_lines(Stream, Rest).

save_students(File, Students) :-
    open(File, write, Stream),
    write_students(Stream, Students),
    close(Stream).

write_students(_, []).
write_students(Stream, [student(ID,E,X)|Rest]) :-
    write(Stream, ID),
    write(Stream, ','),
    write(Stream, E),
    write(Stream, ','),
    ( X = none -> write(Stream, 'null') ; write(Stream, X) ),
    nl(Stream),
    write_students(Stream, Rest).

% Helpers to load/save from default data file
load_default(Students) :-
    file_path(File),
    load_students(File, Students).

save_default(Students) :-
    file_path(File),
    save_students(File, Students).
