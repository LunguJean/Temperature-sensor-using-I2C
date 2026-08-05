# Temperature-sensor-using-I2C

I2C și citirea temperaturii
Implementați un master I2C în SystemVerilog, fără IP core-uri Xilinx. Master-ul trebuie să
comunice cu senzorul de temperatură de pe placă, să citească periodic valoarea temperaturii și
să o convertească în grade Celsius conform specificațiilor din datasheet-ul senzorului.

### --Saptamana 5, luni--

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



### -- Saptamana 5, marti --

In plus, pentru a evita conflictele pe liniile SDA si SCL, am utilizat intrari open-drain specifice I2C. Astfel, placa nu impune niciodata nivelul logic 1 pe magistrala. Atunci cand se transmite un nivel logic 0, linia este trasa la masa ( 0 ), iar pentru nivelul logic 1, iesirea este trecuta in starea de inalta impedanta (1'bz) si se elibereaza linia. In protocolul I2C, nivelul de logic 1 este obtinut prin rezistentele de pull-up ce mentin SDA si SCL la nivel de 1 logic cand nu au de efectuat o comanda sau niciun slave nu le impune sa treaca la nivel logic 0. Datorita acestui lucru este permis o arhitectura multi slave cu un singur master.



Pentru modulul i2c_master am realizat o simulare totala a receptiei si transmiterii datelor prin intermediul i2c. In cadrul testbench-ului am simultat si rezistente de pull-up pentru a reproduce functionarea in totalitate a protocolului.

<img width="1316" height="778" alt="image" src="https://github.com/user-attachments/assets/36f93f68-e263-400a-8eb7-cbd8eebe54c6" />

### -- Saptmana 5, miercuri -- 

In continuare am decis sa ma documentez despre senzorul de temperatura de pe Nexys A7, ADT7420. Adresa acestuia in I2C este 0x4B, iar datele despre temperatura sunt stocate in 2 registre de 8 biti ( pentru MSB avem 0x00 si pentru LSB 0x01 ). Din cei 16 biti, valoarea temperaturii este stocata in cei primii 13 biti de la stanga la dreapta. 

Pentru a intelege operatia de citire am folosit urmatoarea schema:
<img width="771" height="214" alt="image" src="https://github.com/user-attachments/assets/18801698-5878-44ea-9d91-05e62dbca954" />

In imaginea atasata sunt prezentate operatia de citire a datelor de la senzor, impartita in 2 tranzactii. In prima tranzactie, master-ul genereaza conditia de START si transmite adresa la care se vrea sa se faca scrierea ( 0x4B ). Dupa primirea bitului de scriere si a semnalului de confirmare ACK din partea slave-ului, masterul transmite adresa registrului din care vrea sa citeasca date ( 0x00 ).Dupa confirmarea receptiei a octetului MSB, se transmite din nou ACK si masterul genereaza o noua conditie de START ( aici denumita repeated start ), eliberand magistrala pentru a trece la citire

In a 2-a tranzactie, masterul retransmite adresa slave-ului impreuna cu bitul de citire READ. Dupa confirmare, incepe transmiterea datelor: primul octet transmis este MSB-ul, impreuna cu ACK dupa ce masterul receptioneaza, apoi LSB-ul urmat de semnalul NACK ce indica faptul ca masterul nu mai solicita alte date de la senzor. Comunicatia este ulterior incheiata prin STOP, iar cei 2 octeti sunt concatenati pentru obtinerea valorii complete a temperaturii.





### -- Saptamana 6, luni --

Am adaptat codul pentru i2c_master, eliminand simularea rezistentelor de pullup. Acum in momentul in care SDA-ul se doreste a fi liber, se trece direct in nivelul logic 1. 

Acest lucru a fost posibil prin utilizarea a 2 semnale : sda_in ( valoarea citita de master ) si sda_out ( valoarea transmisa de master ). I2C utilizeaza o arhitectura tip open-drain in care dispozitivele conectate nu transmit direct nivelul activ logic 1, ele pot doar sa forteze logic 0. Datorita acestui lucru a fost initial nevoie de rezistente de pullup ce simulau trecerea in 1, ulterior aceasta metoda dovedindu-se a fi invalida din punct de vedere al implementarii pe placa.

Pe langa aceasta modificare, codul masterului a fost optimizat prin introducerea unor faze pentru transferul bitilor. Fiecare operatie de scriere sau citire este impartita in 4 faze:

- PHASE0 - pregatirea valorii pe SDA in timp ce SCL e 0
- PHASE1 - ridicarea SCL
- PHASE2 - mentinerea nivelului logic 1 pentru transmiterea datelor
- PHASE3 - oborarea semnalului SCL inainte de trecerea la urmatorul bit

Prin utilizarea fazelor, FSM-ul a fost simplificat, reducandu-se nivelul starilor la 7 stari principale : IDLE, START, WRITE, READ, ACK, STOP, DONE. Fiecare stare utilizeaza aceeasi succesiune de 4 faze in care se observa mai clar functionalitatea.

In testbench am simulat transmiterea si receptionarea unor octeti. Masterul transmite un octet catre slave, iar acesta raspunde prin ACK. La citire, slave-ul transmite succesiv octetul si masterul memoreaza in registrul rx. La final, masterul trimite ACK sau NACK, in functie de semnalul de control.

Această relație reproduce comportamentul dominant al nivelului logic 0 specific magistralei I²C. Dacă masterul sau dispozitivul slave aplică nivelul logic 0, valoarea observată pe magistrală devine 0. Linia va avea nivelul logic 1 numai atunci când atât sda_out, cât și slave_out sunt egale cu 1.

Am decis sa reproduc comportamentul specific I2C fara rezistentele de pullup simulate. Astfel, daca masterul sau dispozitivul slave sunt 0, valoarea pe bus devine 0. Linia v-a fi 1 atunci cand sda_out si slave_out sunt 1 ( sda_in = sda_out & slave_out ).

### Simularea master-ului

In formele de unda se pot observa conditiile de START si STOP, octetul transmis sau receptionat, ACK sau NACK, precum si evolutia starilor si a fazelor, scl_out, sda_out sau chiar bit_count. 

<img width="1423" height="780" alt="image" src="https://github.com/user-attachments/assets/ab0645b5-5105-4d5a-8540-1bf15716cc0e" />


### -- Saptamana 6, marti --

In continuare, pentru a putea afisa pe ecranul cu 7 segmente valoarea temperaturii masurate de senzor, sunt necesare inca 2 module importante:

- temp_controller - modul ce controleaza comunicatia dintre placa si senzor prin I2C, citeste si transmite date despre temperatura
  
- temp_converter - transforma datele primite de la senzor in temperatura propriuzisa, scrisa in grade Celsius

Pentru modulul de control al temperaturii, implementarea a fost realizata cu un FSM ce coordoneaza intreaga secventa de comunicatie I2C. La pornire, controller-ul asteapta un interval pentru a putea citi prima valoare ( FIRST_READY_DELAY ), necesar pentru conversia temperaturii. Ulterior, citirile sunt realizate periodic, la un interval READ_INTERVAL, ales acum 240 ms, corespunzator perioadei tipice de actualizare a temperaturii de catre senzorul ADT7420.

FSM-ul controllerului cuprinde starile:
- IDLE – starea de repaus, in care se asteapta prima citire sau trecerea la urmatoarea citire
- SEND_START_WRITE – transmite masterului conditia de START a primei citiri
- WAIT_START_WRITE – asteapta confirmarea finalizarii conditiei de start
- SEND_ADDRESS_WRITE – transmite adresa senzorului impreuna cu bitul de scriere ( 0x96 )
- WAIT_ADDRESS_WRITE – asteapta finalizarea transmiterii adresei si asteapta ACK
- SEND_REGISTER_ADDRESS – transmite adresa registrului de temperatura
- WAIT_REGISTER_ADDRESS – asteapta confirmarea 
- SEND_REPEATED_START – genereaza o conditie de a repeta pornirea, fara eliberarea magistralei
- WAIT_REPEATED_START – asteapta finalizarea conditiei
- SEND_ADDRESS_READ – transmite adresa si bitul de citire ( 0x97 )
- WAIT_ADDRESS_READ – asteapta finalizarea si verifica ACK
- SEND_READ_MSB – citeste primul octet, iar dupa receptie, masterul trimite ACK
- WAIT_READ_MSB – asteapta terminarea si memoreaza in MSB
- SEND_READ_LSB – comanda citirea LSB, dupa terminare trimite ACK
- WAIT_READ_LSB – asteapta terminarea citirii si memoreaza LSB
- SEND_STOP – transmite catre master conditia de STOP
- WAIT_STOP – asteapta terminarea si verifica ACK sau NACK
- SAVE_RESULT – concateneaza MSB si LSB si formeaza cei 16 biti de date, data_valid indica faptul ca se asteapta o noua valoare
- WAIT_NEXT_READ – reseteaza contorul de asteptare si se pregateste pt o noua citire


In cadrul fiecarei secvente de citire, controllerul transmite catre modului i2c_master comenzile necesare pentru generarea conditiei de START, REPEATED_START si STOP, pentru selectarea registrului de temperatura si pentru citirea succesiva a celor 16 biti ce compun valoarea temperaturii. La final, cei 16 biti ( temperature_raw ) sunt transmisi catre temp_converter pentru a fi convertiti in grade celsius.

In modulul de conversie se aplica urmatoarele formule :

- "temperature_count = temperature_raw >> 3" - valoarea temperaturii este reprezentata in primii 13 biti, de aceea valoarea "raw" se shifteaza la dreapta cu 3 rezultand temperatura exprimata in 1/16 unitati
 
- "temp_celsius = temperature_count >> 4" - shiftarea cu 4 la dreapta este echivalenta cu impartirea la 16, obtinandu-se astfel partea intreaga a valorii in grade C
  
- "temp_fraction = (temperature_count[3:0] * 10) >> 4" - cei 4 biti inferiori reprezinta fractia temperaturii in saisprezecimi de grad celsius. Pentru a afisa o singura zecimala, fractia este inmultita cu 10 si deplasata la dreapta cu 4 pozitii ( impartita la 16 )

### -- Saptamana 6, miercuri --










