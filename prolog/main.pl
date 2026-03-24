# University Student Registration System in Prolog 
:- use_module(library(readutil)).

# Variable para la ruta del archivo de datos.
data_file_candidates(['data/University.txt', '../data/University.txt']).

# Intenta resolver la ruta del archivo.
resolve_data_file(File) :-
    data_file_candidates(Candidates),
    member(File, Candidates),
    exists_file(File),
    !.
resolve_data_file('data/University.txt').

# Carga los estudiantes desde el archivo o retorna vacio.
load_students(File, Students) :-
    (   exists_file(File)
    ->  open(File, read, Stream),
        read_lines(Stream, Students),
        close(Stream)
    ;   Students = []
    ).

# Lee todas las líneas del archivo y las convierte en estructuras.
read_lines(Stream, []) :-
    at_end_of_stream(Stream).

# Lee cada línea, intenta parsearla y acumula los estudiantes.
read_lines(Stream, Students) :-
    \+ at_end_of_stream(Stream),
    read_line_to_string(Stream, Line),
    (   parse_line(Line, Student)
    ->  Students = [Student|Rest]
    ;   Students = Rest
    ),
    read_lines(Stream, Rest).

# Parsea una línea en una estructura de estudiante.
parse_line(Line, student(ID, Name, Entry, Exit)) :-
    split_string(Line, ",", " \t", Parts),
    parse_parts(Parts, ID, Name, Entry, Exit).

# Parsea las partes de la línea dependiendo del formato.
parse_parts([IDStr, NameStr, EStr, XStr], ID, Name, Entry, Exit) :-
    IDStr \= "",
    NameStr \= "",
    number_string(Entry, EStr),
    parse_exit(XStr, Exit),
    ID = IDStr,
    Name = NameStr.
parse_parts([IDStr, EStr, XStr], ID, Name, Entry, Exit) :-
    IDStr \= "",
    number_string(Entry, EStr),
    parse_exit(XStr, Exit),
    ID = IDStr,
    Name = "Unknown".

# Parsea el campo de salida, aceptando "null" como none.
parse_exit("null", none).
parse_exit(XStr, Exit) :-
    number_string(Exit, XStr).

# Guarda los estudiantes en el archivo.
save_students(File, Students) :-
    open(File, write, Stream),
    write_students(Stream, Students),
    close(Stream).

# Escribe cada estudiante en el archivo, manejando el formato de salida.
write_students(_, []).
write_students(Stream, [student(ID,Name,E,X)|Rest]) :-
    write(Stream, ID),
    write(Stream, ','),
    write(Stream, Name),
    write(Stream, ','),
    write(Stream, E),
    write(Stream, ','),
    ( X = none -> write(Stream, 'null') ; write(Stream, X) ),
    nl(Stream),
    write_students(Stream, Rest).

# Funciones para manejar la lógica de check-in, check-out, búsqueda y listado de estudiantes.
load_default(Students) :-
    resolve_data_file(File),
    load_students(File, Students).

# Guarda los estudiantes en el archivo por defecto.
save_default(Students) :-
    resolve_data_file(File),
    save_students(File, Students).

# Busca un estudiante por ID.    
search_student(Students, ID, student(ID, Name, Entry, none)) :-
    member(student(ID, Name, Entry, none), Students).

# Busca un estudiante por ID que ya haya salido.
check_in(Students, ID, Name, Entry, Result, Message) :-
    (   search_student(Students, ID, _)
    ->  Result = Students,
        Message = 'Student is already inside.'
    ;   append(Students, [student(ID, Name, Entry, none)], Result),
        Message = 'Check-in saved.'
    ).

# Actualiza el registro de salida de un estudiante.
check_out(Students, ID, Exit, Result, Message) :-
    checkout_update(Students, ID, Exit, Result, Status),
    message_for_checkout(Status, Message).

# Recorre la lista de estudiantes para actualizar el registro de salida.
checkout_update([], _, _, [], not_found).
checkout_update([student(ID, Name, Entry, none)|Rest], ID, Exit, [student(ID, Name, Entry, none)|Rest], invalid_time) :-
    Exit < Entry,
    !.
checkout_update([student(ID, Name, Entry, none)|Rest], ID, Exit, [student(ID, Name, Entry, Exit)|Rest], ok) :-
    Exit >= Entry,
    !.
checkout_update([S|Rest], ID, Exit, [S|OutRest], Status) :-
    checkout_update(Rest, ID, Exit, OutRest, Status).

# Mensajes para los resultados del check-out.
message_for_checkout(ok, 'Check-out saved.').
message_for_checkout(not_found, 'Student not found or already checked out.').
message_for_checkout(invalid_time, 'Exit time cannot be earlier than entry time.').

