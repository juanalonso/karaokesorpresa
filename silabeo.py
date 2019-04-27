import sys
from syltippy import syllabize

if len(sys.argv) != 2:
    exit()

silabas, _ = syllabize(sys.argv[1]) 

print (silabas)

salida = open('numsilabas.txt', 'w')
salida.write(str(len(silabas)))
salida.close()