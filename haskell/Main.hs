module Main where

import Data.Char (isSpace)
import Data.List (findIndex, foldl')
import Data.Maybe (mapMaybe)
import System.Directory (doesFileExist)
import Text.Read (readMaybe)

dataFileCandidates :: [FilePath]
dataFileCandidates = ["data/University.txt", "../data/University.txt"]

-- Resuelve la ruta del archivo de datos.
resolveDataFile :: IO FilePath
resolveDataFile = go dataFileCandidates
    where
        go [] = return "data/University.txt"
        go (p:ps) = do
                exists <- doesFileExist p
                if exists then return p else go ps

wordsWhen :: (Char -> Bool) -> String -> [String]
wordsWhen p s =
    case dropWhile p s of
        "" -> []
        s' -> w : wordsWhen p s''
          where
            (w, s'') = break p s'

-- Student = (ID, Name, EntryMinutes, Maybe ExitMinutes)
type Student = (String, String, Int, Maybe Int)

-- Limpia espacios al inicio/final de una entrada.
trim :: String -> String
trim = f . f
    where
        f = reverse . dropWhile isSpace

stripTrailingDot :: String -> String
stripTrailingDot s
        | not (null s) && last s == '.' = init s
        | otherwise = s

normalizeOption :: String -> String
normalizeOption = stripTrailingDot . trim

-- Registra la entrada de un estudiante.
checkIn :: [Student] -> String -> String -> Int -> Either String [Student]
checkIn students sid name entryTime =
    case findStudentById students sid of
        Just (_, _, _, Nothing) -> Left "Student is already inside."
        Just _ -> Right (replaceStudent students sid (sid, name, entryTime, Nothing))
        Nothing -> Right (students ++ [(sid, name, entryTime, Nothing)])

-- Busca un estudiante que aun no ha hecho check-out.
searchStudent :: [Student] -> String -> Maybe Student
searchStudent students sid =
    case [st | st@(id, _, _, Nothing) <- students, id == sid] of
        [st] -> Just st
        _ -> Nothing

findStudentById :: [Student] -> String -> Maybe Student
findStudentById students sid =
    case [st | st@(id, _, _, _) <- students, id == sid] of
        [] -> Nothing
        xs -> Just (last xs)

replaceStudent :: [Student] -> String -> Student -> [Student]
replaceStudent students sid newStudent =
    case findIndex (\(id, _, _, _) -> id == sid) students of
        Just idx -> take idx students ++ [newStudent] ++ drop (idx + 1) students
        Nothing -> students

normalizeStudents :: [Student] -> [Student]
normalizeStudents = foldl' upsert []
  where
    upsert acc st@(sid, _, _, _) =
        case findIndex (\(id, _, _, _) -> id == sid) acc of
            Just idx -> take idx acc ++ [st] ++ drop (idx + 1) acc
            Nothing -> acc ++ [st]

-- Registra la salida y valida que no sea antes de la entrada.
checkOut :: [Student] -> String -> Int -> Either String [Student]
checkOut students sid exitTime =
    case break isTarget students of
        (_, []) -> Left "Student not found or already checked out."
        (before, target:after) ->
            let (_, _, entry, _) = target
             in if exitTime < entry
                    then Left "Exit time cannot be earlier than entry time."
                    else Right (before ++ [setExit target exitTime] ++ after)
  where
    isTarget (id, _, _, Nothing) = id == sid
    isTarget _ = False
    setExit (id, name, entry, _) t = (id, name, entry, Just t)

-- Muestra la informacion del estudiante y su tiempo total si ya salio.
printStudent :: Student -> IO ()
printStudent (sid, name, entry, exitMaybe) = do
    putStrLn $ "Student ID: " ++ sid
    putStrLn $ "Name: " ++ name
    putStrLn $ "Entry Time: " ++ formatTime entry
    case exitMaybe of
        Nothing -> putStrLn "Status: Currently inside"
        Just exit -> do
            putStrLn $ "Exit Time: " ++ formatTime exit
            putStrLn $ "Time Spent: " ++ formatTime (exit - entry)

-- Convierte minutos (0-1439) al formato HH:MM.
formatTime :: Int -> String
formatTime mins =
    let h = mins `div` 60
        m = mins `mod` 60
    in padZero h ++ ":" ++ padZero m
  where
    padZero n = if n < 10 then "0" ++ show n else show n

-- Lista todos los estudiantes cargados.
listAllStudents :: [Student] -> IO ()
listAllStudents [] = putStrLn "No students loaded."
listAllStudents students = do
    putStrLn "\n=== Students List ==="
    mapM_ printStudent students
    putStrLn "====================\n"

-- Carga estudiantes desde archivo (soporta formato nuevo y legado).
loadStudents :: IO [Student]
loadStudents = do
    dataFile <- resolveDataFile
    exists <- doesFileExist dataFile
    if not exists
        then return []
        else do
            content <- readFile dataFile
            return (normalizeStudents (mapMaybe parseLine (lines content)))
  where
    -- Soporta lineas: ID,Name,Entry,Exit e ID,Entry,Exit.
    parseLine line =
        case wordsWhen (== ',') line of
            [sid, name, entryStr, exitStr] -> do
                entry <- readMaybe entryStr
                exit <- case exitStr of
                    "null" -> Just Nothing
                    _ -> Just <$> readMaybe exitStr
                Just (sid, name, entry, exit)
            [sid, entryStr, exitStr] -> do
                entry <- readMaybe entryStr
                exit <- case exitStr of
                    "null" -> Just Nothing
                    _ -> Just <$> readMaybe exitStr
                Just (sid, "Unknown", entry, exit)
            _ -> Nothing

-- Convierte un estudiante al formato de archivo.
studentToString :: Student -> String
studentToString (sid, name, entry, exit) =
    sid ++ "," ++ name ++ "," ++ show entry ++ "," ++
    case exit of
        Nothing -> "null"
        Just t -> show t

-- Guarda la lista actual de estudiantes en el archivo.
saveStudents :: [Student] -> IO ()
saveStudents students = do
    dataFile <- resolveDataFile
    writeFile dataFile (unlines (map studentToString students))

-- Lee y parsea una hora ingresada como HH:MM.
readTimeInput :: IO (Maybe Int)
readTimeInput = do
    timeStr <- getLine
    return (parseTimeInput timeStr)

-- Menu principal interactivo.
menu :: [Student] -> IO ()
menu students = do
    putStrLn "\n=== Student Registration System ==="
    putStrLn "1. Check In"
    putStrLn "2. Search"
    putStrLn "3. Check Out"
    putStrLn "4. List Students"
    putStrLn "5. Exit"
    putStrLn "===================================="
    option <- fmap normalizeOption getLine
    case option of
        "1" -> do
            putStrLn "Enter student ID:"
            sid <- fmap trim getLine
            putStrLn "Enter student name:"
            name <- fmap trim getLine
            if null sid || null name
                then do
                    putStrLn "ID and name cannot be empty."
                    menu students
                else do
                    putStrLn "Enter entry time (HH:MM):"
                    mt <- readTimeInput
                    case mt of
                        Nothing -> do
                            putStrLn "Invalid time format. Use HH:MM (00:00 to 23:59)."
                            menu students
                        Just t ->
                            case checkIn students sid name t of
                                Left msg -> do
                                    putStrLn msg
                                    menu students
                                Right newList -> do
                                    saveStudents newList
                                    putStrLn "Check-in saved."
                                    menu newList
        "2" -> do
            putStrLn "Enter student ID:"
            sid <- fmap trim getLine
            case findStudentById students sid of
                Nothing -> putStrLn "Student not found."
                Just st@(_, _, _, Nothing) -> do
                    putStrLn ""
                    printStudent st
                Just _ -> putStrLn "Student already checked out."
            menu students
        "3" -> do
            putStrLn "Enter student ID:"
            sid <- fmap trim getLine
            if null sid
                then do
                    putStrLn "ID cannot be empty."
                    menu students
                else do
                    putStrLn "Enter exit time (HH:MM):"
                    mt <- readTimeInput
                    case mt of
                        Nothing -> do
                            putStrLn "Invalid time format. Use HH:MM (00:00 to 23:59)."
                            menu students
                        Just t ->
                            case checkOut students sid t of
                                Left msg -> do
                                    putStrLn msg
                                    menu students
                                Right newList -> do
                                    saveStudents newList
                                    putStrLn "Check-out saved."
                                    menu newList
        "4" -> do
            refreshed <- loadStudents
            listAllStudents refreshed
            menu refreshed
        "5" ->
            putStrLn "Bye"
        _ -> do
            putStrLn "Invalid option. Please try again."
            menu students

-- Parsea HH:MM a minutos desde las 00:00.
parseTimeInput :: String -> Maybe Int
parseTimeInput timeStr =
    case wordsWhen (== ':') (trim timeStr) of
        [hStr, mStr] -> do
            h <- readMaybe hStr
            m <- readMaybe mStr
            if h >= 0 && h < 24 && m >= 0 && m < 60
                then Just (h * 60 + m)
                else Nothing
        _ -> Nothing

-- Punto de entrada del programa.
main :: IO ()
main = do
    students <- loadStudents
    menu students
