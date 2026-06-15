// #define PROCESSING_LIGHT_SHADER to specjalna dyrektywa (makro) dla Processingu.
// Informuje kompilator Processingu, że ten shader służy do obliczeń z użyciem świateł 
// (a nie np. do samej tekstury czy koloru). Processing dzięki temu automatycznie wstrzykuje 
// pewne domyślne zmienne (np. pozycje świateł) do shadera w tle.
#define PROCESSING_LIGHT_SHADER

// uniform mat4 to zmienna typu "uniform" (taka sama dla każdego wierzchołka w trakcie rysowania pojedynczej klatki).
// mat4 oznacza macierz 4x4 (używaną do przekształceń w przestrzeni 3D).
// modelview to macierz zawierająca pozycję kamery oraz przesunięcia (translacje) z funkcji pushMatrix().
uniform mat4 modelview;

// transform to tzw. Projection Modelview Matrix - macierz rzutująca wierzchołek 3D na płaski ekran 2D (piksele na monitorze).
uniform mat4 transform;

// normalMatrix to macierz 3x3 używana do obracania wektorów normalnych (kątów odbicia światła), żeby zawsze były prostopadłe do powierzchni nawet po obróceniu obiektu.
uniform mat3 normalMatrix;

// attribute to zmienna (dane), która jest inna dla KAŻDEGO wierzchołka (punktu geometrycznego) przetwarzanego przez kartę graficzną.
// vec4 to wektor z 4 wartościami (x, y, z, w). vertex przechowuje pozycję danego wierzchołka w przestrzeni.
attribute vec4 vertex;

// color przechowuje bazowy kolor wierzchołka wyliczony przez Processing na podstawie funkcji fill().
attribute vec4 color;

// normal przechowuje "wektor normalny" - wektor skierowany pionowo od powierzchni trójkąta (informuje w którą stronę "patrzy" wierzchołek).
attribute vec3 normal;

// varying to specjalna zmienna używana do przekazania danych z tego pliku (shadera wierzchołków) 
// do drugiego pliku (shadera pikseli / fragmentów). Dane te są interpolowane (płynnie uśredniane) dla pikseli leżących między wierzchołkami.
// vertColor przekaże kolor do shadera fragmentów.
varying vec4 vertColor;

// ecPosition przekaże pozycję wierzchołka w tak zwanych współrzędnych oka (Eye Coordinates) kamery, czyli "jak daleko od kamery jest ten punkt".
varying vec3 ecPosition;

// void main() to główna funkcja shadera, wykonywana na karcie graficznej dla KAŻDEGO narysowanego wierzchołka.
void main() {
  // gl_Position to wbudowana zmienna OpenGL. Wymaga wyliczenia ostatecznej pozycji piksela na płaskim ekranie monitora.
  // Mnożymy macierz rzutującą (transform) przez pozycję trójwymiarową wierzchołka (vertex).
  gl_Position = transform * vertex;
  
  // Obliczamy ecPosition, mnożąc macierz modelview przez vertex. Przekształca to punkt z przestrzeni świata 3D na przestrzeń zależną wyłącznie od kamery (zera osi X, Y, Z są w kamerze).
  // Wynik z wektora 4D rzutujemy (konwertujemy) do wektora 3D (vec3), odrzucając czwartą zmienną 'w'.
  ecPosition = vec3(modelview * vertex);
  
  // Przepisujemy kolor wierzchołka z Processingu bez zmian, aby wysłać go do shadera pikseli.
  vertColor = color;
}