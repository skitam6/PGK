// Wymagane przez Processing określenie typu shadera (tłumaczyłem w poprzednim pliku).
#define PROCESSING_LIGHT_SHADER

// GL_ES to dyrektywa sprawdzająca, czy kod uruchamia się na urządzeniu z OpenGL ES (np. telefony, Raspberry Pi, czy zintegrowane karty Mac).
#ifdef GL_ES
// Jeśli tak, musimy określić precyzję (dokładność po przecinku) obliczeń zmiennych zmiennoprzecinkowych (float) i całkowitych (int). 
// 'mediump' to optymalny kompromis między szybkością a jakością dla prostych zadań.
precision mediump float;
precision mediump int;
#endif

// Zmienne 'varying' są tutaj odbierane od shadera wierzchołków (flat_vert.glsl). 
// Tu otrzymujemy wyliczony kolor dla tego konkretnego piksela ekranu.
varying vec4 vertColor;
// Tu otrzymujemy pozycję trójwymiarową danego piksela względem kamery.
varying vec3 ecPosition;

// Poniższe zmienne 'uniform' są automatycznie podsyłane przez wbudowany system świateł w Processingu.
// lightCount określa ile źródeł światła jest obecnie włączonych w grze (np. 1 kierunkowe, 1 punktowe itp.).
uniform int lightCount;
// Tablice (np. [8]) przechowują dane maksymalnie 8 świateł (limit Processingu).
uniform vec4 lightPosition[8]; // Pozycja każdego ze świateł w 3D.
uniform vec3 lightNormal[8];   // Kierunek świecenia światła (dla kierunkowych i reflektorów).
uniform vec3 lightAmbient[8];  // Natężenie minimalnego "poświatu" (ambient) od każdego światła.
uniform vec3 lightDiffuse[8];  // Właściwy kolor emitowany przez światło (ten oświetlający przedmioty).
uniform vec3 lightSpecular[8]; // Kolor "błysku" odbijającego się w materiałach metalicznych od każdego ze świateł.
uniform vec3 lightFalloff[8];  // Współczynniki opadania natężenia światła na dystansie.
uniform vec2 lightSpot[8];     // Parametry określające kąt i rozmycie snopa światła dla reflektorów (spotLight).

// Zmienne przypisywane ręcznie przez nas w funkcji applyMaterial w pliku głównym.
// Posiadają nasz prefix "my", by ominąć leniwe błędy optymalizacyjne biblioteki P3D.
uniform vec4 myAmbient;   // Ogólny cień materiału (minimalna jasność obiektu bez padającego światła).
uniform vec4 mySpecular;  // Jak mocno błyszczy dany materiał (dla metalu jasny biały błysk).
uniform vec4 myEmissive;  // Własne światło materiału (używane w żarówkach i słońcu).
uniform float myShininess; // Skupienie błysku. Im większa liczba, tym błysk mniejszy, ale ostrzejszy.

