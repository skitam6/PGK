1. STEROWANIE
W / S - Jazda łazikiem przód / tył
A / D - Skręcanie łazikiem lewo / prawo
Q / E - Obrót wieżyczki
I / K - Sterowanie przegubem 1 (Górne Ramię)
J / L - Sterowanie przegubem 2 (Dolne Ramię)
Z / X - Rozwarcie / Zamknięcie chwytaka
SPACJA - Wystrzelenie pocisku

R - Resetowanie misji 
L - Włączenie / Wyłączenie całego systemu świateł
P - Zmiana Presetu Oświetlenia 
M - Zmiana Materiału łazika (0: Matowy, 1: Metaliczny, 2: Emissive)

1 - Tryb renderowania (Solid / Wireframe)
2 - Zmiana rzutowania (Perspective / Ortho)
3 - Debug Mode (Rysuje siatkę podłoża, osie XYZ oraz Hitboxy/Sfery kolizyjne przeszkód i łazika)
4 - Transformacja chwytaka (T*R vs R*T)
F - Zmiana trybu Cieniowania (Domyślny / Flat Shading)
C - Przełączanie trybu kamery (Orbit / Chase)


2. TRYBY KAMERY
- Tryb 0 (Orbitalna): Swobodna kamera kontrolowana myszką. Umożliwia orbitowanie wokół środka sceny, przybliżanie (scroll) oraz oddalanie.
- Tryb 1 (Chase ): Kamera śledząca ruch pojazdu.

3. TRYBY SHADINGU
- Tryb 0 (Domyślny): Wykorzystuje domyślne renderowanie Processingu.
- Tryb 1 (Flat):Shader napisany w języku GLSL

4. OPIS KOLIZJI
Kolizja łazika to dwie połączone Sfery:
- Promień (ROVER_RADIUS).
- Przesunięcie (ROVER_OFFSET)(od środka, w przód i w tył).

Na scenie znajduje się 10 przeszkód. Każda z przeszkód posiada swoją sferę kolizyjną o zadanym promieniu (parametr obsR w przedziale od 35 do 80). 
Kolizja nie pozwala na przenikanie.

- Zbierajki: Łazik może zebrać jeden z 6 znaczników misji, jeśli jakakolwiek część jego Hitboxu znajdzie się w promieniu obiektu.
- Pociski: Wystrzeliwane obiekty fizyczne posiadają promień PROBE_RADIUS. Jeżeli wejdą w sferę kolizji którejkolwiek z przeszkód powodują eksplozję.