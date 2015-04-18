**Kifutópálya világítás megvalósítása**

Az INT nyomógomb, a fényérzékelő és a LED0~LED7  LED-ek felhasználásával készítsen kifutópálya világítást a következők szerint:

* a két LED sor képezi a kifutópálya széleit jelző lámpasort
* a LED-ek fényereje függ a külső megvilágítástól, a fényérzékelőről beolvasott érték alapján 4 különböző fényerőt lehet alkalmazni
* a fényerőt időzítő alkalmazásával (időalap 500 usec) kialakított PWM-mel lehet változtatni 
* az INT nyomógomb lenyomására változzon a működés módja: a kikapcsolás - szabályozott fényerejű működés – teljes fényerejű működés ciklusban
* a nyomógomb egy lenyomására csak egy módváltás történjen
