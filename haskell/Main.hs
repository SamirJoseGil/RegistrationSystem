module Main where

import System.Directory (doesFileExist)

dataFileCandidates :: [FilePath]
dataFileCandidates = ["data/University.txt", "../data/University.txt"]

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

-- Type definition for a student: (ID, Entry Time, Exit Time)
type Student = (String, Int, Maybe Int)

-- Check In: Add a student with entry time (if not already in the list)
checkIn :: [Student] -> String -> Int -> [Student]
checkIn students sid entryTime =
    case searchStudent students sid of
        Just _ -> students  -- Already checked in
        Nothing -> students ++ [(sid, entryTime, Nothing)]

-- Search: Find a student currently inside (with no exit time)
searchStudent :: [Student] -> String -> Maybe Student
searchStudent students sid = 
    case [st | st@(id, _, Nothing) <- students, id == sid] of
        [st] -> Just st
        _ -> Nothing

-- Check Out: Add exit time to a student
checkOut :: [Student] -> String -> Int -> [Student]
checkOut students sid exitTime =
    map (\st@(id, entry, _) -> if id == sid then (id, entry, Just exitTime) else st) students

-- Print student info with time spent
printStudent :: Student -> IO ()
printStudent (sid, entry, exitMaybe) = do
    putStrLn $ "Student ID: " ++ sid
    putStrLn $ "Entry Time: " ++ formatTime entry
    case exitMaybe of
        Nothing -> putStrLn "Status: Currently inside"
        Just exit -> do
            putStrLn $ "Exit Time: " ++ formatTime exit
            putStrLn $ "Time Spent: " ++ formatTime (exit - entry)

-- Format time from minutes (0-1439) to HH:MM format
formatTime :: Int -> String
formatTime mins =
    let h = mins `div` 60
        m = mins `mod` 60
    in padZero h ++ ":" ++ padZero m
  where
    padZero n = if n < 10 then "0" ++ show n else show n

-- List all students
listAllStudents :: [Student] -> IO ()
listAllStudents [] = putStrLn "No students loaded."
listAllStudents students = do
    putStrLn "\n=== Students List ==="
    mapM_ printStudent students
    putStrLn "====================\n"


loadStudents :: IO [Student]
loadStudents = do
    dataFile <- resolveDataFile
    content <- readFile dataFile
    return (map parseLine (lines content))
  where
    parseLine line =
        let [sid, entry, exit] = wordsWhen (== ',') line
         in (sid, read entry, if exit == "null" then Nothing else Just (read exit))

studentToString :: Student -> String
studentToString (sid, entry, exit) =
    sid ++ "," ++ show entry ++ "," ++
    case exit of
        Nothing -> "null"
        Just t -> show t

saveStudents :: [Student] -> IO ()
saveStudents students = do
    dataFile <- resolveDataFile
    writeFile dataFile (unlines (map studentToString students))

menu :: [Student] -> IO ()
menu students = do
    putStrLn "\n=== Student Registration System ==="
    putStrLn "1. Check In"
    putStrLn "2. Search"
    putStrLn "3. Check Out"
    putStrLn "4. List Students"
    putStrLn "5. Exit"
    putStrLn "===================================="
    option <- getLine
    case option of
        "1" -> do
            putStrLn "Enter student ID:"
            sid <- getLine
            putStrLn "Enter entry time (HH:MM):"
            timeStr <- getLine
            let t = parseTimeInput timeStr
            let newList = checkIn students sid t
            saveStudents newList
            putStrLn "✓ Check-in saved."
            menu newList
        "2" -> do
            putStrLn "Enter student ID:"
            sid <- getLine
            case searchStudent students sid of
                Nothing -> putStrLn "✗ Student not found or already checked out."
                Just st -> do
                    putStrLn ""
                    printStudent st
            menu students
        "3" -> do
            putStrLn "Enter student ID:"
            sid <- getLine
            putStrLn "Enter exit time (HH:MM):"
            timeStr <- getLine
            let t = parseTimeInput timeStr
            let newList = checkOut students sid t
            saveStudents newList
            putStrLn "✓ Check-out saved."
            menu newList
        "4" -> do
            listAllStudents students
            menu students
        "5" ->
            putStrLn "Bye"
        _ -> do
            putStrLn "✗ Invalid option. Please try again."
            menu students

-- Parse time input from HH:MM format to minutes
parseTimeInput :: String -> Int
parseTimeInput timeStr =
    case wordsWhen (== ':') timeStr of
        [hStr, mStr] -> read hStr * 60 + read mStr
        _ -> 0

main :: IO ()
main = do
    students <- loadStudents
    menu students
