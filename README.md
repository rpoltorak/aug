# Projekt AUG

## Link do repo
https://github.com/rpoltorak/aug

## Build

Aby skompilować projekt nalezy postepowac nastepujaco:

W katalogu glownym:

```
$ cd src && make && cd ..
```

Aby przetestowac program nalezy wykorzystac istniejacy juz plik z kodem:
```
$ ./program test.x
```

## Uwagi
Program tworzony byl na systemie OSX, dlatego tez moga (ale nie musza) wystapic problemy z
buildem w innych srodowiskach. Na pewno warto zwrocic uwage na plik `Makefile` i opcje `-ll` przy kompilacji.
Niestety OSX nie obsluguje biblioteki do ktorej odnosi sie `-flf`, stad taka zmiana. Na linuxie prawdopobonie trzeba to zmienic na `-lfl`.