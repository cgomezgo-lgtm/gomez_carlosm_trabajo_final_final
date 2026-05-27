import processing.sound.*;

AudioIn entrada;
Amplitude analizadorVol;
FFT analizadorFFT;

int bandas = 256;
float[] espectro  = new float[bandas];

float volSuave  = 0;
float bassSuave = 0;

int numFlores = 7;

PShape[] floresImg = new PShape[numFlores];

float[] floresX    = new float[numFlores];
float[] floresY    = new float[numFlores];
float[] floresTam  = new float[numFlores];
float[] floresEsc  = new float[numFlores];
float[] floresAng  = new float[numFlores];
float[] floresVel  = new float[numFlores];
float[] floresFase = new float[numFlores];

int numBokeh = 25;

float[] bokehX    = new float[numBokeh];
float[] bokehY    = new float[numBokeh];
float[] bokehTam  = new float[numBokeh];
float[] bokehAlfa = new float[numBokeh];
float[] bokehVX   = new float[numBokeh];
float[] bokehVY   = new float[numBokeh];

int[] bokehCol = new int[numBokeh];

color[] paleta = {

  color(255, 80, 180),
  color(80, 255, 160),
  color(120, 200, 255),
  color(255, 220, 60),
  color(180, 80, 255),
  color(255, 130, 50),
  color(60, 255, 230)

};

float[] sueloH   = new float[400];
int[] sueloCol   = new int[400];

boolean audioActivo = false;

void setup() {

  size(1200, 700);

  colorMode(RGB, 255);

  shapeMode(CORNER);

  background(5,5,15);

  // FLORES
  float margen = 80;

  float paso = (width - margen * 2) / (numFlores - 1);

  for (int i = 0; i < numFlores; i++) {

    floresX[i] = margen + i * paso;

    floresY[i] = height - 20;

    floresTam[i] = random(180, 260);

    floresEsc[i] = 1.0;

    floresAng[i] = 0;

    floresVel[i] = random(0.008, 0.018);

    floresFase[i] = random(TWO_PI);

    floresImg[i] = loadShape("flor6.svg");

    if (floresImg[i] != null) {

      floresImg[i].disableStyle();

    }
  }

  // BOKEH
  for (int i = 0; i < numBokeh; i++) {

    bokehX[i] = random(width);

    bokehY[i] = random(height);

    bokehTam[i] = random(40, 130);

    bokehAlfa[i] = random(15, 45);

    bokehVX[i] = random(-0.3, 0.3);

    bokehVY[i] = random(-0.2, 0.1);

    bokehCol[i] = int(random(paleta.length));
  }

  // SUELO
  for (int i = 0; i < sueloH.length; i++) {

    sueloH[i] = random(8, 22);

    sueloCol[i] = int(random(paleta.length));

  }

  // AUDIO
  entrada = new AudioIn(this, 0);

  analizadorVol = new Amplitude(this);

  analizadorFFT = new FFT(this, bandas);

  entrada.start();

  analizadorVol.input(entrada);

  analizadorFFT.input(entrada);

  audioActivo = true;
}

void draw() {

  // FONDO
  fill(5, 5, 15, 25);

  noStroke();

  rect(0, 0, width, height);

  actualizarAudio();

  dibujarBokeh();

  dibujarFlores();

  dibujarSuelo();
}

void actualizarAudio() {

  if (!audioActivo) return;

  float vol = analizadorVol.analyze();

  // MÁS SENSIBILIDAD
  volSuave = lerp(volSuave, vol * 6.0, 0.25);

  analizadorFFT.analyze(espectro);

  float sumaBass = 0;

  for (int i = 0; i < 8; i++) {

    sumaBass += espectro[i];

  }

  bassSuave = lerp(bassSuave, sumaBass / 8, 0.25);

  println(volSuave);
}

void dibujarBokeh() {

  noStroke();

  for (int i = 0; i < numBokeh; i++) {

    bokehX[i] += bokehVX[i];

    bokehY[i] += bokehVY[i];

    if (bokehX[i] < -bokehTam[i]) {
      bokehX[i] = width + bokehTam[i];
    }

    if (bokehX[i] > width + bokehTam[i]) {
      bokehX[i] = -bokehTam[i];
    }

    if (bokehY[i] < -bokehTam[i]) {
      bokehY[i] = height + bokehTam[i];
    }

    if (bokehY[i] > height + bokehTam[i]) {
      bokehY[i] = -bokehTam[i];
    }

    float tam = bokehTam[i] * (1.0 + bassSuave * 8.0);

    float alfa = bokehAlfa[i] + bassSuave * 120;

    color c = paleta[bokehCol[i]];

    fill(red(c), green(c), blue(c), constrain(alfa, 0, 120));

    ellipse(bokehX[i], bokehY[i], tam, tam);

    fill(red(c), green(c), blue(c), 20);

    ellipse(bokehX[i], bokehY[i], tam * 1.7, tam * 1.7);
  }
}

void dibujarFlores() {

  for (int i = 0; i < numFlores; i++) {

    // ESCALA MÁS FUERTE
    float escObj = constrain(
      map(volSuave, 0, 0.1, 0.8, 2.8),
      0.8,
      2.8
    );

    floresEsc[i] = lerp(floresEsc[i], escObj, 0.12);

    float osc = sin(frameCount * floresVel[i] + floresFase[i]) * 0.04;

    // MÁS MOVIMIENTO
    float sac = bassSuave * 1.5 * ((i % 2 == 0) ? 1 : -1);

    floresAng[i] = lerp(floresAng[i], osc + sac, 0.2);

    float tam = floresTam[i] * floresEsc[i];

    float hueVal = (frameCount * 0.4 + i * 52) % 360;

    colorMode(HSB, 360, 255, 255);

    color tinte = color(hueVal, 170, 255);

    colorMode(RGB, 255);

    pushMatrix();

    translate(floresX[i], floresY[i]);

    rotate(floresAng[i]);

    noStroke();

    fill(red(tinte), green(tinte), blue(tinte), 40 + bassSuave * 120);

    ellipse(0, -tam * 0.5, tam * 1.5, tam * 1.5);

    if (floresImg[i] != null) {

      fill(red(tinte), green(tinte), blue(tinte), 255);

      shape(floresImg[i], -tam / 2, -tam, tam, tam);

    } else {

      fill(red(tinte), green(tinte), blue(tinte), 255);

      ellipse(0, -tam * 0.5, tam * 0.6, tam * 0.6);

    }

    popMatrix();
  }
}

void dibujarSuelo() {

  noStroke();

  float pulsoBass = bassSuave * 50;

  for (int i = 0; i < sueloH.length; i++) {

    color c = paleta[sueloCol[i]];

    fill(red(c), green(c), blue(c), 180);

    float x = map(i, 0, sueloH.length, 0, width);

    rect(
      x,
      height - sueloH[i] - pulsoBass,
      3,
      sueloH[i] + pulsoBass
    );
  }
}
