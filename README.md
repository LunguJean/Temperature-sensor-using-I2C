# Temperature-sensor-using-I2C

I2C și citirea temperaturii
Implementați un master I2C în SystemVerilog, fără IP core-uri Xilinx. Master-ul trebuie să
comunice cu senzorul de temperatură de pe placă, să citească periodic valoarea temperaturii și
să o convertească în grade Celsius conform specificațiilor din datasheet-ul senzorului.

### Saptamana 5, luni

## Rezolvare:

Am inceput proiectul prin documentarea despre protocolul de comunicatie I2C si modul de transmisie a datelor intre un circuit master si unul/mai multe circuite tip slave
. Astfel, am ajuns la concluzia ca proiectul v-a fi impartit astfel:

- i2c_master - operatiile de baza ale unui dispozitiv master pentru protocolul I2C
- controller - controleaza comenzile pentru citirea temperaturii
- converter , b2d , 7segdec , display_controller - module ce permit afisarea pe ecranul cu 7 segmente a valorii temperaturii ( vezi Counter binar pe 16 biti )

 ### Protocolul I2C
 
I2C(Inter-Integrated Circuit) este un protocol de comunicatie seriala sincrona utilizat pentru transferul de date intre circuite digitale integrate. Comunicarea se realizeaza prin intermediul:

- SCL - semnalul de ceas generat de master
- SDA - linia bidirectionala ( BUS-ul ) pentru transmitere si receptie

O transmisie I2C este formata din urmatoarele etape :

- generarea conditiei de START
- transmiterea adresei SLAVE-ului
- transmiterea bitului de citire/scriere
- verificarea semnalului ACK
- transmiterea sau receptionarea datelor
- transmiterea unui semnal ACK/NACK
- generarea conditiei de STOP

Astfel , modulul i2c_master controleaza liniile SDA si SCL si implementeaza aceste operatii pentru transmisie. Pentru aceasta implementare am ales frecventa standard de 100khz ( frecventa semnalului SCL ).
Asadar, numarul de cicluri corespunzator unei jumatati de perioada a SCL este calculat dupa urmatoarea formula : HALF_PERIOD = CLK_FREQ / (2*I2C_FREQ), rezultand 500 de cicluri de ceas.

Modulul este implementat sub forma unui FSM cu mai multe stari:

- IDLE - busy este dezactivat, se asteapta o comanda
- START - SDA si SCL sunt eliberate ( ambele sunt 1 ), se pregateste conditia de incepere a comunicatiei ( SDA -> 0 )
- START_SDA - daca SDA e 0 si SCL ramane 1
- START_DONE - dupa generarea conditiei de start, linia SCL->0 , iar magistrala este pregatita pentru transmiterea primului bit
- WRITE_BIT - se stabileste bitul ce urmeaza a fi transmis ( modificarea liniei se face cat timp SCL->0 )
- WRITE_HIGH - SCL->1, slave citeste valoarea bitului
- WRITE_LOW - SCL->0, transmisia s-a incheiat ( daca mai exista biti de transmis, automatul revine in WRITE_BIT )
- WAIT_ACK - dupa transmiterea octetului, masterul elibereaza SDA si permite transmiterea bitului de confirmare
- ACK_HIGH - SCL->1 ( valoarea transmisa devine valida )
- READ_ACK - daca SDA->0, transmisia a fost confirmata.Daca SDA->1, este detectata o eroare (NACK)
- ACK_LOW - SCL->0 , secventa de ack este incheiata
- READ_BIT - se elibereaza SDA
- READ_HIGH - SCL->1, slave-ul prezinta urmatorul bit pe SDA
- READ_DATA - masterul citeste valoarea si o memoreaza
- READ_LOW - SCL->0 ( daca mai exista biti se trece din nou in READ_BIT )
- SEND_ACK - SCL->1, slave citeste ce a transmis master, iar masterul stabileste valoarea de ACK ( daca urmeaza receptionarea unui nou octet ) sau NACK ( daca se finalizeaza citirea octetilor )
- SEND_ACK_HIGH - SCL->1, slave citeste raspunsul
- SENC_ACK_LOW - SCL->0, SDA este eliberata
- STOP - SDA si SCL sunt aduse la nivel 0
- STOP_HIGH - SCL->1, SDA ramane 0
- STOP_DONE - SDA->1 si SCL ramane 1, rezultand conditia de stop
- DONE - starea de finalizare, semnal activat pe un singur ciclu de ceas, semnalul busy e dezactivat si se revine in starea IDLE



### Saptamana 5, marti

In plus, pentru a evita conflictele pe liniile SDA si SCL, am utilizat intrari open-drain specifice I2C. Astfel, placa nu impune niciodata nivelul logic 1 pe magistrala. Atunci cand se transmite un nivel logic 0, linia este trasa la masa ( 0 ), iar pentru nivelul logic 1, iesirea este trecuta in starea de inalta impedanta (1'bz) si se elibereaza linia. In protocolul I2C, nivelul de logic 1 este obtinut prin rezistentele de pull-up ce mentin SDA si SCL la nivel de 1 logic cand nu au de efectuat o comanda sau niciun slave nu le impune sa treaca la nivel logic 0. Datorita acestui lucru este permis o arhitectura multi slave cu un singur master.



Pentru modulul i2c_master am realizat o simulare totala a receptiei si transmiterii datelor prin intermediul i2c. In cadrul testbench-ului am simultat si rezistente de pull-up pentru a reproduce functionarea in totalitate a protocolului.

<img width="1316" height="778" alt="image" src="https://github.com/user-attachments/assets/36f93f68-e263-400a-8eb7-cbd8eebe54c6" />