# Funciones para formatear el tiempo y mostrar la información de los estudiantes.
format_time(Minutes, TimeStr) :-
    H is Minutes // 60,
    M is Minutes mod 60,
    format(string(TimeStr), '~|~`0t~d~2+:~|~`0t~d~2+', [H, M]).

# Imprime la información de un estudiante.
print_student(student(ID, Name, Entry, none)) :-
    format_time(Entry, EntryStr),
    format('Student ID: ~w~n', [ID]),
    format('Name: ~w~n', [Name]),
    format('Entry Time: ~w~n', [EntryStr]),
    write('Status: Currently inside'), nl.
print_student(student(ID, Name, Entry, Exit)) :-
    Exit \= none,
    Spent is Exit - Entry,
    format_time(Entry, EntryStr),
    format_time(Exit, ExitStr),
    format_time(Spent, SpentStr),
    format('Student ID: ~w~n', [ID]),
    format('Name: ~w~n', [Name]),
    format('Entry Time: ~w~n', [EntryStr]),
    format('Exit Time: ~w~n', [ExitStr]),
    format('Time Spent: ~w~n', [SpentStr]).

# Lista todos los estudiantes cargados.
list_students([]) :-
    write('No students loaded.'), nl.
list_students(Students) :-
    nl,
    write('=== Students List ==='), nl,
    forall(member(S, Students), (print_student(S), nl)),
    write('===================='), nl, nl.

# Funciones para manejar la entrada de tiempo y el menú interactivo.
parse_time_input(TimeStr, Minutes) :-
    split_string(TimeStr, ':', ' \t', [HStr, MStr]),
    number_string(H, HStr),
    number_string(M, MStr),
    between(0, 23, H),
    between(0, 59, M),
    Minutes is H * 60 + M.

# Pide al usuario que ingrese un tiempo y lo valida.    
ask_time(Prompt, Minutes) :-
    write(Prompt), nl,
    read_input_string(TimeStr),
    (   TimeStr == end_of_file
    ->  fail
    ;   parse_time_input(TimeStr, Minutes)
    ->  true
    ;   write('Invalid time format. Use HH:MM (00:00 to 23:59).'), nl,
        fail
    ).

# Lee la entrada del usuario como una cadena.
read_input_string(Value) :-
    read_line_to_string(user_input, Raw),
    (   Raw == end_of_file
    ->  Value = end_of_file
    ;   normalize_space(string(Trimmed), Raw),
        strip_trailing_dot(Trimmed, Value)
    ).

# Elimina un punto final común que SWI agrega a las entradas numéricas.
strip_trailing_dot(Input, Output) :-
    sub_string(Input, Before, 1, 0, "."),
    sub_string(Input, 0, Before, _, Output),
    !.
strip_trailing_dot(Input, Input).

# Menú principal que muestra las opciones y maneja la navegación.
menu(Students) :-
    nl,
    write('=== Student Registration System ==='), nl,
    write('1. Check In'), nl,
    write('2. Search'), nl,
    write('3. Check Out'), nl,
    write('4. List Students'), nl,
    write('5. Exit'), nl,
    write('===================================='), nl,
    read_input_string(Option),
    handle_option(Option, Students).

# Maneja la opción seleccionada por el usuario.
handle_option("1", Students) :-
    write('Enter student ID:'), nl,
    read_input_string(ID),
    write('Enter student name:'), nl,
    read_input_string(Name),
    (   ask_time('Enter entry time (HH:MM):', Entry)
    ->  check_in(Students, ID, Name, Entry, NewStudents, Message),
        write(Message), nl,
        (   Message = 'Check-in saved.'
        ->  save_default(NewStudents),
            menu(NewStudents)
        ;   menu(Students)
        )
    ;   menu(Students)
    ).
handle_option("2", Students) :-
    write('Enter student ID:'), nl,
    read_input_string(ID),
    (   search_student(Students, ID, Student)
    ->  nl,
        print_student(Student), nl
    ;   write('Student not found or already checked out.'), nl
    ),
    menu(Students).
handle_option("3", Students) :-
    write('Enter student ID:'), nl,
    read_input_string(ID),
    (   ask_time('Enter exit time (HH:MM):', Exit)
    ->  check_out(Students, ID, Exit, NewStudents, Message),
        write(Message), nl,
        (   Message = 'Check-out saved.'
        ->  save_default(NewStudents),
            menu(NewStudents)
        ;   menu(Students)
        )
    ;   menu(Students)
    ).
handle_option("4", _Students) :-
    load_default(LoadedStudents),
    list_students(LoadedStudents),
    menu(LoadedStudents).
handle_option(end_of_file, _Students) :-
    write('Bye'), nl.
handle_option("5", _Students) :-
    write('Bye'), nl.
handle_option(_, Students) :-
    write('Invalid option. Please try again.'), nl,
    menu(Students).

# Punto de entrada del programa.
main :-
    load_default(Students),
    menu(Students).