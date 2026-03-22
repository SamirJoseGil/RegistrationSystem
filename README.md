# RegistrationSystem

Sistema de registro de estudiantes universitarios desarrollado en Haskell y Prolog.

## Descripcion

El programa permite gestionar la entrada y salida de estudiantes de la universidad, registrando horarios y calculando el tiempo permanencia. Se implementan dos versiones del mismo sistema:

- Version Haskell: Enfoque funcional
- Version Prolog: Enfoque logico

## Estructura del Proyecto

```
RegistrationSystem/
  haskell/
    Main.hs
  prolog/
    main.pl
  data/
    University.txt
```

## Funcionamiento

El programa ofrece las siguientes opciones:

1. Check In - Registra la entrada de un estudiante
2. Search - Busca un estudiante actualmente en la universidad
3. Check Out - Registra la salida de un estudiante
4. List Students - Muestra todos los estudiantes cargados
5. Exit - Cierra el programa

## Como Ejecutar

### Version Haskell

Requiere GHC (Glasgow Haskell Compiler) instalado.

Compilacion:
```
cd haskell
ghc -o Main Main.hs
```

Ejecucion:
```
./Main
```

O en Windows:
```
Main.exe
```

### Version Prolog

Requiere SWI-Prolog instalado.

Ejecucion:
```
cd prolog
swipl main.pl
```

## Formato del Archivo de Datos

El archivo University.txt contiene los registros de estudiantes con el siguiente formato:

```
ID,TiempoEntrada,TiempoSalida
456,500,600
789,420,null
```

Donde:
- ID: Identificador del estudiante
- TiempoEntrada: Hora de entrada en formato minutos (0-1439)
- TiempoSalida: Hora de salida o "null" si aun esta dentro

## Entrada de Tiempo

El programa maneja la hora en formato HH:MM, ejemplo:
- 08:30 = 510 minutos
- 14:45 = 885 minutos

El tiempo se convierte internamente a minutos desde las 00:00.