// Główna funkcja wywoływana dla KAŻDEGO jednego wyrenderowanego piksela na monitorze.
void main() {
  // KLUCZOWY FRAGMENT DLA FLAT SHADINGU
  // dFdx i dFdy to zaawansowane funkcje matematyczne różniczkujące (pochodne cząstkowe).
  // "Podglądają" one fizyczną pozycję sąsiedniego piksela renderowanego obok.
  vec3 u = dFdx(ecPosition);
  vec3 v = dFdy(ecPosition);
  
  // cross(u, v) (iloczyn wektorowy) matematycznie wylicza wektor prostopadły do powierzchni zbudowanej z pikseli obok.
  // normalize upewnia się, że wektor ma długość dokładnie 1.0 (ważne do wzorów fizycznych).
  // Znak '-' odwraca strzałkę o 180 stopni, aby światło prawidłowo łapało "wierzch" ścian zamiast "wnętrza".
  vec3 normal = -normalize(cross(u, v));
  
  // Kierunek z punktu do naszej kamery. Ponieważ pozycję kamery wyliczamy w środku jako (0,0,0), kierunek to odwrócona pozycja punktu.
  vec3 viewDirection = normalize(-ecPosition);
  
  // Startowe zmienne trzymające sumę światła z wszystkich żarówek padających na ten jeden piksel.
  vec3 totalAmbient = vec3(0.0);
  vec3 totalDiffuse = vec3(0.0);
  vec3 totalSpecular = vec3(0.0);
  
  // Pętla iterująca przez wszystkie aktywne światła na mapie.
  for (int i = 0; i < 8; i++) {
    // Jeśli zbadaliśmy już wszystkie prawdziwe źródła światła, wychodzimy z pętli żeby nie marnować mocy karty.
    if (i >= lightCount) break;
    
    // Dodajemy poświatę światła z otoczenia, niezależnie od odległości.
    totalAmbient += lightAmbient[i];
    
    // Jeśli światło nie emituje realnego koloru, pomijamy ciężkie wzory trygonometryczne.
    if (length(lightDiffuse[i]) == 0.0 && length(lightSpecular[i]) == 0.0) continue;
    
    vec3 lightDir;
    float attenuation = 1.0; // Utrata jasności światła z dystansem (1.0 = świeci najmocniej)
    float spotEffect = 1.0;  // Utrata jasności na obrzeżach reflektora (1.0 = sam środek latarki)
    
    // Jeśli 'w' pozycji światła to 0.0, oznacza to, że jest to słońce (światło kierunkowe z nieskończoności, nie ma punktu w przestrzeni).
    if (lightPosition[i].w == 0.0) {
      // Kierunek od słońca jest stały dla całej gry (i odwracamy go minusem by wskazywał od piksela stronę nieba).
      lightDir = -normalize(lightNormal[i]);
    } else {
      // Jeśli to normalna żarówka (latarnia/reflektor).
      // Wektor z tego narysowanego piksela do pozycji żarówki.
      vec3 lightPath = lightPosition[i].xyz - ecPosition;
      // Dystans mierzony funkcją length() od żarówki do piksela.
      float dist = length(lightPath);
      // Ujednolicamy dystans by stworzyć czysty wektor celujący (kierunek 3D).
      lightDir = normalize(lightPath);
      
      // Wzór na "słabnięcie" światła w miarę odległości od latarni. Falloff x,y,z ustawialiśmy w setupLights().
      attenuation = 1.0 / (lightFalloff[i].x + lightFalloff[i].y * dist + lightFalloff[i].z * dist * dist);
      
      // Jeśli światło jest reflektorem łazika (czyli ma ustawiony limit szerokości stożka świecenia x > 0.0).
      if (lightSpot[i].x > 0.0) {
        // Obliczamy tzw. iloczyn skalarny (dot product). 
        // W skrócie: funkcja dot(A, B) zwraca wartość 1.0 gdy patrzysz idealnie w promień reflektora, i maleje do zera w miarę skręcania głowy.
        float spotCos = dot(lightDir, normalize(-lightNormal[i]));
        // Jeśli punkt jest poza światłem (kąt jest za duży, wartość spadła poza tolerancję reflektora), wyciemniamy na zero.
        if (spotCos < lightSpot[i].x) spotEffect = 0.0;
        // W przeciwnym razie robimy płynne zanikanie na krawędzi snopa światła matematycznym potęgowaniem (pow).
        else spotEffect = pow(max(0.0, spotCos), lightSpot[i].y);
      }
    }
    
    // Ostateczna, skumulowana siła tego konkretnego źródła światła uderzająca w ten piksel.
    float intensity = attenuation * spotEffect;
    
    // Obliczamy to dalej tylko jeśli światło w ogóle tu dociera (świeci > 0).
    if (intensity > 0.0) {
      // Wzór na rozproszenie (Diffuse): Iloczyn wektora ściany (normal) oraz kierunku padania fotonów światła.
      // Wylicza to jak mocno "na wprost" ściana patrzy w światło. Ściana ustawiona bokiem do latarni dostanie prawie zero światła.
      float diffuseFactor = max(0.0, dot(normal, lightDir));
      
      // Dodajemy kolor światła pomnożony przez kąt ściany i jego utratę w przestrzeni do wielkiej puli zebranej ze wszystkich świateł.
      totalDiffuse += lightDiffuse[i] * diffuseFactor * intensity;
      
      // Jeśli materiał nie jest matem i pochłania choć trochę światła - tworzymy "BŁYSK" (Specular)
      if (diffuseFactor > 0.0 && myShininess > 0.0) {
        // Algorytm liczenia odbicia błysku (metoda Phonga): odbijamy promień światła względem kąta ściany jak odbicie piłki w bilardzie.
        vec3 reflection = reflect(-lightDir, normal);
        
        // Znowu iloczyn skalarny: badamy jak bardzo ta odbita wirtualna piłka uderzyłaby prosto w nasze Oczy (kamerę). Im bliżej trafienia, tym jaśniejszy błysk.
        float specularFactor = pow(max(0.0, dot(reflection, viewDirection)), myShininess);
        // Dodajemy potężny błysk specualar (tylko w materiale Metalowym) do naszego kalkulatora.
        totalSpecular += lightSpecular[i] * specularFactor * intensity;
      }
    }
  }
  
  // Bierzemy sam kolor z wierzchołka RGB (odrzucamy A, czyli kanał Alpha przeźroczystości, bo nasz świat jest stały na trójkątach).
  vec3 baseColor = vertColor.rgb;
  
  // WZÓR KOŃCOWY ŁĄCZĄCY WSZYSTKO W JEDEN KOLOR PIKSELA:
  // Kolor świecący sam w sobie (dla żarówek) +
  // Najzwyklejszy kolor bazowy pomnożony przez odcień materiału oraz cień +
  // Kolor bazowy uderzony wszystkimi promieniami oświetlającymi na wprost +
  // Biały kolor materiału mnożony przez idealne odbicia promieni światła od kątów (błysk metalu).
  vec3 finalColor = myEmissive.rgb + 
                    baseColor * myAmbient.rgb * totalAmbient + 
                    baseColor * totalDiffuse + 
                    mySpecular.rgb * totalSpecular;
                    
  // Zabezpieczenie: jeśli na siłę powiedzieliśmy materiałowi "BĄDŹ ŻARÓWKĄ" z poziomu Processinga w funkcji emissive(), to wymuszamy czysty, rażący kolor świecenia, ignorując i deklasując cienie i inne zmienne (latarnia w nocy).
  if (length(myEmissive.rgb) > 0.05) {
    finalColor = baseColor;
  }
  
  // Wrzucamy zsumowany, piękny kolor piksela do wbudowanej w OpenGL ostatecznej zmiennej wypluwanej na monitor dla kanału RGB i oryginalnej przeźroczystości wierzchołka.
  gl_FragColor = vec4(finalColor, vertColor.a);
}